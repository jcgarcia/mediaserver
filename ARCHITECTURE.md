# MediaServer Architecture Documentation

## Overview

MediaServer is a cloud-native, scalable media processing and storage solution built for AWS deployment. It provides secure upload, processing, and delivery of images and videos with automatic thumbnail generation, authentication, and comprehensive monitoring capabilities.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                AWS Cloud Infrastructure                          │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐             │
│  │   Application   │    │    CloudFront   │    │    Route 53     │             │
│  │ Load Balancer   │◄───┤      CDN        │◄───┤      DNS        │             │
│  │     (ALB)       │    │  (Distribution) │    │   (Optional)    │             │
│  └─────────────────┘    └─────────────────┘    └─────────────────┘             │
│           │                                                                     │
│           ▼                                                                     │
│  ┌─────────────────────────────────────────────────────────────────┐           │
│  │                    ECS Fargate Cluster                         │           │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │           │
│  │  │  MediaServer    │  │  MediaServer    │  │  MediaServer    │ │           │
│  │  │   Container     │  │   Container     │  │   Container     │ │           │
│  │  │   (Task 1)      │  │   (Task 2)      │  │   (Task N)      │ │           │
│  │  └─────────────────┘  └─────────────────┘  └─────────────────┘ │           │
│  └─────────────────────────────────────────────────────────────────┘           │
│                                    │                                           │
│                                    ▼                                           │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐             │
│  │       S3        │    │   Parameter     │    │   CloudWatch    │             │
│  │  Media Storage  │    │     Store       │    │   Logs/Metrics  │             │
│  │                 │    │  (JWT Secret)   │    │                 │             │
│  └─────────────────┘    └─────────────────┘    └─────────────────┘             │
│                                                                                 │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐             │
│  │       ECR       │    │       VPC       │    │  Security       │             │
│  │  Container      │    │   Networking    │    │    Groups      │             │
│  │   Registry      │    │                 │    │                 │             │
│  └─────────────────┘    └─────────────────┘    └─────────────────┘             │
└─────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────┐
│                              CI/CD Pipeline                                     │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  GitHub ──► Jenkins ──► Docker Build ──► ECR Push ──► Terraform ──► ECS Deploy │
│     │           │            │              │            │             │       │
│     │           ▼            ▼              ▼            ▼             ▼       │
│     └──► Tests ──► Security ──► Image Scan ──► Infra ──► App Deploy ──► Health │
│                    Checks        (ECR)       Provision   (Ansible)     Check   │
└─────────────────────────────────────────────────────────────────────────────────┘
```

## System Components

### 1. Application Layer

#### **Node.js Express Server**
- **Technology**: Node.js 18 with Express.js framework
- **Architecture**: RESTful API with modular route structure
- **Security**: Helmet.js, CORS, rate limiting (100 req/15min per IP)
- **Authentication**: JWT-based token authentication
- **File Processing**: Sharp for images, FFmpeg for videos
- **Health Monitoring**: Built-in health check endpoints

#### **API Endpoints Structure**
```
/health                     # Health check endpoints
├── GET /                   # Basic health status
└── GET /detailed          # Detailed system health

/api/auth                   # Authentication endpoints
├── POST /register         # User registration
├── POST /login           # User authentication
└── GET /verify           # Token verification

/api/media                  # Media management endpoints
├── POST /upload          # Media file upload
├── GET /                 # List media files
├── GET /:id              # Get specific media
└── DELETE /:id           # Delete media file
```

### 2. Storage Layer

#### **Amazon S3 Media Storage**
- **Bucket Configuration**: Private bucket with server-side encryption (AES256)
- **Structure**: Organized by media type (`media/images/`, `media/videos/`, `media/files/`)
- **Features**:
  - Versioning enabled
  - Lifecycle policies (Standard → IA → Glacier)
  - CORS configuration for web access
  - Public access blocked for security
- **Thumbnail Generation**: Automatic thumbnail creation for images

#### **File Organization**
```
s3://mediaserver-storage-[random]/
├── media/
│   ├── images/
│   │   ├── [uuid].jpg
│   │   └── [uuid]_thumb.jpg
│   ├── videos/
│   │   ├── [uuid].mp4
│   │   └── [uuid]_thumb.jpg
│   └── files/
│       └── [uuid].[ext]
```

### 3. Container Platform

#### **Amazon ECS with Fargate**
- **Orchestration**: Fully managed container orchestration
- **Compute**: Serverless containers (256 CPU, 512MB RAM)
- **Scaling**: Auto-scaling based on CPU/memory utilization
- **Service Discovery**: Built-in service mesh capabilities
- **Health Checks**: Container and application-level health monitoring

#### **Container Specifications**
```dockerfile
Base Image: node:18-alpine
Dependencies: FFmpeg, Sharp, AWS SDK
Security: Non-root user (nodejs:1001)
Networking: Port 3000 exposed
Health Check: HTTP GET /health every 30s
Resource Limits: 256 CPU units, 512MB memory
```

### 4. Infrastructure as Code

#### **Terraform Configuration**
- **Provider**: AWS Provider v5.x
- **State Management**: Local state (S3 backend configurable)
- **Resources**: 
  - ECS cluster and services
  - S3 bucket with policies
  - IAM roles and policies
  - Security groups
  - CloudWatch log groups
  - SSM parameters for secrets

#### **Ansible Automation**
- **Deployment Orchestration**: Complete deployment workflow
- **Tasks**:
  - Infrastructure provisioning
  - Docker image building and pushing
  - ECS service updates
  - Health verification
- **Idempotency**: Safe to run multiple times

### 5. Security Architecture

#### **Identity and Access Management**
- **ECS Task Execution Role**: Permissions for ECS task management
- **ECS Task Role**: Application permissions (S3 access, CloudWatch)
- **Principle of Least Privilege**: Minimal required permissions
- **Secrets Management**: AWS Systems Manager Parameter Store

#### **Network Security**
- **VPC**: Default VPC with public subnets
- **Security Groups**: 
  - ALB: HTTP/HTTPS from internet
  - ECS Tasks: HTTP from ALB only
- **Encryption**: Data at rest (S3) and in transit (HTTPS)

#### **Application Security**
- **JWT Authentication**: Stateless token-based auth
- **Rate Limiting**: 100 requests per 15 minutes per IP
- **Input Validation**: File type and size restrictions
- **CORS Policy**: Configurable allowed origins
- **Security Headers**: Helmet.js implementation

### 6. Monitoring and Observability

#### **CloudWatch Integration**
- **Log Groups**: `/ecs/mediaserver` for application logs
- **Metrics**: Container and application metrics
- **Alarms**: CPU, memory, and error rate monitoring
- **Retention**: 30-day log retention by default

#### **Health Monitoring**
```json
Health Check Endpoints:
{
  "basic": "GET /health",
  "detailed": "GET /health/detailed",
  "checks": {
    "s3_connectivity": "AWS S3 bucket access",
    "memory_usage": "Container memory metrics",
    "uptime": "Service uptime tracking"
  }
}
```

### 7. CI/CD Pipeline

#### **Jenkins Pipeline Stages**
1. **Source Control**: GitHub webhook triggers
2. **Dependency Management**: pnpm install with lock file
3. **Testing**: Jest test suite execution
4. **Security Scanning**: Container vulnerability assessment
5. **Image Building**: Docker multi-stage build
6. **Registry Push**: ECR image deployment
7. **Infrastructure**: Terraform apply via Ansible
8. **Application Deployment**: ECS service update
9. **Health Verification**: Post-deployment testing

#### **Deployment Strategy**
- **Blue-Green**: Zero-downtime deployments
- **Rollback Capability**: Previous image versions maintained
- **Environment Promotion**: Dev → Staging → Production
- **Automated Testing**: Integration and smoke tests

## Data Flow

### 1. Media Upload Flow
```
Client Request ──► Load Balancer ──► ECS Container ──► S3 Upload
                                          │
                                          ▼
                            Thumbnail Generation ──► S3 Thumbnail Storage
                                          │
                                          ▼
                                    Response to Client
```

### 2. Media Retrieval Flow
```
Client Request ──► Load Balancer ──► ECS Container ──► S3 Signed URL
                                          │
                                          ▼
                                   Direct S3 Access ──► Client
```

### 3. Authentication Flow
```
Login Request ──► ECS Container ──► JWT Generation ──► Client Storage
                       │
                       ▼
              Subsequent Requests ──► JWT Validation ──► Resource Access
```

## Scalability Considerations

### **Horizontal Scaling**
- **ECS Auto Scaling**: CPU/memory-based scaling policies
- **Load Balancing**: Application Load Balancer distribution
- **Stateless Design**: No server-side session storage

### **Performance Optimization**
- **CDN Integration**: CloudFront for global content delivery
- **Caching Strategy**: Browser caching headers
- **Image Optimization**: Automatic thumbnail generation
- **Efficient Storage**: S3 lifecycle policies for cost optimization

### **Capacity Planning**
- **Compute**: Fargate tasks scale from 2 to 10 instances
- **Storage**: S3 unlimited storage capacity
- **Network**: ALB handles high concurrent connections
- **Database**: Optional MongoDB/Redis for metadata caching

## Deployment Environments

### **Development**
- **Local**: Docker Compose with local S3 emulation
- **Testing**: Isolated AWS resources with cost optimization
- **Configuration**: Environment-specific variables

### **Production**
- **High Availability**: Multi-AZ deployment
- **Monitoring**: Comprehensive CloudWatch dashboards
- **Backup**: S3 versioning and cross-region replication
- **Disaster Recovery**: Infrastructure as Code for quick recovery

## Cost Optimization

### **Resource Efficiency**
- **Fargate Spot**: Cost-effective compute for non-critical workloads
- **S3 Lifecycle**: Automatic data archival (Standard → IA → Glacier)
- **Log Retention**: 30-day default with configurable retention
- **Right-sizing**: Container resources optimized for workload

### **Monitoring and Alerts**
- **Cost Budgets**: AWS Budget alerts for spending thresholds
- **Resource Utilization**: CloudWatch metrics for optimization
- **Reserved Capacity**: Future consideration for predictable workloads

## Security Best Practices

### **Data Protection**
- **Encryption**: At rest (S3 AES256) and in transit (TLS)
- **Access Control**: IAM roles with minimal permissions
- **Secrets Management**: AWS Systems Manager Parameter Store
- **Network Isolation**: VPC with security group restrictions

### **Compliance**
- **Audit Logging**: CloudTrail for API call tracking
- **Data Residency**: EU-West-2 region for GDPR compliance
- **Retention Policies**: Configurable data retention periods
- **Access Reviews**: Regular IAM permission audits

## Future Enhancements

### **Planned Features**
1. **Database Integration**: MongoDB for metadata storage
2. **Caching Layer**: Redis for improved performance
3. **Video Processing**: Advanced video transcoding with AWS MediaConvert
4. **Multi-Region**: Global deployment for better latency
5. **API Gateway**: AWS API Gateway for advanced routing
6. **WebSocket Support**: Real-time upload progress notifications
7. **AI Integration**: AWS Rekognition for content analysis

### **Scalability Roadmap**
1. **Microservices**: Split into dedicated services (auth, media, processing)
2. **Event-Driven**: SNS/SQS for asynchronous processing
3. **GraphQL**: Enhanced API with GraphQL endpoint
4. **Mobile SDK**: Native mobile application support

## Troubleshooting Guide

### **Common Issues**
1. **Upload Failures**: Check S3 bucket permissions and network connectivity
2. **Authentication Errors**: Verify JWT secret in Parameter Store
3. **Container Health**: Monitor ECS task health and CloudWatch logs
4. **Performance Issues**: Review container resource allocation and scaling policies

### **Monitoring Commands**
```bash
# Check ECS service status
aws ecs describe-services --cluster mediaserver-cluster --services mediaserver-service

# View application logs
aws logs tail /ecs/mediaserver --follow

# Check S3 bucket access
aws s3 ls s3://mediaserver-storage-[suffix]/

# Monitor container metrics
aws cloudwatch get-metric-statistics --namespace AWS/ECS --metric-name CPUUtilization
```

## Conclusion

The MediaServer architecture provides a robust, scalable, and secure solution for media processing and storage in the cloud. With comprehensive monitoring, automated deployment, and strong security practices, it serves as a production-ready platform for media-centric applications.

The modular design allows for easy maintenance and future enhancements, while the Infrastructure as Code approach ensures consistent and repeatable deployments across environments.