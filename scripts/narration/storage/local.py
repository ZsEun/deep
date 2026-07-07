"""Local filesystem storage backend.

Writes MP3 artifacts to `assets/audio/{slug}.mp3` and returns the
site-relative URL `/assets/audio/{slug}.mp3` for inclusion in the
manifest. Supports `put`, `delete`, and `exists`, creating parent
directories as needed.
"""

from __future__ import annotations
