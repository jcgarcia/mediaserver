# Media Server

A scalable, cloud-native media server built for multi-cloud deployment with support for image and video upload, processing, and delivery.

## 🌟 Repository Overview

This repository contains multiple deployment strategies across different branches. **Choose the branch that matches your deployment target:**

| Branch | Deployment Target | Status | Description |
|--------|------------------|--------|-------------|
| **[main](#main-branch-local-development)** | Local Development | ✅ Ready | Base application code, Docker setup |
| **[terra](#terra-branch-terraform-aws)** | AWS (Terraform) | ✅ Production Ready | Complete AWS infrastructure with Terraform |
| **[aws](#aws-branch-jenkins-aws)** | AWS (Jenkins) | ✅ Ready | Jenkins-based AWS deployment with OIDC |
| **[aws-pg](#aws-pg-branch-aws-postgres)** | AWS + PostgreSQL | ✅ Ready | AWS deployment with PostgreSQL integration |
| **[oci](#oci-branch-oracle-cloud)** | Oracle Cloud | ✅ Ready | Oracle Cloud Infrastructure deployment |

---

## 🚀 Quick Start Guide

### 1. Choose Your Deployment Strategy

**For Local Development**: Stay on `main` branch
**For Production AWS (Recommended)**: Use `terra` branch
**For AWS with CI/CD**: Use `aws` branch  
**For AWS with Database**: Use `aws-pg` branch
**For Oracle Cloud**: Use `oci` branch

### 2. Clone and Switch to Your Target Branch

```bash
git clone https://github.com/jcgarcia/mediaserver.git
cd mediaserver

# Switch to your target branch
git checkout terra    # For Terraform AWS deployment
# OR
git checkout aws      # For Jenkins AWS deployment  
# OR  
git checkout aws-pg   # For AWS with PostgreSQL
# OR
git checkout oci      # For Oracle Cloud
```

## 🎯 Decision Matrix: Which Branch Should You Use?

| Scenario | Recommended Branch | Why |
|----------|-------------------|-----|
| **New to cloud deployment** | `terra` | Complete documentation, tested, ready-to-use |
| **Production AWS deployment** | `terra` | Infrastructure as Code, auto-scaling, monitoring |
| **Already using Jenkins** | `aws` | Integrates with existing CI/CD pipeline |
| **Need database integration** | `aws-pg` | PostgreSQL ready, database migrations included |
| **Using Oracle Cloud** | `oci` | Oracle-specific configurations and setup |
| **Local development only** | `main` | Lightweight, no cloud dependencies |
| **Learning Terraform** | `terra` | Best documented, step-by-step guides included |
| **Enterprise deployment** | `terra` or `aws` | Professional setup with security best practices |

---

## Features

- 🚀 **Scalable Architecture**: Built on AWS ECS with Fargate for serverless containers
- 📁 **S3 Storage**: Secure media storage with AWS S3
- 🖼️ **Image Processing**: Automatic thumbnail generation with Sharp
- 🎥 **Video Support**: Video upload and processing capabilities with FFmpeg
- 🔒 **Authentication**: JWT-based authentication system
- 🛡️ **Security**: Rate limiting, CORS, Helmet.js security headers
- 📊 **Health Monitoring**: Built-in health checks for monitoring
- 🌐 **CDN Ready**: Prepared for CloudFront integration
- 🐳 **Containerized**: Docker support for easy deployment

---

## 📋 Branch-Specific Build Instructions

### `main` Branch: Local Development

**Purpose**: Base application development and Docker containerization  
**Use Case**: Local development, testing, basic Docker deployment

```bash
git checkout main

# Install dependencies
pnpm install

# Configure environment
cp .env.example .env
# Edit .env with your configuration

# Start development server
pnpm dev

# Or run with Docker
docker-compose up -d
```

**What's Included**:
- Node.js Express application
- Docker configuration
- Basic deployment scripts
- Local development setup

---

### `terra` Branch: Terraform AWS ⭐ **RECOMMENDED**

**Purpose**: Production-ready AWS infrastructure using Terraform  
**Use Case**: Professional AWS deployment with Infrastructure as Code  
**Status**: ✅ **Fully tested and production-ready**

```bash
git checkout terra

# Review the comprehensive documentation
cat TERRAFORM_DOCUMENTATION.md        # Layman explanations
cat TERRAFORM_STEP_BY_STEP_GUIDE.md  # 36-step deployment guide
cat DEPLOYMENT_GUIDE.md              # Production procedures
cat TESTING_SUMMARY.md               # Validation results

# Configure Terraform
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
nano terraform/terraform.tfvars

# Deploy infrastructure (36 AWS resources)
./deploy-terraform.sh

# Clean up when done
./destroy-terraform.sh
```

**What's Included**:
- 13 Terraform files (36 AWS resources)
- ECS Fargate cluster with auto-scaling
- Application Load Balancer with SSL
- S3 storage with lifecycle management
- CloudWatch monitoring and logging
- IAM roles with least-privilege security
- Comprehensive documentation (5 guides)
- Automated deployment and cleanup scripts

**Cost Estimate**: ~$20-100/month depending on usage

---

### `aws` Branch: Jenkins AWS

**Purpose**: AWS deployment using Jenkins CI/CD with OIDC authentication  
**Use Case**: Organizations using Jenkins for CI/CD pipelines

```bash
git checkout aws

# Review Jenkins setup guides
cat JENKINS_AWS_OIDC_SSO_GUIDE.md     # OIDC setup with AWS
cat JENKINS_OIDC_PROVIDER_AWS_GUIDE.md # Provider configuration
cat JENKINS_OIDC_PROJECT_SETUP.md     # Project setup
cat JENKINS_PIPELINE_FIXED.md         # Pipeline configuration

# Deploy using deployment script
./deploy-aws.sh      # Standard deployment
./deploy-aws-sso.sh  # With SSO integration

# Configure Jenkins job
# Import jenkins-job-config-aws.xml into your Jenkins instance
```

**What's Included**:
- Jenkins pipeline configuration
- AWS OIDC integration setup
- SSO authentication guides
- Deployment automation scripts
- Jenkins job configuration files

---

### `aws-pg` Branch: AWS with PostgreSQL

**Purpose**: AWS deployment with PostgreSQL database integration  
**Use Case**: Applications requiring relational database backend

```bash
git checkout aws-pg

# Review PostgreSQL integration
cat DEPLOYMENT_GUIDE.md               # Updated for PostgreSQL
# Check scripts/ directory for database setup

# Run preflight checks
./scripts/preflight-aws-pg-local.sh   # Local environment check  
./scripts/preflight-aws-pg.sh         # AWS environment check

# Deploy with database
./deploy-aws.sh
```

**What's Included**:
- PostgreSQL integration
- Database migration scripts
- Enhanced deployment procedures
- Preflight validation scripts

---

### `oci` Branch: Oracle Cloud

**Purpose**: Oracle Cloud Infrastructure deployment  
**Use Case**: Organizations using Oracle Cloud services

```bash
git checkout oci

# Review OCI architecture
cat OCI_ARCHITECTURE_OVERVIEW.md      # Complete OCI setup guide

# Configure OCI credentials
# Follow OCI_ARCHITECTURE_OVERVIEW.md for setup

# Deploy using provided scripts
# (Follow OCI-specific deployment procedures)
```

**What's Included**:
- Oracle Cloud architecture documentation
- OCI deployment configurations
- Jenkins job configuration for OCI
- Detailed setup procedures

---

## 🏗️ Application Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Application   │    │       S3        │    │   CloudFront    │
│  Load Balancer  │───▶│     Bucket      │───▶│      CDN        │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │
         ▼
┌─────────────────┐    ┌─────────────────┐
│   ECS Cluster   │    │      ECR        │
│    (Fargate)    │◀───│   Repository    │
└─────────────────┘    └─────────────────┘
```

## AWS Resources Created

- **S3 Bucket**: `mediaserver-storage-[timestamp]` (to be created)
- **ECR Repository**: `<account-id>.dkr.ecr.eu-west-2.amazonaws.com/mediaserver`
- **ECS Cluster**: `mediaserver-cluster` (to be created)

## API Endpoints

### Health Check
- `GET /health` - Basic health check
- `GET /health/detailed` - Detailed health information

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - User login
- `GET /api/auth/verify` - Verify JWT token

### Media Management
- `POST /api/media/upload` - Upload media file
- `GET /api/media` - List media files
- `GET /api/media/:id` - Get specific media file
- `DELETE /api/media/:id` - Delete media file

## Local Development

1. **Clone the repository**:
   ```bash
   git clone https://github.com/jcgarcia/mediaserver.git
   cd mediaserver
   ```

2. **Install dependencies**:
   ```bash
   pnpm install
   ```

3. **Configure environment**:
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

4. **Start development server**:
   ```bash
   pnpm dev
   ```

## Docker Deployment

1. **Build the image**:
   ```bash
   docker build -t mediaserver .
   ```

2. **Run with Docker Compose**:
   ```bash
   docker-compose up -d
   ```

## AWS Deployment

### Prerequisites
- AWS CLI configured with appropriate permissions
- Docker installed
- Node.js 18+ with pnpm package manager for local development

### Deploy to AWS ECS

1. **Build and push Docker image**:
   ```bash
   # Get ECR login token
   aws ecr get-login-password --region eu-west-2 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.eu-west-2.amazonaws.com

   # Build and tag image
   docker build -t mediaserver .
   docker tag mediaserver:latest <account-id>.dkr.ecr.eu-west-2.amazonaws.com/mediaserver:latest

   # Push to ECR
   docker push <account-id>.dkr.ecr.eu-west-2.amazonaws.com/mediaserver:latest
   ```

2. **Create ECS Task Definition**:
   ```bash
   aws ecs register-task-definition --cli-input-json file://ecs-task-definition.json
   ```

3. **Create ECS Service**:
   ```bash
   aws ecs create-service --cluster mediaserver-cluster --service-name mediaserver-service --task-definition mediaserver:1 --desired-count 2
   ```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `NODE_ENV` | Environment mode | `development` |
| `PORT` | Application port | `3000` |
| `S3_BUCKET_NAME` | S3 bucket for media storage | Required |
| `AWS_REGION` | AWS region | `eu-west-2` |
| `JWT_SECRET` | Secret for JWT tokens | Required |
| `MONGODB_URI` | MongoDB connection string | Optional |
| `REDIS_URL` | Redis connection URL | Optional |
| `ALLOWED_ORIGINS` | CORS allowed origins | `http://localhost:3000` |

## Usage Examples

### Upload Media
```bash
curl -X POST \
  -H "Content-Type: multipart/form-data" \
  -F "media=@path/to/your/image.jpg" \
  http://localhost:3000/api/media/upload
```

### Get Media
```bash
curl http://localhost:3000/api/media/your-media-id
```

### Authentication
```bash
# Login
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "password": "admin123"}' \
  http://localhost:3000/api/auth/login

# Use token in subsequent requests
curl -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  http://localhost:3000/api/media/upload
```

## Monitoring

The application includes comprehensive health checks:

- Container health checks in Docker
- ECS health checks for service management
- Application-level health endpoints
- S3 connectivity checks

## Security Features

- JWT-based authentication
- Rate limiting (100 requests per 15 minutes per IP)
- CORS protection
- Security headers with Helmet.js
- File type validation
- File size limits (100MB)

## Performance Optimizations

- Automatic image thumbnail generation
- CDN-ready architecture
- Efficient S3 storage with proper naming
- Container-based horizontal scaling
- Memory and CPU optimized Docker image

## 📞 Support & Documentation

### Need Help?

1. **Check Branch-Specific Documentation**: Each branch has its own detailed guides
2. **Review Issue History**: Common problems and solutions
3. **Open an Issue**: For new problems or questions

### Branch-Specific Documentation Locations

| Branch | Key Documentation Files |
|--------|------------------------|
| `terra` | `TERRAFORM_DOCUMENTATION.md`, `TERRAFORM_STEP_BY_STEP_GUIDE.md`, `DEPLOYMENT_GUIDE.md` |
| `aws` | `JENKINS_AWS_OIDC_SSO_GUIDE.md`, `JENKINS_OIDC_PROVIDER_AWS_GUIDE.md` |
| `aws-pg` | `DEPLOYMENT_GUIDE.md`, scripts in `scripts/` directory |
| `oci` | `OCI_ARCHITECTURE_OVERVIEW.md` |
| `main` | This `README.md`, `SETUP.md` |

## 🤝 Contributing

### Branch Strategy

- **`main`**: Core application changes, base features
- **`terra`**: Terraform infrastructure improvements
- **`aws`**: Jenkins and AWS deployment enhancements
- **`aws-pg`**: Database integration features
- **`oci`**: Oracle Cloud specific updates

### Contribution Process

1. Fork the repository
2. Create a feature branch from the appropriate base branch
3. Make your changes with proper documentation
4. Test your changes (especially for deployment branches)
5. Submit a pull request to the correct branch

## 📄 License

MIT License - see LICENSE file for details.

## 🏆 Project Status

- **Active Development**: All branches actively maintained
- **Production Ready**: `terra` branch fully tested and validated
- **Multi-Cloud**: Supports AWS, Oracle Cloud deployments
- **Enterprise Ready**: Professional security and monitoring setup

---

**Happy Deploying! 🚀**

*Choose your branch, follow the guides, and get your media server running in minutes!*
