# MediaServer Terraform Infrastructure

This directory contains the complete Terraform infrastructure for deploying the MediaServer application on AWS.

## Architecture Overview

The Terraform configuration creates a production-ready, scalable infrastructure including:

- **ECS Fargate Cluster** - Serverless container orchestration
- **Application Load Balancer** - HTTP/HTTPS load balancing and SSL termination
- **ECR Repository** - Container image registry with lifecycle policies
- **S3 Bucket** - Media storage with encryption and lifecycle management
- **Auto Scaling** - CPU-based scaling with CloudWatch alarms
- **Security Groups** - Network security with least privilege access
- **IAM Roles** - Service permissions with minimal required access
- **CloudWatch** - Logging, monitoring, and alerting
- **Systems Manager** - Secure parameter storage for secrets

## Prerequisites

1. **AWS CLI** configured with appropriate permissions
2. **Terraform** >= 1.0 installed
3. **Docker** for building and pushing images
4. AWS account with sufficient permissions

### Required AWS Permissions

Your AWS user/role needs permissions for:
- ECS (full access)
- ECR (full access)
- S3 (full access)
- IAM (role creation and policy attachment)
- CloudWatch (logs and metrics)
- Systems Manager (parameter store)
- Application Load Balancer
- Auto Scaling

## Quick Start

### 1. Clone and Setup

```bash
git clone <repository>
cd mediaserver
git checkout terra
```

### 2. Configure Variables

```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# Edit terraform.tfvars with your specific values
```

### 3. Deploy Infrastructure

```bash
./deploy-terraform.sh
```

### 4. Build and Deploy Application

```bash
# Login to ECR
ECR_URL=$(cd terraform && terraform output -raw ecr_repository_url)
aws ecr get-login-password --region eu-west-2 | docker login --username AWS --password-stdin $ECR_URL

# Build and push image
docker build -t mediaserver .
docker tag mediaserver:latest $ECR_URL:latest
docker push $ECR_URL:latest

# Update ECS service
aws ecs update-service --cluster mediaserver-cluster --service mediaserver-service --force-new-deployment
```

## Configuration

### terraform.tfvars Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `aws_region` | AWS region for deployment | `eu-west-2` | No |
| `environment` | Environment name | `production` | No |
| `project_name` | Project name for resources | `mediaserver` | No |
| `container_cpu` | CPU units for ECS tasks | `256` | No |
| `container_memory` | Memory (MB) for ECS tasks | `512` | No |
| `desired_count` | Initial number of tasks | `2` | No |
| `min_capacity` | Minimum tasks for scaling | `1` | No |
| `max_capacity` | Maximum tasks for scaling | `10` | No |
| `container_port` | Application port | `3000` | No |
| `allowed_cidr_blocks` | CIDR blocks for ALB access | `["0.0.0.0/0"]` | No |
| `enable_s3_versioning` | Enable S3 versioning | `true` | No |
| `s3_bucket_force_destroy` | Allow Terraform to destroy bucket | `false` | No |
| `log_retention_days` | CloudWatch log retention | `30` | No |
| `enable_deletion_protection` | ALB deletion protection | `false` | No |
| `ssl_certificate_arn` | SSL certificate ARN | `""` | No |

### Example Configuration

```hcl
# Basic configuration
aws_region = "eu-west-2"
environment = "production"
project_name = "mediaserver"

# Scaling configuration
desired_count = 3
min_capacity = 2
max_capacity = 20

# Security configuration
allowed_cidr_blocks = ["10.0.0.0/8", "172.16.0.0/12"]

# SSL configuration (optional)
ssl_certificate_arn = "arn:aws:acm:eu-west-2:123456789012:certificate/abc123"
```

## Resource Details

### ECS Cluster
- **Name**: `{project_name}-cluster`
- **Type**: Fargate
- **Container Insights**: Enabled
- **Capacity Providers**: Fargate and Fargate Spot

### Application Load Balancer
- **Type**: Application Load Balancer
- **Scheme**: Internet-facing
- **Listeners**: HTTP (80), optional HTTPS (443)
- **Health Check**: `GET /health`

### Auto Scaling
- **Metric**: CPU Utilization
- **Scale Up**: >70% CPU for 2 periods (5 minutes)
- **Scale Down**: <20% CPU for 2 periods (5 minutes)
- **Cooldown**: 5 minutes

### S3 Bucket
- **Encryption**: AES256
- **Versioning**: Configurable
- **Lifecycle**: Standard → IA (30 days) → Glacier (90 days)
- **Public Access**: Blocked

### Security
- **ECS Tasks**: Accept traffic only from ALB
- **ALB**: Accept traffic from specified CIDR blocks
- **IAM**: Least privilege roles for ECS execution and tasks

## Deployment Process

### Infrastructure Deployment

1. **Validation**: Terraform validates configuration
2. **Planning**: Shows resources to be created/modified
3. **Confirmation**: Manual approval required
4. **Provisioning**: Creates all AWS resources
5. **Output**: Displays important resource information

### Application Deployment

1. **Image Build**: Docker builds application image
2. **ECR Push**: Uploads image to ECR repository
3. **Service Update**: ECS updates service with new image
4. **Health Check**: Verifies application health

## Monitoring and Logging

### CloudWatch Logs
- **ECS Logs**: `/ecs/{project_name}`
- **Application Logs**: `/aws/ecs/{project_name}/app`
- **Retention**: Configurable (default 30 days)

### CloudWatch Metrics
- **ECS Service**: CPU, Memory, Task count
- **ALB**: Request count, Response time, Errors
- **S3**: Storage usage, Request metrics

### CloudWatch Alarms
- **High CPU**: Triggers scale up
- **Low CPU**: Triggers scale down
- **Custom alarms**: Can be added for other metrics

## Scaling

### Horizontal Scaling
- **Auto Scaling**: Based on CPU utilization
- **Manual Scaling**: Update `desired_count` variable
- **Load Balancing**: ALB distributes traffic across tasks

### Vertical Scaling
- **CPU/Memory**: Update `container_cpu` and `container_memory`
- **Instance Types**: Fargate handles underlying compute

## Security Best Practices

### Network Security
- **VPC**: Uses default VPC (can be customized)
- **Security Groups**: Restrictive ingress rules
- **ALB**: Public-facing with configurable CIDR access
- **ECS Tasks**: Private communication via ALB

### Data Security
- **S3 Encryption**: Server-side encryption at rest
- **Secrets**: Stored in Systems Manager Parameter Store
- **IAM**: Minimal required permissions
- **Container Security**: Non-root user, security scanning

### Access Control
- **JWT Authentication**: Application-level auth
- **AWS IAM**: Infrastructure access control
- **Parameter Store**: Secure secret storage
- **CloudTrail**: API access logging (optional)

## Troubleshooting

### Common Issues

#### 1. Deployment Fails
```bash
# Check Terraform logs
terraform plan -detailed-exitcode

# Validate configuration
terraform validate

# Check AWS permissions
aws sts get-caller-identity
```

#### 2. ECS Service Unhealthy
```bash
# Check service status
aws ecs describe-services --cluster mediaserver-cluster --services mediaserver-service

# Check task logs
aws logs tail /ecs/mediaserver --follow

# Check task definition
aws ecs describe-task-definition --task-definition mediaserver
```

#### 3. ALB Health Check Failures
```bash
# Check target group health
aws elbv2 describe-target-health --target-group-arn <target-group-arn>

# Test health endpoint
curl http://<alb-dns>/health

# Check security groups
aws ec2 describe-security-groups --group-ids <security-group-id>
```

#### 4. Application Not Accessible
```bash
# Check ALB status
aws elbv2 describe-load-balancers --names mediaserver-alb

# Check DNS resolution
nslookup <alb-dns-name>

# Check listener rules
aws elbv2 describe-listeners --load-balancer-arn <alb-arn>
```

### Diagnostic Commands

```bash
# Get all outputs
cd terraform && terraform output

# Check resource status
aws ecs list-clusters
aws ecs list-services --cluster mediaserver-cluster
aws s3 ls

# View logs
aws logs describe-log-groups --log-group-name-prefix "/ecs/mediaserver"
aws logs tail /ecs/mediaserver --since 1h

# Check scaling activities
aws application-autoscaling describe-scaling-activities --service-namespace ecs
```

## Cost Optimization

### Resource Optimization
- **Fargate Spot**: Use for non-critical workloads
- **Reserved Capacity**: For predictable workloads
- **S3 Lifecycle**: Automatic archival to cheaper storage
- **Log Retention**: Shorter retention for cost savings

### Monitoring Costs
- **AWS Cost Explorer**: Track spending by service
- **Budgets**: Set up spending alerts
- **Right-sizing**: Monitor and adjust resource allocation

## Cleanup

### Destroy Infrastructure
```bash
./destroy-terraform.sh
```

### Manual Cleanup (if needed)
```bash
# Remove ECR images first
aws ecr list-images --repository-name mediaserver --query 'imageIds[*]' --output json | \
aws ecr batch-delete-image --repository-name mediaserver --image-ids file:///dev/stdin

# Then destroy with Terraform
cd terraform && terraform destroy
```

## Advanced Configuration

### Custom VPC
Update `data.tf` to reference your custom VPC:
```hcl
data "aws_vpc" "custom" {
  tags = {
    Name = "my-custom-vpc"
  }
}
```

### Multi-Environment
Use Terraform workspaces:
```bash
terraform workspace new staging
terraform workspace new production
terraform workspace select production
```

### SSL/TLS Configuration
Add SSL certificate:
```hcl
ssl_certificate_arn = "arn:aws:acm:region:account:certificate/cert-id"
```

### Custom Domain
Add Route 53 records:
```hcl
resource "aws_route53_record" "mediaserver" {
  zone_id = var.hosted_zone_id
  name    = var.domain_name
  type    = "A"
  
  alias {
    name                   = aws_lb.mediaserver.dns_name
    zone_id                = aws_lb.mediaserver.zone_id
    evaluate_target_health = true
  }
}
```

## Support

For issues and questions:
1. Check the troubleshooting section
2. Review AWS CloudWatch logs
3. Validate Terraform configuration
4. Check AWS service limits
5. Open an issue in the repository

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes and test
4. Submit a pull request
5. Ensure all tests pass