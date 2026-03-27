"""Pytest configuration for import_wechat tests."""

import sys
import os

# Add the scripts directory to the path so we can import import_wechat
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
