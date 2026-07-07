"""Audio concatenator.

Stitches per-segment MP3 bytes into a single MP3 with configurable
silence gaps inserted at language boundaries. Uses `pydub` (FFmpeg) to
decode each part, insert `AudioSegment.silent(duration=gap_ms)` between
segments whose `lang` differs from the predecessor, and re-encode to
MP3 at 64 kbps.

Returns the combined MP3 bytes and the reported duration in seconds.
"""

from __future__ import annotations
