#!/usr/bin/env python3
"""
AI Web Builder - CP4/CP5 Benchmark Runner
Executes query workload, measures execution timings, captures raw EXPLAIN JSON plans,
evaluates index optimizations, and validates result equivalence.
"""

import argparse
import hashlib
import json
import os
import platform
import subprocess
import sys
import time
from pathlib import Path

QUERIES = [
    {
        "id": "Q01",
        "name": "User credential authentication lookup",
        "concepts": "INNER JOIN, equality filtering, LIMIT",
        "sql": """SELECT 
    u.id AS user_id,
    u.email,
    u.name,
    u.image,
    u.credits,
    u.total_creation,
    u.email_verified,
    a.id AS account_id,
    a.provider_id,
    a.password AS password_hash
FROM users u
INNER JOIN accounts a ON u.id = a.user_id
WHERE u.email = 'shivam.choubey@example.com' 
  AND a.provider_id = 'credential'
LIMIT 1;"""
    },
    {
        "id": "Q02",
        "name": "Active session validation and profile security check",
        "concepts": "INNER JOIN, unique token lookup, date comparison",
        "sql": """SELECT 
    s.id AS session_id,
    s.token,
    s.expires_at,
    s.user_id,
    u.email,
    u.name,
    u.credits,
    u.total_creation,
    u.email_verified
FROM sessions s
INNER JOIN users u ON s.user_id = u.id
WHERE s.token = 'sess_token_seed_000001'
  AND s.expires_at > CURRENT_TIMESTAMP;"""
    },
    {
        "id": "Q03",
        "name": "Active project workspace with code and active version",
        "concepts": "LEFT JOIN, INNER JOIN, UUID lookups",
        "sql": """SELECT 
    p.id AS project_id,
    p.name AS project_name,
    p.initial_prompt,
    p.current_code,
    p.is_published,
    p.created_at,
    p.updated_at,
    v.id AS active_version_id,
    v.description AS active_version_desc,
    v.timestamp AS active_version_time,
    u.id AS owner_id,
    u.name AS owner_name,
    u.email AS owner_email
FROM website_projects p
LEFT JOIN versions v ON p.current_version_id = v.id
INNER JOIN users u ON p.user_id = u.id
WHERE p.id = '11111111-1111-1111-1111-111111111111'
  AND p.user_id = 'usr_seed_000001';"""
    },
    {
        "id": "Q04",
        "name": "Chronological project dialogue history stream",
        "concepts": "INNER JOIN, FK filtering, ascending ordering",
        "sql": """SELECT 
    c.id AS message_id,
    c.role,
    c.content,
    c.timestamp,
    p.id AS project_id,
    p.name AS project_name
FROM conversations c
INNER JOIN website_projects p ON c.project_id = p.id
WHERE c.project_id = '11111111-1111-1111-1111-111111111111'
  AND p.user_id = 'usr_seed_000001'
ORDER BY c.timestamp ASC;"""
    },
    {
        "id": "Q05",
        "name": "Project version history and rollback targets",
        "concepts": "INNER JOIN, FK filtering, descending ordering",
        "sql": """SELECT 
    v.id AS version_id,
    v.project_id,
    v.description,
    v.timestamp,
    p.name AS project_name
FROM versions v
INNER JOIN website_projects p ON v.project_id = p.id
WHERE v.project_id = '11111111-1111-1111-1111-111111111111'
  AND p.user_id = 'usr_seed_000001'
ORDER BY v.timestamp DESC;"""
    },
    {
        "id": "Q06",
        "name": "User projects dashboard with aggregate summary counts",
        "concepts": "3-table join, GROUP BY, COUNT DISTINCT, MAX aggregate",
        "sql": """SELECT 
    p.id AS project_id,
    p.name,
    p.is_published,
    p.created_at,
    p.updated_at,
    COUNT(DISTINCT v.id) AS total_versions,
    COUNT(DISTINCT c.id) AS total_messages,
    MAX(v.timestamp) AS last_code_snapshot_at
FROM website_projects p
LEFT JOIN versions v ON p.id = v.project_id
LEFT JOIN conversations c ON p.id = c.project_id
WHERE p.user_id = 'usr_seed_000001'
GROUP BY p.id, p.name, p.is_published, p.created_at, p.updated_at
ORDER BY p.updated_at DESC;"""
    },
    {
        "id": "Q07",
        "name": "Published community projects showcase discovery feed",
        "concepts": "Partial filtering, INNER JOIN, descending ordering, LIMIT",
        "sql": """SELECT 
    p.id AS project_id,
    p.name AS project_name,
    p.initial_prompt,
    p.created_at,
    p.updated_at,
    u.id AS creator_id,
    u.name AS creator_name,
    u.image AS creator_avatar
FROM website_projects p
INNER JOIN users u ON p.user_id = u.id
WHERE p.is_published = TRUE
ORDER BY p.created_at DESC
LIMIT 20;"""
    },
    {
        "id": "Q08",
        "name": "Public live published website code rendering",
        "concepts": "UUID lookup, boolean condition, projection",
        "sql": """SELECT 
    p.id AS project_id,
    p.name,
    p.current_code,
    p.updated_at,
    u.name AS author_name
FROM website_projects p
INNER JOIN users u ON p.user_id = u.id
WHERE p.id = '11111111-1111-1111-1111-111111111111'
  AND p.is_published = TRUE;"""
    },
    {
        "id": "Q09",
        "name": "Stripe webhook transaction settlement verification",
        "concepts": "3-table join, UUID primary key lookup",
        "sql": """SELECT 
    t.id AS transaction_id,
    t.amount,
    t.credits,
    t.is_paid,
    t.stripe_session_id,
    t.created_at,
    p.plan_id,
    p.name AS plan_name,
    p.amount_usd AS plan_price,
    u.id AS user_id,
    u.email AS user_email,
    u.credits AS current_user_credits
FROM transactions t
INNER JOIN subscription_plans p ON t.plan_id = p.plan_id
INNER JOIN users u ON t.user_id = u.id
WHERE t.id = '44444444-4444-4444-4444-444444444444';"""
    },
    {
        "id": "Q10",
        "name": "User billing and invoice purchase ledger",
        "concepts": "INNER JOIN, user filtering, descending ordering",
        "sql": """SELECT 
    t.id AS transaction_id,
    t.amount,
    t.credits,
    t.is_paid,
    t.stripe_session_id,
    t.created_at,
    p.plan_id,
    p.name AS plan_name
FROM transactions t
INNER JOIN subscription_plans p ON t.plan_id = p.plan_id
WHERE t.user_id = 'usr_seed_000001'
ORDER BY t.created_at DESC;"""
    },
    {
        "id": "Q11",
        "name": "Top community creators leaderboard by published websites",
        "concepts": "CTE, GROUP BY, HAVING, DENSE_RANK window function",
        "sql": """WITH creator_stats AS (
    SELECT 
        u.id AS creator_id,
        u.name AS creator_name,
        u.image AS creator_avatar,
        COUNT(p.id) AS published_website_count,
        MAX(p.updated_at) AS latest_website_update
    FROM users u
    INNER JOIN website_projects p ON u.id = p.user_id
    WHERE p.is_published = TRUE
    GROUP BY u.id, u.name, u.image
    HAVING COUNT(p.id) >= 1
)
SELECT 
    creator_id,
    creator_name,
    creator_avatar,
    published_website_count,
    latest_website_update,
    DENSE_RANK() OVER (ORDER BY published_website_count DESC, latest_website_update DESC) AS rank
FROM creator_stats
ORDER BY rank ASC, published_website_count DESC
LIMIT 10;"""
    },
    {
        "id": "Q12",
        "name": "Daily paid checkout revenue and credit issuance velocity",
        "concepts": "IST date grouping, SUM, COUNT, conditional filter",
        "sql": """SELECT 
    DATE(t.created_at AT TIME ZONE 'Asia/Kolkata') AS txn_date,
    COUNT(*) AS paid_txns,
    SUM(t.amount) AS daily_revenue_usd,
    SUM(t.credits) AS total_credits_issued
FROM transactions t
WHERE t.is_paid = TRUE
  AND t.created_at >= '2026-10-01 00:00:00+05:30'
GROUP BY DATE(t.created_at AT TIME ZONE 'Asia/Kolkata')
ORDER BY txn_date ASC;"""
    }
]

SESSION_SETTINGS = """
SET TimeZone = 'Asia/Kolkata';
SET jit = off;
SET plan_cache_mode = force_custom_plan;
"""

def run_psql(cmd_args, sql, psql_path="psql"):
    """Execute SQL query using psql and return stdout."""
    full_cmd = [psql_path] + cmd_args
    proc = subprocess.run(
        full_cmd,
        input=sql,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        check=True
    )
    return proc.stdout

def get_engine_version(cmd_args, psql_path):
    version_sql = "SELECT version();"
    return run_psql(cmd_args + ["-t", "-A"], version_sql, psql_path).strip()

def run_query_data(cmd_args, sql, psql_path):
    """Run query to fetch result rows for equivalence check."""
    data_sql = f"{SESSION_SETTINGS}\n{sql}"
    res = run_psql(cmd_args + ["-A", "-F", "\t", "--no-align"], data_sql, psql_path)
    lines = [l for l in res.strip().splitlines() if l and not l.startswith("SET")]
    # Strip row count footer like (1 row)
    if lines:
        last = lines[-1].strip()
        if last.startswith("(") and last.endswith(")"):
            lines.pop()
    content = "\n".join(lines)
    fingerprint = hashlib.sha256(content.encode("utf-8")).hexdigest()
    return len(lines), fingerprint, content

def run_explain_analyze(cmd_args, sql, psql_path):
    """Run EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON) and return parsed JSON."""
    explain_sql = f"""{SESSION_SETTINGS}
EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)
{sql}"""
    raw_output = run_psql(cmd_args + ["-t", "-A"], explain_sql, psql_path)
    # Strip any preceding non-JSON output (like SET, NOTICE, etc.)
    start_idx = raw_output.find('[')
    if start_idx == -1:
        raise ValueError(f"No JSON array start found in output:\n{raw_output}")
    json_text = raw_output[start_idx:].strip()
    try:
        data = json.loads(json_text)
        return data
    except Exception as e:
        print(f"Error parsing JSON output: {e}\nRaw output:\n{raw_output}", file=sys.stderr)
        raise

def main():
    parser = argparse.ArgumentParser(description="AI Web Builder DBMS Benchmark Runner")
    parser.add_argument("--dsn", default="dbname=ai_web_builder_test", help="PostgreSQL DSN or dbname")
    parser.add_argument("--host", default="localhost", help="PostgreSQL host")
    parser.add_argument("--port", default="5432", help="PostgreSQL port")
    parser.add_argument("--user", default=os.environ.get("USER", ""), help="PostgreSQL username")
    parser.add_argument("--pg-bin", default="", help="Path to PostgreSQL binary directory")
    parser.add_argument("--output-dir", default=str(Path(__file__).parent), help="Output directory for plans and summary")
    parser.add_argument("--indexes-sql", default=str(Path(__file__).parent / "indexes.sql"), help="Path to indexes.sql")
    parser.add_argument("--skip-indexes", action="store_true", help="Skip applying indexes.sql")
    args = parser.parse_args()

    psql_path = "psql"
    if args.pg_bin:
        psql_path = os.path.join(args.pg_bin, "psql")

    cmd_args = ["-h", args.host, "-p", str(args.port), "-d", args.dsn]
    if args.user:
        cmd_args.extend(["-U", args.user])

    out_dir = Path(args.output_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    engine_version = get_engine_version(cmd_args, psql_path)
    print("=" * 80)
    print("AI Web Builder DBMS Workload Benchmark")
    print(f"Engine: {engine_version}")
    print(f"Platform: {platform.system()} {platform.machine()} ({platform.platform()})")
    print(f"Output Directory: {out_dir}")
    print("=" * 80)

    # Dictionary to hold full summary
    summary = {
        "benchmark_date": time.strftime("%Y-%m-%d %H:%M:%S %Z"),
        "engine_version": engine_version,
        "platform": f"{platform.system()} {platform.machine()} ({platform.platform()})",
        "queries": {}
    }

    # -------------------------------------------------------------------------
    # PHASE 1: Baseline Measurements
    # -------------------------------------------------------------------------
    print("\n[PHASE 1] Executing Baseline Workload (03_schema.sql)...")
    baseline_results = {}

    for q in QUERIES:
        qid = q["id"]
        sql = q["sql"]
        print(f"  Measuring {qid}: {q['name']}...", end="", flush=True)

        # 1. Warm-up and equivalence baseline
        row_count, fp, content = run_query_data(cmd_args, sql, psql_path)
        # Excluded EXPLAIN warm-up
        _ = run_explain_analyze(cmd_args, sql, psql_path)

        # 2. Five measured runs
        measured_runs = []
        for run_idx in range(5):
            plan_json = run_explain_analyze(cmd_args, sql, psql_path)
            exec_time = plan_json[0]["Execution Time"]
            plan_time = plan_json[0].get("Planning Time", 0.0)
            measured_runs.append({
                "run": run_idx + 1,
                "execution_time_ms": exec_time,
                "planning_time_ms": plan_time,
                "plan": plan_json
            })

        # Calculate median execution time run
        sorted_by_exec = sorted(measured_runs, key=lambda x: x["execution_time_ms"])
        median_run = sorted_by_exec[2] # 3rd of 5 is median
        times = [r["execution_time_ms"] for r in measured_runs]
        avg_time = sum(times) / len(times)

        # Save representative median plan
        before_plan_file = out_dir / f"{qid.lower()}_before.json"
        with open(before_plan_file, "w") as pf:
            json.dump(median_run["plan"], pf, indent=2)

        # Extract buffer statistics from representative run
        top_plan = median_run["plan"][0]["Plan"]
        shared_hit = top_plan.get("Shared Hit Blocks", 0)
        shared_read = top_plan.get("Shared Read Blocks", 0)

        baseline_results[qid] = {
            "name": q["name"],
            "concepts": q["concepts"],
            "row_count": row_count,
            "fingerprint": fp,
            "run_1_ms": times[0],
            "run_2_ms": times[1],
            "run_3_ms": times[2],
            "all_runs_ms": times,
            "median_ms": median_run["execution_time_ms"],
            "avg_ms": avg_time,
            "planning_ms": median_run["planning_time_ms"],
            "shared_hit_blocks": shared_hit,
            "shared_read_blocks": shared_read,
            "plan_file": before_plan_file.name
        }
        print(f" Done. Median: {median_run['execution_time_ms']:.3f} ms (Rows: {row_count})")

    # -------------------------------------------------------------------------
    # PHASE 2: Apply Optimization Indexes
    # -------------------------------------------------------------------------
    if not args.skip_indexes and os.path.exists(args.indexes_sql):
        print("\n[PHASE 2] Applying Optimization Candidate Indexes (indexes.sql)...")
        with open(args.indexes_sql) as f:
            idx_sql = f.read()
        run_psql(cmd_args, idx_sql, psql_path)
        print("  Candidate indexes applied and ANALYZE executed successfully.")

    # -------------------------------------------------------------------------
    # PHASE 3: Optimized Measurements
    # -------------------------------------------------------------------------
    print("\n[PHASE 3] Executing Optimized Workload (indexes.sql active)...")
    optimized_results = {}

    for q in QUERIES:
        qid = q["id"]
        sql = q["sql"]
        print(f"  Measuring {qid}: {q['name']}...", end="", flush=True)

        # 1. Warm-up and equivalence check
        opt_rows, opt_fp, opt_content = run_query_data(cmd_args, sql, psql_path)
        base_fp = baseline_results[qid]["fingerprint"]
        if opt_fp != base_fp:
            print(f" [WARNING: Hash mismatch! Base {base_fp[:8]} != Opt {opt_fp[:8]}]", end="")
        else:
            print(" [Equivalence verified]", end="")

        # Excluded EXPLAIN warm-up
        _ = run_explain_analyze(cmd_args, sql, psql_path)

        # 2. Five measured runs
        measured_runs = []
        for run_idx in range(5):
            plan_json = run_explain_analyze(cmd_args, sql, psql_path)
            exec_time = plan_json[0]["Execution Time"]
            plan_time = plan_json[0].get("Planning Time", 0.0)
            measured_runs.append({
                "run": run_idx + 1,
                "execution_time_ms": exec_time,
                "planning_time_ms": plan_time,
                "plan": plan_json
            })

        # Calculate median execution time run
        sorted_by_exec = sorted(measured_runs, key=lambda x: x["execution_time_ms"])
        median_run = sorted_by_exec[2]
        times = [r["execution_time_ms"] for r in measured_runs]
        avg_time = sum(times) / len(times)

        # Save representative median plan
        after_plan_file = out_dir / f"{qid.lower()}_after.json"
        with open(after_plan_file, "w") as pf:
            json.dump(median_run["plan"], pf, indent=2)

        top_plan = median_run["plan"][0]["Plan"]
        shared_hit = top_plan.get("Shared Hit Blocks", 0)
        shared_read = top_plan.get("Shared Read Blocks", 0)

        before_median = baseline_results[qid]["median_ms"]
        ratio = before_median / median_run["execution_time_ms"] if median_run["execution_time_ms"] > 0 else 1.0

        optimized_results[qid] = {
            "row_count": opt_rows,
            "fingerprint": opt_fp,
            "equivalent": (opt_fp == base_fp),
            "run_1_ms": times[0],
            "run_2_ms": times[1],
            "run_3_ms": times[2],
            "all_runs_ms": times,
            "median_ms": median_run["execution_time_ms"],
            "avg_ms": avg_time,
            "planning_ms": median_run["planning_time_ms"],
            "shared_hit_blocks": shared_hit,
            "shared_read_blocks": shared_read,
            "plan_file": after_plan_file.name,
            "speedup_ratio": ratio
        }
        print(f" Median: {median_run['execution_time_ms']:.3f} ms (Ratio: {ratio:.2f}x)")

    # -------------------------------------------------------------------------
    # Combine into Summary Structure
    # -------------------------------------------------------------------------
    for q in QUERIES:
        qid = q["id"]
        summary["queries"][qid] = {
            "name": q["name"],
            "concepts": q["concepts"],
            "baseline": baseline_results[qid],
            "optimized": optimized_results[qid]
        }

    summary_file = out_dir / "summary.json"
    with open(summary_file, "w") as sf:
        json.dump(summary, sf, indent=2)
    print(f"\n[SUMMARY] Saved benchmark summary to {summary_file}")

    # -------------------------------------------------------------------------
    # Generate Timings Table Markdown
    # -------------------------------------------------------------------------
    table_lines = [
        "| Query | Result rows | Run 1 (ms) | Run 2 (ms) | Run 3 (ms) | Before Avg (ms) | After Avg (ms) | Before / After |",
        "| :--- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |"
    ]
    for q in QUERIES:
        qid = q["id"]
        b = baseline_results[qid]
        o = optimized_results[qid]
        r1 = f"{b['run_1_ms']:.3f}"
        r2 = f"{b['run_2_ms']:.3f}"
        r3 = f"{b['run_3_ms']:.3f}"
        b_avg = f"{b['avg_ms']:.3f}"
        o_avg = f"{o['avg_ms']:.3f}"
        ratio_str = f"{o['speedup_ratio']:.2f}×"
        table_lines.append(f"| {qid} | {b['row_count']} | {r1} | {r2} | {r3} | {b_avg} | {o_avg} | {ratio_str} |")

    table_md = "\n".join(table_lines) + "\n"
    table_file = out_dir / "timings_table.md"
    with open(table_file, "w") as tf:
        tf.write(table_md)
    print(f"[SUMMARY] Saved timings table to {table_file}")

    print("\n" + table_md)
    print("=" * 80)
    print("Benchmark completed successfully.")
    print("=" * 80)

if __name__ == "__main__":
    main()
