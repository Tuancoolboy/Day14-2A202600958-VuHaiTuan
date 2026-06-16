#!/usr/bin/env bash
set -euo pipefail

python -m pytest tests/ -v
python bonus_framework_comparison.py
