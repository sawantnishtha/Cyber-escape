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
CREATE OR REPLACE FUNCTION validate_admin_key(p_key TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_admin RECORD;
BEGIN
    SELECT * INTO v_admin FROM admin_users WHERE admin_key_hash = p_key LIMIT 1;
    IF NOT FOUND THEN
        -- Fallback default check for demo/init
        IF p_key = 'ADMIN-CYBER-2026' THEN
            RETURN jsonb_build_object(
                'success', true,
                'admin', jsonb_build_object(
                    'name', 'Head Organizer',
                    'role', 'superadmin'
                )
            );
        END IF;
        RETURN jsonb_build_object('success', false, 'error', 'Invalid admin authentication key.');
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'admin', jsonb_build_object(
            'name', v_admin.admin_name,
            'role', v_admin.role
        )
    );
END;
$$;

-- 3. SUBMIT QUESTION ANSWER (SECURE SERVER-SIDE EVALUATION)
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

    -- Check answer (case-insensitive trim)
    IF UPPER(TRIM(v_question.correct_answer)) = UPPER(TRIM(p_submitted_answer)) THEN
        v_is_correct := TRUE;
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
    v_expected_code TEXT;
    v_word TEXT;
BEGIN
    -- Demo codes & words mapping (can be managed in database)
    IF p_round_number = 1 THEN
        v_expected_code := 'CYBR';
        v_word := 'THINK';
    ELSIF p_round_number = 2 THEN
        v_expected_code := 'TECH';
        v_word := 'BEFORE';
    ELSIF p_round_number = 3 THEN
        v_expected_code := 'BYTE';
        v_word := 'YOU';
    ELSIF p_round_number = 4 THEN
        v_expected_code := 'CODE';
        v_word := 'ESCAPE';
    ELSE
        RETURN jsonb_build_object('success', false, 'error', 'Invalid round');
    END IF;

    IF UPPER(TRIM(p_submitted_code)) = UPPER(TRIM(v_expected_code)) THEN
        -- Insert into team_words
        INSERT INTO team_words (team_id, round_number, word, unlocked_at)
        VALUES (p_team_id, p_round_number, v_word, NOW())
        ON CONFLICT (team_id, round_number) DO NOTHING;

        -- Update round_results
        UPDATE round_results 
        SET code_completed = TRUE, code_completed_at = NOW() 
        WHERE team_id = p_team_id AND round_number = p_round_number;

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
        updated_at = NOW();

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
        status = CASE WHEN id = ANY(p_selected_team_ids) THEN 'selected' ELSE 'eliminated' END;

    INSERT INTO audit_logs (admin_id, action, round_number, metadata)
    VALUES ('admin', 'CONFIRM_SELECTION', p_round_number, jsonb_build_object('selected_count', array_length(p_selected_team_ids, 1)));

    RETURN jsonb_build_object('success', true, 'selected_count', array_length(p_selected_team_ids, 1));
END;
$$;
