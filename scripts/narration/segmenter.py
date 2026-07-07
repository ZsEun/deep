"""Language segmenter.

Partitions a `NarrationScript` into an ordered sequence of
`LanguageSegment` values covering the whole script with no gaps or
overlaps. Classifies each character as `zh` (CJK), `en` (ASCII letter),
or neutral; attaches neutrals to a neighboring language; merges short
segments surrounded by a different language; and collapses adjacent
same-language runs.

Pure module: no network or disk I/O.
"""

from __future__ import annotations
