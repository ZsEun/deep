"""Pytest configuration for scripts tests.

Adds both ``blog_deep/deep/scripts`` (so ``narration.*`` package imports
resolve) and ``blog_deep/deep/scripts/narration`` (so direct submodule
imports inside the narration package also resolve) to ``sys.path``.

Also preserves the legacy path used by the ``import_wechat`` smoke tests.
"""

from __future__ import annotations

import os
import sys

_SCRIPTS_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
_NARRATION_DIR = os.path.join(_SCRIPTS_DIR, "narration")

for _path in (_NARRATION_DIR, _SCRIPTS_DIR):
    if _path not in sys.path:
        sys.path.insert(0, _path)
