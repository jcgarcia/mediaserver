# Individual Terraform File Explanations

## Detailed Script-by-Script Analysis

This document provides an in-depth explanation of each Terraform file with code examples and line-by-line breakdowns.

---

## 1. provider.tf - The Foundation

### What This File Contains:
```hcl
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project     = "MediaServer"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}
```

### Line-by-Line Explanation:

**Line 1-2**: `terraform { required_version = ">= 1.0" }`
- **What it means**: "This code only works with Terraform version 1.0 or newer"
- **Why it matters**: Ensures everyone uses compatible versions
- **Real analogy**: Like saying "This recipe only works in ovens made after 2020"

**Lines 3-8**: `required_providers` block
- **What it means**: "We need the AWS plugin, version 5.x"
- **Why it matters**: Downloads the right tools to talk to Amazon's services
- **Real analogy**: Like downloading the right app to control your smart TV

**Lines 11-12**: `provider "aws" { region = var.aws_region }`
- **What it means**: "Connect to Amazon's cloud in the specified region"
- **Why it matters**: Tells AWS where in the world to build everything
- **Real analogy**: Like telling a taxi driver "Take me to the London office, not the New York one"

**Lines 13-18**: `default_tags` block
- **What it means**: "Put these labels on everything we create"
- **Why it matters**: Helps track costs and ownership
- **Real analogy**: Like putting your name and date on every document you create

---

## 2. variables.tf - The Settings Menu

### Key Variable Examples:

```hcl
variable "container_cpu" {
  description = "CPU units for ECS task"
  type        = number
  default     = 256
}
```

**Breaking this down:**
- **`variable "container_cpu"`**: Creates a setting called "container_cpu"
- **`description`**: Human-readable explanation of what this controls
- **`type = number`**: This setting must be a number (not text)
- **`default = 256`**: If user doesn't specify, use 256

**What 256 CPU units means:**
- 1024 = 1 full CPU core
- 256 = 1/4 of a CPU core
- Think of it like: "Give each server 25% of a computer processor"

### Another Example:
```hcl
variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access the application"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
```

**Breaking this down:**
- **`type = list(string)`**: This is a list of text values
- **`["0.0.0.0/0"]`**: Means "allow access from anywhere on the internet"
- **Could be changed to**: `["203.0.113.0/24"]` to only allow access from a specific company network

---

## 3. data.tf - The Information Gatherer

### Example Data Source:
```hcl
data "aws_vpc" "default" {
  default = true
}
```

**What this does:**
- **"data"**: "Go ask AWS for information" (don't create anything new)
- **"aws_vpc"**: "About the virtual private cloud (network)"
- **"default"**: "Give me the default network that already exists"
- **Result**: Now we can reference this existing network in other scripts

### Why We Need This:
Imagine you're connecting a new printer to an existing office network. You need to know:
- What's the network name?
- What's the IP address range?
- Where are the network ports?

This file asks AWS those same questions about the existing infrastructure.

---

## 4. ecr.tf - The Application Warehouse

### Main Repository Creation:
```hcl
resource "aws_ecr_repository" "mediaserver" {
  name = var.project_name
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}
```

**Breaking this down:**
- **`resource "aws_ecr_repository"`**: "Create a new container image warehouse"
- **`name = var.project_name`**: "Call it whatever the project name is" (probably "mediaserver")
- **`image_tag_mutability = "MUTABLE"`**: "Allow updating tags" (like updating version labels)
- **`scan_on_push = true`**: "Check every new version for security problems automatically"

### Lifecycle Policy:
```hcl
policy = jsonencode({
  rules = [
    {
      rulePriority = 1
      description  = "Keep last 10 images"
      selection = {
        tagStatus     = "tagged"
        countType     = "imageCountMoreThan"
        countNumber   = 10
      }
      action = {
        type = "expire"
      }
    }
  ]
})
```

**What this means in plain English:**
"If we have more than 10 versions of our application stored, automatically delete the oldest ones to save space and money."

It's like having a rule: "Only keep the last 10 family photos on your phone, delete older ones automatically."

---

## 5. s3.tf - The File Storage System

### Bucket Creation:
```hcl
resource "aws_s3_bucket" "media_storage" {
  bucket        = "${var.project_name}-storage-${random_string.bucket_suffix.result}"
  force_destroy = var.s3_bucket_force_destroy
}
```

**Breaking this down:**
- **`bucket = "${var.project_name}-storage-${random_string.bucket_suffix.result}"`**: 
  - Creates a name like "mediaserver-storage-abc123"
  - The random part ensures the name is unique worldwide
- **`force_destroy`**: Controls whether Terraform can delete the bucket even if it has files in it

### Encryption Configuration:
```hcl
# S3 bucket lifecycle configuration
resource "aws_s3_bucket_lifecycle_configuration" "media_storage" {
  bucket = aws_s3_bucket.media_storage.id

  rule {
    id     = "media_lifecycle"
    status = "Enabled"
    
    filter {}  # Required empty filter for AWS provider v5.x

    # Delete incomplete multipart uploads after 7 days
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
```

**What this means:**
"Every file uploaded to this storage is automatically scrambled (encrypted) so even if someone steals the hard drives, they can't read the files."

### Lifecycle Rules:
```hcl
rule {
  id     = "media_lifecycle"
  status = "Enabled"
  
  transition {
    days          = 30
    storage_class = "STANDARD_IA"
  }
  
  transition {
    days          = 90
    storage_class = "GLACIER"
  }
}
```

**What this means:**
- **Day 1-30**: Files stored in fast, expensive storage (for quick access)
- **Day 31-90**: Files moved to slower, cheaper storage (still accessible but takes longer)
- **Day 91+**: Files moved to very cheap archive storage (takes hours to retrieve)

This is like organizing your closet: frequently used clothes in easy reach, seasonal clothes in higher shelves, very old clothes in the attic.

---

## 6. iam.tf - The Security Badge System

### Task Execution Role:
```hcl
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.project_name}-ecs-task-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}
```

**What this creates:**
A "job title" called "ecs-task-execution-role" that:
- Can be "assumed" (used) by the ECS service (Amazon's container manager)
- Is like giving the container manager a badge that says "I'm authorized to start and stop applications"

### S3 Access Policy:
```hcl
policy = jsonencode({
  Version = "2012-10-17"
  Statement = [
    {
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ]
      Resource = [
        aws_s3_bucket.media_storage.arn,
        "${aws_s3_bucket.media_storage.arn}/*"
      ]
    }
  ]
})
```

**Translation to plain English:**
"Give our application permission to:
- Read files from our storage bucket
- Upload new files to our storage bucket
- Delete files from our storage bucket
- List what files are in our storage bucket

But ONLY our storage bucket - nothing else!"

---

## 7. security.tf - The Network Firewall

### ECS Security Group:
```hcl
resource "aws_security_group" "ecs_tasks" {
  name_prefix = "${var.project_name}-ecs-tasks"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description     = "HTTP traffic from ALB"
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

**Breaking down the ingress rule:**
- **`ingress`**: "Rules for incoming traffic"
- **`from_port = var.container_port`**: "Allow traffic on port 3000 (our app's port)"
- **`protocol = "tcp"`**: "Using the standard web protocol"
- **`security_groups = [aws_security_group.alb.id]`**: "But ONLY from our load balancer"

**Breaking down the egress rule:**
- **`egress`**: "Rules for outgoing traffic"
- **`from_port = 0, to_port = 0`**: "All ports"
- **`protocol = "-1"`**: "All protocols"
- **`cidr_blocks = ["0.0.0.0/0"]`**: "To anywhere on the internet"

**Real-world analogy:**
Like a security checkpoint where:
- Incoming: Only delivery trucks from our approved shipping company can enter
- Outgoing: Our employees can go anywhere they need to go

---

## 8. alb.tf - The Traffic Director

### Load Balancer Creation:
```hcl
resource "aws_lb" "mediaserver" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = data.aws_subnets.default.ids
}
```

**Key settings explained:**
- **`internal = false`**: "This load balancer faces the internet" (not internal-only)
- **`load_balancer_type = "application"`**: "Smart load balancer that understands HTTP" (not just TCP)
- **`subnets = data.aws_subnets.default.ids`**: "Spread across multiple data centers for reliability"

### Target Group with Health Checks:
```hcl
resource "aws_lb_target_group" "mediaserver" {
  name        = "${var.project_name}-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health"
    timeout             = 5
    unhealthy_threshold = 2
  }
}
```

**Health check explained:**
- **`path = "/health"`**: "Check if the server is healthy by visiting /health"
- **`interval = 30`**: "Check every 30 seconds"
- **`matcher = "200"`**: "A response code of 200 means 'healthy'"
- **`healthy_threshold = 2`**: "Need 2 good responses in a row to mark as healthy"
- **`unhealthy_threshold = 2`**: "Need 2 bad responses in a row to mark as unhealthy"
- **`timeout = 5`**: "If no response in 5 seconds, consider it a failure"

**Real-world analogy:**
Like a supervisor who checks on workers every 30 seconds by asking "How are you doing?" If they respond "Good!" twice in a row, they're considered working. If they don't respond or say they're having problems twice in a row, they're considered not working and won't get new tasks.

---

## 9. ecs.tf - The Application Manager

### Cluster Creation:
```hcl
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"
  
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}
```

**What this creates:**
- A "cluster" is like a "department" that manages all our application workers
- `containerInsights = "enabled"` means "Turn on detailed monitoring and analytics"

### Task Definition:
```hcl
resource "aws_ecs_task_definition" "mediaserver" {
  family                   = var.project_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.container_cpu
  memory                   = var.container_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
}
```

**Key components explained:**
- **`family`**: "This is version 1, 2, 3... of the 'mediaserver' task"
- **`network_mode = "awsvpc"`**: "Give each container its own IP address"
- **`requires_compatibilities = ["FARGATE"]`**: "Use serverless containers (AWS manages the servers)"
- **`cpu = var.container_cpu`**: "Each container gets this much processing power"
- **`memory = var.container_memory`**: "Each container gets this much RAM"
- **`execution_role_arn`**: "Use this security badge to start containers"
- **`task_role_arn`**: "Give running containers this security badge for accessing AWS services"

### Container Definition (inside task definition):
```hcl
container_definitions = jsonencode([
  {
    name  = var.project_name
    image = "${aws_ecr_repository.mediaserver.repository_url}:latest"
    
    portMappings = [
      {
        containerPort = var.container_port
        protocol      = "tcp"
      }
    ]

    environment = [
      {
        name  = "NODE_ENV"
        value = var.environment
      },
      {
        name  = "S3_BUCKET_NAME"
        value = aws_s3_bucket.media_storage.bucket
      }
    ]

    secrets = [
      {
        name      = "JWT_SECRET"
        valueFrom = aws_ssm_parameter.jwt_secret.arn
      }
    ]
  }
])
```

**Breaking this down:**
- **`image`**: "Use the latest version of our application from our private warehouse"
- **`portMappings`**: "The application listens on port 3000 inside the container"
- **`environment`**: "Set these environment variables (non-sensitive settings)"
- **`secrets`**: "Get these sensitive values from the secure parameter store"

### ECS Service:
```hcl
resource "aws_ecs_service" "mediaserver" {
  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.mediaserver.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  load_balancer {
    target_group_arn = aws_lb_target_group.mediaserver.arn
    container_name   = var.project_name
    container_port   = var.container_port
  }
}
```

**What the service does:**
- **`desired_count = var.desired_count`**: "Always keep this many copies running" (default: 2)
- **`launch_type = "FARGATE"`**: "Use serverless containers"
- **`load_balancer` block**: "Register running containers with the load balancer so they can receive traffic"

**Real-world analogy:**
The ECS Service is like a restaurant manager who:
- Knows the recipe (task definition)
- Ensures there are always 2 cooks working (desired_count)
- Tells the receptionist (load balancer) which cooks are available to take orders
- If a cook gets sick, immediately hires a replacement

---

## 10. autoscaling.tf - The Smart Staffing Manager

### Scaling Target:
```hcl
resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.mediaserver.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}
```

**What this sets up:**
- **`resource_id`**: "We're managing the number of containers in this specific service"
- **`scalable_dimension = "ecs:service:DesiredCount"`**: "We're scaling the count of running tasks"
- **`min_capacity = 1, max_capacity = 10`**: "Never have fewer than 1 or more than 10 containers"

### Scale-Up Policy:
```hcl
resource "aws_appautoscaling_policy" "scale_up" {
  name               = "${var.project_name}-scale-up"
  policy_type        = "StepScaling"
  
  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown               = 300
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }
}
```

**Breaking this down:**
- **`policy_type = "StepScaling"`**: "Add/remove a specific number of containers"
- **`adjustment_type = "ChangeInCapacity"`**: "Change the total count by a fixed amount"
- **`cooldown = 300`**: "Wait 5 minutes after scaling before scaling again"
- **`scaling_adjustment = 1`**: "Add exactly 1 more container"

### CPU Alarm:
```hcl
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.project_name}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "70"
  
  alarm_actions = [aws_appautoscaling_policy.scale_up.arn]
}
```

**What this alarm does:**
- **`metric_name = "CPUUtilization"`**: "Watch the CPU usage percentage"
- **`threshold = "70"`**: "Trigger when CPU goes above 70%"
- **`evaluation_periods = "2"`**: "Must stay above 70% for 2 consecutive checks"
- **`period = "300"`**: "Each check is 5 minutes"
- **`statistic = "Average"`**: "Use the average CPU across all containers"
- **`alarm_actions`**: "When triggered, execute the scale-up policy"

**Real-world analogy:**
Like a restaurant manager who:
- Watches how busy the kitchen is every 5 minutes
- If the kitchen is more than 70% busy for 10 minutes straight, calls in another cook
- Waits 5 minutes after calling someone before making another decision
- Never has fewer than 1 cook or more than 10 cooks working

---

This detailed breakdown shows how each Terraform file contributes to building a complete, production-ready infrastructure that can automatically handle varying loads while maintaining security and cost-effectiveness.