-- =========================================================================
-- CYBER ESCAPE - SUPABASE MASTER UPDATE SCRIPT
-- Paste and execute this entire script in your Supabase SQL Editor:
-- https://supabase.com/dashboard/project/axwoerwkfcvmaisqkzur/sql
-- =========================================================================

-- 1. FIX: Admin Set Game State (Satisfies Postgres safe-update mode)
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

-- 2. FIX: Admin Confirm Round Selections
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

-- 3. UPDATED & TOLERANT VERIFY ROUND CODE (CYBR, TECH, BYTE, CODE)
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
        -- Accepts both CYBR (new 4-letter) and legacy CYBER1
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

-- 4. UPDATE ROUND 2 TECHNICAL CROSSWORDS (100% Mathematically Valid Intersections)
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

-- 5. ATOMIC ADMIN RESET EVENT FUNCTION
CREATE OR REPLACE FUNCTION admin_reset_event(
    p_admin_key TEXT
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

    -- Reset game session to initial state
    UPDATE game_session 
    SET current_state = 'LANDING',
        current_round = 1,
        round_timer_seconds = 300,
        timer_started_at = NOW(),
        started_at = NOW(),
        updated_at = NOW()
    WHERE id IS NOT NULL;

    -- Reset all teams to active and Round 1
    UPDATE teams 
    SET status = 'active',
        current_round = 1,
        updated_at = NOW()
    WHERE id IS NOT NULL;

    -- Clear all submission and selection progress
    DELETE FROM round_results WHERE team_id IS NOT NULL;
    DELETE FROM team_words WHERE team_id IS NOT NULL;
    DELETE FROM team_questions WHERE team_id IS NOT NULL;
    DELETE FROM round_selections WHERE team_id IS NOT NULL;
    DELETE FROM final_attempts WHERE team_id IS NOT NULL;

    INSERT INTO audit_logs (admin_id, action, round_number, metadata)
    VALUES ('admin', 'EVENT_RESTARTED', 1, jsonb_build_object('timestamp', NOW()));

    RETURN jsonb_build_object('success', true);
END;
$$;

