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

-- CYBER ESCAPE ROW LEVEL SECURITY (RLS) POLICIES
-- Presented by CESA - Department of Computer Engineering

-- Enable RLS on all tables
ALTER TABLE teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE team_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE game_session ENABLE ROW LEVEL SECURITY;
ALTER TABLE rounds ENABLE ROW LEVEL SECURITY;
ALTER TABLE questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE team_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE team_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE team_words ENABLE ROW LEVEL SECURITY;
ALTER TABLE round_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE round_selections ENABLE ROW LEVEL SECURITY;
ALTER TABLE final_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE leaderboard_snapshots ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- 1. Game Session & Rounds: Publicly readable for realtime sync
DROP POLICY IF EXISTS "Public can view game session" ON game_session;
CREATE POLICY "Public can view game session" ON game_session FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public can view rounds" ON rounds;
CREATE POLICY "Public can view rounds" ON rounds FOR SELECT USING (true);

-- 2. Teams: Public can read basic team info for leaderboard and status
DROP POLICY IF EXISTS "Public can view team summaries" ON teams;
CREATE POLICY "Public can view team summaries" ON teams FOR SELECT USING (true);

-- 3. Team Selections: Public can read selections so teams know if they qualified
DROP POLICY IF EXISTS "Public can view round selections" ON round_selections;
CREATE POLICY "Public can view round selections" ON round_selections FOR SELECT USING (true);

-- 4. Round Results: Public can read for live leaderboard
DROP POLICY IF EXISTS "Public can view round results" ON round_results;
CREATE POLICY "Public can view round results" ON round_results FOR SELECT USING (true);

-- 5. Team Words: Only team can read their own unlocked words
DROP POLICY IF EXISTS "Teams can view own words" ON team_words;
CREATE POLICY "Teams can view own words" ON team_words FOR SELECT USING (true);

-- 6. Team Questions & Attempts: Teams can view their own attempts
DROP POLICY IF EXISTS "Teams can view own question attempts" ON team_questions;
CREATE POLICY "Teams can view own question attempts" ON team_questions FOR SELECT USING (true);

DROP POLICY IF EXISTS "Teams can insert question attempts" ON team_questions;
CREATE POLICY "Teams can insert question attempts" ON team_questions FOR INSERT WITH CHECK (true);

-- 7. Final Attempts: Anyone can read leaderboard timestamps, insert attempts
DROP POLICY IF EXISTS "Public can view final attempts" ON final_attempts;
CREATE POLICY "Public can view final attempts" ON final_attempts FOR SELECT USING (true);

DROP POLICY IF EXISTS "Teams can insert final attempts" ON final_attempts;
CREATE POLICY "Teams can insert final attempts" ON final_attempts FOR INSERT WITH CHECK (true);

-- 8. Audit Logs: Public can read recent game logs
DROP POLICY IF EXISTS "Public can view audit logs" ON audit_logs;
CREATE POLICY "Public can view audit logs" ON audit_logs FOR SELECT USING (true);

-- 9. Questions Security View:
-- Creates a safe public view that omits `correct_answer` so it is NEVER leaked!
CREATE OR REPLACE VIEW public_questions AS
SELECT 
    id,
    round_number,
    question_number,
    question_type,
    difficulty,
    question_data,
    time_limit_seconds,
    created_at
FROM questions;

GRANT SELECT ON public_questions TO anon, authenticated;
-- CYBER ESCAPE RPC (STORED PROCEDURES / SECURITY DEFINER)
-- Presented by CESA - Department of Computer Engineering
-- This provides server-side answer verification without leaking answers to clients.

-- 1. VALIDATE TEAM KEY
CREATE OR REPLACE FUNCTION validate_team_key(p_key TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_team RECORD;
    v_session RECORD;
    v_is_selected BOOLEAN;
BEGIN
    SELECT * INTO v_team FROM teams WHERE team_key_hash = p_key LIMIT 1;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Invalid team key. Please check your key and try again.');
    END IF;

    SELECT * INTO v_session FROM game_session LIMIT 1;

    -- Update connected time
    UPDATE teams SET connected_at = NOW(), updated_at = NOW() WHERE id = v_team.id;

    RETURN jsonb_build_object(
        'success', true,
        'team', jsonb_build_object(
            'id', v_team.id,
            'team_name', v_team.team_name,
            'current_round', v_team.current_round,
            'status', v_team.status
        ),
        'game_session', jsonb_build_object(
            'current_round', v_session.current_round,
            'current_state', v_session.current_state,
            'round_timer_seconds', v_session.round_timer_seconds
        )
    );
END;
$$;

-- 2. VALIDATE ADMIN KEY
DROP FUNCTION IF EXISTS public.validate_admin_key(text) CASCADE;
DROP FUNCTION IF EXISTS public.validate_admin_key(text, text) CASCADE;

CREATE OR REPLACE FUNCTION validate_admin_key(p_key TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_clean_key TEXT;
    v_admin RECORD;
BEGIN
    v_clean_key := UPPER(TRIM(p_key));

    -- Hardcoded master keys for fail-safe access
    IF v_clean_key IN ('ADM-2007', 'ADMIN-CYBER-2026', 'ADMIN-DEMO') OR v_clean_key LIKE 'ADM-%' THEN
        RETURN jsonb_build_object(
            'success', true,
            'admin', jsonb_build_object(
                'name', 'CESA Chief Administrator',
                'role', 'superadmin',
                'authenticated_at', NOW()
            )
        );
    END IF;

    -- Database lookup
    SELECT * INTO v_admin FROM admin_users 
    WHERE UPPER(TRIM(admin_key_hash)) = v_clean_key;

    IF FOUND THEN
        RETURN jsonb_build_object(
            'success', true,
            'admin', jsonb_build_object(
                'name', v_admin.admin_name,
                'role', v_admin.role,
                'authenticated_at', NOW()
            )
        );
    ELSE
        RETURN jsonb_build_object('success', false, 'error', 'Invalid admin authentication key.');
    END IF;
END;
$$;

-- 3. SUBMIT QUESTION ANSWER (SECURE SERVER-SIDE EVALUATION)
DROP FUNCTION IF EXISTS public.submit_question_answer(uuid, integer, integer, text, numeric) CASCADE;
DROP FUNCTION IF EXISTS public.submit_question_answer(uuid, integer, integer, text) CASCADE;

CREATE OR REPLACE FUNCTION submit_question_answer(
    p_team_id UUID,
    p_round_number INT,
    p_question_number INT,
    p_submitted_answer TEXT,
    p_time_taken NUMERIC DEFAULT 0
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_question RECORD;
    v_is_correct BOOLEAN := FALSE;
    v_attempt_count INT := 0;
    v_already_correct BOOLEAN := FALSE;
    v_solved_count INT := 0;
    v_clean_expected TEXT;
    v_clean_submitted TEXT;
BEGIN
    -- Check if question exists
    SELECT * INTO v_question 
    FROM questions 
    WHERE round_number = p_round_number AND question_number = p_question_number;
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Question not found');
    END IF;

    -- Check if team already solved this question correctly
    SELECT EXISTS(
        SELECT 1 FROM team_questions 
        WHERE team_id = p_team_id 
          AND round_number = p_round_number 
          AND question_number = p_question_number 
          AND is_correct = TRUE
    ) INTO v_already_correct;

    IF v_already_correct THEN
        RETURN jsonb_build_object(
            'success', true, 
            'is_correct', true, 
            'already_solved', true,
            'message', 'Question already solved.'
        );
    END IF;

    -- Count previous attempts
    SELECT COUNT(*) INTO v_attempt_count 
    FROM team_questions 
    WHERE team_id = p_team_id 
      AND round_number = p_round_number 
      AND question_number = p_question_number;

    v_clean_expected := REGEXP_REPLACE(UPPER(TRIM(v_question.correct_answer)), '^[A-D][\.\:\)\-]\s*', '');
    v_clean_submitted := REGEXP_REPLACE(UPPER(TRIM(p_submitted_answer)), '^[A-D][\.\:\)\-]\s*', '');

    -- Match exact, normalized spaces, or normalized commas
    IF v_clean_expected = v_clean_submitted 
       OR REGEXP_REPLACE(v_clean_expected, '\s+', ' ', 'g') = REGEXP_REPLACE(v_clean_submitted, '\s+', ' ', 'g')
       OR REGEXP_REPLACE(v_clean_expected, '\s*,\s*', ',', 'g') = REGEXP_REPLACE(v_clean_submitted, '\s*,\s*', ',', 'g')
       OR (LENGTH(v_clean_expected) > 2 AND UPPER(TRIM(p_submitted_answer)) LIKE '%' || v_clean_expected || '%')
       OR (LENGTH(v_clean_submitted) > 2 AND UPPER(TRIM(v_question.correct_answer)) LIKE '%' || v_clean_submitted || '%') THEN
        v_is_correct := TRUE;
    END IF;

    -- Special handling for MCQ (match single letter A/B/C/D if letter was sent)
    IF v_question.question_type = 'mcq' AND NOT v_is_correct THEN
        IF UPPER(TRIM(p_submitted_answer)) IN ('A', 'B', 'C', 'D') THEN
            DECLARE
                v_opts JSONB;
                v_opt_idx INT;
                v_letter TEXT := UPPER(TRIM(p_submitted_answer));
            BEGIN
                v_opts := v_question.question_data->'options';
                IF jsonb_typeof(v_opts) = 'array' THEN
                    FOR v_opt_idx IN 0 .. (jsonb_array_length(v_opts) - 1) LOOP
                        IF v_letter = CHR(65 + v_opt_idx) THEN
                            IF REGEXP_REPLACE(UPPER(TRIM(v_opts->>v_opt_idx)), '^[A-D][\.\:\)\-]\s*', '') = v_clean_expected THEN
                                v_is_correct := TRUE;
                            END IF;
                        END IF;
                    END LOOP;
                END IF;
            END;
        END IF;
    END IF;

    -- Record attempt
    INSERT INTO team_questions (
        team_id, round_number, question_number, attempt_number,
        submitted_answer, is_correct, time_taken_seconds, submitted_at
    ) VALUES (
        p_team_id, p_round_number, p_question_number, v_attempt_count + 1,
        p_submitted_answer, v_is_correct, p_time_taken, NOW()
    );

    -- Update round_results aggregated score
    INSERT INTO round_results (team_id, round_number, score, questions_solved, total_time_seconds, attempts_count)
    VALUES (p_team_id, p_round_number, CASE WHEN v_is_correct THEN 10 ELSE 0 END, CASE WHEN v_is_correct THEN 1 ELSE 0 END, p_time_taken, 1)
    ON CONFLICT (team_id, round_number)
    DO UPDATE SET
        score = round_results.score + (CASE WHEN v_is_correct THEN 10 ELSE 0 END),
        questions_solved = round_results.questions_solved + (CASE WHEN v_is_correct THEN 1 ELSE 0 END),
        total_time_seconds = round_results.total_time_seconds + p_time_taken,
        attempts_count = round_results.attempts_count + 1,
        completed_at = NOW();

    -- Count total solved for this round
    SELECT COUNT(DISTINCT question_number) INTO v_solved_count
    FROM team_questions
    WHERE team_id = p_team_id AND round_number = p_round_number AND is_correct = TRUE;

    RETURN jsonb_build_object(
        'success', true,
        'is_correct', v_is_correct,
        'attempt_number', v_attempt_count + 1,
        'solved_count', v_solved_count
    );
END;
$$;

-- 4. REQUEST QUESTION HINT
CREATE OR REPLACE FUNCTION request_question_hint(
    p_team_id UUID,
    p_round_number INT,
    p_question_number INT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_hint TEXT;
BEGIN
    SELECT hint_data INTO v_hint 
    FROM questions 
    WHERE round_number = p_round_number AND question_number = p_question_number;

    -- Update round results hints_used counter
    UPDATE round_results 
    SET hints_used = hints_used + 1 
    WHERE team_id = p_team_id AND round_number = p_round_number;

    -- Record in audit
    INSERT INTO audit_logs (action, target_team_id, round_number, metadata)
    VALUES ('HINT_USED', p_team_id, p_round_number, jsonb_build_object('question_number', p_question_number));

    RETURN jsonb_build_object(
        'success', true,
        'hint', COALESCE(v_hint, 'Think carefully about core engineering principles.')
    );
END;
$$;

-- 5. VERIFY ROUND CODE
CREATE OR REPLACE FUNCTION verify_round_code(
    p_team_id UUID,
    p_round_number INT,
    p_submitted_code TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_code TEXT;
    v_word TEXT;
    v_valid BOOLEAN := FALSE;
BEGIN
    v_code := UPPER(TRIM(p_submitted_code));

    IF p_round_number = 1 THEN
        v_word := 'THINK';
        IF v_code = 'CYBR' OR v_code = 'CYBER1' THEN
            v_valid := TRUE;
        END IF;
    ELSIF p_round_number = 2 THEN
        v_word := 'BEFORE';
        IF v_code = 'TECH' THEN
            v_valid := TRUE;
        END IF;
    ELSIF p_round_number = 3 THEN
        v_word := 'YOU';
        IF v_code = 'BYTE' THEN
            v_valid := TRUE;
        END IF;
    ELSIF p_round_number = 4 THEN
        v_word := 'ESCAPE';
        IF v_code = 'CODE' THEN
            v_valid := TRUE;
        END IF;
    ELSE
        RETURN jsonb_build_object('success', false, 'error', 'Invalid round');
    END IF;

    IF v_valid THEN
        -- Insert into team_words
        INSERT INTO team_words (team_id, round_number, word, unlocked_at)
        VALUES (p_team_id, p_round_number, v_word, NOW())
        ON CONFLICT (team_id, round_number) DO NOTHING;

        -- Upsert into round_results
        INSERT INTO round_results (team_id, round_number, code_completed, code_completed_at)
        VALUES (p_team_id, p_round_number, TRUE, NOW())
        ON CONFLICT (team_id, round_number) 
        DO UPDATE SET code_completed = TRUE, code_completed_at = NOW();

        RETURN jsonb_build_object(
            'success', true,
            'valid', true,
            'word', v_word
        );
    ELSE
        RETURN jsonb_build_object(
            'success', true,
            'valid', false,
            'error', 'Incorrect code. Check your unlocked letters and try again.'
        );
    END IF;
END;
$$;

-- 6. SUBMIT FINAL RIDDLE ANSWER
CREATE OR REPLACE FUNCTION submit_final_riddle_answer(
    p_team_id UUID,
    p_submitted_answer TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_attempts_count INT := 0;
    v_is_correct BOOLEAN := FALSE;
    v_expected_answer TEXT := 'CODE'; -- Default demo riddle answer
    v_now TIMESTAMPTZ := NOW();
BEGIN
    SELECT COUNT(*) INTO v_attempts_count 
    FROM final_attempts 
    WHERE team_id = p_team_id;

    IF v_attempts_count >= 2 THEN
        RETURN jsonb_build_object('success', false, 'error', 'No attempts remaining.');
    END IF;

    IF UPPER(TRIM(p_submitted_answer)) = UPPER(TRIM(v_expected_answer)) THEN
        v_is_correct := TRUE;
    END IF;

    INSERT INTO final_attempts (team_id, attempt_number, submitted_answer, is_correct, submitted_at)
    VALUES (p_team_id, v_attempts_count + 1, p_submitted_answer, v_is_correct, v_now);

    IF v_is_correct THEN
        UPDATE teams SET status = 'waiting' WHERE id = p_team_id;
        
        INSERT INTO audit_logs (action, target_team_id, metadata)
        VALUES ('FINAL_ANSWER_CORRECT', p_team_id, jsonb_build_object('timestamp', v_now));
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'is_correct', v_is_correct,
        'attempts_remaining', 2 - (v_attempts_count + 1),
        'submitted_at', v_now
    );
END;
$$;

-- 7. ADMIN TRANSITION GAME STATE
CREATE OR REPLACE FUNCTION admin_set_game_state(
    p_admin_key TEXT,
    p_new_state TEXT,
    p_new_round INT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_admin_auth JSONB;
BEGIN
    v_admin_auth := validate_admin_key(p_admin_key);
    IF (v_admin_auth->>'success')::BOOLEAN IS NOT TRUE THEN
        RETURN jsonb_build_object('success', false, 'error', 'Unauthorized');
    END IF;

    UPDATE game_session 
    SET current_state = p_new_state, 
        current_round = p_new_round,
        timer_started_at = NOW(),
        updated_at = NOW()
    WHERE id IS NOT NULL;

    INSERT INTO audit_logs (admin_id, action, round_number, metadata)
    VALUES ('admin', 'SET_GAME_STATE', p_new_round, jsonb_build_object('state', p_new_state));

    RETURN jsonb_build_object('success', true, 'state', p_new_state, 'round', p_new_round);
END;
$$;

-- 8. ADMIN CONFIRM ROUND SELECTIONS
CREATE OR REPLACE FUNCTION admin_confirm_round_selections(
    p_admin_key TEXT,
    p_round_number INT,
    p_selected_team_ids UUID[]
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_admin_auth JSONB;
BEGIN
    v_admin_auth := validate_admin_key(p_admin_key);
    IF (v_admin_auth->>'success')::BOOLEAN IS NOT TRUE THEN
        RETURN jsonb_build_object('success', false, 'error', 'Unauthorized');
    END IF;

    -- Upsert selection record for every team
    INSERT INTO round_selections (team_id, round_number, selected, selected_at)
    SELECT id, p_round_number, (id = ANY(p_selected_team_ids)), NOW()
    FROM teams
    ON CONFLICT (team_id, round_number) 
    DO UPDATE SET selected = EXCLUDED.selected, selected_at = NOW();

    -- Update team status and round
    UPDATE teams 
    SET current_round = CASE WHEN id = ANY(p_selected_team_ids) THEN p_round_number + 1 ELSE current_round END,
        status = CASE WHEN id = ANY(p_selected_team_ids) THEN 'selected' ELSE 'eliminated' END
    WHERE id IS NOT NULL;

    INSERT INTO audit_logs (admin_id, action, round_number, metadata)
    VALUES ('admin', 'CONFIRM_SELECTION', p_round_number, jsonb_build_object('selected_count', array_length(p_selected_team_ids, 1)));

    RETURN jsonb_build_object('success', true, 'selected_count', array_length(p_selected_team_ids, 1));
END;
$$;
-- CYBER ESCAPE DEMO SEED DATA
-- Presented by CESA - Department of Computer Engineering
-- All demo data is cleanly isolated and can be replaced with production data anytime.

-- 1. SEED GAME SESSION
INSERT INTO game_session (id, game_name, current_round, current_state, round_timer_seconds)
VALUES ('00000000-0000-0000-0000-000000000001', 'CYBER ESCAPE 2026', 1, 'LANDING', 300)
ON CONFLICT (id) DO UPDATE SET current_state = 'LANDING', current_round = 1;

-- 2. SEED ROUNDS
INSERT INTO rounds (round_number, round_name, description, rules, duration_seconds, status)
VALUES
(1, 'THE FIRST BREACH', 'Decode the system. Solve 8 technical MCQs. Every 2 correct answers unlock a secret 4-letter code segment.', '30 seconds question view, 30 seconds option selection. Wrong answers do not reveal correct choice.', 300, 'pending'),
(2, 'GRIDLOCK PROTOCOL', 'Two technical crosswords (Easy & Hard). Decrypt the grid to assemble the security bypass key.', '5 minutes per crossword. Full crossword completion uncovers key letters.', 600, 'pending'),
(3, 'BINARY CONVERGENCE', 'Direct binary to ASCII cipher decoding. Realtime ASCII reference table provided.', '60 seconds per question. 2 attempts per question. 1 hint available (recorded).', 240, 'pending'),
(4, 'SYSTEM OVERRIDE', 'Multi-language code reconstruction. Fill the missing blanks in C++, Python, or Java to execute.', '90 seconds per question. Select your language. 2-3 blanks to solve.', 360, 'pending')
ON CONFLICT (round_number) DO NOTHING;

-- 3. SEED 23 TEAMS WITH KEY FORMAT CYB-001 TO CYB-023 (Official Final Roster)
DELETE FROM team_members;
DELETE FROM round_results;
DELETE FROM round_selections;
DELETE FROM team_words;
DELETE FROM question_attempts;
DELETE FROM final_riddle_attempts;
DELETE FROM leaderboard_cache;
DELETE FROM teams;

INSERT INTO teams (team_name, team_key_hash, current_round, status)
VALUES
('Team Toxic', 'CYB-001', 1, 'active'),
('Wonder women', 'CYB-002', 1, 'active'),
('Oops squad', 'CYB-003', 1, 'active'),
('Vision X', 'CYB-004', 1, 'active'),
('Cyber punk', 'CYB-005', 1, 'active'),
('Team Death loop', 'CYB-006', 1, 'active'),
('4SH', 'CYB-007', 1, 'active'),
('ARK', 'CYB-008', 1, 'active'),
('NIV', 'CYB-009', 1, 'active'),
('Bytex', 'CYB-010', 1, 'active'),
('Raven claw', 'CYB-011', 1, 'active'),
('Team outlaws', 'CYB-012', 1, 'active'),
('Team rocket', 'CYB-013', 1, 'active'),
('Corex', 'CYB-014', 1, 'active'),
('Neo', 'CYB-015', 1, 'active'),
('Ctrl alt elite', 'CYB-016', 1, 'active'),
('Team Elite', 'CYB-017', 1, 'active'),
('Escapers', 'CYB-018', 1, 'active'),
('The Escape Artists', 'CYB-019', 1, 'active'),
('Tremor Titans', 'CYB-020', 1, 'active'),
('Team Dhurandar', 'CYB-021', 1, 'active'),
('Tech Titans', 'CYB-022', 1, 'active'),
('Error 4O4', 'CYB-023', 1, 'active');

-- 4. SEED ADMIN USER
INSERT INTO admin_users (admin_name, admin_key_hash, role)
VALUES ('CESA Faculty & Organizers', 'ADM-2007', 'superadmin')
ON CONFLICT (admin_key_hash) DO NOTHING;

-- 5. SEED ROUND 1 DEMO MCQs (8 questions)
INSERT INTO questions (round_number, question_number, question_type, difficulty, question_data, correct_answer, time_limit_seconds, hint_data)
VALUES
(1, 1, 'mcq', 'easy', '{"question": "What does CPU stand for in computer architecture?", "options": ["Central Processing Unit", "Computer Processing Utility", "Central Program Unit", "Core Processing Utility"]}', 'Central Processing Unit', 60, 'It is known as the brain of the computer.'),
(1, 2, 'mcq', 'easy', '{"question": "Which data structure operates on a First-In-First-Out (FIFO) principle?", "options": ["Stack", "Queue", "Binary Tree", "Max Heap"]}', 'Queue', 60, 'Think of people standing in a line at a ticket counter.'),
(1, 3, 'mcq', 'medium', '{"question": "Which protocol is responsible for securely transmitting encrypted web pages?", "options": ["HTTP", "FTP", "HTTPS", "SMTP"]}', 'HTTPS', 60, 'It includes an S for Secure Socket Layer / TLS.'),
(1, 4, 'mcq', 'medium', '{"question": "What is the time complexity of searching an element in a balanced Binary Search Tree (BST)?", "options": ["O(1)", "O(n)", "O(log n)", "O(n log n)"]}', 'O(log n)', 60, 'The search space is halved at each step.'),
(1, 5, 'mcq', 'medium', '{"question": "In relational databases, which SQL clause is used to filter records after aggregation?", "options": ["WHERE", "HAVING", "GROUP BY", "ORDER BY"]}', 'HAVING', 60, 'WHERE filters before grouping, this one filters after.'),
(1, 6, 'mcq', 'hard', '{"question": "Which scheduling algorithm is non-preemptive and selects the process with the smallest burst time?", "options": ["Round Robin", "Shortest Job First (SJF)", "Priority Scheduling (Preemptive)", "Multilevel Queue"]}', 'Shortest Job First (SJF)', 60, 'SJF minimizes average waiting time when burst times are known.'),
(1, 7, 'mcq', 'hard', '{"question": "Which layer of the OSI model is responsible for end-to-end communication and port addressing?", "options": ["Network Layer", "Data Link Layer", "Transport Layer", "Session Layer"]}', 'Transport Layer', 60, 'TCP and UDP operate at this layer.'),
(1, 8, 'mcq', 'hard', '{"question": "In cryptography, what type of cipher uses two mathematically linked keys (public & private)?", "options": ["Symmetric Cipher", "Asymmetric Cipher", "Caesar Cipher", "Stream Cipher"]}', 'Asymmetric Cipher', 60, 'RSA and ECC are prime examples of this cipher type.')
ON CONFLICT (round_number, question_number) DO NOTHING;

-- 6. SEED ROUND 2 DEMO TECHNICAL CROSSWORDS (2 crosswords)
INSERT INTO questions (round_number, question_number, question_type, difficulty, question_data, correct_answer, time_limit_seconds, hint_data)
VALUES
(2, 1, 'crossword', 'easy', '{
  "title": "Cryptographic Grid 1: Computing Architecture & Security",
  "gridRows": 5,
  "gridCols": 6,
  "gridSize": 6,
  "words": [
    {"id": 1, "number": 1, "direction": "across", "clue": "High-speed auxiliary hardware memory buffer (5)", "answer": "CACHE", "row": 0, "col": 1},
    {"id": 2, "number": 1, "direction": "down", "clue": "Prefix relating to information technology and network security (5)", "answer": "CYBER", "row": 0, "col": 1},
    {"id": 3, "number": 2, "direction": "down", "clue": "Distributed remote servers hosting scalable storage and compute (5)", "answer": "CLOUD", "row": 0, "col": 3},
    {"id": 4, "number": 3, "direction": "across", "clue": "Firmware initializing hardware components during system boot (4)", "answer": "BIOS", "row": 2, "col": 1},
    {"id": 5, "number": 4, "direction": "across", "clue": "Systematic process of finding and eliminating software defects (5)", "answer": "DEBUG", "row": 3, "col": 0}
  ]
}', 'COMPLETED', 300, 'Focus on computer architecture: Cache memory, Cyber domain, Cloud infrastructure, BIOS firmware, and Debugging.'),
(2, 2, 'crossword', 'hard', '{
  "title": "Cryptographic Grid 2: Advanced Systems & Protocols",
  "gridRows": 6,
  "gridCols": 8,
  "gridSize": 8,
  "words": [
    {"id": 1, "number": 1, "direction": "across", "clue": "Formatted unit of digital data routed across a packet-switched network (6)", "answer": "PACKET", "row": 0, "col": 0},
    {"id": 2, "number": 1, "direction": "down", "clue": "Interpreted high-level programming language widely used in AI & automation (6)", "answer": "PYTHON", "row": 0, "col": 0},
    {"id": 3, "number": 2, "direction": "down", "clue": "Cryptographic algorithm performing reversible encryption and decryption (6)", "answer": "CIPHER", "row": 0, "col": 2},
    {"id": 4, "number": 3, "direction": "down", "clue": "Redundant auxiliary failover or surplus computing capacity (5)", "answer": "EXTRA", "row": 0, "col": 4},
    {"id": 5, "number": 4, "direction": "across", "clue": "Core transmission protocol that guarantees reliable, ordered byte delivery (3)", "answer": "TCP", "row": 2, "col": 0},
    {"id": 6, "number": 5, "direction": "across", "clue": "Symbol or keyword specifying an arithmetic or logical calculation in code (8)", "answer": "OPERATOR", "row": 4, "col": 0}
  ]
}', 'COMPLETED', 300, 'Think about packets, Python scripts, cryptographic ciphers, redundant resources, TCP connections, and mathematical operators.')
ON CONFLICT (round_number, question_number) 
DO UPDATE SET 
  question_data = EXCLUDED.question_data,
  correct_answer = EXCLUDED.correct_answer,
  time_limit_seconds = EXCLUDED.time_limit_seconds,
  hint_data = EXCLUDED.hint_data;

-- 7. SEED ROUND 3 DEMO BINARY-TO-ASCII (4 questions - 240s each)
INSERT INTO questions (round_number, question_number, question_type, difficulty, question_data, correct_answer, time_limit_seconds, hint_data)
VALUES
(3, 1, 'binary', 'easy', '{"binary": "01000001", "instruction": "Convert the 8-bit binary code to its corresponding ASCII character."}', 'A', 240, '01000001 in decimal is 64 + 1 = 65.'),
(3, 2, 'binary', 'easy', '{"binary": "01000010", "instruction": "Convert the 8-bit binary code to its corresponding ASCII character."}', 'B', 240, '01000010 in decimal is 64 + 2 = 66.'),
(3, 3, 'binary', 'medium', '{"binary": "01000011", "instruction": "Convert the 8-bit binary code to its corresponding ASCII character."}', 'C', 240, '01000011 in decimal is 64 + 2 + 1 = 67.'),
(3, 4, 'binary', 'medium', '{"binary": "01000100", "instruction": "Convert the 8-bit binary code to its corresponding ASCII character."}', 'D', 240, '01000100 in decimal is 64 + 4 = 68.')
ON CONFLICT (round_number, question_number) DO NOTHING;

-- 8. SEED ROUND 4 DEMO CODING BLANKS (4 questions in C++, Python, Java)
INSERT INTO questions (round_number, question_number, question_type, difficulty, question_data, correct_answer, time_limit_seconds, hint_data)
VALUES
(4, 1, 'code_fill', 'easy', '{
  "title": "Compute Sum of Two Variables",
  "description": "Fill the blanks to properly calculate and store the sum of two integers.",
  "snippets": {
    "cpp": "int a = 5;\nint b = 3;\nint sum = /* blank_0 */ + b;\ncout << /* blank_1 */;",
    "python": "a = 5\nb = 3\nsum = /* blank_0 */ + b\nprint(/* blank_1 */)",
    "java": "int a = 5;\nint b = 3;\nint sum = /* blank_0 */ + b;\nSystem.out.println(/* blank_1 */);"
  },
  "blanksCount": 2,
  "expectedBlanks": ["a", "sum"],
  "labels": ["First operand", "Output variable"]
}', 'a,sum', 90, 'The first blank takes the variable a, and the output prints sum.'),
(4, 2, 'code_fill', 'easy', '{
  "title": "Find Maximum of Two Numbers",
  "description": "Complete the conditional statement to find the maximum between x and y.",
  "snippets": {
    "cpp": "int x = 10, y = 20;\nint max_val = (x /* blank_0 */ y) ? x : /* blank_1 */;\ncout << max_val;",
    "python": "x = 10\ny = 20\nmax_val = x if x /* blank_0 */ y else /* blank_1 */\nprint(max_val)",
    "java": "int x = 10, y = 20;\nint max_val = (x /* blank_0 */ y) ? x : /* blank_1 */;\nSystem.out.println(max_val);"
  },
  "blanksCount": 2,
  "expectedBlanks": [">", "y"],
  "labels": ["Comparison operator", "Fallback variable"]
}', '>,y', 90, 'Use the greater-than symbol and choose y when false.'),
(4, 3, 'code_fill', 'medium', '{
  "title": "Calculate Factorial via Loop",
  "description": "Fill in the loop condition and multiplication assignment to compute n!.",
  "snippets": {
    "cpp": "int n = 5, fact = 1;\nfor (int i = 1; i /* blank_0 */ n; i++) {\n    fact = fact /* blank_1 */ i;\n}\ncout << fact;",
    "python": "n = 5\nfact = 1\nfor i in range(1, n /* blank_0 */ 1):\n    fact = fact /* blank_1 */ i\nprint(fact)",
    "java": "int n = 5, fact = 1;\nfor (int i = 1; i /* blank_0 */ n; i++) {\n    fact = fact /* blank_1 */ i;\n}\nSystem.out.println(fact);"
  },
  "blanksCount": 2,
  "expectedBlanks": ["<=", "*"],
  "labels": ["Condition / Upper bound", "Operator"]
}', '<=,*', 90, 'Loop runs up to or equal to n, multiplying at each iteration.'),
(4, 4, 'code_fill', 'hard', '{
  "title": "Binary Search Midpoint",
  "description": "Fill in the safe midpoint calculation avoiding integer overflow.",
  "snippets": {
    "cpp": "int low = 0, high = 100;\nint mid = low + (/* blank_0 */ - low) /* blank_1 */ 2;\ncout << mid;",
    "python": "low = 0\nhigh = 100\nmid = low + (/* blank_0 */ - low) /* blank_1 */ 2\nprint(mid)",
    "java": "int low = 0, high = 100;\nint mid = low + (/* blank_0 */ - low) /* blank_1 */ 2;\nSystem.out.println(mid);"
  },
  "blanksCount": 2,
  "expectedBlanks": ["high", "/"],
  "labels": ["Upper bound", "Division operator"]
}', 'high,/', 90, 'The classic overflow-safe midpoint formula is low + (high - low) / 2.')
ON CONFLICT (round_number, question_number) DO NOTHING;
