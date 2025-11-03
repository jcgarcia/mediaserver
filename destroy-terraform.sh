#!/bin/bash

# destroy-terraform.sh - Destroy MediaServer infrastructure

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
PROJECT_NAME=${PROJECT_NAME:-"mediaserver"}

print_warning "WARNING: This will destroy ALL MediaServer infrastructure!"
print_warning "This action cannot be undone."
echo ""

# Ask for confirmation
print_warning "Are you sure you want to destroy the infrastructure? Type 'destroy' to confirm:"
read -r response

if [[ "$response" != "destroy" ]]; then
    print_error "Operation cancelled."
    exit 1
fi

# Change to terraform directory
cd "$TERRAFORM_DIR"

# Check if terraform.tfvars exists
if [ ! -f "terraform.tfvars" ]; then
    print_error "terraform.tfvars not found. Cannot proceed with destroy."
    exit 1
fi

# Initialize Terraform (in case it's not initialized)
print_status "Initializing Terraform..."
terraform init

# Plan the destruction
print_status "Planning infrastructure destruction..."
terraform plan -destroy -out=destroy-plan

# Final confirmation
echo ""
print_warning "Review the destruction plan above."
print_warning "This will permanently delete all resources. Are you absolutely sure? (yes/no)"
read -r final_response

if [[ "$final_response" != "yes" ]]; then
    print_error "Destruction cancelled."
    exit 1
fi

# Apply the destruction
print_status "Destroying infrastructure..."
terraform apply destroy-plan

# Clean up terraform files
print_status "Cleaning up Terraform state files..."
rm -f tfplan destroy-plan terraform.tfstate.backup

print_success "Infrastructure destruction completed!"
print_status "All AWS resources have been removed."

# Clean up deployment info file
if [ -f "../deployment-info.txt" ]; then
    rm -f "../deployment-info.txt"
    print_status "Deployment info file removed."
fi