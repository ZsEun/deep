"""Pricing and cost tracking.

Computes per-engine Polly synthesis costs from a character count and a
price table, and formats the per-run summary string that the CLI emits
at the end of each build (posts generated / skipped / failed / removed,
characters per engine, total cost, deferred list, wall-time).
"""

from __future__ import annotations
