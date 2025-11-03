# Media Server

A scalable, cloud-native media server built for AWS deployment with support for image and video upload, processing, and delivery.

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

## Architecture

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
- **ECR Repository**: `<YOUR-ACCOUNT-ID>.dkr.ecr.eu-west-2.amazonaws.com/mediaserver`
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
   aws ecr get-login-password --region eu-west-2 | docker login --username AWS --password-stdin <YOUR-ACCOUNT-ID>.dkr.ecr.eu-west-2.amazonaws.com

   # Build and tag image
   docker build -t mediaserver .
   docker tag mediaserver:latest <YOUR-ACCOUNT-ID>.dkr.ecr.eu-west-2.amazonaws.com/mediaserver:latest

   # Push to ECR
   docker push <YOUR-ACCOUNT-ID>.dkr.ecr.eu-west-2.amazonaws.com/mediaserver:latest
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

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

MIT License - see LICENSE file for details.

## Support

For support and questions, please open an issue in the GitHub repository.
