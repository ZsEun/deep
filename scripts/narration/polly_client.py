"""Amazon Polly client wrapper.

Thin, testable wrapper around `boto3.client("polly").synthesize_speech`.
Looks up `(voice_id, engine)` for each segment's language from the
configured voice map, applies the standard boto3 retry layer, and
returns the MP3 bytes produced by Polly.

Keeps network I/O isolated from the rest of the pipeline so it can be
mocked via `botocore.stub.Stubber` in tests.
"""

from __future__ import annotations
