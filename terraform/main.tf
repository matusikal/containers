terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

module "vpc" {
  source               = "./modules/vpc"
  vpc_cidr             = "10.0.0.0/16"
  public_subnet_1_cidr = "10.0.1.0/24"
  public_subnet_2_cidr = "10.0.2.0/24"
  private_subnet_1_cidr = "10.0.3.0/24"
  private_subnet_2_cidr = "10.0.4.0/24"
}

module "sg" {
  source = "./modules/sg"
  vpc_id = module.vpc.vpc_id
}

module "rds" {
  source     = "./modules/rds"
  subnet_ids = module.vpc.private_subnet_ids
  rds_security_group_id = module.sg.rds_sg_id
}

module "ecr" {
  source = "./modules/ecr"
}

module "alb" {
  source            = "./modules/alb"
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  alb_sg_id         = module.sg.alb_sg_id
}

module "ecs" {
  source = "./modules/ecs"
  execution_role_arn = module.iam.ecs_execution_role_arn
  task_role_arn      = module.iam.ecs_task_role_arn
  ecr_image_url      = module.ecr.repository_url
  rds_endpoint       = module.rds.rds_endpoint
  db_password        = module.rds.db_password
  private_subnet_ids = module.vpc.private_subnet_ids
  ecs_sg_id          = module.sg.ecs_sg_id
  target_group_arn   = module.alb.target_group_arn
}

module "iam" {
  source         = "./modules/iam"
  rds_secret_arn = module.rds.rds_secret_arn
}

module "cognito" {
  source = "./modules/cognito"
  callback_urls = [
    "http://localhost:3000",
    "https://${module.s3.s3_distribution_domain_name}"
  ]
}

module "api" {
  source       = "./modules/api"
  alb_dns_name = module.alb.alb_dns_name
  user_pool_id = module.cognito.user_pool_id
  user_pool_client_id = module.cognito.user_pool_client_id
}

module "s3" {
  source = "./modules/s3"
  bucket_name          = "docker-portfolio-bucket-the-third"
  acm_certificate_arn  = "arn:aws:acm:us-east-1:064318812275:certificate/12a0b8b7-2efc-4c22-a251-9808b3ea6464"
  #domain_aliases        = ["project3.aleksanedermatusik.xyz"]
  environment           = "Dev"
}