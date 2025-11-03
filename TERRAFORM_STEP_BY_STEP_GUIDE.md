# Step-by-Step Terraform Infrastructure Guide

This guide explains each component that Terraform creates in the exact order of deployment, with detailed explanations of what each resource does and why it's needed.

## Infrastructure Creation Order

Terraform automatically determines the correct order based on resource dependencies. Here's the step-by-step process:

---

## Phase 1: Foundation & Random Values

### Step 1: Generate Random Values
```hcl
resource "random_string" "bucket_suffix"
resource "random_password" "jwt_secret"
```

**What happens:**
- Creates a random 8-character string for S3 bucket naming (e.g., "abc12345")
- Generates a secure 32-character password for JWT token signing

**Why first:**
These values are needed by other resources, so they must be created first.

**Real-world analogy:**
Like generating unique serial numbers and security codes before manufacturing products.

---

## Phase 2: Networking Foundation

### Step 2: Discover Existing Network Infrastructure
```hcl
data "aws_vpc" "default"
data "aws_subnets" "default"
data "aws_availability_zones" "available"
```

**What happens:**
- Finds your existing default VPC (Virtual Private Cloud)
- Discovers all available subnets within that VPC
- Lists all availability zones in the region

**Network Details Found:**
- VPC ID: `vpc-0d7f549dbf9fa7957`
- Subnets: 3 subnets across different availability zones
- Region: eu-west-2 (London)

**Why this approach:**
Instead of creating a new VPC (which would be more complex), we use the existing default network infrastructure that AWS provides.

**Real-world analogy:**
Like using existing city roads and utilities instead of building your own infrastructure from scratch.

---

## Phase 3: Security Groups (Network Firewalls)

### Step 3: Create Application Load Balancer Security Group
```hcl
resource "aws_security_group" "alb"
```

**What it creates:**
- **Name**: `mediaserver-alb`
- **Purpose**: Controls traffic to/from the load balancer
- **Inbound rules**: 
  - Port 80 (HTTP) from anywhere (0.0.0.0/0)
  - Port 443 (HTTPS) from anywhere (0.0.0.0/0)
- **Outbound rules**: All traffic allowed

**Security Model:**
```
Internet (0.0.0.0/0) → Port 80/443 → Load Balancer
```

**Real-world analogy:**
Like security guards at a building entrance who let visitors in through the main doors but check their credentials.

### Step 4: Create ECS Tasks Security Group
```hcl
resource "aws_security_group" "ecs_tasks"
```

**What it creates:**
- **Name**: `mediaserver-ecs-tasks`
- **Purpose**: Controls traffic to/from application containers
- **Inbound rules**: 
  - Port 3000 (app port) ONLY from ALB security group
- **Outbound rules**: All traffic allowed (for downloading updates, accessing AWS services)

**Security Model:**
```
Load Balancer → Port 3000 → Application Containers
Application Containers → All Ports → Internet (for AWS API calls, updates)
```

**Real-world analogy:**
Like having internal security that only allows authorized personnel (load balancer) to access work areas, but employees can go anywhere they need for work.

---

## Phase 4: Storage Infrastructure

### Step 5: Create S3 Bucket for Media Storage
```hcl
resource "aws_s3_bucket" "media_storage"
```

**What it creates:**
- **Name**: `mediaserver-storage-{random-suffix}` (e.g., `mediaserver-storage-abc12345`)
- **Purpose**: Stores all uploaded media files (images, videos)
- **Force Destroy**: Enabled (for testing - allows Terraform to delete bucket with files)

**Why random suffix:**
S3 bucket names must be globally unique across ALL AWS accounts worldwide.

### Step 6: Configure S3 Bucket Encryption
```hcl
resource "aws_s3_bucket_server_side_encryption_configuration" "media_storage"
```

**What it does:**
- Automatically encrypts every file uploaded using AES256 encryption
- Files are scrambled so even if someone steals the storage drives, they can't read the files

### Step 7: Enable S3 Bucket Versioning
```hcl
resource "aws_s3_bucket_versioning" "media_storage"
```

**What it does:**
- Keeps multiple versions of files when they're updated
- If you accidentally delete or overwrite a file, you can recover the previous version

### Step 8: Block Public Access to S3 Bucket
```hcl
resource "aws_s3_bucket_public_access_block" "media_storage"
```

**What it does:**
- Prevents accidental public exposure of files
- All settings set to `true` = maximum protection
- Files can only be accessed through your application

### Step 9: Configure CORS for S3 Bucket
```hcl
resource "aws_s3_bucket_cors_configuration" "media_storage"
```

**What it does:**
- Allows web browsers to upload files directly to S3
- Permits GET, PUT, POST, DELETE operations
- Currently allows from all origins (*) - should be restricted in production

### Step 10: Set Up S3 Lifecycle Management
```hcl
resource "aws_s3_bucket_lifecycle_configuration" "media_storage"
```

**What it does:**
- **Days 1-30**: Files in Standard storage (fast, expensive)
- **Days 31-90**: Files moved to Standard-IA (slower, cheaper)
- **Days 91+**: Files moved to Glacier (very slow, very cheap)
- **Cleanup**: Deletes incomplete uploads after 7 days

**Cost savings:**
Automatically moves old files to cheaper storage tiers.

**Fixed Issue:**
Added `filter {}` block which is required by AWS provider v5.x.

---

## Phase 5: Container Registry

### Step 11: Create ECR Repository
```hcl
resource "aws_ecr_repository" "mediaserver"
```

**What it creates:**
- **Name**: `mediaserver`
- **Purpose**: Stores Docker images of your application
- **Image Scanning**: Enabled - automatically scans for security vulnerabilities
- **Tag Mutability**: MUTABLE - allows updating image tags

### Step 12: Set ECR Repository Permissions
```hcl
resource "aws_ecr_repository_policy" "mediaserver"
```

**What it does:**
- Allows ECS tasks to pull (download) container images
- Restricts access to only authorized roles

### Step 13: Configure ECR Lifecycle Policy
```hcl
resource "aws_ecr_lifecycle_policy" "mediaserver"
```

**What it does:**
- Keeps only the last 10 tagged images (versions like v1.0, v1.1, etc.)
- Keeps only the last 5 untagged images
- Automatically deletes older images to save storage costs

---

## Phase 6: Identity and Access Management (Security)

### Step 14: Create ECS Task Execution Role
```hcl
resource "aws_iam_role" "ecs_task_execution_role"
```

**What it creates:**
- **Name**: `mediaserver-ecs-task-execution-role`
- **Purpose**: Allows ECS service to manage containers (start, stop, pull images)
- **Trust Policy**: Only ECS tasks can assume this role

**Think of it as:**
A "System Administrator" badge that lets ECS manage containers.

### Step 15: Attach Standard ECS Execution Policy
```hcl
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy"
```

**What it does:**
- Attaches AWS's standard policy for ECS task execution
- Provides permissions to pull images from ECR, write logs to CloudWatch

### Step 16: Create ECS Task Role
```hcl
resource "aws_iam_role" "ecs_task_role"
```

**What it creates:**
- **Name**: `mediaserver-ecs-task-role`
- **Purpose**: Provides permissions for the running application
- **Trust Policy**: Only ECS tasks can assume this role

**Think of it as:**
An "Application Worker" badge that gives the app permissions to do its job.

### Step 17: Create S3 Access Policy for Tasks
```hcl
resource "aws_iam_role_policy" "ecs_task_s3_policy"
```

**What it allows:**
- Read files from S3 bucket (`s3:GetObject`)
- Upload files to S3 bucket (`s3:PutObject`)
- Delete files from S3 bucket (`s3:DeleteObject`)
- List bucket contents (`s3:ListBucket`)
- **ONLY** for the specific mediaserver bucket

### Step 18: Create CloudWatch Access Policy for Tasks
```hcl
resource "aws_iam_role_policy" "ecs_task_cloudwatch_policy"
```

**What it allows:**
- Write application logs to CloudWatch
- Send custom metrics
- Create log streams

---

## Phase 7: Secure Configuration Storage

### Step 19: Store JWT Secret
```hcl
resource "aws_ssm_parameter" "jwt_secret"
```

**What it creates:**
- **Name**: `/mediaserver/jwt-secret`
- **Type**: SecureString (encrypted)
- **Value**: The random 32-character password generated earlier
- **Purpose**: Used by application to sign and verify JWT tokens

### Step 20: Store S3 Bucket Name
```hcl
resource "aws_ssm_parameter" "s3_bucket_name"
```

**What it creates:**
- **Name**: `/mediaserver/s3-bucket-name`
- **Type**: String (not encrypted - not sensitive)
- **Value**: The actual S3 bucket name created
- **Purpose**: Tells the application which bucket to use

### Step 21: Store Application Configuration
```hcl
resource "aws_ssm_parameter" "app_config"
```

**What it creates:**
- **Name**: `/mediaserver/app-config`
- **Type**: String
- **Value**: JSON with NODE_ENV, AWS_REGION, S3_BUCKET, APP_PORT
- **Purpose**: Centralized configuration for the application

---

## Phase 8: Load Balancer Infrastructure

### Step 22: Create Application Load Balancer
```hcl
resource "aws_lb" "mediaserver"
```

**What it creates:**
- **Name**: `mediaserver-alb`
- **Type**: Application Load Balancer (Layer 7 - understands HTTP)
- **Scheme**: Internet-facing (public)
- **Subnets**: Deployed across all 3 availability zones
- **Security Groups**: Uses the ALB security group created earlier

**High Availability:**
Automatically spreads across multiple data centers for redundancy.

### Step 23: Create Target Group
```hcl
resource "aws_lb_target_group" "mediaserver"
```

**What it creates:**
- **Name**: `mediaserver-tg`
- **Purpose**: Defines healthy application instances
- **Target Type**: IP (for Fargate containers)
- **Health Check Configuration**:
  - Path: `/health`
  - Healthy threshold: 2 consecutive successes
  - Unhealthy threshold: 2 consecutive failures
  - Interval: Every 30 seconds
  - Timeout: 5 seconds

**Health Check Process:**
```
Every 30 seconds → GET /health → Expect HTTP 200
2 successes = healthy, 2 failures = unhealthy
```

### Step 24: Create Load Balancer Listener
```hcl
resource "aws_lb_listener" "mediaserver"
```

**What it creates:**
- **Port**: 80 (HTTP)
- **Action**: Forward all traffic to the target group
- **Purpose**: Routes incoming requests to healthy application instances

**Traffic Flow:**
```
Internet → Port 80 → Load Balancer → Target Group → Healthy Containers
```

---

## Phase 9: Container Orchestration

### Step 25: Create ECS Cluster
```hcl
resource "aws_ecs_cluster" "main"
```

**What it creates:**
- **Name**: `mediaserver-cluster`
- **Type**: Fargate (serverless containers)
- **Container Insights**: Enabled for monitoring
- **Purpose**: Management platform for containers

**Think of it as:**
A "department" that manages all application workers.

### Step 26: Configure Cluster Capacity Providers
```hcl
resource "aws_ecs_cluster_capacity_providers" "main"
```

**What it sets up:**
- **Primary**: Fargate (regular, predictable pricing)
- **Secondary**: Fargate Spot (up to 70% cheaper, can be interrupted)
- **Strategy**: 100% weight on Fargate, base capacity of 1

### Step 27: Create Task Definition
```hcl
resource "aws_ecs_task_definition" "mediaserver"
```

**What it defines:**
- **Family**: `mediaserver`
- **CPU**: 256 units (1/4 of a CPU core)
- **Memory**: 512 MB
- **Network**: awsvpc (each container gets its own IP)
- **Execution Role**: For ECS to manage the container
- **Task Role**: For the application to access AWS services

**Container Definition:**
- **Image**: From ECR repository (mediaserver:latest)
- **Port**: 3000 (application listens here)
- **Environment Variables**: NODE_ENV, PORT, AWS_REGION, S3_BUCKET_NAME
- **Secrets**: JWT_SECRET from Parameter Store
- **Logging**: All output goes to CloudWatch
- **Health Check**: curl command to /health endpoint

### Step 28: Create ECS Service
```hcl
resource "aws_ecs_service" "mediaserver"
```

**What it creates:**
- **Name**: `mediaserver-service`
- **Desired Count**: 2 containers always running
- **Launch Type**: Fargate (serverless)
- **Network**: Public subnets with public IPs
- **Security Groups**: ECS tasks security group
- **Load Balancer Integration**: Registers containers with target group

**Fixed Configuration:**
- **Deployment Maximum**: 200% (can have up to 4 containers during updates)
- **Deployment Minimum**: 100% (always keep at least 2 healthy containers)
- **Circuit Breaker**: Enabled with rollback on failure
- **Execute Command**: Enabled for debugging

**Service Responsibilities:**
- Keep exactly 2 containers running at all times
- Replace unhealthy containers automatically
- Register/deregister containers with load balancer
- Handle rolling deployments with zero downtime

---

## Phase 10: Auto Scaling

### Step 29: Create Auto Scaling Target
```hcl
resource "aws_appautoscaling_target" "ecs_target"
```

**What it sets up:**
- **Resource**: The ECS service container count
- **Min Capacity**: 1 container minimum
- **Max Capacity**: 10 containers maximum
- **Scalable Dimension**: Service desired count

### Step 30: Create Scale-Up Policy
```hcl
resource "aws_appautoscaling_policy" "scale_up"
```

**What it does:**
- **Action**: Add 1 more container
- **Cooldown**: Wait 5 minutes before scaling again
- **Trigger**: Connected to high CPU alarm

**Fixed Issue:**
Removed unsupported `tags` attribute from scaling policies.

### Step 31: Create Scale-Down Policy
```hcl
resource "aws_appautoscaling_policy" "scale_down"
```

**What it does:**
- **Action**: Remove 1 container
- **Cooldown**: Wait 5 minutes before scaling again
- **Trigger**: Connected to low CPU alarm

### Step 32: Create High CPU Alarm
```hcl
resource "aws_cloudwatch_metric_alarm" "high_cpu"
```

**What it monitors:**
- **Metric**: Average CPU utilization across all containers
- **Threshold**: 70%
- **Evaluation**: 2 consecutive periods of 5 minutes each (10 minutes total)
- **Action**: Trigger scale-up policy

**Scaling Logic:**
```
If CPU > 70% for 10 minutes → Add 1 container → Wait 5 minutes → Evaluate again
```

### Step 33: Create Low CPU Alarm
```hcl
resource "aws_cloudwatch_metric_alarm" "low_cpu"
```

**What it monitors:**
- **Metric**: Average CPU utilization across all containers
- **Threshold**: 20%
- **Evaluation**: 2 consecutive periods of 5 minutes each (10 minutes total)
- **Action**: Trigger scale-down policy

**Scaling Logic:**
```
If CPU < 20% for 10 minutes → Remove 1 container → Wait 5 minutes → Evaluate again
```

---

## Phase 11: Monitoring and Logging

### Step 34: Create ECS Log Group
```hcl
resource "aws_cloudwatch_log_group" "ecs_logs"
```

**What it creates:**
- **Name**: `/ecs/mediaserver`
- **Purpose**: Stores container system logs
- **Retention**: 30 days
- **Usage**: ECS service logs, container startup/shutdown events

### Step 35: Create Application Log Group
```hcl
resource "aws_cloudwatch_log_group" "app_logs"
```

**What it creates:**
- **Name**: `/aws/ecs/mediaserver/app`
- **Purpose**: Stores application-specific logs
- **Retention**: 30 days
- **Usage**: Your application's console.log() output, errors, requests

### Step 36: Create CloudWatch Dashboard
```hcl
resource "aws_cloudwatch_dashboard" "mediaserver"
```

**What it creates:**
- **Name**: `mediaserver-dashboard`
- **Widgets**: 
  - ECS service CPU and memory metrics
  - S3 storage usage and object count
- **Time Series**: Visual charts showing metrics over time
- **Auto-refresh**: Real-time monitoring capability

---

## Final Infrastructure Overview

After all 36 resources are created, you'll have:

### 🏗️ Complete Architecture
```
Internet → ALB → ECS Fargate Containers → S3 Storage
    ↓        ↓            ↓                    ↓
  Users   Routes      Processes            Stores
         Traffic      Requests             Files
```

### 🔐 Security Layers
```
1. Internet → ALB Security Group (Ports 80/443 only)
2. ALB → ECS Security Group (Port 3000 only)
3. ECS → S3 (IAM permissions only)
4. S3 → Encrypted storage + Private access
```

### 📊 Monitoring Stack
```
Application Logs → CloudWatch Logs → Retention Policies
Container Metrics → CloudWatch Metrics → Alarms → Auto Scaling
Dashboard → Real-time Visualization
```

### 💰 Cost Optimization
```
ECS: Pay only for running containers
S3: Automatic lifecycle (Standard → IA → Glacier)
CloudWatch: 30-day log retention
Auto Scaling: Scale down during low usage
```

### 🚀 High Availability
```
Multi-AZ: Load balancer across 3 availability zones
Auto Healing: Unhealthy containers automatically replaced
Rolling Deployments: Zero-downtime updates
Circuit Breaker: Automatic rollback on failures
```

This infrastructure provides enterprise-grade reliability, security, and scalability while remaining cost-effective through automation and intelligent resource management.