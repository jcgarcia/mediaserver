# MediaServer Terraform Deployment Guide

## What We've Built

This "terra" branch contains a complete, production-ready infrastructure setup for the MediaServer application using Terraform. Here's what you now have:

### 📁 Complete Terraform Infrastructure (13 files)
1. **provider.tf** - Connects to AWS and sets up basic configuration
2. **variables.tf** - All customizable settings in one place
3. **data.tf** - Gathers information about existing AWS resources
4. **ecr.tf** - Creates secure storage for application images
5. **s3.tf** - Creates scalable file storage for user media
6. **iam.tf** - Sets up security roles and permissions
7. **security.tf** - Creates network firewalls and access rules
8. **alb.tf** - Creates load balancer for distributing traffic
9. **ecs.tf** - Creates and manages application containers
10. **autoscaling.tf** - Automatically adjusts server count based on demand
11. **cloudwatch.tf** - Sets up monitoring and logging
12. **ssm.tf** - Manages secure configuration storage
13. **outputs.tf** - Reports important information after deployment

### 🚀 Deployment Scripts
- **deploy-terraform.sh** - One-click deployment script
- **destroy-terraform.sh** - Safe cleanup script
- **terraform/README.md** - Complete deployment documentation

### 📚 Documentation
- **TERRAFORM_DOCUMENTATION.md** - Explains every file in simple terms
- **TERRAFORM_DETAILED_BREAKDOWN.md** - Line-by-line code explanations

## What This Infrastructure Gives You

### 🏗️ Production-Ready Architecture
- **High Availability**: Spreads across multiple data centers
- **Auto Scaling**: Automatically handles traffic spikes
- **Load Balancing**: Distributes traffic evenly
- **Security**: Multiple layers of protection
- **Monitoring**: Comprehensive logging and alerting
- **Cost Optimization**: Only pay for what you use

### 🔧 Key Features
- **Serverless Containers**: No server management needed
- **Automatic SSL**: Easy HTTPS setup (when certificate provided)
- **Encrypted Storage**: All data encrypted at rest
- **Backup Strategy**: Versioned storage with lifecycle management
- **Zero-Downtime Deployments**: Update without service interruption
- **Health Monitoring**: Automatic failure detection and recovery

### 💰 Cost Structure
- **Compute**: Pay only when containers are running
- **Storage**: Automatic lifecycle management reduces costs
- **Networking**: Efficient load balancing minimizes data transfer costs
- **Monitoring**: Built-in logging with configurable retention

## Before You Deploy

### Prerequisites Checklist
- [ ] AWS CLI installed and configured
- [ ] Terraform installed (version 1.0+) - **Tested with v1.13.4**
- [ ] Docker installed (for application deployment)
- [ ] AWS account with sufficient permissions
- [ ] Basic understanding of what each component does (see documentation)

### ✅ Validation Status
This infrastructure has been fully tested and validated with:
- **Terraform**: v1.13.4
- **AWS Provider**: v5.100.0
- **Random Provider**: v3.7.2
- **Resources Planned**: 36 AWS resources ready for creation
- **Compatibility**: All AWS Provider v5.x compatibility issues resolved

### AWS Permissions Required
Your AWS user needs permissions for:
- ECS (Elastic Container Service)
- ECR (Elastic Container Registry)
- S3 (Simple Storage Service)
- IAM (Identity and Access Management)
- CloudWatch (Monitoring)
- Systems Manager (Parameter Store)
- Elastic Load Balancing
- Application Auto Scaling

## Deployment Process

### Step 1: Review Configuration
```bash
# Edit the settings file
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
nano terraform/terraform.tfvars  # Adjust settings as needed
```

### Step 2: Deploy Infrastructure
```bash
# Run the deployment script
./deploy-terraform.sh
```

This script will:
1. ✅ Check prerequisites (Terraform, AWS CLI, credentials)
2. 🔍 Initialize Terraform and validate configuration
3. 📋 Show you exactly what will be created
4. ⏰ Wait for your confirmation
5. 🏗️ Build all infrastructure components
6. 📄 Generate deployment summary with important URLs and commands

### Step 3: Deploy Application
After infrastructure is ready:
```bash
# Get the repository URL from deployment output
ECR_URL=$(cd terraform && terraform output -raw ecr_repository_url)

# Login to ECR
aws ecr get-login-password --region eu-west-2 | docker login --username AWS --password-stdin $ECR_URL

# Build and push your application
docker build -t mediaserver .
docker tag mediaserver:latest $ECR_URL:latest
docker push $ECR_URL:latest

# Update the ECS service
aws ecs update-service --cluster mediaserver-cluster --service mediaserver-service --force-new-deployment
```

### Step 4: Verify Deployment
```bash
# Check application health
curl $(cd terraform && terraform output -raw application_url)/health

# Monitor deployment
aws ecs describe-services --cluster mediaserver-cluster --services mediaserver-service

# Watch logs
aws logs tail /ecs/mediaserver --follow
```

## What Happens During Deployment

### Phase 1: Infrastructure Provisioning (5-10 minutes)
1. **Network Setup**: Creates security groups and configures network access
2. **Storage Creation**: Sets up S3 bucket with encryption and policies
3. **Container Registry**: Creates ECR repository for application images
4. **Load Balancer**: Sets up ALB with health checks
5. **Container Platform**: Creates ECS cluster and task definitions
6. **Auto Scaling**: Configures scaling policies and CloudWatch alarms
7. **Monitoring**: Sets up log groups and dashboards
8. **Security**: Creates IAM roles and stores secrets

### Phase 2: Application Deployment (3-5 minutes)
1. **Image Build**: Docker builds your application container
2. **Image Push**: Uploads container to ECR registry
3. **Service Update**: ECS pulls new image and updates running containers
4. **Health Checks**: Load balancer verifies application is responding
5. **Traffic Routing**: New containers start receiving traffic

## Understanding the Components

### Traffic Flow
```
Internet → Load Balancer → ECS Containers → S3 Storage
    ↓           ↓              ↓            ↓
   Users    Distributes    Processes    Stores Files
           Traffic        Requests
```

### Security Layers
```
Internet (Public)
    ↓
Load Balancer (Public subnet)
    ↓
ECS Containers (Private subnet)
    ↓
S3 Storage (Private with encryption)
```

### Scaling Behavior
```
Low Traffic (1-2 containers)
    ↓
Medium Traffic (2-5 containers)
    ↓
High Traffic (5-10 containers)
    ↓
Traffic Decreases → Automatically scales down
```

## Monitoring and Maintenance

### Key Metrics to Watch
- **CPU Utilization**: Should stay below 70% most of the time
- **Memory Usage**: Should have headroom for traffic spikes
- **Request Count**: Helps understand usage patterns
- **Error Rate**: Should be minimal (<1%)
- **Response Time**: Should be consistently fast

### Log Locations
- **Application Logs**: `/ecs/mediaserver`
- **System Logs**: Available through ECS console
- **Access Logs**: Can be enabled on the load balancer

### Regular Maintenance Tasks
- **Security Updates**: Rebuild and redeploy containers regularly
- **Cost Review**: Monitor AWS billing for optimization opportunities
- **Backup Verification**: Ensure S3 versioning is working
- **Performance Tuning**: Adjust container resources based on usage

## Customization Options

### Easy Customizations (in terraform.tfvars)
- **Scaling limits**: Adjust min/max container counts
- **Resource allocation**: Change CPU/memory per container
- **Region**: Deploy in different AWS regions
- **Environment**: Set up separate dev/staging/prod environments

### Advanced Customizations (modify .tf files)
- **Custom domains**: Add Route 53 DNS configuration
- **SSL certificates**: Enable HTTPS with your own certificate
- **Database integration**: Add RDS database
- **Caching layer**: Add Redis/ElastiCache
- **Multiple environments**: Use Terraform workspaces

## Troubleshooting Common Issues

### Deployment Fails
```bash
# Check Terraform logs
terraform plan -detailed-exitcode

# Verify AWS credentials
aws sts get-caller-identity

# Check for naming conflicts
aws s3 ls | grep mediaserver
```

### Application Won't Start
```bash
# Check ECS service status
aws ecs describe-services --cluster mediaserver-cluster --services mediaserver-service

# View container logs
aws logs tail /ecs/mediaserver --follow

# Check task definition
aws ecs describe-task-definition --task-definition mediaserver
```

### Can't Access Application
```bash
# Check load balancer status
aws elbv2 describe-load-balancers --names mediaserver-alb

# Verify security groups
aws ec2 describe-security-groups --filters "Name=group-name,Values=mediaserver-*"

# Test health endpoint directly
curl -v http://[load-balancer-dns]/health
```

## Cost Management

### Expected Monthly Costs (approximate)
- **ECS Fargate**: $30-100 (depending on usage)
- **Load Balancer**: $16-20
- **S3 Storage**: $1-10 (depending on file volume)
- **Data Transfer**: $5-20 (depending on traffic)
- **CloudWatch**: $5-15 (for logs and metrics)

**Total**: $57-165/month for moderate usage

### Cost Optimization Tips
1. **Use Fargate Spot**: Up to 70% savings for fault-tolerant workloads
2. **S3 Lifecycle**: Automatically archive old files
3. **Log Retention**: Reduce log retention period
4. **Right-sizing**: Monitor and adjust container resources
5. **Reserved Capacity**: For predictable workloads

## Next Steps After Deployment

### Immediate Tasks
1. **Set up monitoring alerts**: Configure CloudWatch alarms for critical metrics
2. **Test the application**: Upload files, test all endpoints
3. **Document URLs**: Save load balancer DNS and other important endpoints
4. **Set up CI/CD**: Integrate with your deployment pipeline

### Medium-term Improvements
1. **Custom domain**: Set up Route 53 and SSL certificate
2. **Database integration**: Add persistent data storage
3. **Caching**: Implement Redis for better performance
4. **Multi-environment**: Set up staging and development environments

### Long-term Enhancements
1. **Multi-region**: Deploy across multiple AWS regions
2. **CDN**: Add CloudFront for global content delivery
3. **Advanced monitoring**: Implement APM and error tracking
4. **Backup strategy**: Set up cross-region backup

This infrastructure gives you a solid foundation that can grow with your application. Start with the basic deployment and gradually add more sophisticated features as your needs evolve.