"""Storage backends for narration audio artifacts.

Defines the `StorageBackend` protocol and ships two implementations:
`LocalStorage` (writes to `assets/audio/` for the default GitHub-Pages
deploy) and `S3Storage` (uploads to S3 behind CloudFront for large
archives).
"""
