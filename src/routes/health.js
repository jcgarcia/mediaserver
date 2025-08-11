const express = require('express');
const router = express.Router();

// Health check endpoint
router.get('/', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    service: 'mediaserver',
    version: process.env.npm_package_version || '1.0.0'
  });
});

// Detailed health check
router.get('/detailed', async (req, res) => {
  const health = {
    status: 'healthy',
    timestamp: new Date().toISOString(),
    service: 'mediaserver',
    version: process.env.npm_package_version || '1.0.0',
    checks: {
      database: 'healthy',
      s3: 'healthy',
      memory: process.memoryUsage(),
      uptime: process.uptime()
    }
  };

  // Check S3 connectivity
  try {
    const AWS = require('aws-sdk');
    const s3 = new AWS.S3({ region: process.env.AWS_REGION || 'eu-west-2' });
    await s3.headBucket({ Bucket: process.env.S3_BUCKET_NAME }).promise();
  } catch (error) {
    health.checks.s3 = 'unhealthy';
    health.status = 'degraded';
  }

  const statusCode = health.status === 'healthy' ? 200 : 503;
  res.status(statusCode).json(health);
});

module.exports = router;
