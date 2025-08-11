#!/bin/bash

# scripts/manage.sh - Manage MediaServer deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Default values
ENVIRONMENT=${ENVIRONMENT:-production}
AWS_REGION=${AWS_REGION:-eu-west-2}
PROJECT_NAME=${PROJECT_NAME:-mediaserver}

# Function to show usage
usage() {
    echo "Usage: $0 <action> [options]"
    echo ""
    echo "Actions:"
    echo "  status              Show service status"
    echo "  logs               Show recent logs"
    echo "  scale              Scale the service"
    echo "  restart            Restart the service"
    echo "  destroy            Destroy all infrastructure"
    echo ""
    echo "Options:"
    echo "  --desired-count N   Number of tasks for scale action"
    echo "  --force            Skip confirmation prompts"
    echo ""
    echo "Examples:"
    echo "  $0 status"
    echo "  $0 scale --desired-count 3"
    echo "  $0 logs"
    echo "  $0 restart"
    echo "  $0 destroy --force"
}

# Parse command line arguments
ACTION=""
DESIRED_COUNT=""
FORCE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        status|logs|scale|restart|destroy)
            ACTION="$1"
            shift
            ;;
        --desired-count)
            DESIRED_COUNT="$2"
            shift 2
            ;;
        --force)
            FORCE=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Check if action is provided
if [ -z "$ACTION" ]; then
    print_error "No action specified"
    usage
    exit 1
fi

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    print_error "AWS credentials not configured"
    exit 1
fi

case $ACTION in
    status)
        print_status "Getting service status..."
        ansible-playbook ansible/playbooks/manage.yml \
            -e action=status \
            -e environment="$ENVIRONMENT" \
            -e aws_region="$AWS_REGION" \
            -e project_name="$PROJECT_NAME"
        ;;
    logs)
        print_status "Getting recent logs..."
        ansible-playbook ansible/playbooks/manage.yml \
            -e action=logs \
            -e environment="$ENVIRONMENT" \
            -e aws_region="$AWS_REGION" \
            -e project_name="$PROJECT_NAME"
        ;;
    scale)
        if [ -z "$DESIRED_COUNT" ]; then
            print_error "Please specify --desired-count for scale action"
            exit 1
        fi
        print_status "Scaling service to $DESIRED_COUNT tasks..."
        ansible-playbook ansible/playbooks/manage.yml \
            -e action=scale \
            -e desired_count="$DESIRED_COUNT" \
            -e environment="$ENVIRONMENT" \
            -e aws_region="$AWS_REGION" \
            -e project_name="$PROJECT_NAME"
        ;;
    restart)
        print_status "Restarting service..."
        ansible-playbook ansible/playbooks/manage.yml \
            -e action=restart \
            -e environment="$ENVIRONMENT" \
            -e aws_region="$AWS_REGION" \
            -e project_name="$PROJECT_NAME"
        ;;
    destroy)
        print_status "Destroying infrastructure..."
        ansible-playbook ansible/playbooks/destroy.yml \
            -e force_destroy="$FORCE" \
            -e environment="$ENVIRONMENT" \
            -e aws_region="$AWS_REGION" \
            -e project_name="$PROJECT_NAME"
        ;;
    *)
        print_error "Unknown action: $ACTION"
        usage
        exit 1
        ;;
esac
