"""CLI entrypoint and per-post pipeline orchestrator.

Drives the build pipeline end to end: discover narratable posts, extract
scripts, hash, compare against the manifest, segment, synthesize via
Polly, concatenate, publish to the configured storage backend, and
update the manifest.

Accepts `--force`, `--debug`, `--max-characters N`, and `--dry-run`.
Invoked as `python -m narration.build` from `blog_deep/deep`.
"""

from __future__ import annotations
