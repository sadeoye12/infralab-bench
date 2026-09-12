#!/bin/bash
set -euo pipefail

# ── Python bootstrap (T0 shell tasks may not have Python) ────────────────
if ! command -v python3 &>/dev/null; then
    DEBIAN_FRONTEND=noninteractive apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get install -y -qq python3 python3-pip >/dev/null 2>&1 || true
fi

# ── Service bootstrap (if needed) ──────────────────────────────────────
# Start any services the task requires.
# Database tasks: start the DB server and wait for readiness.

if command -v pg_isready &>/dev/null && [ -d /var/lib/postgresql ]; then
    su - postgres -c "pg_ctlcluster $(pg_lsclusters -h | awk '{print $1, $2}') start" 2>/dev/null || true
    for i in $(seq 1 30); do su - postgres -c "pg_isready" &>/dev/null && break; sleep 1; done
fi

if command -v mysqld_safe &>/dev/null && [ -d /var/lib/mysql ]; then
    mysqld_safe --skip-networking=0 &
    for i in $(seq 1 30); do mysqladmin ping --silent 2>/dev/null && break; sleep 1; done
fi

if command -v redis-server &>/dev/null && [ -f /etc/redis/redis.conf ]; then
    redis-server /etc/redis/redis.conf --daemonize no 2>/dev/null &
    for i in $(seq 1 30); do redis-cli ping 2>/dev/null | grep -q PONG && break; sleep 1; done
fi

if command -v mongod &>/dev/null && [ -d /var/lib/mongodb ]; then
    mongod --config /etc/mongod.conf 2>/dev/null &
    for i in $(seq 1 30); do mongosh --quiet --eval "db.runCommand({ping:1})" &>/dev/null && break; sleep 1; done
fi

# ── Apply solution if present ──────────────────────────────────────────
# REMOVED: test.sh must not run solve.sh. The framework will run solve.sh first during validation.

# ── Run pytest with CTRF output ────────────────────────────────────────
cd /app

# Install pytest if not present (best-effort; Dockerfile should have it)
if ! python3 -c "import pytest" 2>/dev/null; then
    uv pip install --system pytest 2>/dev/null || pip install pytest 2>/dev/null || true
fi

# Copy test file from /tests into workspace
mkdir -p /app
cp /tests/test_outputs.py /app/test_outputs.py 2>/dev/null || true

# Run tests (disable errexit to capture exit code and write reward file).
# Avoid fail-fast so Harbor sees the full failing surface for partial scoring.
set +e
python3 -m pytest /app/test_outputs.py --no-header -p no:cacheprovider -vs 2>&1
test_status=$?
set -e

# Ensure logs directory exists (Harbor mounts /logs but may not create subdirs)
mkdir -p /logs/verifier

if [ $test_status -eq 0 ]; then
    echo 1 > /logs/verifier/reward.txt
else
    echo 0 > /logs/verifier/reward.txt
fi

exit 0
