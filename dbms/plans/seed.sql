-- ============================================================================
-- Deterministic Synthetic Seed Data: AI Web Builder
-- Course: Advanced Programming / Database Management Systems
-- Team: AI_Web_Builder (Team No.: T0080)
-- Target DBMS: PostgreSQL 14+
-- Checkpoint: CP4 / Benchmark Performance Dataset
-- ============================================================================
-- Generates deterministic synthetic data with realistic volume:
--   - 2,001 Users
--   - 2,001 Linked Authentication Accounts
--   - 3,001 Authentication Sessions
--   - 1,002 Verification Challenges
--   - 3 Active Subscription Plans
--   - 10,002 Billing Ledger Transactions (~80% Paid, 20% Pending/Expired)
--   - 5,002 Website Projects (Published & Private)
--   - 20,002 Code Version Snapshots
--   - 40,002 Dialogue Messages in Conversations
-- ============================================================================

\set ON_ERROR_STOP on

BEGIN;

-- ----------------------------------------------------------------------------
-- 1. Deterministic Users
-- ----------------------------------------------------------------------------
-- Primary benchmark user
INSERT INTO users (
    id, email, name, image, total_creation, credits, email_verified, created_at, updated_at
) VALUES (
    'usr_seed_000001',
    'shivam.choubey@example.com',
    'Shivam Choubey',
    'https://avatars.githubusercontent.com/u/10001',
    42,
    250,
    TRUE,
    TIMESTAMPTZ '2026-09-01 10:00:00+05:30',
    TIMESTAMPTZ '2026-11-20 18:30:00+05:30'
) ON CONFLICT (id) DO UPDATE SET updated_at = EXCLUDED.updated_at;

-- Dedicated disposable user for DELETE test query
INSERT INTO users (
    id, email, name, image, total_creation, credits, email_verified, created_at, updated_at
) VALUES (
    'usr_seed_temp_delete',
    'temp.delete@example.com',
    'Temp Delete User',
    NULL,
    0,
    20,
    FALSE,
    TIMESTAMPTZ '2026-11-01 08:00:00+05:30',
    TIMESTAMPTZ '2026-11-01 08:00:00+05:30'
) ON CONFLICT (id) DO NOTHING;

-- Bulk synthetic users (2,000 users)
INSERT INTO users (
    id, email, name, image, total_creation, credits, email_verified, created_at, updated_at
)
SELECT
    'usr_seed_' || LPAD(i::text, 6, '0') AS id,
    'user_' || i || '@example.com' AS email,
    'Synthetic User ' || i AS name,
    CASE WHEN i % 3 = 0 THEN 'https://images.unsplash.com/photo-seed-' || i ELSE NULL END AS image,
    (i % 35) AS total_creation,
    ((i * 13) % 450) + 10 AS credits,
    (i % 4 != 0) AS email_verified,
    TIMESTAMPTZ '2026-08-01 00:00:00+05:30' + (i * INTERVAL '40 minutes') AS created_at,
    TIMESTAMPTZ '2026-08-01 00:00:00+05:30' + (i * INTERVAL '40 minutes') + ((i % 10) * INTERVAL '2 hours') AS updated_at
FROM generate_series(2, 2000) AS s(i)
ON CONFLICT (id) DO NOTHING;

-- ----------------------------------------------------------------------------
-- 2. Deterministic Accounts
-- ----------------------------------------------------------------------------
-- Primary benchmark user credential account
INSERT INTO accounts (
    id, user_id, provider_id, account_id, password, scope, created_at, updated_at
) VALUES (
    'acc_seed_000001',
    'usr_seed_000001',
    'credential',
    'acc_shivam_credential',
    '$2a$10$wT0o3q6VzXgY8YwLq1zR6uR9Fj0L4kE6N9Q3j8H5W2k8P1L4M7N2e',
    'email,profile',
    TIMESTAMPTZ '2026-09-01 10:00:00+05:30',
    TIMESTAMPTZ '2026-09-01 10:00:00+05:30'
) ON CONFLICT (provider_id, account_id) DO NOTHING;

-- Temporary delete account
INSERT INTO accounts (
    id, user_id, provider_id, account_id, password, created_at, updated_at
) VALUES (
    'acc_seed_temp_delete',
    'usr_seed_temp_delete',
    'credential',
    'acc_temp_delete',
    '$2a$10$wT0o3q6VzXgY8YwLq1zR6uR9Fj0L4kE6N9Q3j8H5W2k8P1L4M7N2e',
    TIMESTAMPTZ '2026-11-01 08:00:00+05:30',
    TIMESTAMPTZ '2026-11-01 08:00:00+05:30'
) ON CONFLICT (provider_id, account_id) DO NOTHING;

-- Bulk accounts linked to synthetic users
INSERT INTO accounts (
    id, user_id, provider_id, account_id, access_token, refresh_token, password, scope, created_at, updated_at
)
SELECT
    'acc_seed_' || LPAD(i::text, 6, '0') AS id,
    'usr_seed_' || LPAD(i::text, 6, '0') AS user_id,
    CASE (i % 4)
        WHEN 0 THEN 'credential'
        WHEN 1 THEN 'google'
        WHEN 2 THEN 'github'
        ELSE 'discord'
    END AS provider_id,
    'oauth_acc_' || i AS account_id,
    'access_token_mock_' || md5(i::text) AS access_token,
    'refresh_token_mock_' || md5((i * 7)::text) AS refresh_token,
    CASE WHEN (i % 4) = 0 THEN '$2a$10$mockPasswordHashedForSeed1234567890' ELSE NULL END AS password,
    'email,profile' AS scope,
    TIMESTAMPTZ '2026-08-01 00:00:00+05:30' + (i * INTERVAL '40 minutes') AS created_at,
    TIMESTAMPTZ '2026-08-01 00:00:00+05:30' + (i * INTERVAL '40 minutes') AS updated_at
FROM generate_series(2, 2000) AS s(i)
ON CONFLICT (provider_id, account_id) DO NOTHING;

-- ----------------------------------------------------------------------------
-- 3. Deterministic Sessions
-- ----------------------------------------------------------------------------
-- Primary benchmark user active session
INSERT INTO sessions (
    id, user_id, token, expires_at, ip_address, user_agent, created_at, updated_at
) VALUES (
    'sess_seed_000001',
    'usr_seed_000001',
    'sess_token_seed_000001',
    TIMESTAMPTZ '2027-01-01 00:00:00+05:30',
    '192.168.1.10',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)',
    TIMESTAMPTZ '2026-11-01 10:00:00+05:30',
    TIMESTAMPTZ '2026-11-23 20:00:00+05:30'
) ON CONFLICT (token) DO NOTHING;

-- Bulk sessions (3,000 sessions)
INSERT INTO sessions (
    id, user_id, token, expires_at, ip_address, user_agent, created_at, updated_at
)
SELECT
    'sess_seed_' || LPAD(i::text, 6, '0') AS id,
    'usr_seed_' || LPAD(((i % 2000) + 1)::text, 6, '0') AS user_id,
    'sess_token_seed_' || LPAD(i::text, 6, '0') AS token,
    CASE 
        WHEN i % 5 = 0 THEN TIMESTAMPTZ '2026-10-01 00:00:00+05:30' -- Expired session
        ELSE TIMESTAMPTZ '2027-01-01 00:00:00+05:30' + (i * INTERVAL '10 minutes') -- Active session
    END AS expires_at,
    '10.0.' || ((i / 256) % 256) || '.' || (i % 256) AS ip_address,
    CASE (i % 3)
        WHEN 0 THEN 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) Chrome/120.0'
        WHEN 1 THEN 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Edge/120.0'
        ELSE 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15'
    END AS user_agent,
    TIMESTAMPTZ '2026-08-01 00:00:00+05:30' + (i * INTERVAL '25 minutes') AS created_at,
    TIMESTAMPTZ '2026-08-01 00:00:00+05:30' + (i * INTERVAL '25 minutes') AS updated_at
FROM generate_series(2, 3000) AS s(i)
ON CONFLICT (token) DO NOTHING;

-- ----------------------------------------------------------------------------
-- 4. Deterministic Verifications
-- ----------------------------------------------------------------------------
INSERT INTO verifications (
    id, identifier, value, expires_at, created_at, updated_at
) VALUES (
    'verif_seed_000001',
    'shivam.choubey@example.com',
    '984321',
    TIMESTAMPTZ '2027-01-01 00:00:00+05:30',
    TIMESTAMPTZ '2026-11-23 20:00:00+05:30',
    TIMESTAMPTZ '2026-11-23 20:00:00+05:30'
) ON CONFLICT (identifier, value) DO NOTHING;

INSERT INTO verifications (
    id, identifier, value, expires_at, created_at, updated_at
) VALUES (
    'verif_seed_temp_delete',
    'temp.delete@example.com',
    '112233',
    TIMESTAMPTZ '2027-01-01 00:00:00+05:30',
    TIMESTAMPTZ '2026-11-23 20:00:00+05:30',
    TIMESTAMPTZ '2026-11-23 20:00:00+05:30'
) ON CONFLICT (identifier, value) DO NOTHING;

INSERT INTO verifications (
    id, identifier, value, expires_at, created_at, updated_at
)
SELECT
    'verif_seed_' || LPAD(i::text, 6, '0') AS id,
    'user_' || i || '@example.com' AS identifier,
    LPAD(((i * 7919) % 1000000)::text, 6, '0') AS value,
    TIMESTAMPTZ '2026-12-01 00:00:00+05:30' + (i * INTERVAL '1 hour') AS expires_at,
    TIMESTAMPTZ '2026-09-01 00:00:00+05:30' + (i * INTERVAL '1 hour') AS created_at,
    TIMESTAMPTZ '2026-09-01 00:00:00+05:30' + (i * INTERVAL '1 hour') AS updated_at
FROM generate_series(3, 1000) AS s(i)
ON CONFLICT (identifier, value) DO NOTHING;

-- ----------------------------------------------------------------------------
-- 5. Deterministic Subscription Plans
-- ----------------------------------------------------------------------------
INSERT INTO subscription_plans (plan_id, name, credits, amount_usd, is_active) VALUES
    ('basic', 'Basic Credit Pack', 100, 5.00, TRUE),
    ('pro', 'Pro Developer Pack', 400, 19.00, TRUE),
    ('enterprise', 'Enterprise Team Pack', 1000, 49.00, TRUE)
ON CONFLICT (plan_id) DO NOTHING;

-- ----------------------------------------------------------------------------
-- 6. Deterministic Billing Ledger Transactions (10,000 rows)
-- ----------------------------------------------------------------------------
-- Primary benchmark user transaction
INSERT INTO transactions (
    id, user_id, plan_id, amount, credits, is_paid, stripe_session_id, created_at, updated_at
) VALUES (
    '44444444-4444-4444-4444-444444444444',
    'usr_seed_000001',
    'pro',
    19.00,
    400,
    TRUE,
    'cs_test_mock_stripe_session_000001',
    TIMESTAMPTZ '2026-11-05 14:30:00+05:30',
    TIMESTAMPTZ '2026-11-05 14:31:12+05:30'
) ON CONFLICT (id) DO NOTHING;

-- Disposable transaction for DELETE test
INSERT INTO transactions (
    id, user_id, plan_id, amount, credits, is_paid, stripe_session_id, created_at, updated_at
) VALUES (
    '66666666-6666-6666-6666-666666666666',
    'usr_seed_temp_delete',
    'basic',
    5.00,
    100,
    FALSE,
    'cs_test_mock_stripe_session_temp_delete',
    TIMESTAMPTZ '2026-11-20 10:00:00+05:30',
    TIMESTAMPTZ '2026-11-20 10:00:00+05:30'
) ON CONFLICT (id) DO NOTHING;

-- Bulk transactions
INSERT INTO transactions (
    id, user_id, plan_id, amount, credits, is_paid, stripe_session_id, created_at, updated_at
)
SELECT
    -- Deterministic UUID generated from MD5 hash
    (md5('txn_seed_' || i)::uuid) AS id,
    'usr_seed_' || LPAD(((i % 1500) + 1)::text, 6, '0') AS user_id,
    CASE (i % 3)
        WHEN 0 THEN 'basic'
        WHEN 1 THEN 'pro'
        ELSE 'enterprise'
    END AS plan_id,
    CASE (i % 3)
        WHEN 0 THEN 5.00
        WHEN 1 THEN 19.00
        ELSE 49.00
    END AS amount,
    CASE (i % 3)
        WHEN 0 THEN 100
        WHEN 1 THEN 400
        ELSE 1000
    END AS credits,
    (i % 5 != 0) AS is_paid, -- 80% paid, 20% pending/failed
    'cs_test_' || md5(('session_' || i)::text) AS stripe_session_id,
    TIMESTAMPTZ '2026-09-01 00:00:00+05:30' + (i * INTERVAL '7 minutes') AS created_at,
    TIMESTAMPTZ '2026-09-01 00:00:00+05:30' + (i * INTERVAL '7 minutes') + INTERVAL '45 seconds' AS updated_at
FROM generate_series(1, 10000) AS s(i)
ON CONFLICT (id) DO NOTHING;

-- ----------------------------------------------------------------------------
-- 7. Deterministic Website Projects (5,000 rows)
-- ----------------------------------------------------------------------------
-- Primary benchmark user project
INSERT INTO website_projects (
    id, user_id, name, initial_prompt, current_code, is_published, created_at, updated_at
) VALUES (
    '11111111-1111-1111-1111-111111111111',
    'usr_seed_000001',
    'E-Commerce AI Storefront',
    'Build a sleek modern e-commerce storefront for minimalist mechanical keyboards',
    '<!DOCTYPE html><html><head><title>Keyboard Store</title></head><body><h1>Mechanical Keyboards</h1></body></html>',
    TRUE,
    TIMESTAMPTZ '2026-10-10 11:00:00+05:30',
    TIMESTAMPTZ '2026-11-22 17:45:00+05:30'
) ON CONFLICT (id) DO UPDATE SET updated_at = EXCLUDED.updated_at;

-- Disposable project for DELETE query test
INSERT INTO website_projects (
    id, user_id, name, initial_prompt, current_code, is_published, created_at, updated_at
) VALUES (
    '55555555-5555-5555-5555-555555555555',
    'usr_seed_000001',
    'Temp Disposable Project',
    'Draft ephemeral website to test cascade deletion',
    '<!DOCTYPE html><html><body>Draft</body></html>',
    FALSE,
    TIMESTAMPTZ '2026-11-21 09:00:00+05:30',
    TIMESTAMPTZ '2026-11-21 09:00:00+05:30'
) ON CONFLICT (id) DO NOTHING;

-- Bulk projects (5,000 projects across users)
INSERT INTO website_projects (
    id, user_id, name, initial_prompt, current_code, is_published, created_at, updated_at
)
SELECT
    (md5('proj_seed_' || i)::uuid) AS id,
    'usr_seed_' || LPAD(((i % 1800) + 1)::text, 6, '0') AS user_id,
    CASE (i % 6)
        WHEN 0 THEN 'SaaS Portfolio ' || i
        WHEN 1 THEN 'E-Commerce Boutique ' || i
        WHEN 2 THEN 'AI Analytics Landing ' || i
        WHEN 3 THEN 'Creative Agency Showcase ' || i
        WHEN 4 THEN 'Personal Blog & Newsletter ' || i
        ELSE 'Decentralized App Portal ' || i
    END AS name,
    'Generate a responsive web layout featuring modern typography, grid hero section, dynamic testimonials, and integrated pricing cards for project #' || i AS initial_prompt,
    '<!DOCTYPE html><html lang="en"><head><title>Project ' || i || '</title><style>body{font-family:sans-serif;margin:0;padding:2rem;background:#f8fafc;color:#0f172a}header{display:flex;justify-content:space-between;align-items:center}.hero{margin-top:3rem;text-align:center}.btn{background:#3b82f6;color:#fff;padding:0.75rem 1.5rem;border-radius:0.5rem;text-decoration:none}</style></head><body><header><h2>Project #' || i || '</h2><nav><a href="#about">About</a> | <a href="#pricing">Pricing</a></nav></header><div class="hero"><h1>Future of Web Creation</h1><p>Crafted seamlessly with AI Web Builder generative engine.</p><a class="btn" href="#">Get Started</a></div></body></html>' AS current_code,
    (i % 3 = 0) AS is_published, -- 33% published to community feed
    TIMESTAMPTZ '2026-08-15 00:00:00+05:30' + (i * INTERVAL '28 minutes') AS created_at,
    TIMESTAMPTZ '2026-08-15 00:00:00+05:30' + (i * INTERVAL '28 minutes') + ((i % 8) * INTERVAL '3 hours') AS updated_at
FROM generate_series(1, 5000) AS s(i)
ON CONFLICT (id) DO NOTHING;

-- ----------------------------------------------------------------------------
-- 8. Deterministic Versions (Code Snapshots) (20,000 rows)
-- ----------------------------------------------------------------------------
-- Benchmark primary project version snapshots
INSERT INTO versions (
    id, project_id, code, description, timestamp
) VALUES (
    '22222222-2222-2222-2222-222222222222',
    '11111111-1111-1111-1111-111111111111',
    '<!DOCTYPE html><html><head><title>Keyboard Store v1</title></head><body><h1>Mechanical Keyboards</h1><p>Initial release</p></body></html>',
    'Initial generation from prompt',
    TIMESTAMPTZ '2026-10-10 11:05:00+05:30'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO versions (
    id, project_id, code, description, timestamp
) VALUES (
    '33333333-3333-3333-3333-333333333333',
    '11111111-1111-1111-1111-111111111111',
    '<!DOCTYPE html><html><head><title>Keyboard Store v2 Dark</title></head><body class="dark"><h1>Mechanical Keyboards</h1><button id="cart">Cart</button></body></html>',
    'Add dark mode theme and floating cart button',
    TIMESTAMPTZ '2026-11-22 17:45:00+05:30'
) ON CONFLICT (id) DO NOTHING;

-- Link active version on benchmark project
UPDATE website_projects
SET current_version_id = '33333333-3333-3333-3333-333333333333'
WHERE id = '11111111-1111-1111-1111-111111111111';

-- Bulk versions (4 versions per project for 5,000 projects = 20,000 versions)
INSERT INTO versions (
    id, project_id, code, description, timestamp
)
SELECT
    (md5('ver_seed_' || p_id || '_' || v_idx)::uuid) AS id,
    (md5('proj_seed_' || p_id)::uuid) AS project_id,
    '<!DOCTYPE html><html><head><title>Snapshot v' || v_idx || '</title></head><body><h1>Version ' || v_idx || ' Code</h1><p>Checksum: ' || md5((p_id * 100 + v_idx)::text) || '</p></body></html>' AS code,
    CASE v_idx
        WHEN 1 THEN 'Initial generation'
        WHEN 2 THEN 'Refined color scheme and button alignment'
        WHEN 3 THEN 'Mobile responsive hamburger menu'
        ELSE 'Final production ready snapshot'
    END AS description,
    TIMESTAMPTZ '2026-08-15 00:00:00+05:30' + (p_id * INTERVAL '28 minutes') + (v_idx * INTERVAL '45 minutes') AS timestamp
FROM generate_series(1, 5000) AS p(p_id)
CROSS JOIN generate_series(1, 4) AS v(v_idx)
ON CONFLICT (id) DO NOTHING;

-- Point each project's current_version_id to its 4th (latest) version
UPDATE website_projects p
SET current_version_id = (md5('ver_seed_' || s.p_id || '_4')::uuid)
FROM (
    SELECT generate_series(1, 5000) AS p_id
) s
WHERE p.id = (md5('proj_seed_' || s.p_id)::uuid);

-- ----------------------------------------------------------------------------
-- 9. Deterministic Conversations (Dialogue Messages) (40,000 rows)
-- ----------------------------------------------------------------------------
-- Benchmark project dialogue messages
INSERT INTO conversations (
    id, project_id, role, content, timestamp
) VALUES 
(
    '77777777-1111-1111-1111-111111111111',
    '11111111-1111-1111-1111-111111111111',
    'user',
    'Build a sleek modern e-commerce storefront for minimalist mechanical keyboards',
    TIMESTAMPTZ '2026-10-10 11:00:00+05:30'
),
(
    '77777777-2222-2222-2222-222222222222',
    '11111111-1111-1111-1111-111111111111',
    'assistant',
    'Understood! Crafting an e-commerce storefront with tactile layout, high-contrast typography, product grid, and responsive cart interaction.',
    TIMESTAMPTZ '2026-10-10 11:00:15+05:30'
),
(
    '77777777-3333-3333-3333-333333333333',
    '11111111-1111-1111-1111-111111111111',
    'user',
    'Add dark mode toggle and cart floating button',
    TIMESTAMPTZ '2026-11-22 17:44:00+05:30'
),
(
    '77777777-4444-4444-4444-444444444444',
    '11111111-1111-1111-1111-111111111111',
    'assistant',
    'Updated styling with CSS variables for dark theme and added floating action button for checkout cart.',
    TIMESTAMPTZ '2026-11-22 17:45:00+05:30'
)
ON CONFLICT (id) DO NOTHING;

-- Bulk conversations (8 messages per project for 5,000 projects = 40,000 messages)
INSERT INTO conversations (
    id, project_id, role, content, timestamp
)
SELECT
    (md5('conv_seed_' || p_id || '_' || m_idx)::uuid) AS id,
    (md5('proj_seed_' || p_id)::uuid) AS project_id,
    CASE WHEN m_idx % 2 = 1 THEN 'user'::role_enum ELSE 'assistant'::role_enum END AS role,
    CASE 
        WHEN m_idx = 1 THEN 'Generate initial website from prompt for project #' || p_id
        WHEN m_idx = 2 THEN 'Analyzed prompt: scaffolding HTML5 skeleton, CSS3 flexbox grid, and interactive JS components.'
        WHEN m_idx = 3 THEN 'Can you make the header sticky with glassmorphism blur effect?'
        WHEN m_idx = 4 THEN 'Applied sticky positioning with backdrop-filter: blur(12px) and subtle border styling.'
        WHEN m_idx = 5 THEN 'Now add a pricing matrix comparing Basic, Pro, and Enterprise tiers.'
        WHEN m_idx = 6 THEN 'Engineered three-tier pricing cards with hover scale effects and clear call-to-actions.'
        WHEN m_idx = 7 THEN 'Ensure full mobile responsiveness and touch-friendly padding.'
        ELSE 'Optimized responsive media queries for 320px to 1440px displays. Project ready for deployment!'
    END AS content,
    TIMESTAMPTZ '2026-08-15 00:00:00+05:30' + (p_id * INTERVAL '28 minutes') + (m_idx * INTERVAL '15 minutes') AS timestamp
FROM generate_series(1, 5000) AS p(p_id)
CROSS JOIN generate_series(1, 8) AS m(m_idx)
ON CONFLICT (id) DO NOTHING;

COMMIT;

-- Analyze all tables to populate query planner statistics
ANALYZE users;
ANALYZE accounts;
ANALYZE sessions;
ANALYZE verifications;
ANALYZE subscription_plans;
ANALYZE transactions;
ANALYZE website_projects;
ANALYZE versions;
ANALYZE conversations;
