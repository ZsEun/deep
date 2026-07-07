"""Narration script extractor.

Transforms a post's raw Markdown source into a plain-text `NarrationScript`
suitable for text-to-speech. Strips front matter, fenced/inline code, raw
HTML, and flattens links; replaces or drops images per `ImageAltMode`;
normalizes whitespace and preserves paragraph breaks.

Pure module: no network or disk I/O. All logic is deterministic and
idempotent so that `extract(extract(m).text) == extract(m)`.
"""

from __future__ import annotations
