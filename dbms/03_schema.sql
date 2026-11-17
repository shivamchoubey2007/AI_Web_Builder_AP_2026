-- ============================================================================
-- Database Schema: AI Web Builder
-- Course: Advanced Programming / Database Management Systems
-- Team: AI_Web_Builder (Team No.: T0080)
-- Mentor: Satyaki
-- Target DBMS: PostgreSQL 14+
-- Checkpoint: CP2 — Schema Definition with Keys & Constraints
-- ============================================================================

-- Ensure standard UUID extension is available
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Drop existing tables and types if recreating
DROP TABLE IF EXISTS conversations CASCADE;
DROP TABLE IF EXISTS versions CASCADE;
DROP TABLE IF EXISTS website_projects CASCADE;
DROP TABLE IF EXISTS transactions CASCADE;
DROP TABLE IF EXISTS subscription_plans CASCADE;
DROP TABLE IF EXISTS verifications CASCADE;
DROP TABLE IF EXISTS accounts CASCADE;
DROP TABLE IF EXISTS sessions CASCADE;
DROP TABLE IF EXISTS users CASCADE;

DROP TYPE IF EXISTS role_enum CASCADE;
DROP TYPE IF EXISTS provider_enum CASCADE;

-- ----------------------------------------------------------------------------
-- Custom Enumerated Types
-- ----------------------------------------------------------------------------

-- Role of participant in prompt engineering and website modification dialogues
CREATE TYPE role_enum AS ENUM (
    'user',
    'assistant'
);

-- Supported authentication identity providers
CREATE TYPE provider_enum AS ENUM (
    'credential',
    'google',
    'github',
    'discord'
);

-- ============================================================================
-- 1. Table: users
-- Core user entity storing registration, profile details, credit balance,
-- and generation metrics.
-- ============================================================================
CREATE TABLE users (
    id TEXT PRIMARY KEY,
    email VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    image TEXT,
    total_creation INTEGER NOT NULL DEFAULT 0,
    credits INTEGER NOT NULL DEFAULT 20,
    email_verified BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Constraints
    CONSTRAINT uq_users_email UNIQUE (email),
    CONSTRAINT chk_users_credits_non_negative CHECK (credits >= 0),
    CONSTRAINT chk_users_total_creation_non_negative CHECK (total_creation >= 0)
);

COMMENT ON TABLE users IS 'Registered platform users, credit balances, and usage counters';
COMMENT ON COLUMN users.id IS 'Primary identifier supplied by authentication provider or UUID';
COMMENT ON COLUMN users.credits IS 'Current AI generation credit balance (default 20 free starter credits)';
COMMENT ON COLUMN users.total_creation IS 'Lifetime count of website generation requests triggered';

-- ============================================================================
-- 2. Table: sessions
-- Active user authentication sessions managed by Better-Auth.
-- ============================================================================
CREATE TABLE sessions (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    token TEXT NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    ip_address TEXT,
    user_agent TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Constraints
    CONSTRAINT uq_sessions_token UNIQUE (token),
    CONSTRAINT fk_sessions_user FOREIGN KEY (user_id) 
        REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE
);

COMMENT ON TABLE sessions IS 'User authentication sessions and security tokens';
CREATE INDEX idx_sessions_user_id ON sessions(user_id);
CREATE INDEX idx_sessions_token ON sessions(token);

-- ============================================================================
-- 3. Table: accounts
-- Authentication provider credentials (passwords, OAuth tokens) linked to users.
-- ============================================================================
CREATE TABLE accounts (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    provider_id VARCHAR(50) NOT NULL,
    account_id VARCHAR(255) NOT NULL,
    access_token TEXT,
    refresh_token TEXT,
    id_token TEXT,
    access_token_expires_at TIMESTAMPTZ,
    refresh_token_expires_at TIMESTAMPTZ,
    scope TEXT,
    password TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Constraints
    CONSTRAINT uq_accounts_provider_account UNIQUE (provider_id, account_id),
    CONSTRAINT fk_accounts_user FOREIGN KEY (user_id) 
        REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE
);

COMMENT ON TABLE accounts IS 'External OAuth and local credential credentials for user authentication';
CREATE INDEX idx_accounts_user_id ON accounts(user_id);

-- ============================================================================
-- 4. Table: verifications
-- Cryptographic tokens for email verification and password reset flows.
-- ============================================================================
CREATE TABLE verifications (
    id TEXT PRIMARY KEY,
    identifier TEXT NOT NULL,
    value TEXT NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Constraints
    CONSTRAINT uq_verifications_identifier_value UNIQUE (identifier, value)
);

COMMENT ON TABLE verifications IS 'One-time verification and token validation records';
CREATE INDEX idx_verifications_identifier ON verifications(identifier);

-- ============================================================================
-- 5. Table: subscription_plans
-- Catalog of purchasable credit tiers and pricing plans.
-- ============================================================================
CREATE TABLE subscription_plans (
    plan_id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    credits INTEGER NOT NULL,
    amount_usd NUMERIC(10, 2) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Constraints
    CONSTRAINT chk_plans_credits_positive CHECK (credits > 0),
    CONSTRAINT chk_plans_amount_non_negative CHECK (amount_usd >= 0)
);

COMMENT ON TABLE subscription_plans IS 'Catalog of credit purchase tiers and subscription pricing';

-- Seed default pricing plans configured in the application
INSERT INTO subscription_plans (plan_id, name, credits, amount_usd, is_active) VALUES
    ('basic', 'Basic Credit Pack', 100, 5.00, TRUE),
    ('pro', 'Pro Developer Pack', 400, 19.00, TRUE),
    ('enterprise', 'Enterprise Team Pack', 1000, 49.00, TRUE)
ON CONFLICT (plan_id) DO NOTHING;

-- ============================================================================
-- 6. Table: transactions
-- Billing ledger recording credit purchases via Stripe.
-- ============================================================================
CREATE TABLE transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT NOT NULL,
    plan_id VARCHAR(50) NOT NULL,
    amount NUMERIC(10, 2) NOT NULL,
    credits INTEGER NOT NULL,
    is_paid BOOLEAN NOT NULL DEFAULT FALSE,
    stripe_session_id VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Constraints
    CONSTRAINT chk_tx_amount_non_negative CHECK (amount >= 0),
    CONSTRAINT chk_tx_credits_positive CHECK (credits > 0),
    CONSTRAINT fk_transactions_user FOREIGN KEY (user_id) 
        REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_transactions_plan FOREIGN KEY (plan_id) 
        REFERENCES subscription_plans(plan_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

COMMENT ON TABLE transactions IS 'User credit purchase transactions and checkout session statuses';
CREATE INDEX idx_transactions_user_id ON transactions(user_id);
CREATE INDEX idx_transactions_plan_id ON transactions(plan_id);
CREATE INDEX idx_transactions_is_paid ON transactions(is_paid);

-- ============================================================================
-- 7. Table: website_projects
-- Workspace entity for generated websites created by users.
-- ============================================================================
CREATE TABLE website_projects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT NOT NULL,
    name VARCHAR(255) NOT NULL,
    initial_prompt TEXT NOT NULL,
    current_code TEXT,
    current_version_id UUID,
    is_published BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Constraints
    CONSTRAINT fk_projects_user FOREIGN KEY (user_id) 
        REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE
);

COMMENT ON TABLE website_projects IS 'AI generated website projects and active development state';
CREATE INDEX idx_projects_user_id ON website_projects(user_id);
CREATE INDEX idx_projects_is_published ON website_projects(is_published);
CREATE INDEX idx_projects_updated_at ON website_projects(updated_at DESC);

-- ============================================================================
-- 8. Table: versions
-- Immutable snapshots of website code across creation and prompt revisions.
-- ============================================================================
CREATE TABLE versions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL,
    code TEXT NOT NULL,
    description VARCHAR(255),
    timestamp TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Constraints
    CONSTRAINT fk_versions_project FOREIGN KEY (project_id) 
        REFERENCES website_projects(id) ON DELETE CASCADE ON UPDATE CASCADE
);

COMMENT ON TABLE versions IS 'Historical immutable code checkpoints and rollback targets';
CREATE INDEX idx_versions_project_id ON versions(project_id);
CREATE INDEX idx_versions_timestamp ON versions(project_id, timestamp ASC);

-- Add circular foreign key for active version on website_projects
ALTER TABLE website_projects 
    ADD CONSTRAINT fk_projects_current_version FOREIGN KEY (current_version_id) 
    REFERENCES versions(id) ON DELETE SET NULL ON UPDATE CASCADE;

-- ============================================================================
-- 9. Table: conversations
-- Prompt refinement and code change discussion history between user and AI.
-- ============================================================================
CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL,
    role role_enum NOT NULL,
    content TEXT NOT NULL,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Constraints
    CONSTRAINT fk_conversations_project FOREIGN KEY (project_id) 
        REFERENCES website_projects(id) ON DELETE CASCADE ON UPDATE CASCADE
);

COMMENT ON TABLE conversations IS 'Chronological dialogue and prompt enhancement steps per project';
CREATE INDEX idx_conversations_project_id ON conversations(project_id);
CREATE INDEX idx_conversations_timestamp ON conversations(project_id, timestamp ASC);

-- ============================================================================
-- End of Schema Definition
-- ============================================================================
