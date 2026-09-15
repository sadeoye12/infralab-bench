#!/bin/bash
set -euo pipefail

# Wait for postgres to be ready
for i in $(seq 1 30); do
    if pg_isready -h 127.0.0.1 -U postgres >/dev/null 2>&1; then break; fi
    sleep 1
done

# 1. Fix version so regenerator stops overwriting cache with stale templates
sed -i 's/version: "v1.0"/version: "v2.1"/' /etc/sweep.yaml

# 2. Enable export flags to generate JSON output
sed -i 's/enabled: false/enabled: true/' /etc/sweep.yaml
if ! grep -q "format: json" /etc/sweep.yaml; then
    echo '  format: json' >> /etc/sweep.yaml
fi

# 3. Manually rebuild the cache with the correct radius so fast-search succeeds
python3 /app/sweep/build_cache.py --radius 2

# 4. Ensure /app is writable by postgres user for \copy output
chmod a+w /app

# 5. Append bulk DB join logic to run.sh
# Must use bulk SQL rather than a bash loop to beat the 3-second orchestrator timeout
if ! grep -q "matches.json" /app/sweep/run.sh; then
    cat << 'EOF' >> /app/sweep/run.sh

if [ -f /app/matches.json ]; then
    jq -r '.[].mol_id' /app/matches.json > /tmp/ids.csv
    cat << 'SQL' > /tmp/join.sql
\c chemistry
CREATE TEMP TABLE t_mols (mol_id TEXT);
\copy t_mols FROM '/tmp/ids.csv'
\copy (SELECT t.mol_id, b.batch_id FROM t_mols t JOIN public.batches b USING(mol_id)) TO '/app/results.csv' CSV HEADER
SQL
    su - postgres -c "psql -f /tmp/join.sql"
fi
EOF
fi

# Run the pipeline to ensure artifacts exist
bash /app/sweep/run.sh >/dev/null 2>&1 || true
