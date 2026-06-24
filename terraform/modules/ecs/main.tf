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