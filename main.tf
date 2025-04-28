terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "your-tf-state-bucket"
    key            = "ecs-demo-project/terraform.tfstate"
    region         = "eu-central-1" 
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}


provider "aws" {
  region = var.aws_region
}

module "network" {
  source = "./modules/network"

  project_name       = var.project_name
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
}

module "security" {
  source = "./modules/security"

  project_name    = var.project_name
  vpc_id          = module.network.vpc_id
  container_port  = var.container_port
}

module "alb" {
  source = "./modules/alb"

  project_name         = var.project_name
  vpc_id               = module.network.vpc_id
  public_subnet_ids    = module.network.public_subnet_ids
  alb_security_group_id = module.security.alb_security_group_id
  container_port       = var.container_port
  health_check_path    = var.health_check_path
}

module "ecs" {
  source = "./modules/ecs"

  project_name               = var.project_name
  aws_region                 = var.aws_region
  vpc_id                     = module.network.vpc_id
  private_subnet_ids         = module.network.private_subnet_ids
  ecs_tasks_security_group_id = module.security.ecs_tasks_security_group_id
  container_image            = var.container_image
  container_port             = var.container_port
  container_cpu              = var.container_cpu
  container_memory           = var.container_memory
  service_desired_count      = var.service_desired_count
  auto_scaling_min_capacity  = var.auto_scaling_min_capacity
  auto_scaling_max_capacity  = var.auto_scaling_max_capacity
  target_group_arn           = module.alb.target_group_arn
  health_check_path          = var.health_check_path
  task_execution_role_arn    = module.security.ecs_task_execution_role_arn
  task_role_arn              = module.security.ecs_task_role_arn
}

# Root module outputs
output "alb_dns_name" {
  description = "DNS name of the load balancer"
  value       = module.alb.alb_dns_name
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs.ecs_cluster_name
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = module.ecs.ecs_service_name
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.network.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.network.private_subnet_ids
}