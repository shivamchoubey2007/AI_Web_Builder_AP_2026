-- ============================================================================
-- Candidate Optimization Indexes: AI Web Builder
-- Course: Advanced Programming / Database Management Systems
-- Team: AI_Web_Builder (Team No.: T0080)
-- Target DBMS: PostgreSQL 14+
-- Checkpoint: CP3/CP4 Index Optimization
-- ============================================================================
-- This script adds candidate indexes to evaluate execution plan changes and
-- timing improvements over the base schema (03_schema.sql).
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Index 1: Partial covering index for daily revenue and credit reporting (Q12)
-- Rationale:
-- Eliminates sequential heap scan over transactions table for financial rollups.
-- Restricts index entries strictly to settled payments (is_paid = TRUE) and
-- includes amount and credits in the index payload to enable Index-Only Scans.
-- ----------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS cp4_transactions_paid_created_covering_idx 
ON transactions (created_at) 
INCLUDE (amount, credits) 
WHERE is_paid = TRUE;

-- ----------------------------------------------------------------------------
-- Index 2: Partial B-tree index for community showcase feed discovery (Q07)
-- Rationale:
-- Accelerates community showcase queries filtering on is_published = TRUE and
-- sorting by created_at DESC. Avoids in-memory sort by leveraging pre-sorted
-- index tree order.
-- ----------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS cp4_projects_published_created_idx 
ON website_projects (created_at DESC) 
WHERE is_published = TRUE;

-- ----------------------------------------------------------------------------
-- Index 3: Composite index for user billing and transaction ledger (Q10)
-- Rationale:
-- Pairs user_id equality filter with descending created_at sort order to
-- optimize retrieval of user payment history without an explicit Sort node.
-- ----------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS cp4_transactions_user_created_idx 
ON transactions (user_id, created_at DESC);

-- ----------------------------------------------------------------------------
-- Index 4: Composite covering index for version history timeline (Q05)
-- Rationale:
-- Speeds up rollback version lookups sorted chronologically backwards.
-- ----------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS cp4_versions_project_time_desc_idx 
ON versions (project_id, timestamp DESC) 
INCLUDE (description);

-- Refresh planner statistics across optimized relations
ANALYZE transactions;
ANALYZE website_projects;
ANALYZE versions;
