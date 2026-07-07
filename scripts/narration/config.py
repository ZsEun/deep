"""Configuration loader and data models.

Defines the dataclasses and enums used across the pipeline
(`NarrationScript`, `LanguageSegment`, `SegmentAudio`, `ConcatenatedAudio`,
`VoiceConfig`, `RetryConfig`, `ManifestEntry`, `Manifest`, `BuildConfig`,
`ImageAltMode`) and implements `load_config(config_path, env)` which
reads `_config.yml` plus environment overrides (`AWS_REGION`,
`AWS_DEFAULT_REGION`, `NARRATION_STORAGE_BACKEND`).
"""

from __future__ import annotations
