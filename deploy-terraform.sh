#!/bin/bash

# deploy-terraform.sh - Deploy MediaServer infrastructure with Terraform

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Configuration
TERRAFORM_DIR="terraform"
AWS_REGION=${AWS_REGION:-"eu-west-2"}
ENVIRONMENT=${ENVIRONMENT:-"production"}
PROJECT_NAME=${PROJECT_NAME:-"mediaserver"}

print_status "Starting MediaServer infrastructure deployment..."

# Check prerequisites
print_status "Checking prerequisites..."

if ! command -v terraform &> /dev/null; then
    print_error "Terraform is not installed. Please install Terraform first."
    exit 1
fi

if ! command -v aws &> /dev/null; then
    print_error "AWS CLI is not installed. Please install AWS CLI first."
    exit 1
fi

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    print_error "AWS credentials not configured. Please run 'aws configure' first."
    exit 1
fi

print_success "Prerequisites check passed"

# Change to terraform directory
cd "$TERRAFORM_DIR"

# Create terraform.tfvars if it doesn't exist
if [ ! -f "terraform.tfvars" ]; then
    print_warning "terraform.tfvars not found. Creating from example..."
    cp terraform.tfvars.example terraform.tfvars
    print_warning "Please edit terraform.tfvars with your specific values and run this script again."
    exit 1
fi

# Initialize Terraform
print_status "Initializing Terraform..."
terraform init

# Validate Terraform configuration
print_status "Validating Terraform configuration..."
terraform validate

# Plan the deployment
print_status "Planning Terraform deployment..."
terraform plan -out=tfplan

# Ask for confirmation
echo ""
print_warning "Review the plan above. Do you want to apply these changes? (yes/no)"
read -r response

if [[ "$response" != "yes" ]]; then
    print_error "Deployment cancelled."
    exit 1
fi

# Apply the deployment
print_status "Applying Terraform configuration..."
terraform apply tfplan

# Get outputs
print_status "Retrieving deployment information..."
echo ""
print_success "Deployment completed successfully!"
echo ""

# Display important outputs
ECR_URL=$(terraform output -raw ecr_repository_url)
S3_BUCKET=$(terraform output -raw s3_bucket_name)
ALB_DNS=$(terraform output -raw alb_dns_name)
APP_URL=$(terraform output -raw application_url)

echo "=== Deployment Summary ==="
echo "Project: $PROJECT_NAME"
echo "Environment: $ENVIRONMENT"
echo "Region: $AWS_REGION"
echo ""
echo "Resources Created:"
echo "- ECR Repository: $ECR_URL"
echo "- S3 Bucket: $S3_BUCKET"
echo "- Load Balancer: $ALB_DNS"
echo "- Application URL: $APP_URL"
echo ""

# Create deployment info file
cat > ../deployment-info.txt << EOF
MediaServer Deployment Information
Generated: $(date)

ECR Repository URL: $ECR_URL
S3 Bucket Name: $S3_BUCKET
Load Balancer DNS: $ALB_DNS
Application URL: $APP_URL

Next Steps:
1. Build and push Docker image:
   aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_URL
   docker build -t $PROJECT_NAME .
   docker tag $PROJECT_NAME:latest $ECR_URL:latest
   docker push $ECR_URL:latest

2. Update ECS service to deploy the application:
   aws ecs update-service --cluster $PROJECT_NAME-cluster --service $PROJECT_NAME-service --force-new-deployment

3. Check application health:
   curl $APP_URL/health

4. View logs:
   aws logs tail /ecs/$PROJECT_NAME --follow
EOF

print_success "Deployment information saved to deployment-info.txt"
print_status "Infrastructure deployment complete!"
print_warning "Don't forget to build and push your Docker image to start the application."