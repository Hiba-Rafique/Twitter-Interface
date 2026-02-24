require('dotenv').config();
const express = require('express');
const multer = require('multer');
const { S3Client, PutObjectCommand, GetObjectCommand } = require('@aws-sdk/client-s3');
const { Upload } = require('@aws-sdk/lib-storage');

const app = express();
const upload = multer({ storage: multer.memoryStorage() });

// Basic CORS for local development
// Simple CORS + logging middleware for local development
app.use((req, res, next) => {
  console.log(`[Storage Backend] ${req.method} ${req.url}`);
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,POST,OPTIONS');
  // Allow common headers plus our custom company header used by the client
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type,Authorization,x-company-id');
  // Allow credentials if needed
  res.setHeader('Access-Control-Allow-Credentials', 'true');
  if (req.method === 'OPTIONS') return res.sendStatus(204);
  next();
});

const accountId = process.env.R2_ACCOUNT_ID;
const bucket = process.env.R2_BUCKET;
const accessKeyId = process.env.R2_ACCESS_KEY_ID;
const secretAccessKey = process.env.R2_SECRET_ACCESS_KEY;

if (!accountId || !bucket || !accessKeyId || !secretAccessKey) {
  console.warn('R2 credentials missing. See .env.example and set environment variables.');
}

const endpoint = accountId ? `https://${accountId}.r2.cloudflarestorage.com` : undefined;

const s3 = new S3Client({
  endpoint: endpoint,
  region: 'auto',
  credentials: accessKeyId && secretAccessKey ? { accessKeyId, secretAccessKey } : undefined,
  forcePathStyle: false,
});

app.post('/initialize', async (req, res) => {
  // Lightweight endpoint for clients to check backend availability
  res.json({ success: true, message: 'initialized' });
});

app.post('/upload', upload.single('file'), async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ success: false, message: 'No file uploaded' });
    if (!bucket) return res.status(500).json({ success: false, message: 'R2 bucket not configured' });

    const originalName = req.file.originalname || `file_${Date.now()}`;
    const key = `posts/${Date.now()}_${Math.random().toString(36).slice(2)}_${originalName}`;

    const uploadParams = {
      Bucket: bucket,
      Key: key,
      Body: req.file.buffer,
      ContentType: req.file.mimetype || 'application/octet-stream',
      // ACL not used by R2; manage access via Workers or bucket settings
    };

    const parallelUpload = new Upload({
      client: s3,
      params: uploadParams,
    });

    const result = await parallelUpload.done();

    // Return a key the client can use. How you expose the URL depends on your setup.
    res.json({
      success: true,
      message: 'Uploaded',
      key: key,
      size: req.file.size,
      contentType: req.file.mimetype,
      result,
    });
  } catch (err) {
    console.error('Upload error', err);
    res.status(500).json({ success: false, message: String(err) });
  }
});

// Serve files from R2 through the backend to add CORS and correct headers.
// GET /files/<key>
app.get('/files/*', async (req, res) => {
  try {
    if (!bucket) return res.status(500).send('R2 bucket not configured');

    // Express places the wildcard part in req.params[0]
    const key = req.params[0];
    console.log(`[Storage Backend] GET /files/${key}`);

    const getCmd = new GetObjectCommand({ Bucket: bucket, Key: key });
    const data = await s3.send(getCmd);

    // Forward content-type and length if present
    if (data.ContentType) res.setHeader('Content-Type', data.ContentType);
    if (data.ContentLength) res.setHeader('Content-Length', data.ContentLength);

    // Body is a stream in Node.js; pipe it to response
    const body = data.Body;
    if (body && typeof body.pipe === 'function') {
      body.pipe(res);
    } else if (body) {
      // Fallback: buffer
      const chunks = [];
      for await (const chunk of body) chunks.push(chunk);
      const buffer = Buffer.concat(chunks);
      res.send(buffer);
    } else {
      res.status(404).send('Not found');
    }
  } catch (err) {
    console.error('Error fetching file', err);
    res.status(404).send('Not found');
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Storage backend listening on http://localhost:${PORT}`));
