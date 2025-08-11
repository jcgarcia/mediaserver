const express = require('express');
const multer = require('multer');
const multerS3 = require('multer-s3');
const AWS = require('aws-sdk');
const sharp = require('sharp');
const ffmpeg = require('fluent-ffmpeg');
const path = require('path');
const { v4: uuidv4 } = require('uuid');

const router = express.Router();

// Configure AWS
const s3 = new AWS.S3({
  region: process.env.AWS_REGION || 'eu-west-2'
});

// Configure CloudFront (if available)
const cloudfront = new AWS.CloudFront({
  region: process.env.AWS_REGION || 'eu-west-2'
});

// Multer configuration for S3 upload
const upload = multer({
  storage: multerS3({
    s3: s3,
    bucket: process.env.S3_BUCKET_NAME,
    metadata: function (req, file, cb) {
      cb(null, { 
        fieldName: file.fieldname,
        uploadedBy: req.user?.id || 'anonymous',
        uploadedAt: new Date().toISOString()
      });
    },
    key: function (req, file, cb) {
      const fileExtension = path.extname(file.originalname);
      const fileName = `${uuidv4()}${fileExtension}`;
      const folder = file.mimetype.startsWith('image/') ? 'images' : 
                    file.mimetype.startsWith('video/') ? 'videos' : 'files';
      cb(null, `media/${folder}/${fileName}`);
    }
  }),
  limits: {
    fileSize: 100 * 1024 * 1024 // 100MB limit
  },
  fileFilter: (req, file, cb) => {
    // Allow images and videos
    if (file.mimetype.startsWith('image/') || file.mimetype.startsWith('video/')) {
      cb(null, true);
    } else {
      cb(new Error('Only image and video files are allowed'), false);
    }
  }
});

// Upload endpoint
router.post('/upload', upload.single('media'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'No file uploaded' });
    }

    const mediaData = {
      id: path.parse(req.file.key).name,
      originalName: req.file.originalname,
      mimeType: req.file.mimetype,
      size: req.file.size,
      s3Key: req.file.key,
      s3Bucket: req.file.bucket,
      uploadedAt: new Date().toISOString(),
      url: req.file.location
    };

    // Generate thumbnails for images
    if (req.file.mimetype.startsWith('image/')) {
      try {
        const thumbnailKey = req.file.key.replace(/(\.[^.]+)$/, '_thumb$1');
        
        // Get original image from S3
        const originalImage = await s3.getObject({
          Bucket: req.file.bucket,
          Key: req.file.key
        }).promise();

        // Generate thumbnail
        const thumbnail = await sharp(originalImage.Body)
          .resize(300, 300, { 
            fit: 'inside',
            withoutEnlargement: true 
          })
          .jpeg({ quality: 80 })
          .toBuffer();

        // Upload thumbnail to S3
        await s3.upload({
          Bucket: req.file.bucket,
          Key: thumbnailKey,
          Body: thumbnail,
          ContentType: 'image/jpeg'
        }).promise();

        mediaData.thumbnailKey = thumbnailKey;
      } catch (thumbError) {
        console.error('Thumbnail generation failed:', thumbError);
        // Continue without thumbnail
      }
    }

    res.status(201).json({
      message: 'File uploaded successfully',
      media: mediaData
    });

  } catch (error) {
    console.error('Upload error:', error);
    res.status(500).json({ error: 'Upload failed', message: error.message });
  }
});

// Get media file
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { thumbnail } = req.query;

    // Find the file in S3 (this would typically come from a database)
    const listParams = {
      Bucket: process.env.S3_BUCKET_NAME,
      Prefix: `media/`
    };

    const objects = await s3.listObjectsV2(listParams).promise();
    const mediaFile = objects.Contents.find(obj => obj.Key.includes(id));

    if (!mediaFile) {
      return res.status(404).json({ error: 'Media file not found' });
    }

    let key = mediaFile.Key;
    if (thumbnail && key.match(/\.(jpg|jpeg|png|gif)$/i)) {
      const thumbnailKey = key.replace(/(\.[^.]+)$/, '_thumb$1');
      // Check if thumbnail exists
      try {
        await s3.headObject({ Bucket: process.env.S3_BUCKET_NAME, Key: thumbnailKey }).promise();
        key = thumbnailKey;
      } catch (err) {
        // Thumbnail doesn't exist, use original
      }
    }

    // Generate signed URL for secure access
    const signedUrl = s3.getSignedUrl('getObject', {
      Bucket: process.env.S3_BUCKET_NAME,
      Key: key,
      Expires: 3600 // 1 hour
    });

    res.json({
      id,
      url: signedUrl,
      key: key
    });

  } catch (error) {
    console.error('Get media error:', error);
    res.status(500).json({ error: 'Failed to retrieve media', message: error.message });
  }
});

// List media files
router.get('/', async (req, res) => {
  try {
    const { page = 1, limit = 20, type } = req.query;
    
    const listParams = {
      Bucket: process.env.S3_BUCKET_NAME,
      Prefix: type ? `media/${type}/` : 'media/',
      MaxKeys: parseInt(limit)
    };

    const objects = await s3.listObjectsV2(listParams).promise();
    
    const mediaFiles = objects.Contents
      .filter(obj => !obj.Key.endsWith('/') && !obj.Key.includes('_thumb'))
      .map(obj => ({
        id: path.parse(obj.Key).name,
        key: obj.Key,
        size: obj.Size,
        lastModified: obj.LastModified,
        url: `${req.protocol}://${req.get('host')}/api/media/${path.parse(obj.Key).name}`
      }));

    res.json({
      files: mediaFiles,
      count: mediaFiles.length,
      page: parseInt(page),
      limit: parseInt(limit)
    });

  } catch (error) {
    console.error('List media error:', error);
    res.status(500).json({ error: 'Failed to list media files', message: error.message });
  }
});

// Delete media file
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    // Find the file in S3
    const listParams = {
      Bucket: process.env.S3_BUCKET_NAME,
      Prefix: `media/`
    };

    const objects = await s3.listObjectsV2(listParams).promise();
    const mediaFile = objects.Contents.find(obj => obj.Key.includes(id));

    if (!mediaFile) {
      return res.status(404).json({ error: 'Media file not found' });
    }

    // Delete original file
    await s3.deleteObject({
      Bucket: process.env.S3_BUCKET_NAME,
      Key: mediaFile.Key
    }).promise();

    // Delete thumbnail if it exists
    const thumbnailKey = mediaFile.Key.replace(/(\.[^.]+)$/, '_thumb$1');
    try {
      await s3.deleteObject({
        Bucket: process.env.S3_BUCKET_NAME,
        Key: thumbnailKey
      }).promise();
    } catch (err) {
      // Thumbnail might not exist, ignore error
    }

    res.json({ message: 'Media file deleted successfully' });

  } catch (error) {
    console.error('Delete media error:', error);
    res.status(500).json({ error: 'Failed to delete media file', message: error.message });
  }
});

module.exports = router;
