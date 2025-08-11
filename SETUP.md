# AWS Account Setup Checklist

## ✅ Steps to Complete Before Running Deployment

### 1. **Activate Required AWS Services**
You need to activate these services in the AWS Console:

#### **S3 Service Activation:**
1. Go to [AWS S3 Console](https://s3.console.aws.amazon.com/)
2. Click "Get Started" or "Create bucket" button
3. This will activate S3 service for your account

#### **ECS Service Activation:**
1. Go to [AWS ECS Console](https://console.aws.amazon.com/ecs/)
2. Click "Get Started" or "Create Cluster" button
3. This will activate ECS service for your account

### 2. **Verify Service Activation**
Run these commands to verify services are active:

```bash
# Test S3
aws s3 ls

# Test ECS  
aws ecs list-clusters
```

### 3. **Run Deployment Script**
Once services are activated, run:

```bash
./deploy-aws.sh
```

## 📋 What the Deployment Script Will Create

### **AWS Resources:**
- ✅ **ECR Repository**: `007041844937.dkr.ecr.eu-west-2.amazonaws.com/mediaserver` (already created)
- 🔄 **S3 Bucket**: `mediaserver-storage-[timestamp]` (for media files)
- 🔄 **ECS Cluster**: `mediaserver-cluster` (for container orchestration)
- 🔄 **IAM Roles**: `ecsTaskExecutionRole` and `ecsTaskRole` (for permissions)
- 🔄 **CloudWatch Log Group**: `/ecs/mediaserver` (for logging)
- 🔄 **Security Group**: `mediaserver-sg` (for network access)
- 🔄 **Parameter Store**: JWT secret storage
- 🔄 **ECS Service**: `mediaserver-service` (running containers)

### **Application Features:**
- 📁 **Media Upload/Download**: REST API for file management
- 🖼️ **Image Processing**: Automatic thumbnail generation
- 🎥 **Video Support**: Upload and serve video files
- 🔐 **Authentication**: JWT-based user authentication
- 📊 **Health Monitoring**: Built-in health checks
- 🚀 **Auto-scaling**: Fargate-based container scaling

## 🎯 After Deployment

### **Access Your Media Server:**
1. Get the public IP of your ECS tasks:
   ```bash
   aws ecs describe-tasks --cluster mediaserver-cluster --tasks $(aws ecs list-tasks --cluster mediaserver-cluster --query 'taskArns[0]' --output text) --query 'tasks[0].attachments[0].details[?name==`networkInterfaceId`].value' --output text | xargs -I {} aws ec2 describe-network-interfaces --network-interface-ids {} --query 'NetworkInterfaces[0].Association.PublicIp' --output text
   ```

2. Test the health endpoint:
   ```bash
   curl http://[PUBLIC_IP]:3000/health
   ```

### **API Endpoints:**
- `GET /health` - Health check
- `POST /api/auth/register` - Register user
- `POST /api/auth/login` - User login
- `POST /api/media/upload` - Upload media
- `GET /api/media` - List media files
- `GET /api/media/:id` - Get media file

### **Example Usage:**
```bash
# Register a user
curl -X POST http://[PUBLIC_IP]:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "password": "admin123"}'

# Upload a file
curl -X POST http://[PUBLIC_IP]:3000/api/media/upload \
  -H "Authorization: Bearer [JWT_TOKEN]" \
  -F "media=@image.jpg"
```

## 🔧 Optional Enhancements

After basic deployment, you can add:
- **Application Load Balancer** for high availability
- **CloudFront CDN** for global content delivery
- **RDS Database** for metadata storage
- **Custom Domain** with Route 53
- **SSL Certificate** with ACM
- **Auto Scaling** policies

## 🆘 Troubleshooting

### **Common Issues:**
1. **Service not activated**: Make sure S3 and ECS are activated in console
2. **Permission denied**: Ensure your AWS user has sufficient permissions
3. **Container fails to start**: Check CloudWatch logs in `/ecs/mediaserver`
4. **Network issues**: Verify security group allows port 3000

### **Useful Commands:**
```bash
# Check service status
aws ecs describe-services --cluster mediaserver-cluster --services mediaserver-service

# View logs
aws logs tail /ecs/mediaserver --follow

# Check running tasks
aws ecs list-tasks --cluster mediaserver-cluster

# Get task details
aws ecs describe-tasks --cluster mediaserver-cluster --tasks [TASK_ARN]
```

---
**Ready to deploy?** Activate the services and run `./deploy-aws.sh` 🚀
