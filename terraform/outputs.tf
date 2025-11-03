# terraform/outputs.tf
output "account_id" {
  description = "AWS Account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "region" {
  description = "AWS Region"
  value       = data.aws_region.current.name
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket for media storage"
  value       = aws_s3_bucket.media_storage.bucket
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.media_storage.arn
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.main.arn
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.mediaserver.name
}

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.mediaserver.repository_url
}

output "task_definition_arn" {
  description = "ARN of the ECS task definition"
  value       = aws_ecs_task_definition.mediaserver.arn
}

output "security_group_id" {
  description = "ID of the ECS tasks security group"
  value       = aws_security_group.ecs_tasks.id
}

output "log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.ecs_logs.name
}

output "jwt_secret_parameter" {
  description = "SSM Parameter name for JWT secret"
  value       = aws_ssm_parameter.jwt_secret.name
  sensitive   = true
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = data.aws_vpc.default.id
}

output "subnet_ids" {
  description = "IDs of the subnets"
  value       = data.aws_subnets.default.ids
}

# Export environment variables for application
output "environment_variables" {
  description = "Environment variables for the application"
  value = {
    S3_BUCKET_NAME = aws_s3_bucket.media_storage.bucket
    AWS_REGION     = var.aws_region
    NODE_ENV       = var.environment
    PORT           = var.container_port
  }
}

output "alb_dns_name" {
  description = "DNS name of the load balancer"
  value       = aws_lb.mediaserver.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the load balancer"
  value       = aws_lb.mediaserver.zone_id
}

output "alb_arn" {
  description = "ARN of the load balancer"
  value       = aws_lb.mediaserver.arn
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = aws_lb_target_group.mediaserver.arn
}

output "ecr_repository_arn" {
  description = "ARN of the ECR repository"
  value       = aws_ecr_repository.mediaserver.arn
}

output "application_url" {
  description = "URL to access the application"
  value       = "http://${aws_lb.mediaserver.dns_name}"
}
