#!/bin/bash

# scripts/deploy.sh - Deploy MediaServer using Terraform and Ansible

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Default values
ENVIRONMENT=${ENVIRONMENT:-production}
AWS_REGION=${AWS_REGION:-eu-west-2}
PROJECT_NAME=${PROJECT_NAME:-mediaserver}

print_status "Deploying MediaServer..."
print_status "Environment: $ENVIRONMENT"
print_status "Region: $AWS_REGION"
print_status "Project: $PROJECT_NAME"

# Check if AWS credentials are configured
if ! aws sts get-caller-identity &> /dev/null; then
    print_error "AWS credentials not configured. Please run 'aws configure' or set up SSO"
    exit 1
fi

# Run Ansible deployment playbook
print_status "Running Ansible deployment..."
ansible-playbook ansible/playbooks/deploy.yml \
    -e environment="$ENVIRONMENT" \
    -e aws_region="$AWS_REGION" \
    -e project_name="$PROJECT_NAME" \
    -v

print_status "Deployment completed!"
echo ""
echo "📋 Useful commands:"
echo "- Check status: ./scripts/manage.sh status"
echo "- View logs: ./scripts/manage.sh logs"
echo "- Scale service: ./scripts/manage.sh scale --desired-count 3"
echo "- Restart service: ./scripts/manage.sh restart"
