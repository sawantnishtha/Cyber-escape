-- CYBER ESCAPE DATABASE SCHEMA
-- Presented by CESA - Department of Computer Engineering

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. TEAMS TABLE
CREATE TABLE IF NOT EXISTS teams (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_name TEXT NOT NULL UNIQUE,
    team_key_hash TEXT NOT NULL UNIQUE,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'waiting', 'selected', 'eliminated')),
    current_round INT NOT NULL DEFAULT 1,
    connected_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. TEAM MEMBERS TABLE
CREATE TABLE IF NOT EXISTS team_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    member_name TEXT NOT NULL,
    member_identifier TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. GAME SESSION TABLE
CREATE TABLE IF NOT EXISTS game_session (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    game_name TEXT NOT NULL DEFAULT 'CYBER ESCAPE 2026',
    current_round INT NOT NULL DEFAULT 1,
    current_state TEXT NOT NULL DEFAULT 'LANDING' 
        CHECK (current_state IN (
            'LANDING',
            'R1_WAITING', 'R1_ACTIVE', 'R1_RESULT',
            'R2_WAITING', 'R2_ACTIVE', 'R2_RESULT',
            'R3_WAITING', 'R3_ACTIVE', 'R3_RESULT',
            'R4_WAITING', 'R4_ACTIVE', 'R4_RESULT',
            'FINAL_RIDDLE', 'FINAL_WAITING', 'FINAL_RESULT'
        )),
    round_timer_seconds INT NOT NULL DEFAULT 0,
    timer_started_at TIMESTAMPTZ,
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. ROUNDS TABLE
CREATE TABLE IF NOT EXISTS rounds (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    round_number INT NOT NULL UNIQUE,
    round_name TEXT NOT NULL,
    description TEXT,
    rules TEXT,
    duration_seconds INT NOT NULL DEFAULT 300,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'waiting', 'active', 'ended', 'result_declared')),
    started_at TIMESTAMPTZ,
    ended_at TIMESTAMPTZ
);

-- 5. QUESTIONS TABLE (Holds technical challenges)
-- Sensitive correct_answer and hint_data can be queried only by RPC or admin
CREATE TABLE IF NOT EXISTS questions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    round_number INT NOT NULL,
    question_number INT NOT NULL,
    question_type TEXT NOT NULL CHECK (question_type IN ('mcq', 'crossword', 'binary', 'code_fill', 'riddle')),
    difficulty TEXT NOT NULL CHECK (difficulty IN ('easy', 'medium', 'hard')),
    question_data JSONB NOT NULL, -- Prompt, options/grid/code template/binary input
    correct_answer TEXT NOT NULL, -- Kept secret, evaluated via RPC
    time_limit_seconds INT NOT NULL DEFAULT 60,
    hint_data TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(round_number, question_number)
);

-- 6. TEAM QUESTIONS (Submissions & attempts tracking)
CREATE TABLE IF NOT EXISTS team_questions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    round_number INT NOT NULL,
    question_number INT NOT NULL,
    attempt_number INT NOT NULL DEFAULT 1,
    submitted_answer TEXT,
    is_correct BOOLEAN NOT NULL DEFAULT FALSE,
    hint_used BOOLEAN NOT NULL DEFAULT FALSE,
    started_at TIMESTAMPTZ DEFAULT NOW(),
    submitted_at TIMESTAMPTZ DEFAULT NOW(),
    time_taken_seconds NUMERIC(10, 2) DEFAULT 0
);

-- 7. TEAM CODES (4-letter unlockable codes)
CREATE TABLE IF NOT EXISTS team_codes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    round_number INT NOT NULL,
    code_segment_index INT NOT NULL DEFAULT 1,
    expected_code TEXT NOT NULL,
    is_unlocked BOOLEAN NOT NULL DEFAULT FALSE,
    is_submitted BOOLEAN NOT NULL DEFAULT FALSE,
    unlocked_at TIMESTAMPTZ,
    submitted_at TIMESTAMPTZ
);

-- 8. TEAM WORDS (Revealed hidden words that form final clue)
CREATE TABLE IF NOT EXISTS team_words (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    round_number INT NOT NULL,
    word TEXT NOT NULL,
    unlocked_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(team_id, round_number)
);

-- 9. ROUND RESULTS (Team aggregated stats per round)
CREATE TABLE IF NOT EXISTS round_results (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    round_number INT NOT NULL,
    score INT NOT NULL DEFAULT 0,
    questions_solved INT NOT NULL DEFAULT 0,
    total_time_seconds NUMERIC(10, 2) NOT NULL DEFAULT 0,
    hints_used INT NOT NULL DEFAULT 0,
    attempts_count INT NOT NULL DEFAULT 0,
    code_completed BOOLEAN NOT NULL DEFAULT FALSE,
    code_completed_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    status TEXT NOT NULL DEFAULT 'in_progress',
    UNIQUE(team_id, round_number)
);

-- 10. ROUND SELECTIONS (Admin promotion records - NEVER DELETED)
CREATE TABLE IF NOT EXISTS round_selections (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    round_number INT NOT NULL,
    selected BOOLEAN NOT NULL DEFAULT FALSE,
    selected_by TEXT NOT NULL DEFAULT 'admin',
    selected_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    notes TEXT,
    UNIQUE(team_id, round_number)
);

-- 11. FINAL ATTEMPTS (Attempts for the ultimate riddle)
CREATE TABLE IF NOT EXISTS final_attempts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    attempt_number INT NOT NULL,
    submitted_answer TEXT NOT NULL,
    is_correct BOOLEAN NOT NULL DEFAULT FALSE,
    submitted_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 12. LEADERBOARD SNAPSHOTS (Performance tracking over time)
CREATE TABLE IF NOT EXISTS leaderboard_snapshots (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    round_number INT NOT NULL,
    rank INT NOT NULL,
    score INT NOT NULL,
    time_seconds NUMERIC(10, 2) NOT NULL,
    hints_used INT NOT NULL,
    captured_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 13. ADMIN USERS TABLE
CREATE TABLE IF NOT EXISTS admin_users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    admin_name TEXT NOT NULL,
    admin_key_hash TEXT NOT NULL UNIQUE,
    role TEXT NOT NULL DEFAULT 'organizer',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 14. AUDIT LOGS (Immutable record of all admin & state events)
CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    admin_id TEXT,
    action TEXT NOT NULL,
    target_team_id UUID,
    round_number INT,
    metadata JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable Realtime for key synchronization tables (Idempotent)
DO $$
BEGIN
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE game_session, teams, round_selections, round_results, team_words, final_attempts, audit_logs;
    EXCEPTION WHEN duplicate_object THEN
        NULL;
    END;
END $$;

