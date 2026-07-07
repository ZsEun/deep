"""Amazon S3 storage backend.

Uploads MP3 artifacts to `s3://{bucket}/audio/{slug}.mp3` with
`Content-Type: audio/mpeg` and returns the CloudFront URL
`https://{cloudfront_domain}/audio/{slug}.mp3` for inclusion in the
manifest. Supports `put`, `delete`, and `exists`, and (optionally)
issues a CloudFront invalidation after each successful upload.
"""

from __future__ import annotations
