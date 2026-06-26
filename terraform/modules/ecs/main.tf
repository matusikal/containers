resource "aws_ecs_cluster" "dailylog_cluster" {
  name = "dailylog-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = { Name = "dailylog-cluster" }
}

resource "aws_ecs_cluster_capacity_providers" "dailylog_providers" {
  cluster_name = aws_ecs_cluster.dailylog_cluster.name

  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name = "/ecs/dailylog-api"
  retention_in_days = 7

  tags = { Name = "dailylog-ecs-log-group" }
}


resource "aws_ecs_task_definition" "dailylog_api_task" {
  family                   = "dailylog-api"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([
    {
      name      = "dailylog-api"
      image     = var.ecr_image_url
      essential = true
      
      portMappings = [
        {
          containerPort = 5000
          hostPort      = 5000
          protocol      = "tcp"
        }
      ]

      environment = [
        { name = "DB_HOST",     value = var.rds_endpoint },
        { name = "DB_NAME",     value = "dailylog" },
        { name = "DB_USER",     value = "dailylog_admin" },
        { name = "DB_PASSWORD", value = var.db_password }
      ]
    

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_log_group.name
          "awslogs-region"        = "eu-central-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}



resource "aws_ecs_service" "dailylog_service" {
  name            = "dailylog-service"
  cluster         = aws_ecs_cluster.dailylog_cluster.id
  task_definition = aws_ecs_task_definition.dailylog_api_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_sg_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "dailylog-api"
    container_port   = 5000
  }
}