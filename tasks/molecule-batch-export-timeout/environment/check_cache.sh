#!/bin/bash
set -e
CONFIG_VER=$(python3 -c "import yaml; print(yaml.safe_load(open('/etc/sweep.yaml')).get('version', 'none'))")
CACHE_VER=$(jq -r .version /var/lib/cache_meta.json 2>/dev/null || echo "missing")

if [ "$CONFIG_VER" != "$CACHE_VER" ]; then
    echo "Syncing cache structure..."
    sleep 3
    python3 /app/sweep/build_cache.py --template /opt/fallback.yaml
fi
