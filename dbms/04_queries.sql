-- ============================================================================
-- Database Application Queries: AI Web Builder
-- Course: Advanced Programming / Database Management Systems
-- Team: AI_Web_Builder (Team No.: T0080)
-- Mentor: Satyaki Sir
-- Target DBMS: PostgreSQL 14+
-- Checkpoint: Application SQL Queries & Workload Execution
-- Reference Application: https://github.com/shivamchoubey2007/AI-Web-Builder
-- ============================================================================
-- This script contains all SQL queries executed by the AI Web Builder
-- application backend across all controllers, middleware, and authentication
-- handlers. Queries are structured by functional module, utilize relational JOINs
-- where possible to optimize data retrieval across normalized relations, and are
-- explicitly annotated as either:
--   -- READ   (for SELECT operations, projections, and analytical aggregations)
--   -- WRITE  (for INSERT, UPDATE, and DELETE data manipulation operations)
-- ============================================================================

-- ============================================================================
-- Default Parameter Bindings for Interactive & Automated psql Execution
-- ============================================================================
\set ON_ERROR_STOP on

-- User and Auth Bindings
\set email 'shivam.choubey@example.com'
\set user_id 'usr_seed_000001'
\set name 'Shivam Choubey'
\set image 'https://avatars.githubusercontent.com/u/10001'
\set account_id 'acc_seed_000001'
\set provider_id 'credential'
\set provider_account_id 'acc_shivam_credential'
\set password_hash '$2a$10$wT0o3q6VzXgY8YwLq1zR6uR9Fj0L4kE6N9Q3j8H5W2k8P1L4M7N2e'
\set access_token 'mock_access_token_demo_xyz'
\set refresh_token 'mock_refresh_token_demo_xyz'
\set id_token 'mock_id_token_demo_xyz'
\set access_token_expires_at '2027-01-01 00:00:00+05:30'
\set refresh_token_expires_at '2027-06-01 00:00:00+05:30'
\set scope 'email,profile'

-- Session Bindings
\set session_id 'sess_seed_000001'
\set token 'sess_token_seed_000001'
\set expires_at '2027-01-01 00:00:00+05:30'
\set new_expires_at '2027-02-01 00:00:00+05:30'
\set ip_address '192.168.1.10'
\set user_agent 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)'

-- Verification Bindings
\set verification_id 'verif_seed_000001'
\set identifier 'shivam.choubey@example.com'
\set value '984321'
\set token_value '984321'

-- Project & Version Bindings
\set project_id '11111111-1111-1111-1111-111111111111'
\set project_name 'E-Commerce AI Storefront'
\set initial_prompt 'Build a sleek modern e-commerce storefront for minimalist mechanical keyboards'
\set generated_code '<!DOCTYPE html><html><head><title>Keyboard Store</title></head><body><h1>Mechanical Keyboards</h1></body></html>'
\set enhanced_prompt_msg 'Analyzed prompt: scaffolding HTML5 skeleton, CSS3 flexbox grid, and interactive JS components.'
\set version_id '22222222-2222-2222-2222-222222222222'
\set new_version_id '33333333-3333-3333-3333-333333333333'
\set revision_message 'Add dark mode toggle and cart floating button'
\set enhanced_revision_prompt 'Refactor UI styling with CSS variables for dark theme and append floating action button for cart'
\set revised_code '<!DOCTYPE html><html><head><title>Keyboard Store Dark</title></head><body class="dark"><h1>Mechanical Keyboards</h1><button id="cart">Cart</button></body></html>'
\set rollback_code '<!DOCTYPE html><html><head><title>Keyboard Store v1</title></head><body><h1>Mechanical Keyboards</h1></body></html>'
\set custom_code '<!DOCTYPE html><html><head><title>Custom Store</title></head><body><h1>Customized Store</h1></body></html>'

-- Billing & Plan Bindings
\set plan_id 'pro'
\set amount 19.00
\set credits 400
\set credits_purchased 400
\set transaction_id '44444444-4444-4444-4444-444444444444'
\set stripe_session_id 'cs_test_mock_stripe_session_000001'

-- Dedicated Disposable Targets for Safe Idempotent DELETE Queries
\set temp_user_id 'usr_seed_temp_delete'
\set temp_project_id '55555555-5555-5555-5555-555555555555'
\set temp_verification_id 'verif_seed_temp_delete'
\set temp_transaction_id '66666666-6666-6666-6666-666666666666'
-- ============================================================================


-- ############################################################################
-- SECTION 1: AUTHENTICATION, IDENTITY & SESSION MANAGEMENT
-- (Better-Auth Library & Auth Middleware)
-- ############################################################################

-- ----------------------------------------------------------------------------
-- 1.1 Find User by Email (Sign-in / Credential verification)
-- Endpoint / Context: POST /api/auth/sign-in/email
-- Description: Retrieves user profile details and password hash using a JOIN
--              with accounts to verify login credentials.
-- ----------------------------------------------------------------------------
-- READ
SELECT 
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
WHERE u.email = :'email' 
  AND a.provider_id = 'credential'
LIMIT 1;

-- ----------------------------------------------------------------------------

-- 1.2 Create New User (Sign-up registration)
-- Endpoint / Context: POST /api/auth/sign-up/email
-- Description: Registers a new user with default 20 free starter credits.
-- ----------------------------------------------------------------------------
-- WRITE
INSERT INTO users (
    id,
    email,
    name,
    image,
    total_creation,
    credits,
    email_verified,
    created_at,
    updated_at
) VALUES (
    :'user_id',
    :'email',
    :'name',
    :'image',
    0,
    20,
    FALSE,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
)
ON CONFLICT (id) DO UPDATE SET updated_at = CURRENT_TIMESTAMP;

-- ----------------------------------------------------------------------------

-- 1.3 Create Account Link (Credential or OAuth account linkage)
-- Endpoint / Context: POST /api/auth/sign-up/email or OAuth callback
-- Description: Stores provider identity, tokens, and password hash for a user.
-- ----------------------------------------------------------------------------
-- WRITE
INSERT INTO accounts (
    id,
    user_id,
    provider_id,
    account_id,
    access_token,
    refresh_token,
    id_token,
    access_token_expires_at,
    refresh_token_expires_at,
    scope,
    password,
    created_at,
    updated_at
) VALUES (
    :'account_id',
    :'user_id',
    :'provider_id',
    :'provider_account_id',
    :'access_token',
    :'refresh_token',
    :'id_token',
    :'access_token_expires_at',
    :'refresh_token_expires_at',
    :'scope',
    :'password_hash',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
)
ON CONFLICT (provider_id, account_id) DO NOTHING;

-- ----------------------------------------------------------------------------

-- 1.4 Create Authentication Session (Login session issue)
-- Endpoint / Context: Better-Auth Session Creation
-- Description: Generates a persistent active session token linked to the user.
-- ----------------------------------------------------------------------------
-- WRITE
INSERT INTO sessions (
    id,
    user_id,
    token,
    expires_at,
    ip_address,
    user_agent,
    created_at,
    updated_at
) VALUES (
    :'session_id',
    :'user_id',
    :'token',
    :'expires_at',
    :'ip_address',
    :'user_agent',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
)
ON CONFLICT (token) DO NOTHING;

-- ----------------------------------------------------------------------------

-- 1.5 Validate Session and Authenticate Request (Auth Middleware)
-- Endpoint / Context: Middleware protect() across all protected API routes
-- Description: Verifies session cookie token, ensures it is unexpired, and
--              joins with users table to fetch the authenticated user's state.
-- ----------------------------------------------------------------------------
-- READ
SELECT 
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
WHERE s.token = :'token'
  AND s.expires_at > CURRENT_TIMESTAMP
LIMIT 1;

-- ----------------------------------------------------------------------------

-- 1.6 Refresh / Touch Session Expiry
-- Endpoint / Context: Session keep-alive on user activity
-- Description: Updates session expiration timestamp to maintain active state.
-- ----------------------------------------------------------------------------
-- WRITE
UPDATE sessions
SET 
    expires_at = :'new_expires_at',
    updated_at = CURRENT_TIMESTAMP
WHERE token = :'token';

-- ----------------------------------------------------------------------------

-- 1.7 Terminate Session (Sign-out / Logout)
-- Endpoint / Context: POST /api/auth/sign-out
-- Description: Invalidates and deletes session by token.
-- ----------------------------------------------------------------------------
-- WRITE
DELETE FROM sessions
WHERE token = :'token';

-- ----------------------------------------------------------------------------

-- 1.8 Create Verification Challenge (Email verification / Password reset)
-- Endpoint / Context: Email verification challenge dispatch
-- Description: Stores one-time token challenge with expiry.
-- ----------------------------------------------------------------------------
-- WRITE
INSERT INTO verifications (
    id,
    identifier,
    value,
    expires_at,
    created_at,
    updated_at
) VALUES (
    :'verification_id',
    :'identifier',
    :'value',
    :'expires_at',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
)
ON CONFLICT (identifier, value) DO NOTHING;

-- ----------------------------------------------------------------------------

-- 1.9 Validate Verification Challenge
-- Endpoint / Context: GET /api/auth/verify-email
-- Description: Retrieves active verification record matching identifier & token.
-- ----------------------------------------------------------------------------
-- READ
SELECT 
    id,
    identifier,
    value,
    expires_at
FROM verifications
WHERE identifier = :'identifier'
  AND value = :'token_value'
  AND expires_at > CURRENT_TIMESTAMP;

-- ----------------------------------------------------------------------------

-- 1.10 Mark User Email as Verified
-- Endpoint / Context: Successful email verification callback
-- Description: Sets email_verified flag to TRUE for the user.
-- ----------------------------------------------------------------------------
-- WRITE
UPDATE users
SET 
    email_verified = TRUE,
    updated_at = CURRENT_TIMESTAMP
WHERE email = :'identifier';

-- ----------------------------------------------------------------------------

-- 1.11 Delete Used Verification Record
-- Endpoint / Context: Cleanup after successful verification
-- Description: Removes token record to prevent replay attacks.
-- ----------------------------------------------------------------------------
-- WRITE
DELETE FROM verifications
WHERE id = :'temp_verification_id';

-- ----------------------------------------------------------------------------

-- 1.12 Delete User Account (Account Deletion with Cascade)
-- Endpoint / Context: DELETE /api/auth/delete-user
-- Description: Cascadingly deletes user, triggering ON DELETE CASCADE across
--              sessions, accounts, projects, versions, and conversations.
-- ----------------------------------------------------------------------------
-- WRITE
DELETE FROM users
WHERE id = :'temp_user_id';


-- ############################################################################
-- SECTION 2: USER PROFILE & CREDIT MANAGEMENT
-- (Controllers: userController.ts)
-- ############################################################################

-- ----------------------------------------------------------------------------

-- 2.1 Get Current User Credits & Generation Metrics
-- Endpoint / Context: GET /api/user/credits
-- Description: Retrieves remaining AI credits balance and total generation count.
-- ----------------------------------------------------------------------------
-- READ
SELECT 
    id AS user_id,
    name,
    email,
    credits,
    total_creation
FROM users
WHERE id = :'user_id';

-- ----------------------------------------------------------------------------

-- 2.2 Deduct Credits for AI Generation / Revision
-- Endpoint / Context: POST /api/user/project or POST /api/project/revision/:projectId
-- Description: Decrements 5 credits atomically, enforcing non-negative balance.
-- ----------------------------------------------------------------------------
-- WRITE
UPDATE users
SET 
    credits = credits - 5,
    updated_at = CURRENT_TIMESTAMP
WHERE id = :'user_id'
  AND credits >= 5;

-- ----------------------------------------------------------------------------

-- 2.3 Increment Total Creation Counter
-- Endpoint / Context: POST /api/user/project
-- Description: Increments the lifetime counter of generated projects for the user.
-- ----------------------------------------------------------------------------
-- WRITE
UPDATE users
SET 
    total_creation = total_creation + 1,
    updated_at = CURRENT_TIMESTAMP
WHERE id = :'user_id';

-- ----------------------------------------------------------------------------

-- 2.4 Refund Credits on AI Failure
-- Endpoint / Context: Catch block in project creation or revision failure
-- Description: Restores 5 credits to user if external AI model fails to output code.
-- ----------------------------------------------------------------------------
-- WRITE
UPDATE users
SET 
    credits = credits + 5,
    updated_at = CURRENT_TIMESTAMP
WHERE id = :'user_id';


-- ############################################################################
-- SECTION 3: PROJECT CREATION & INITIAL WEBSITE GENERATION
-- (Controllers: userController.ts -> createUserProject)
-- ############################################################################

-- ----------------------------------------------------------------------------

-- 3.1 Check User Eligibility & Credit Balance
-- Endpoint / Context: POST /api/user/project (Pre-generation check)
-- Description: Ensures the requesting user exists and holds at least 5 credits.
-- ----------------------------------------------------------------------------
-- READ
SELECT 
    id AS user_id,
    credits,
    total_creation
FROM users
WHERE id = :'user_id';

-- ----------------------------------------------------------------------------

-- 3.2 Initialize Website Project Record
-- Endpoint / Context: POST /api/user/project (Step 1: Create project entry)
-- Description: Inserts initial project record linked to the user owner.
-- ----------------------------------------------------------------------------
-- WRITE
INSERT INTO website_projects (
    id,
    user_id,
    name,
    initial_prompt,
    current_code,
    current_version_id,
    is_published,
    created_at,
    updated_at
) VALUES (
    :'project_id',
    :'user_id',
    :'project_name',
    :'initial_prompt',
    NULL,
    NULL,
    FALSE,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
)
ON CONFLICT (id) DO UPDATE SET updated_at = CURRENT_TIMESTAMP
RETURNING id, name, created_at;

-- ----------------------------------------------------------------------------

-- 3.3 Log User Initial Prompt in Conversations
-- Endpoint / Context: POST /api/user/project (Step 2: Log prompt)
-- Description: Inserts user's natural language prompt into dialogue history.
-- ----------------------------------------------------------------------------
-- WRITE
INSERT INTO conversations (
    id,
    project_id,
    role,
    content,
    timestamp
) VALUES (
    gen_random_uuid(),
    :'project_id',
    'user',
    :'initial_prompt',
    CURRENT_TIMESTAMP
)
ON CONFLICT (id) DO NOTHING;

-- ----------------------------------------------------------------------------

-- 3.4 Log AI Prompt Enhancement & Status Messages
-- Endpoint / Context: POST /api/user/project (Step 3: Assistant status logs)
-- Description: Appends assistant enhancement notes and generation progress logs.
-- ----------------------------------------------------------------------------
-- WRITE
INSERT INTO conversations (
    id,
    project_id,
    role,
    content,
    timestamp
) VALUES 
    (gen_random_uuid(), :'project_id', 'assistant', :'enhanced_prompt_msg', CURRENT_TIMESTAMP),
    (gen_random_uuid(), :'project_id', 'assistant', 'now generating your website...', CURRENT_TIMESTAMP)
ON CONFLICT (id) DO NOTHING;

-- ----------------------------------------------------------------------------

-- 3.5 Create Initial Code Version Snapshot
-- Endpoint / Context: POST /api/user/project (Step 4: Save generated code version)
-- Description: Creates the first immutable code checkpoint in versions table.
-- ----------------------------------------------------------------------------
-- WRITE
INSERT INTO versions (
    id,
    project_id,
    code,
    description,
    timestamp
) VALUES (
    :'version_id',
    :'project_id',
    :'generated_code',
    'Initial version',
    CURRENT_TIMESTAMP
)
ON CONFLICT (id) DO UPDATE SET timestamp = CURRENT_TIMESTAMP
RETURNING id, timestamp;

-- ----------------------------------------------------------------------------

-- 3.6 Log Generation Completion Dialogue
-- Endpoint / Context: POST /api/user/project (Step 5: Completion message)
-- Description: Appends completion assistant message to conversation log.
-- ----------------------------------------------------------------------------
-- WRITE
INSERT INTO conversations (
    id,
    project_id,
    role,
    content,
    timestamp
) VALUES (
    gen_random_uuid(),
    :'project_id',
    'assistant',
    'I have created your website. You can now preview it and request any changes.',
    CURRENT_TIMESTAMP
)
ON CONFLICT (id) DO NOTHING;

-- ----------------------------------------------------------------------------

-- 3.7 Update Website Project with Generated Code & Active Version
-- Endpoint / Context: POST /api/user/project (Step 6: Update active project state)
-- Description: Sets current_code and current_version_id foreign key pointer.
-- ----------------------------------------------------------------------------
-- WRITE
UPDATE website_projects
SET 
    current_code = :'generated_code',
    current_version_id = :'version_id',
    updated_at = CURRENT_TIMESTAMP
WHERE id = :'project_id'
  AND user_id = :'user_id';


-- ############################################################################
-- SECTION 4: PROJECT REVISIONS, PROMPT ITERATIONS & ROLLBACK
-- (Controllers: projectController.ts)
-- ############################################################################

-- ----------------------------------------------------------------------------

-- 4.1 Validate Project Ownership and Retrieve Current State
-- Endpoint / Context: POST /api/project/revision/:projectId
-- Description: Joins website_projects with users and active versions to verify
--              ownership, current code base, and user credit balance.
-- ----------------------------------------------------------------------------
-- READ
SELECT 
    p.id AS project_id,
    p.name AS project_name,
    p.current_code,
    p.current_version_id,
    u.id AS user_id,
    u.credits,
    v.description AS current_version_description
FROM website_projects p
INNER JOIN users u ON p.user_id = u.id
LEFT JOIN versions v ON p.current_version_id = v.id
WHERE p.id = :'project_id'
  AND p.user_id = :'user_id';

-- ----------------------------------------------------------------------------

-- 4.2 Append Revision Prompt to Conversation History
-- Endpoint / Context: POST /api/project/revision/:projectId
-- Description: Records the user's iterative change request.
-- ----------------------------------------------------------------------------
-- WRITE
INSERT INTO conversations (
    id,
    project_id,
    role,
    content,
    timestamp
) VALUES (
    gen_random_uuid(),
    :'project_id',
    'user',
    :'revision_message',
    CURRENT_TIMESTAMP
)
ON CONFLICT (id) DO NOTHING;

-- ----------------------------------------------------------------------------

-- 4.3 Log Assistant Revision Status Messages
-- Endpoint / Context: POST /api/project/revision/:projectId
-- Description: Records assistant prompt refinement and processing state.
-- ----------------------------------------------------------------------------
-- WRITE
INSERT INTO conversations (
    id,
    project_id,
    role,
    content,
    timestamp
) VALUES 
    (gen_random_uuid(), :'project_id', 'assistant', :'enhanced_revision_prompt', CURRENT_TIMESTAMP),
    (gen_random_uuid(), :'project_id', 'assistant', 'now making changes to your website...', CURRENT_TIMESTAMP)
ON CONFLICT (id) DO NOTHING;

-- ----------------------------------------------------------------------------

-- 4.4 Record New Revision Snapshot in Versions
-- Endpoint / Context: POST /api/project/revision/:projectId
-- Description: Stores the newly regenerated code checkpoint into versions.
-- ----------------------------------------------------------------------------
-- WRITE
INSERT INTO versions (
    id,
    project_id,
    code,
    description,
    timestamp
) VALUES (
    :'new_version_id',
    :'project_id',
    :'revised_code',
    'changes made',
    CURRENT_TIMESTAMP
)
ON CONFLICT (id) DO UPDATE SET timestamp = CURRENT_TIMESTAMP
RETURNING id, timestamp;

-- ----------------------------------------------------------------------------

-- 4.5 Update Project with Revised Code and Version Pointer
-- Endpoint / Context: POST /api/project/revision/:projectId
-- Description: Points project to the latest version and updates preview code cache.
-- ----------------------------------------------------------------------------
-- WRITE
UPDATE website_projects
SET 
    current_code = :'revised_code',
    current_version_id = :'new_version_id',
    updated_at = CURRENT_TIMESTAMP
WHERE id = :'project_id'
  AND user_id = :'user_id';

-- ----------------------------------------------------------------------------

-- 4.6 Log Revision Completion Dialogue
-- Endpoint / Context: POST /api/project/revision/:projectId
-- Description: Confirms changes have been applied.
-- ----------------------------------------------------------------------------
-- WRITE
INSERT INTO conversations (
    id,
    project_id,
    role,
    content,
    timestamp
) VALUES (
    gen_random_uuid(),
    :'project_id',
    'assistant',
    'I have made the changes to your website. You can now preview it.',
    CURRENT_TIMESTAMP
)
ON CONFLICT (id) DO NOTHING;

-- ----------------------------------------------------------------------------

-- 4.7 Rollback Verification: Fetch Target Version and Project with JOIN
-- Endpoint / Context: GET /api/project/rollback/:projectId/:versionId
-- Description: Joins website_projects with versions to verify the target version
--              belongs to this user's project before executing rollback.
-- ----------------------------------------------------------------------------
-- READ
SELECT 
    p.id AS project_id,
    p.user_id,
    p.name AS project_name,
    v.id AS rollback_version_id,
    v.code AS rollback_code,
    v.description AS rollback_description,
    v.timestamp AS rollback_timestamp
FROM website_projects p
INNER JOIN versions v ON p.id = v.project_id
WHERE p.id = :'project_id'
  AND p.user_id = :'user_id'
  AND v.id = :'version_id';

-- ----------------------------------------------------------------------------

-- 4.8 Execute Rollback: Update Project Active Version & Code
-- Endpoint / Context: GET /api/project/rollback/:projectId/:versionId
-- Description: Sets project's current_code and current_version_id to target version.
-- ----------------------------------------------------------------------------
-- WRITE
UPDATE website_projects
SET 
    current_code = :'rollback_code',
    current_version_id = :'version_id',
    updated_at = CURRENT_TIMESTAMP
WHERE id = :'project_id'
  AND user_id = :'user_id';

-- ----------------------------------------------------------------------------

-- 4.9 Log Rollback Notification in Conversations
-- Endpoint / Context: GET /api/project/rollback/:projectId/:versionId
-- Description: Informs user through chat that rollback has been completed.
-- ----------------------------------------------------------------------------
-- WRITE
INSERT INTO conversations (
    id,
    project_id,
    role,
    content,
    timestamp
) VALUES (
    gen_random_uuid(),
    :'project_id',
    'assistant',
    'I have rolled back your website to selected version. You can now preview it.',
    CURRENT_TIMESTAMP
)
ON CONFLICT (id) DO NOTHING;

-- ----------------------------------------------------------------------------

-- 4.10 Direct Code Editing: Save Manual Changes
-- Endpoint / Context: PUT /api/project/save/:projectId
-- Description: Persists manual in-browser code editor changes into the project.
--              Resets current_version_id to NULL to indicate custom unversioned edit.
-- ----------------------------------------------------------------------------
-- WRITE
UPDATE website_projects
SET 
    current_code = :'custom_code',
    current_version_id = NULL,
    updated_at = CURRENT_TIMESTAMP
WHERE id = :'project_id'
  AND user_id = :'user_id';

-- ----------------------------------------------------------------------------

-- 4.11 Delete Project
-- Endpoint / Context: DELETE /api/project/:projectId
-- Description: Deletes project; cascades automatically to versions and conversations.
-- ----------------------------------------------------------------------------
-- WRITE
DELETE FROM website_projects
WHERE id = :'temp_project_id'
  AND user_id = :'user_id';


-- ############################################################################
-- SECTION 5: PROJECT INSPECTION, PREVIEW & CONVERSATION RETRIEVAL
-- (Controllers: userController.ts & projectController.ts)
-- ############################################################################

-- ----------------------------------------------------------------------------

-- 5.1 Get Single Project with Active Version and Owner Profile
-- Endpoint / Context: GET /api/user/project/:projectId
-- Description: Retrieves detailed project metadata joined with the owner profile
--              and current active version information.
-- ----------------------------------------------------------------------------
-- READ
SELECT 
    p.id AS project_id,
    p.name AS project_name,
    p.initial_prompt,
    p.current_code,
    p.current_version_id,
    p.is_published,
    p.created_at AS project_created_at,
    p.updated_at AS project_updated_at,
    u.id AS owner_id,
    u.name AS owner_name,
    u.email AS owner_email,
    v.description AS current_version_desc,
    v.timestamp AS current_version_timestamp
FROM website_projects p
INNER JOIN users u ON p.user_id = u.id
LEFT JOIN versions v ON p.current_version_id = v.id
WHERE p.id = :'project_id'
  AND p.user_id = :'user_id';

-- ----------------------------------------------------------------------------

-- 5.2 Get Chronological Project Conversation Messages with Project Context
-- Endpoint / Context: GET /api/user/project/:projectId (Dialogue stream)
-- Description: Retrieves all chat messages for a project ordered chronologically,
--              joined with website_projects to enforce authorization check.
-- ----------------------------------------------------------------------------
-- READ
SELECT 
    c.id AS message_id,
    c.project_id,
    c.role,
    c.content,
    c.timestamp,
    p.name AS project_name
FROM conversations c
INNER JOIN website_projects p ON c.project_id = p.id
WHERE c.project_id = :'project_id'
  AND p.user_id = :'user_id'
ORDER BY c.timestamp ASC;

-- ----------------------------------------------------------------------------

-- 5.3 Get Project Version History with Snapshot Details
-- Endpoint / Context: GET /api/user/project/:projectId (Version timeline)
-- Description: Retrieves all historical code versions for a project, joined
--              with website_projects to verify owner security context.
-- ----------------------------------------------------------------------------
-- READ
SELECT 
    v.id AS version_id,
    v.project_id,
    v.code,
    v.description,
    v.timestamp,
    CASE 
        WHEN p.current_version_id = v.id THEN TRUE 
        ELSE FALSE 
    END AS is_active_version
FROM versions v
INNER JOIN website_projects p ON v.project_id = p.id
WHERE v.project_id = :'project_id'
  AND p.user_id = :'user_id'
ORDER BY v.timestamp ASC;

-- ----------------------------------------------------------------------------

-- 5.4 Get All Projects for User with Summary Aggregates (Project Dashboard)
-- Endpoint / Context: GET /api/user/projects
-- Description: Lists user's projects with aggregated version count and message count
--              using LEFT JOINs and GROUP BY.
-- ----------------------------------------------------------------------------
-- READ
SELECT 
    p.id AS project_id,
    p.name AS project_name,
    p.initial_prompt,
    p.current_code,
    p.current_version_id,
    p.is_published,
    p.created_at,
    p.updated_at,
    COUNT(DISTINCT v.id) AS total_versions,
    COUNT(DISTINCT c.id) AS total_messages
FROM website_projects p
LEFT JOIN versions v ON p.id = v.project_id
LEFT JOIN conversations c ON p.id = c.project_id
WHERE p.user_id = :'user_id'
GROUP BY 
    p.id, 
    p.name, 
    p.initial_prompt, 
    p.current_code, 
    p.current_version_id, 
    p.is_published, 
    p.created_at, 
    p.updated_at
ORDER BY p.updated_at DESC;

-- ----------------------------------------------------------------------------

-- 5.5 Toggle Project Public / Private Visibility
-- Endpoint / Context: GET /api/user/publish-toggle/:projectId
-- Description: Atomically toggles is_published boolean status for project.
-- ----------------------------------------------------------------------------
-- WRITE
UPDATE website_projects
SET 
    is_published = NOT is_published,
    updated_at = CURRENT_TIMESTAMP
WHERE id = :'project_id'
  AND user_id = :'user_id'
RETURNING id, name, is_published;


-- ############################################################################
-- SECTION 6: COMMUNITY SHOWCASE & PUBLIC WEBSITE DISCOVERY
-- (Controllers: projectController.ts -> getPublishedProjects & getProjectById)
-- ############################################################################

-- ----------------------------------------------------------------------------

-- 6.1 Get All Published Community Projects (Community Feed)
-- Endpoint / Context: GET /api/project/published
-- Description: Retrieves public website gallery joined with creator profile data,
--              excluding unpublished private drafts.
-- ----------------------------------------------------------------------------
-- READ
SELECT 
    p.id AS project_id,
    p.name AS project_name,
    p.initial_prompt,
    p.current_code,
    p.current_version_id,
    p.is_published,
    p.created_at,
    p.updated_at,
    u.id AS creator_id,
    u.name AS creator_name,
    u.image AS creator_avatar
FROM website_projects p
INNER JOIN users u ON p.user_id = u.id
WHERE p.is_published = TRUE
ORDER BY p.updated_at DESC;

-- ----------------------------------------------------------------------------

-- 6.2 Get Live Published Website Code by ID (Public Live Render)
-- Endpoint / Context: GET /api/project/published/:projectId
-- Description: Joins website_projects with creator details to safely serve
--              public website HTML source code for preview iframe or CDN.
-- ----------------------------------------------------------------------------
-- READ
SELECT 
    p.id AS project_id,
    p.name AS project_name,
    p.current_code,
    p.is_published,
    u.name AS creator_name
FROM website_projects p
INNER JOIN users u ON p.user_id = u.id
WHERE p.id = :'project_id'
  AND p.is_published = TRUE
  AND p.current_code IS NOT NULL;


-- ############################################################################
-- SECTION 7: SUBSCRIPTION PLANS, CHECKOUT & STRIPE WEBHOOK BILLING
-- (Controllers: userController.ts -> purchaseCredits & webhookController.ts)
-- ############################################################################

-- ----------------------------------------------------------------------------

-- 7.1 Fetch Active Subscription Tier Details
-- Endpoint / Context: POST /api/user/purchase-credits
-- Description: Reads plan details, pricing, and credit allowance from catalog.
-- ----------------------------------------------------------------------------
-- READ
SELECT 
    plan_id,
    name AS plan_name,
    credits,
    amount_usd,
    is_active
FROM subscription_plans
WHERE plan_id = :'plan_id'
  AND is_active = TRUE;

-- ----------------------------------------------------------------------------

-- 7.2 Create Pending Purchase Transaction Record
-- Endpoint / Context: POST /api/user/purchase-credits
-- Description: Records a new pending transaction linked to user and selected plan.
-- ----------------------------------------------------------------------------
-- WRITE
INSERT INTO transactions (
    id,
    user_id,
    plan_id,
    amount,
    credits,
    is_paid,
    stripe_session_id,
    created_at,
    updated_at
) VALUES (
    gen_random_uuid(),
    :'user_id',
    :'plan_id',
    :amount,
    :credits,
    FALSE,
    NULL,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
)
ON CONFLICT (id) DO UPDATE SET updated_at = CURRENT_TIMESTAMP
RETURNING id, user_id, plan_id, amount, credits, is_paid;

-- ----------------------------------------------------------------------------

-- 7.3 Fetch Transaction for Webhook Verification with Plan & User JOIN
-- Endpoint / Context: POST /api/webhook/stripe (checkout.session.completed)
-- Description: Retrieves transaction details joined with users and subscription_plans
--              to verify settlement validity and idempotency.
-- ----------------------------------------------------------------------------
-- READ
SELECT 
    t.id AS transaction_id,
    t.user_id,
    t.plan_id,
    t.amount,
    t.credits,
    t.is_paid,
    t.stripe_session_id,
    u.email AS user_email,
    u.name AS user_name,
    sp.name AS plan_name
FROM transactions t
INNER JOIN users u ON t.user_id = u.id
INNER JOIN subscription_plans sp ON t.plan_id = sp.plan_id
WHERE t.id = :'transaction_id';

-- ----------------------------------------------------------------------------

-- 7.4 Mark Transaction as Paid & Attach Stripe Session ID
-- Endpoint / Context: POST /api/webhook/stripe (checkout.session.completed)
-- Description: Updates settlement status to TRUE, ensuring idempotent execution.
-- ----------------------------------------------------------------------------
-- WRITE
UPDATE transactions
SET 
    is_paid = TRUE,
    stripe_session_id = :'stripe_session_id',
    updated_at = CURRENT_TIMESTAMP
WHERE id = :'transaction_id'
  AND is_paid = FALSE;

-- ----------------------------------------------------------------------------

-- 7.5 Fulfill Purchased Credits to User Account
-- Endpoint / Context: POST /api/webhook/stripe (Credit fulfillment)
-- Description: Adds purchased credits balance to user account.
-- ----------------------------------------------------------------------------
-- WRITE
UPDATE users
SET 
    credits = credits + :credits_purchased,
    updated_at = CURRENT_TIMESTAMP
WHERE id = :'user_id';

-- ----------------------------------------------------------------------------

-- 7.6 Handle Expired Checkout Session
-- Endpoint / Context: POST /api/webhook/stripe (checkout.session.expired)
-- Description: Flags or updates transaction record timestamp when session expires.
-- ----------------------------------------------------------------------------
-- WRITE
UPDATE transactions
SET 
    updated_at = CURRENT_TIMESTAMP
WHERE id = :'temp_transaction_id'
  AND is_paid = FALSE;


-- ############################################################################
-- SECTION 8: ANALYTICAL, REPORTING & DASHBOARD QUERIES
-- (Advanced Multi-Table JOINs & Business Intelligence)
-- ############################################################################

-- ----------------------------------------------------------------------------

-- 8.1 User Billing & Invoicing History (Transactions joined with Plans)
-- Context: User Settings / Billing history page
-- Description: Lists user's past purchases joined with subscription plan catalog.
-- ----------------------------------------------------------------------------
-- READ
SELECT 
    t.id AS transaction_id,
    t.amount AS amount_paid_usd,
    t.credits AS credits_awarded,
    t.is_paid,
    t.stripe_session_id,
    t.created_at AS purchase_date,
    sp.plan_id,
    sp.name AS plan_name
FROM transactions t
INNER JOIN subscription_plans sp ON t.plan_id = sp.plan_id
WHERE t.user_id = :'user_id'
ORDER BY t.created_at DESC;

-- ----------------------------------------------------------------------------

-- 8.2 User Account Complete Profile & Metrics Overview
-- Context: User Profile Dashboard
-- Description: Aggregates project counts, published counts, and total monetary
--              investment by joining users, website_projects, and transactions.
-- ----------------------------------------------------------------------------
-- READ
SELECT 
    u.id AS user_id,
    u.name,
    u.email,
    u.image,
    u.credits AS current_credit_balance,
    u.total_creation AS lifetime_generations_triggered,
    u.created_at AS member_since,
    COUNT(DISTINCT p.id) AS total_projects_owned,
    COUNT(DISTINCT CASE WHEN p.is_published THEN p.id END) AS published_projects_count,
    COALESCE(SUM(t.amount) FILTER (WHERE t.is_paid = TRUE), 0.00) AS total_spent_usd
FROM users u
LEFT JOIN website_projects p ON u.id = p.user_id
LEFT JOIN transactions t ON u.id = t.user_id
WHERE u.id = :'user_id'
GROUP BY 
    u.id, 
    u.name, 
    u.email, 
    u.image, 
    u.credits, 
    u.total_creation, 
    u.created_at;

-- ----------------------------------------------------------------------------

-- 8.3 Top Community Creators Leaderboard
-- Context: Community Showcase Leaderboard / Trending Creators
-- Description: Multi-table JOIN and aggregate ranking top users by published
--              projects and recent activity.
-- ----------------------------------------------------------------------------
-- READ
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
ORDER BY 
    published_website_count DESC, 
    latest_website_update DESC
LIMIT 10;

-- ----------------------------------------------------------------------------

-- 8.4 Full Project Evolution & Audit Tree
-- Context: Project Version Inspection / Audit Trail
-- Description: Complete chronological audit trail of all versions, owner details,
--              and current active pointer flags.
-- ----------------------------------------------------------------------------
-- READ
SELECT 
    p.id AS project_id,
    p.name AS project_name,
    u.name AS owner_name,
    u.email AS owner_email,
    v.id AS version_id,
    v.description AS version_description,
    v.timestamp AS version_created_at,
    CASE 
        WHEN p.current_version_id = v.id THEN TRUE 
        ELSE FALSE 
    END AS is_currently_active
FROM website_projects p
INNER JOIN users u ON p.user_id = u.id
INNER JOIN versions v ON p.id = v.project_id
WHERE p.id = :'project_id'
ORDER BY v.timestamp ASC;

-- ----------------------------------------------------------------------------

-- 8.5 Platform System-Wide Usage & Revenue Health Summary
-- Context: Administrator / Platform Health Monitoring
-- Description: Aggregates total platform users, projects, revenue, and active sessions.
-- ----------------------------------------------------------------------------
-- READ
SELECT 
    (SELECT COUNT(*) FROM users) AS total_users,
    (SELECT COUNT(*) FROM website_projects) AS total_projects,
    (SELECT COUNT(*) FROM website_projects WHERE is_published = TRUE) AS total_published_projects,
    (SELECT COUNT(*) FROM versions) AS total_code_versions_generated,
    (SELECT COUNT(*) FROM conversations) AS total_prompts_exchanged,
    (SELECT COALESCE(SUM(amount), 0.00) FROM transactions WHERE is_paid = TRUE) AS total_revenue_usd,
    (SELECT COUNT(*) FROM sessions WHERE expires_at > CURRENT_TIMESTAMP) AS active_valid_sessions;

-- ============================================================================
-- End of Application SQL Queries Script (dbms/04_queries.sql)
-- ============================================================================
