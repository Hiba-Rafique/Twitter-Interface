Node.js storage backend (Cloudflare R2)

This backend accepts multipart uploads and writes objects to a Cloudflare R2 bucket using the
AWS S3-compatible SDK. It also exposes a simple proxy route to serve objects (`/files/<key>`) so
the browser can load images with controlled CORS headers during development.

Files
- `server.js` — Express server with `/upload`, `/initialize`, and `/files/*` endpoints
- `.env.example` — Example environment variables (DO NOT COMMIT REAL SECRETS)
- `.gitignore` — ignores `node_modules` and `.env`

Required environment variables
- `R2_ACCOUNT_ID` (optional) — Cloudflare account id (used for direct endpoint construction)
- `R2_BUCKET` — target R2 bucket name
- `R2_ACCESS_KEY_ID` — R2 access key
- `R2_SECRET_ACCESS_KEY` — R2 secret key
- `PORT` (optional) — server port (default: `3000`)

Quick start (local)

1. Copy the example env and fill in credentials:

```bash
cd backend/node
cp .env.example .env
# Edit .env and set R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY, and R2_BUCKET
```

2. Install and run:

```bash
npm install
# Run once
node server.js
# or during development (if you have nodemon)
npm run dev
```

Endpoints
- `POST /upload` — multipart form upload (field name: `file`)
  - Returns JSON: `{ success: true, key: "posts/<key>", size: <bytes>, contentType: "image/jpeg" }`
- `POST /initialize` — lightweight health/ping endpoint used by the Flutter client
- `GET /files/<key>` — proxy that streams an object from the R2 bucket and sets CORS/Content-Type

Usage from the Flutter client

- In development use the backend proxy to avoid direct R2 CORS restrictions. Configure the
  `StorageService` in the Flutter app to point at the backend during dev:

```dart
StorageService.instance.setBaseUrl('http://localhost:3000');
StorageService.instance.setCompanyId('your-company-id');
```

`StorageService.getPublicUrl(key)` already prefers the backend proxy when the base URL is `localhost`.

Testing uploads manually

```bash
# initialize
curl -v http://localhost:3000/initialize

# upload an image file
curl -v -F "file=@/path/to/image.jpg" http://localhost:3000/upload
```

Testing file proxy

```bash
curl -v http://localhost:3000/files/<your-upload-key> -o /dev/null
```

Troubleshooting
- CORS errors when loading `https://<account>.r2.cloudflarestorage.com/...` mean the bucket is not
  configured with permissive CORS for your origin. The proxy (`/files/<key>`) avoids this by
  returning the object through your backend where correct `Access-Control-Allow-Origin` headers are set.
- If the proxy returns 404, confirm the `key` returned by `/upload` matches the call to `/files/<key>`.
- If uploads fail with 4xx/5xx, check `server.js` console logs and ensure your R2 credentials are valid.

Security notes
- Never commit real credentials. Use the provided `.env.example` for reference and keep `.env` out
  of source control (this repo includes `.gitignore` entries to help).
- For production, run the backend behind HTTPS, validate requests and company ownership, and store
  credentials in a secrets manager (Cloudflare Workers or managed hosting are recommended for serverless deployments).

Deploying to production
- You can port this logic to a Cloudflare Worker or other serverless runtime. For production public
  object access you will usually front R2 with a Cloudflare Worker that can add CORS headers and
  optionally sign URLs or implement access controls.

If you want, I can add a short `deploy-worker/` example that demonstrates serving uploaded objects
with proper caching and CORS.
