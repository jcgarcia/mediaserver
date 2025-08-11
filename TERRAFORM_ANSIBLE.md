# Infrastructure as Code (IaC) Deployment Guide

This document describes how to deploy the MediaServer using **Terraform** for infrastructure provisioning and **Ansible** for application deployment and management.

## 🏗️ **Architecture Overview**

```
┌─────────────────────────────────────────────────────────────┐
│                    Infrastructure as Code                   │
├─────────────────────────────────────────────────────────────┤
│  Terraform (Infrastructure)    │    Ansible (Deployment)    │
│  • S3 Bucket                   │    • Docker Build & Push   │
│  • ECS Cluster                 │    • Service Management    │
│  • IAM Roles                   │    • Health Checks         │
│  • Security Groups             │    • Scaling Operations    │
│  • CloudWatch Logs             │    • Log Management        │
│  • Parameter Store             │    • Restart Operations    │
└─────────────────────────────────────────────────────────────┘
```

## 📁 **Project Structure**

```
mediaserver/
├── terraform/              # Infrastructure as Code
│   ├── provider.tf         # AWS provider configuration
│   ├── variables.tf        # Input variables
│   ├── data.tf            # Data sources
│   ├── s3.tf              # S3 bucket configuration
│   ├── iam.tf             # IAM roles and policies
│   ├── ecs.tf             # ECS cluster and service
│   ├── security.tf        # Security groups
│   ├── cloudwatch.tf      # Monitoring and logs
│   ├── ssm.tf             # Parameter Store
│   ├── outputs.tf         # Output values
│   └── terraform.tfvars.example
├── ansible/               # Deployment automation
│   ├── ansible.cfg        # Ansible configuration
│   ├── inventory/         # Inventory files
│   ├── playbooks/         # Deployment playbooks
│   │   ├── deploy.yml     # Main deployment playbook
│   │   ├── manage.yml     # Management operations
│   │   └── destroy.yml    # Infrastructure destruction
│   └── requirements.yml   # Ansible dependencies
├── scripts/               # Utility scripts
│   ├── setup.sh          # Environment setup
│   ├── deploy.sh         # Deploy infrastructure + app
│   └── manage.sh         # Manage running application
└── src/                  # Application source code
```

## 🚀 **Quick Start**

### **1. Prerequisites**

Ensure you have the following tools installed:

```bash
# Required tools
- AWS CLI (configured with SSO or credentials)
- Terraform >= 1.0
- Ansible >= 2.9
- Docker
- Node.js >= 18
```

### **2. Setup Environment**

```bash
# Run the setup script
./scripts/setup.sh
```

This script will:
- Check prerequisites
- Install Node.js dependencies
- Install Ansible collections
- Initialize Terraform
- Create configuration templates

### **3. Configure Deployment**

```bash
# Copy and edit Terraform variables
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# Edit with your specific values

# Copy and edit environment variables
cp .env.example .env
# Edit with your specific values
```

### **4. Deploy Infrastructure and Application**

```bash
# Deploy everything
./scripts/deploy.sh
```

This will:
- Create AWS infrastructure with Terraform
- Build and push Docker image to ECR
- Deploy ECS service with Ansible
- Configure monitoring and logging

## 🔧 **Management Operations**

### **Check Service Status**
```bash
./scripts/manage.sh status
```

### **View Application Logs**
```bash
./scripts/manage.sh logs
```

### **Scale Service**
```bash
./scripts/manage.sh scale --desired-count 3
```

### **Restart Service**
```bash
./scripts/manage.sh restart
```

### **Destroy Infrastructure**
```bash
./scripts/manage.sh destroy
```

## 📋 **Terraform Configuration**

### **Key Variables (terraform/terraform.tfvars)**

```hcl
# AWS Configuration
aws_region = "eu-west-2"
environment = "production"
project_name = "mediaserver"

# ECS Configuration
container_cpu = 256
container_memory = 512
desired_count = 2
container_port = 3000

# Security Configuration
allowed_cidr_blocks = ["0.0.0.0/0"]  # Restrict in production

# S3 Configuration
enable_s3_versioning = true
s3_bucket_force_destroy = false

# Monitoring
log_retention_days = 30
```

### **Manual Terraform Operations**

```bash
cd terraform

# Initialize
terraform init

# Plan changes
terraform plan

# Apply changes
terraform apply

# Show outputs
terraform output

# Destroy (careful!)
terraform destroy
```

## 🎛️ **Ansible Playbooks**

### **deploy.yml**
- Complete infrastructure deployment
- Docker image build and push
- ECS service deployment
- Health checks

### **manage.yml**
- Service status checks
- Scaling operations
- Service restarts
- Log retrieval

### **destroy.yml**
- Safe infrastructure destruction
- Service scaling to zero
- Resource cleanup

### **Manual Ansible Operations**

```bash
cd ansible

# Install dependencies
ansible-galaxy install -r requirements.yml

# Run deployment
ansible-playbook playbooks/deploy.yml

# Check service status
ansible-playbook playbooks/manage.yml -e action=status

# Scale service
ansible-playbook playbooks/manage.yml -e action=scale -e desired_count=3

# View logs
ansible-playbook playbooks/manage.yml -e action=logs

# Destroy infrastructure
ansible-playbook playbooks/destroy.yml
```

## 🔍 **Monitoring and Troubleshooting**

### **CloudWatch Dashboard**
Terraform creates a CloudWatch dashboard with:
- ECS service metrics (CPU, Memory)
- S3 storage metrics
- Custom application metrics

### **Log Groups**
- `/ecs/mediaserver` - ECS task logs
- `/aws/ecs/mediaserver/app` - Application logs

### **Useful AWS CLI Commands**

```bash
# Check ECS service
aws ecs describe-services --cluster mediaserver-cluster --services mediaserver-service

# Get task public IPs
aws ecs describe-tasks --cluster mediaserver-cluster --tasks $(aws ecs list-tasks --cluster mediaserver-cluster --query 'taskArns[0]' --output text) --query 'tasks[0].attachments[0].details[?name==`networkInterfaceId`].value' --output text | xargs -I {} aws ec2 describe-network-interfaces --network-interface-ids {} --query 'NetworkInterfaces[0].Association.PublicIp' --output text

# View recent logs
aws logs tail /ecs/mediaserver --follow

# Check S3 bucket
aws s3 ls s3://[bucket-name] --recursive
```

## 🔒 **Security Best Practices**

### **Production Hardening**

1. **Network Security**
   ```hcl
   # Restrict access to specific IPs
   allowed_cidr_blocks = ["203.0.113.0/24"]  # Your office IP range
   ```

2. **S3 Security**
   ```hcl
   # Enable versioning and lifecycle policies
   enable_s3_versioning = true
   s3_bucket_force_destroy = false
   ```

3. **Container Security**
   - Non-root user in Dockerfile
   - Security scanning enabled in ECR
   - Least privilege IAM policies

4. **Secrets Management**
   - JWT secrets in Parameter Store (encrypted)
   - No hardcoded credentials
   - Environment-specific configurations

## 🔄 **CI/CD Integration**

### **GitHub Actions Example**

```yaml
name: Deploy MediaServer
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          aws-region: eu-west-2
      - name: Deploy
        run: ./scripts/deploy.sh
```

## 📊 **Cost Optimization**

### **Estimated Monthly Costs**
- **ECS Fargate**: ~$15-30 (2 tasks, 0.25 vCPU, 0.5GB RAM)
- **S3 Storage**: ~$1-5 (depending on usage)
- **Data Transfer**: ~$1-10 (depending on traffic)
- **CloudWatch Logs**: ~$1-5
- **Total**: ~$18-50/month

### **Cost Reduction Tips**
- Use FARGATE_SPOT for development
- Implement S3 lifecycle policies
- Optimize container resource allocation
- Set up CloudWatch billing alerts

## 🆘 **Troubleshooting**

### **Common Issues**

1. **Terraform Init Fails**
   ```bash
   # Clear cache and reinitialize
   rm -rf .terraform
   terraform init
   ```

2. **Docker Build Fails**
   ```bash
   # Check Docker daemon
   docker version
   # Clean up images
   docker system prune -f
   ```

3. **ECS Service Won't Start**
   ```bash
   # Check task definition
   aws ecs describe-task-definition --task-definition mediaserver
   # Check service events
   aws ecs describe-services --cluster mediaserver-cluster --services mediaserver-service
   ```

4. **Cannot Access Application**
   ```bash
   # Check security group
   aws ec2 describe-security-groups --group-names mediaserver-ecs-tasks
   # Check task public IP
   # Verify health endpoint: curl http://[IP]:3000/health
   ```

This Infrastructure as Code approach provides:
- ✅ **Reproducible** deployments
- ✅ **Version controlled** infrastructure
- ✅ **Automated** operations
- ✅ **Scalable** architecture
- ✅ **Production ready** security
