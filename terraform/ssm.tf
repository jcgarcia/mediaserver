# terraform/ssm.tf
# Generate JWT secret
resource "random_password" "jwt_secret" {
  length  = 32
  special = true
}

# Store JWT secret in Parameter Store
resource "aws_ssm_parameter" "jwt_secret" {
  name  = "/${var.project_name}/jwt-secret"
  type  = "SecureString"
  value = random_password.jwt_secret.result

  tags = {
    Name = "${var.project_name}-jwt-secret"
  }
}

# Store S3 bucket name in Parameter Store
resource "aws_ssm_parameter" "s3_bucket_name" {
  name  = "/${var.project_name}/s3-bucket-name"
  type  = "String"
  value = aws_s3_bucket.media_storage.bucket

  tags = {
    Name = "${var.project_name}-s3-bucket-name"
  }
}

# Store application configuration
resource "aws_ssm_parameter" "app_config" {
  name = "/${var.project_name}/app-config"
  type = "String"
  value = jsonencode({
    NODE_ENV     = var.environment
    AWS_REGION   = var.aws_region
    S3_BUCKET    = aws_s3_bucket.media_storage.bucket
    APP_PORT     = var.container_port
  })

  tags = {
    Name = "${var.project_name}-app-config"
  }
}
