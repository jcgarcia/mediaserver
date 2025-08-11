#!/bin/bash

# scripts/setup.sh - Setup script for development environment

set -e

echo "🚀 Setting up MediaServer development environment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running in correct directory
if [ ! -f "package.json" ]; then
    print_error "Please run this script from the project root directory"
    exit 1
fi

# Check prerequisites
print_status "Checking prerequisites..."

# Check Node.js
if ! command -v node &> /dev/null; then
    print_error "Node.js is required but not installed"
    exit 1
else
    print_status "Node.js: $(node --version)"
fi

# Check Docker
if ! command -v docker &> /dev/null; then
    print_error "Docker is required but not installed"
    exit 1
else
    print_status "Docker: $(docker --version)"
fi

# Check AWS CLI
if ! command -v aws &> /dev/null; then
    print_error "AWS CLI is required but not installed"
    exit 1
else
    print_status "AWS CLI: $(aws --version)"
fi

# Check Terraform
if ! command -v terraform &> /dev/null; then
    print_warning "Terraform not found. Installing..."
    # Add Terraform installation logic here
else
    print_status "Terraform: $(terraform version | head -n1)"
fi

# Check Ansible
if ! command -v ansible &> /dev/null; then
    print_warning "Ansible not found. Installing..."
    pip3 install ansible
else
    print_status "Ansible: $(ansible --version | head -n1)"
fi

# Install Node.js dependencies
print_status "Installing Node.js dependencies..."
npm install

# Install Ansible dependencies
print_status "Installing Ansible collections..."
ansible-galaxy install -r ansible/requirements.yml

# Create Terraform variables file if it doesn't exist
if [ ! -f "terraform/terraform.tfvars" ]; then
    print_status "Creating Terraform variables file..."
    cp terraform/terraform.tfvars.example terraform/terraform.tfvars
    print_warning "Please edit terraform/terraform.tfvars with your specific values"
fi

# Create environment file if it doesn't exist
if [ ! -f ".env" ]; then
    print_status "Creating environment file..."
    cp .env.example .env
    print_warning "Please edit .env with your specific values"
fi

# Initialize Terraform
print_status "Initializing Terraform..."
cd terraform
terraform init
cd ..

print_status "Setup completed successfully!"
echo ""
echo "📋 Next steps:"
echo "1. Edit terraform/terraform.tfvars with your AWS configuration"
echo "2. Edit .env with your application configuration"
echo "3. Run: ./scripts/deploy.sh to deploy infrastructure"
echo "4. Run: ./scripts/manage.sh status to check deployment"
