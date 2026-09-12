#!/bin/bash
set -euo pipefail
/app/sweep/check_cache.sh
python3 /app/sweep/search.py
