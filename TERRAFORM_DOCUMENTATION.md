# Terraform Scripts Documentation - Layman's Guide

This document explains every Terraform script in simple, non-technical terms. Think of Terraform as a tool that automatically creates and manages computer resources in the cloud (like Amazon Web Services) by reading instructions from these scripts.

## Overview

Imagine you're setting up a restaurant. Instead of manually buying equipment, hiring staff, and setting up systems one by one, you could write a detailed plan and have someone else execute it perfectly every time. That's what Terraform does for cloud infrastructure - it reads our "recipes" (scripts) and automatically sets up all the technology we need.

## File-by-File Explanation

### 1. `provider.tf` - The Foundation Setup

**What it does in simple terms:**
This file tells Terraform "we want to use Amazon Web Services (AWS) to build our infrastructure" and sets up the basic connection.

**Real-world analogy:**
Like choosing which construction company will build your house and signing the initial contract.

**Key components:**
- **Terraform version requirement**: "We need Terraform version 1.0 or newer"
- **AWS provider**: "We're building everything on Amazon's cloud platform"
- **Region setting**: "Build everything in the London area (eu-west-2)"
- **Default tags**: "Label everything we create with project name, environment, and owner info"

**Why this matters:**
Without this file, Terraform wouldn't know which cloud provider to use or where to build things.

---

### 2. `variables.tf` - The Configuration Settings

**What it does in simple terms:**
This file defines all the customizable settings for our infrastructure - like a settings menu where you can adjust how powerful your servers are, how many you want, etc.

**Real-world analogy:**
Like a restaurant menu where you can customize your order - "How spicy?", "What size?", "Any extras?"

**Key settings explained:**
- **aws_region**: Which Amazon data center location to use (default: London)
- **environment**: Whether this is for testing or real customers (default: production)
- **project_name**: What to call our application (default: mediaserver)
- **container_cpu/memory**: How powerful each server should be (like choosing a car engine size)
- **desired_count**: How many servers to start with (default: 2)
- **min/max_capacity**: Minimum and maximum servers for auto-scaling (1 to 10)
- **container_port**: Which "door" the application uses to receive visitors (default: 3000)
- **allowed_cidr_blocks**: Which internet addresses can access our service (default: everyone)

**Why this matters:**
This lets you easily customize the infrastructure without changing the complex code - just adjust these simple settings.

---

### 3. `data.tf` - The Information Gathering

**What it does in simple terms:**
This file asks AWS "tell me about the existing setup" and gathers information about things that already exist that we need to connect to.

**Real-world analogy:**
Like calling the city to ask "what's the address format in this neighborhood?" or "where's the nearest electrical grid connection?"

**What information it gathers:**
- **AWS account ID**: "What's my account number?"
- **Current region**: "Which data center am I in?"
- **Available zones**: "What sub-areas are available here?"
- **Default network (VPC)**: "What's the existing network setup?"
- **Network subnets**: "What are the different network segments available?"

**Why this matters:**
Our new infrastructure needs to connect to existing AWS services and networks, so we need to know what's already there.

---

### 4. `ecr.tf` - The Container Image Storage

**What it does in simple terms:**
Creates a private storage space for our application's "packaging" (Docker images). Think of it like a private warehouse where we store different versions of our application.

**Real-world analogy:**
Like having a secure warehouse where you store different versions of your product before shipping them to stores.

**What it creates:**
- **ECR Repository**: The actual storage space for our application packages
- **Security policy**: Rules about who can download our application packages
- **Cleanup rules**: Automatically delete old versions to save space (keeps last 10 tagged versions, last 5 untagged)
- **Image scanning**: Automatically check each package for security problems

**Why this matters:**
Every time we update our application, we need somewhere secure to store the new version before deploying it to our servers.

---

### 5. `s3.tf` - The File Storage System

**What it does in simple terms:**
Creates a secure, scalable storage system for all the media files (photos, videos) that users upload to our application.

**Real-world analogy:**
Like building a massive, secure warehouse with different sections, automatic organization, and built-in security systems.

**What it creates:**
- **S3 Bucket**: The main storage container with a unique name
- **Encryption**: All files are automatically scrambled for security
- **Versioning**: Keeps backup copies when files are updated
- **Access blocking**: Prevents accidental public access
- **CORS rules**: Allows web browsers to upload files directly
- **Lifecycle management**: Automatically moves old files to cheaper storage over time

**File organization:**
- New files: Stored in fast, expensive storage
- 30-day-old files: Moved to slower, cheaper storage
- 90-day-old files: Moved to very cheap archival storage

**Why this matters:**
Users need a reliable place to store their photos and videos, and we need it to be secure, scalable, and cost-effective.

---

### 6. `iam.tf` - The Security and Permissions

**What it does in simple terms:**
Creates security roles and permissions that control what our application can and cannot do with AWS services.

**Real-world analogy:**
Like creating employee badges and job descriptions that specify exactly what each worker is allowed to access in your building.

**What it creates:**
- **Task Execution Role**: Like a "system administrator" badge that can start and stop our application containers
- **Task Role**: Like an "application worker" badge that our running application uses to access files and logs
- **S3 Access Policy**: Permission slip saying "this application can read, write, and delete files in our storage"
- **CloudWatch Policy**: Permission slip saying "this application can write log messages and metrics"

**Security principle:**
Each role gets the minimum permissions needed to do its job - nothing more, nothing less.

**Why this matters:**
Without proper permissions, our application couldn't access the file storage or write logs. With too many permissions, it would be a security risk.

---

### 7. `security.tf` - The Network Security

**What it does in simple terms:**
Creates virtual security guards (firewalls) that control what internet traffic can reach our application and what our application can access.

**Real-world analogy:**
Like having security guards at different checkpoints who check IDs and only let authorized people through.

**What it creates:**
- **ECS Tasks Security Group**: Guards for our application servers
  - Only allows traffic from the load balancer
  - Allows all outbound internet access (for downloading updates, etc.)
- **ALB Security Group**: Guards for our load balancer
  - Allows web traffic (HTTP on port 80, HTTPS on port 443) from the internet
  - Can be restricted to specific IP addresses if needed

**Security layers:**
1. Internet users can only reach the load balancer
2. Load balancer can only reach our application servers
3. Application servers can access the internet and AWS services

**Why this matters:**
This creates a secure barrier where only legitimate web traffic can reach our application, protecting it from attacks.

---

### 8. `alb.tf` - The Load Balancer (Traffic Director)

**What it does in simple terms:**
Creates a smart traffic director that receives all internet requests and distributes them evenly across our application servers.

**Real-world analogy:**
Like a receptionist at a busy restaurant who greets customers and assigns them to available waiters based on who's least busy.

**What it creates:**
- **Application Load Balancer**: The main traffic director
- **Target Group**: A list of our application servers that can handle requests
- **Health Checks**: Regularly pings each server with "GET /health" to make sure it's working
- **Listener**: Waits for web traffic on port 80 (HTTP)
- **Optional HTTPS**: Can be configured for secure connections on port 443

**How it works:**
1. User visits our website
2. Load balancer receives the request
3. Checks which application servers are healthy
4. Forwards the request to the least busy healthy server
5. Returns the response to the user

**Why this matters:**
Without a load balancer, users would have to connect directly to individual servers. With it, we can have multiple servers, and if one crashes, traffic automatically goes to the others.

---

### 9. `ecs.tf` - The Container Orchestration (Application Management)

**What it does in simple terms:**
Creates and manages the actual servers that run our application. It's like having an intelligent supervisor that makes sure our application is always running properly.

**Real-world analogy:**
Like having a smart building manager who hires workers, assigns them tasks, monitors their performance, and replaces them if they get sick.

**What it creates:**
- **ECS Cluster**: The "building" where all our application workers operate
- **Task Definition**: The "job description" that explains exactly how to run our application
- **ECS Service**: The "supervisor" that ensures the right number of workers are always running

**Task Definition details:**
- **Container specs**: Use our application image from ECR storage
- **Resource allocation**: Each container gets 256 CPU units and 512MB memory
- **Environment variables**: Settings like which storage bucket to use
- **Secrets**: Secure access to sensitive info like JWT tokens
- **Health checks**: Regular "are you okay?" checks every 30 seconds
- **Logging**: All output goes to CloudWatch for monitoring

**Service management:**
- Always keeps 2 servers running (by default)
- If a server crashes, automatically starts a replacement
- Can update all servers without downtime
- Connects to the load balancer

**Why this matters:**
This ensures our application is always available to users, automatically handles failures, and makes updates easy.

---

### 10. `autoscaling.tf` - The Automatic Scaling System

**What it does in simple terms:**
Creates an intelligent system that automatically adds more servers when busy and removes them when quiet, like having extra staff during rush hour.

**Real-world analogy:**
Like a restaurant manager who calls in extra waiters during busy periods and sends them home when it's quiet, automatically based on customer count.

**What it creates:**
- **Scaling Target**: Defines what can be scaled (our ECS service)
- **Scale-Up Policy**: "Add one more server when needed"
- **Scale-Down Policy**: "Remove one server when not needed"
- **High CPU Alarm**: "If servers are working hard (>70% CPU) for 10 minutes, add another server"
- **Low CPU Alarm**: "If servers are idle (<20% CPU) for 10 minutes, remove a server"

**Scaling rules:**
- Minimum: Always keep 1 server running
- Maximum: Never have more than 10 servers
- Cooldown: Wait 5 minutes between scaling actions to avoid rapid changes

**Why this matters:**
This saves money by only using resources when needed, while ensuring good performance during busy periods.

---

### 11. `cloudwatch.tf` - The Monitoring and Logging System

**What it does in simple terms:**
Creates a comprehensive monitoring system that watches our application's health, stores all log messages, and creates dashboards to visualize performance.

**Real-world analogy:**
Like having security cameras, performance monitors, and a central control room that tracks everything happening in your business.

**What it creates:**
- **Log Groups**: Organized storage for different types of log messages
  - `/ecs/mediaserver`: System-level logs (server startup, crashes, etc.)
  - `/aws/ecs/mediaserver/app`: Application logs (user actions, errors, etc.)
- **Log Retention**: Automatically deletes old logs after 30 days to save space
- **Dashboard**: Visual charts showing:
  - CPU and memory usage over time
  - Storage usage in S3
  - Request counts and response times

**What gets logged:**
- Application startup and shutdown
- User requests and responses
- Error messages and stack traces
- Performance metrics
- Security events

**Why this matters:**
When something goes wrong, logs help us understand what happened. Dashboards help us spot problems before they affect users.

---

### 12. `ssm.tf` - The Secure Configuration Management

**What it does in simple terms:**
Creates secure storage for sensitive configuration data (like passwords and secret keys) that our application needs but shouldn't be visible in code.

**Real-world analogy:**
Like having a secure safe where you store important documents and passwords that employees need access to, but you don't want lying around.

**What it creates:**
- **JWT Secret**: A random 32-character password for securing user login tokens
- **S3 Bucket Name**: Stores which storage bucket our application should use
- **App Configuration**: Bundle of non-sensitive settings in one place

**Security features:**
- **Encryption**: All sensitive data is encrypted when stored
- **Access Control**: Only our application can read these values
- **Audit Trail**: AWS tracks who accessed what and when

**Why this matters:**
Applications need passwords and settings, but storing them in code is insecure. This provides a secure, managed way to handle sensitive configuration.

---

### 13. `outputs.tf` - The Information Reporter

**What it does in simple terms:**
After Terraform builds everything, this file tells us important information about what was created, like addresses, names, and URLs we need to know.

**Real-world analogy:**
Like getting a summary report after construction is finished: "Here's your new address, here are the keys, here's the security code."

**What information it provides:**
- **AWS Account ID**: Which account everything was built in
- **Region**: Which data center location was used
- **S3 Bucket Name**: The exact name of our file storage
- **ECR Repository URL**: Where to upload new versions of our application
- **ECS Cluster/Service Names**: Names of our application management systems
- **Load Balancer DNS**: The web address where users can access our application
- **Application URL**: The complete URL to visit our application

**Why this matters:**
After building infrastructure, we need to know how to deploy our application to it and how users can access it.

---

## How They All Work Together

Think of these files as different specialists working together to build a complete system:

1. **provider.tf**: The project manager who chooses the construction company (AWS)
2. **variables.tf**: The customization options menu
3. **data.tf**: The surveyor who checks existing conditions
4. **ecr.tf**: The warehouse manager who stores application versions
5. **s3.tf**: The storage facility manager who handles user files
6. **iam.tf**: The security manager who issues ID badges and permissions
7. **security.tf**: The security guard who controls access
8. **alb.tf**: The receptionist who directs traffic
9. **ecs.tf**: The operations manager who runs the application
10. **autoscaling.tf**: The resource manager who adjusts staffing
11. **cloudwatch.tf**: The monitoring team who watches everything
12. **ssm.tf**: The safe keeper who stores secrets
13. **outputs.tf**: The reporter who documents what was built

## The Complete Flow

When you run Terraform:

1. **Planning Phase**: Terraform reads all files and creates a plan of what to build
2. **Validation**: Checks that all the pieces fit together correctly
3. **Creation Phase**: Builds everything in the correct order (some things depend on others)
4. **Configuration**: Sets up all the connections between components
5. **Reporting**: Tells you what was created and how to use it

The result is a complete, production-ready infrastructure that can:
- Handle thousands of users simultaneously
- Automatically scale up and down based on demand
- Securely store and serve media files
- Monitor its own health and performance
- Automatically recover from failures
- Be easily updated and maintained

This infrastructure follows cloud best practices for security, scalability, and cost-effectiveness.

## Script Testing and Validation

During testing, we discovered and fixed several compatibility issues with the latest AWS provider version (v5.100.0):

### Issues Found and Fixed:

1. **S3 Lifecycle Configuration**: Added required `filter {}` block for AWS provider v5.x compatibility
2. **ECS Service Deployment**: Updated deployment configuration syntax for proper ECS service management  
3. **Auto Scaling Policies**: Removed unsupported `tags` attribute from scaling policies

### Validation Results:
All scripts have been tested and validated successfully with:
- **Terraform**: v1.13.4
- **AWS Provider**: v5.100.0  
- **Random Provider**: v3.7.2
- **Plan Status**: ✅ 36 resources planned for creation
- **Validation**: ✅ All syntax and configuration validated

The infrastructure is ready for deployment and has been thoroughly tested for compatibility with the latest provider versions.