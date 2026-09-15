#!/bin/bash
set -euo pipefail
su - postgres -c "pg_ctlcluster 15 main start"
for i in $(seq 1 30); do
    if su - postgres -c "psql -c '\q'" >/dev/null 2>&1; then break; fi
    sleep 1
done

cat << 'EOF' > /tmp/insert.sql
CREATE DATABASE chemistry;
\c chemistry
CREATE TABLE batches (mol_id TEXT PRIMARY KEY, batch_id TEXT, status TEXT);
EOF

python3 -c "
with open('/tmp/insert.sql', 'a') as f:
    f.write('INSERT INTO batches VALUES\n')
    values = []
    for i in range(1, 1001):
        status = 'active' if i % 3 != 0 else 'archived'
        values.append(f\"('mol_{i:03d}', 'B-{1000+i}', '{status}')\")
    f.write(',\n'.join(values) + ';\n')
    f.write(\"CREATE VIEW active_batches AS SELECT mol_id, batch_id FROM batches WHERE status = 'active';\n\")
"

su - postgres -c "psql -f /tmp/insert.sql"
su - postgres -c "pg_ctlcluster 15 main stop"
