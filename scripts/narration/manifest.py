"""Manifest manager and content hashing.

Provides `load_manifest`, `save_manifest`, `content_hash`, and
`needs_regeneration`. The manifest is serialized to JSON at
`assets/audio/manifest.json` and mirrored to `_data/audio_manifest.json`
so Jekyll exposes it as `site.data.audio_manifest`.

Writes are atomic (write-then-fsync-then-rename) so a crash mid-run
leaves the previous manifest intact. Updates are staged in memory and
flushed after each successful post.
"""

from __future__ import annotations
