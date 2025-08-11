#!/bin/bash

# AWS Media Server Deployment Script
# Run this script after activating S3 and ECS services in the AWS console

set -e

echo "🚀 Starting AWS Media Server Deployment..."
echo "Account ID: $(aws sts get-caller-identity --query Account --output text)"
echo "Region: $(aws configure get region)"

# Variables
REGION="eu-west-2"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET_NAME="mediaserver-storage-$(date +%Y%m%d-%H%M%S)"
CLUSTER_NAME="mediaserver-cluster"
ECR_REPO="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/mediaserver"

echo "📦 Bucket name will be: ${BUCKET_NAME}"

# Step 1: Create S3 bucket
echo "📁 Creating S3 bucket for media storage..."
aws s3 mb s3://${BUCKET_NAME} --region ${REGION}

# Configure bucket for web access
echo "🔧 Configuring S3 bucket..."
aws s3api put-bucket-cors --bucket ${BUCKET_NAME} --cors-configuration '{
  "CORSRules": [
    {
      "AllowedHeaders": ["*"],
      "AllowedMethods": ["GET", "PUT", "POST", "DELETE"],
      "AllowedOrigins": ["*"],
      "ExposeHeaders": []
    }
  ]
}'

# Step 2: Create IAM roles for ECS
echo "🔐 Creating IAM roles..."

# ECS Task Execution Role
aws iam create-role --role-name ecsTaskExecutionRole --assume-role-policy-document '{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}' || echo "Role ecsTaskExecutionRole already exists"

# Attach AWS managed policy
aws iam attach-role-policy --role-name ecsTaskExecutionRole --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy

# ECS Task Role for S3 access
aws iam create-role --role-name ecsTaskRole --assume-role-policy-document '{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}' || echo "Role ecsTaskRole already exists"

# Create policy for S3 access
aws iam put-role-policy --role-name ecsTaskRole --policy-name S3MediaAccess --policy-document "{
  \"Version\": \"2012-10-17\",
  \"Statement\": [
    {
      \"Effect\": \"Allow\",
      \"Action\": [
        \"s3:GetObject\",
        \"s3:PutObject\",
        \"s3:DeleteObject\",
        \"s3:ListBucket\"
      ],
      \"Resource\": [
        \"arn:aws:s3:::${BUCKET_NAME}\",
        \"arn:aws:s3:::${BUCKET_NAME}/*\"
      ]
    }
  ]
}"

# Step 3: Create CloudWatch Log Group
echo "📊 Creating CloudWatch log group..."
aws logs create-log-group --log-group-name /ecs/mediaserver --region ${REGION} || echo "Log group already exists"

# Step 4: Create ECS Cluster
echo "🏗️ Creating ECS cluster..."
aws ecs create-cluster --cluster-name ${CLUSTER_NAME} --capacity-providers FARGATE --default-capacity-provider-strategy capacityProvider=FARGATE,weight=1

# Step 5: Store JWT secret in Parameter Store
echo "🔑 Creating JWT secret in Parameter Store..."
JWT_SECRET=$(openssl rand -base64 32)
aws ssm put-parameter --name "/mediaserver/jwt-secret" --value "${JWT_SECRET}" --type "SecureString" --overwrite

# Step 6: Update environment file
echo "📝 Updating environment configuration..."
cat > .env.production << EOF
NODE_ENV=production
PORT=3000
AWS_REGION=${REGION}
S3_BUCKET_NAME=${BUCKET_NAME}
JWT_SECRET=${JWT_SECRET}
ALLOWED_ORIGINS=https://yourdomain.com
EOF

# Step 7: Build and push Docker image
echo "🐳 Building and pushing Docker image..."
aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ECR_REPO}

docker build -t mediaserver .
docker tag mediaserver:latest ${ECR_REPO}:latest
docker push ${ECR_REPO}:latest

# Step 8: Update task definition with correct bucket name
echo "📋 Updating ECS task definition..."
cat > ecs-task-definition-updated.json << EOF
{
  "family": "mediaserver",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "executionRoleArn": "arn:aws:iam::${ACCOUNT_ID}:role/ecsTaskExecutionRole",
  "taskRoleArn": "arn:aws:iam::${ACCOUNT_ID}:role/ecsTaskRole",
  "containerDefinitions": [
    {
      "name": "mediaserver",
      "image": "${ECR_REPO}:latest",
      "portMappings": [
        {
          "containerPort": 3000,
          "protocol": "tcp"
        }
      ],
      "essential": true,
      "environment": [
        {
          "name": "NODE_ENV",
          "value": "production"
        },
        {
          "name": "PORT",
          "value": "3000"
        },
        {
          "name": "AWS_REGION",
          "value": "${REGION}"
        },
        {
          "name": "S3_BUCKET_NAME",
          "value": "${BUCKET_NAME}"
        }
      ],
      "secrets": [
        {
          "name": "JWT_SECRET",
          "valueFrom": "arn:aws:ssm:${REGION}:${ACCOUNT_ID}:parameter/mediaserver/jwt-secret"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/mediaserver",
          "awslogs-region": "${REGION}",
          "awslogs-stream-prefix": "ecs"
        }
      },
      "healthCheck": {
        "command": [
          "CMD-SHELL",
          "curl -f http://localhost:3000/health || exit 1"
        ],
        "interval": 30,
        "timeout": 5,
        "retries": 3,
        "startPeriod": 60
      }
    }
  ]
}
EOF

# Step 9: Register task definition
echo "📋 Registering ECS task definition..."
aws ecs register-task-definition --cli-input-json file://ecs-task-definition-updated.json

# Step 10: Get default VPC and subnets
echo "🌐 Getting VPC information..."
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query 'Vpcs[0].VpcId' --output text)
SUBNET_IDS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=${VPC_ID}" --query 'Subnets[*].SubnetId' --output text | tr '\t' ',')

echo "VPC ID: ${VPC_ID}"
echo "Subnet IDs: ${SUBNET_IDS}"

# Step 11: Create security group
echo "🔒 Creating security group..."
SG_ID=$(aws ec2 create-security-group --group-name mediaserver-sg --description "Security group for media server" --vpc-id ${VPC_ID} --query 'GroupId' --output text)

# Allow HTTP traffic
aws ec2 authorize-security-group-ingress --group-id ${SG_ID} --protocol tcp --port 3000 --cidr 0.0.0.0/0

echo "Security Group ID: ${SG_ID}"

# Step 12: Create ECS service
echo "🚀 Creating ECS service..."
aws ecs create-service \
  --cluster ${CLUSTER_NAME} \
  --service-name mediaserver-service \
  --task-definition mediaserver:1 \
  --desired-count 2 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[${SUBNET_IDS}],securityGroups=[${SG_ID}],assignPublicIp=ENABLED}"

echo "✅ Deployment completed!"
echo ""
echo "📋 Summary:"
echo "- S3 Bucket: ${BUCKET_NAME}"
echo "- ECS Cluster: ${CLUSTER_NAME}"
echo "- ECR Repository: ${ECR_REPO}"
echo "- Security Group: ${SG_ID}"
echo ""
echo "🔍 To check service status:"
echo "aws ecs describe-services --cluster ${CLUSTER_NAME} --services mediaserver-service"
echo ""
echo "📝 Environment file updated: .env.production"
