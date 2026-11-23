#!/usr/bin/env sh
# ============================================================================
# Local Isolated Benchmark Runner for AI Web Builder (CP4/CP5)
# Course: Advanced Programming / Database Management Systems
# Team: AI_Web_Builder (Team No.: T0080)
# ============================================================================
# Creates a temporary isolated PostgreSQL cluster on a private Unix socket,
# initializes 03_schema.sql, seeds deterministic data (seed.sql), validates
# execution of 04_queries.sql, executes benchmark.py, collects raw JSON plans,
# before/after execution timings, and tears down cleanly.
# ============================================================================

set -eu

# Resolve PostgreSQL binary path
if [ -n "${PG_BIN:-}" ]; then
    PATH="${PG_BIN}:${PATH}"
elif command -v pg_config >/dev/null 2>&1; then
    PATH="$(pg_config --bindir):${PATH}"
elif [ -d "/opt/homebrew/opt/postgresql@17/bin" ]; then
    PATH="/opt/homebrew/opt/postgresql@17/bin:${PATH}"
elif [ -d "/opt/homebrew/opt/postgresql@18/bin" ]; then
    PATH="/opt/homebrew/opt/postgresql@18/bin:${PATH}"
elif [ -d "/opt/homebrew/bin" ]; then
    PATH="/opt/homebrew/bin:${PATH}"
elif [ -d "/usr/local/opt/postgresql@17/bin" ]; then
    PATH="/usr/local/opt/postgresql@17/bin:${PATH}"
fi

export PATH

# Locate script and project directories
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DBMS_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
ROOT_DIR="$(cd "${DBMS_DIR}/.." && pwd)"

CLUSTER_DIR="$(mktemp -d /tmp/pg_ai_web_builder_cluster_XXXXXX)"
SOCKET_DIR="${CLUSTER_DIR}/sockets"
mkdir -p "${SOCKET_DIR}"

DB_NAME="ai_web_builder_bench"
PORT="54329"

cleanup() {
    echo ""
    echo "[CLEANUP] Tearing down temporary PostgreSQL cluster..."
    if [ -f "${CLUSTER_DIR}/server.log" ]; then
        echo "=== SERVER LOG ==="
        cat "${CLUSTER_DIR}/server.log"
        echo "=================="
    fi
    if [ -f "${CLUSTER_DIR}/postmaster.pid" ]; then
        pg_ctl -D "${CLUSTER_DIR}/data" -m immediate stop >/dev/null 2>&1 || true
    fi
    rm -rf "${CLUSTER_DIR}"
    echo "[CLEANUP] Done."
}

trap cleanup EXIT INT TERM

echo "============================================================================"
echo "AI Web Builder — Automated Local DBMS Benchmark"
echo "Target DBMS: $(psql --version)"
echo "Cluster Directory: ${CLUSTER_DIR}"
echo "============================================================================"

# 1. Initialize cluster
echo "\n[1/5] Initializing temporary cluster..."
initdb -D "${CLUSTER_DIR}/data" --no-locale -E UTF8 -A trust >/dev/null

# 2. Configure and start server (private socket, loopback only)
echo "\n[2/5] Starting server on custom socket..."
cat <<EOF >> "${CLUSTER_DIR}/data/postgresql.conf"
listen_addresses = '127.0.0.1'
port = ${PORT}
unix_socket_directories = '${SOCKET_DIR}'
timezone = 'Asia/Kolkata'
shared_buffers = 128MB
work_mem = 16MB
max_connections = 40
EOF

pg_ctl -D "${CLUSTER_DIR}/data" -l "${CLUSTER_DIR}/server.log" start >/dev/null

# Wait for server ready
psql -h "${SOCKET_DIR}" -p "${PORT}" -d postgres -c '\conninfo' >/dev/null 2>&1 || sleep 1

# 3. Create database and load schema + seed data
echo "\n[3/5] Creating database and applying schema + seed data..."
createdb -h "${SOCKET_DIR}" -p "${PORT}" "${DB_NAME}"

echo "  -> Executing 03_schema.sql..."
psql -h "${SOCKET_DIR}" -p "${PORT}" -d "${DB_NAME}" -v ON_ERROR_STOP=1 -f "${DBMS_DIR}/03_schema.sql" >/dev/null

echo "  -> Executing seed.sql..."
psql -h "${SOCKET_DIR}" -p "${PORT}" -d "${DB_NAME}" -v ON_ERROR_STOP=1 -f "${DBMS_DIR}/plans/seed.sql" >/dev/null

# 4. Validate full application queries execution
echo "\n[4/5] Validating execution of all 52 application queries (04_queries.sql)..."
psql -h "${SOCKET_DIR}" -p "${PORT}" -d "${DB_NAME}" -X -v ON_ERROR_STOP=1 -f "${DBMS_DIR}/04_queries.sql" >/dev/null
echo "  -> All 52 queries executed cleanly with 0 errors."

# 5. Execute benchmark suite
echo "\n[5/5] Running benchmark suite and generating execution plans..."
python3 "${DBMS_DIR}/plans/benchmark.py" \
    --host "${SOCKET_DIR}" \
    --port "${PORT}" \
    --dsn "${DB_NAME}" \
    --output-dir "${DBMS_DIR}/plans" \
    --indexes-sql "${DBMS_DIR}/plans/indexes.sql"

echo "\n============================================================================"
echo "Benchmark completed successfully! All plans saved to dbms/plans/"
echo "============================================================================"
