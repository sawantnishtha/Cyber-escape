-- =========================================================================
-- CYBER ESCAPE - SUPABASE MASTER UPDATE SCRIPT
-- Paste and execute this entire script in your Supabase SQL Editor:
-- https://supabase.com/dashboard/project/axwoerwkfcvmaisqkzur/sql
-- =========================================================================

-- 1. ADMIN KEY VALIDATION RPC
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

-- 1.1 TEAM KEY VALIDATION RPC
DROP FUNCTION IF EXISTS public.validate_team_key(text) CASCADE;

CREATE OR REPLACE FUNCTION validate_team_key(p_key TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_team RECORD;
    v_session RECORD;
    v_clean_key TEXT;
BEGIN
    v_clean_key := UPPER(TRIM(p_key));

    SELECT * INTO v_team FROM teams WHERE UPPER(TRIM(team_key_hash)) = v_clean_key LIMIT 1;
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
            'current_round', COALESCE(v_session.current_round, 1),
            'current_state', COALESCE(v_session.current_state, 'LANDING'),
            'round_timer_seconds', COALESCE(v_session.round_timer_seconds, 300)
        )
    );
END;
$$;

-- 2. SEED ADMIN USER TABLE
INSERT INTO admin_users (admin_name, admin_key_hash, role)
VALUES ('CESA Faculty & Organizers', 'ADM-2007', 'superadmin')
ON CONFLICT (admin_key_hash) 
DO UPDATE SET admin_name = EXCLUDED.admin_name, role = EXCLUDED.role;

-- 3. SEED 20 TEAMS WITH KEY FORMAT CYB-001 TO CYB-020 (Official Attendance Roster)
INSERT INTO teams (team_name, team_key_hash, current_round, status)
VALUES
('Escaper', 'CYB-001', 1, 'active'),
('Ctrl Alt Elite', 'CYB-002', 1, 'active'),
('oops squad', 'CYB-003', 1, 'active'),
('Team Toxic', 'CYB-004', 1, 'active'),
('Ravenclaw', 'CYB-005', 1, 'active'),
('Error 404', 'CYB-006', 1, 'active'),
('ByteX', 'CYB-007', 1, 'active'),
('Neo', 'CYB-008', 1, 'active'),
('Team Elite', 'CYB-009', 1, 'active'),
('CyberPunk', 'CYB-010', 1, 'active'),
('VisionX', 'CYB-011', 1, 'active'),
('CoreX', 'CYB-012', 1, 'active'),
('Team Deathloop', 'CYB-013', 1, 'active'),
('Team Vedant', 'CYB-014', 1, 'active'),
('Cyber Titans', 'CYB-015', 1, 'active'),
('Shadow Hackers', 'CYB-016', 1, 'active'),
('Zero Day', 'CYB-017', 1, 'active'),
('Kernel Panic', 'CYB-018', 1, 'active'),
('Cipher Squad', 'CYB-019', 1, 'active'),
('Terminal Force', 'CYB-020', 1, 'active')
ON CONFLICT (team_key_hash) 
DO UPDATE SET 
  team_name = EXCLUDED.team_name,
  current_round = 1,
  status = 'active';

-- Also clear out legacy demo keys if present
DELETE FROM teams WHERE team_key_hash LIKE 'CE-DEMO-%';

-- 3.1 SEED REGISTERED TEAM MEMBERS
DELETE FROM team_members WHERE team_id IN (SELECT id FROM teams WHERE team_key_hash LIKE 'CYB-%');

INSERT INTO team_members (team_id, member_name, member_identifier)
SELECT t.id, m.name, m.identifier
FROM teams t
JOIN (VALUES
  ('CYB-001', 'SWAR UMBARKAR', 'vu1f2627117 (FE/CE)'),
  ('CYB-001', 'HARSH KODAL', 'vu1f2627106 (FE/CE)'),
  ('CYB-001', 'JAYANT DALVI', 'vu1f2627105 (FE/CE)'),
  ('CYB-001', 'ROHAN BHUSAL', 'vu1f2627107 (FE/CE)'),
  ('CYB-002', 'SHLOK KHAIRNAR', 'vu1f2627115 (FE/CE)'),
  ('CYB-002', 'TANISH DAHIWALKAR', 'vu1f2627103 (FE/CE)'),
  ('CYB-002', 'SUSHANTH AVADHOOTHA', 'vu1f2627112 (FE/CE)'),
  ('CYB-002', 'KARAN CHAUDHARI', 'vu1f2627111 (FE/CE)'),
  ('CYB-003', '007_TASMIYA KAZI TE B', 'vu1s2425007 (BE/CE)'),
  ('CYB-003', '008_RIDDHI SAWANT TE B', 'vu1s2425008 (BE/CE)'),
  ('CYB-003', 'ANVITA KEER TE B', 'vu1s2425011 (BE/CE)'),
  ('CYB-003', '004_RIZWAN SHAIKH TE B', 'vu1s2425004 (BE/CE)'),
  ('CYB-004', 'Sulem Salim Shaikh', 'vu1s2526007 (TE/CE)'),
  ('CYB-004', 'DSE_002_Tanmay Mhatre', 'vu1s2526002 (TE/CE)'),
  ('CYB-004', 'B_DSE_020_HARSH SHINDE', 'vu1s2526020 (TE/CE)'),
  ('CYB-005', '4102_Subhodip_Mathur TE B Batch-A', 'vu1f2324102 (BE/CE)'),
  ('CYB-005', '4107_Sunnyy_Kadam TE-B Batch-A', 'vu1f2324107 (BE/CE)'),
  ('CYB-005', '4036_PRANIT JADHAV_TE-A-BATCH-B', 'vu1f2324036 (BE/CE)'),
  ('CYB-005', '4106_Siddhesh_Achrekar TE-B BATCH-A', 'vu1f2324106 (BE/CE)'),
  ('CYB-006', 'B076_OM BAILKAR', 'vu1f2526076 (SE/CE)'),
  ('CYB-006', 'RITESH RANE', 'vu1f2526092 (SE/CE)'),
  ('CYB-006', 'B086_VIGNESH PONNA', 'vu1f2526086 (SE/CE)'),
  ('CYB-006', 'OM JADHAV', 'vu1f2526071 (SE/CE)'),
  ('CYB-007', 'Pranav Godse', 'vu1f2425109 (TE/CE)'),
  ('CYB-007', 'Shravan Samalla', 'vu1f2425097 (TE/CE)'),
  ('CYB-007', 'RUSHIKESH TOKE', 'vu1f2425101 (TE/CE)'),
  ('CYB-007', 'HARSH SAKPAL', 'vu1f2425127 (TE/CE)'),
  ('CYB-008', '137_VAIDEHI MORE', 'vu1f2425137 (TE/CE)'),
  ('CYB-008', 'B_DSE_016_Raj Bhuran', 'vu1s2526016 (TE/CE)'),
  ('CYB-008', 'B_DSE_015_Dakshata Takarkhede', 'vu1s2526015 (TE/CE)'),
  ('CYB-008', 'AKSHITA GIDDE', 'vu1f2425088 (TE/CE)'),
  ('CYB-009', 'AARYAN DHARNE', 'vu1f2627042 (FE/CE)'),
  ('CYB-009', 'KUNAL RAJPUT', 'vu1f2627037 (FE/CE)'),
  ('CYB-009', 'VYAS GALI', 'vu1f2627044 (FE/CE)'),
  ('CYB-009', 'ANSHUMAAN PANDEY', 'vu1f2627034 (FE/CE)'),
  ('CYB-010', 'B_DSE_003_Kunal Jadhav', 'vu1s2526003 (TE/CE)'),
  ('CYB-010', 'DSE_010_Yaseen Shaikh', 'vu1s2526010 (TE/CE)'),
  ('CYB-010', 'DSE_008_Owais Mukri', 'vu1s2526008 (TE/CE)'),
  ('CYB-011', '002_MUHAMMAD UMAR CHIKTE TE B', 'vu1s2425002 (BE/CE)'),
  ('CYB-011', '001_ARYAN TAMBE TE B', 'vu1s2425001 (BE/CE)'),
  ('CYB-011', 'sayed mohammad', 'sayedmohammadi276 (BE/CE)'),
  ('CYB-012', 'Tanvira Shaikh', 'vu1s2526006 (TE/CE)'),
  ('CYB-012', 'Rohit Pardeshi', 'vu2s2627013 (SE/AI&DS)'),
  ('CYB-012', 'DSE_017_Najma shaikh', 'vu1s2526017 (TE/CE)'),
  ('CYB-012', 'OMKAR CHAVAN', 'vu7s2t2526012 (TE/MECH)'),
  ('CYB-013', '078_Gaurav', 'vu1f2425078 (TE/CE)'),
  ('CYB-013', 'B_Jay Davane_083', 'vu1f2425083 (TE/CE)'),
  ('CYB-013', 'B_132_ Sanjana Gupta', 'vu1f2425132 (TE/CE)'),
  ('CYB-013', 'B_095_ Bhargavi Nimbre', 'vu1f2425095 (TE/CE)'),
  ('CYB-014', 'Vedant Sonawane', 'vu1f2627120 (FE/CE)')
) AS m(key, name, identifier) ON t.team_key_hash = m.key;

-- 4. VERIFY ROUND CODE RPC (NODE, HASH, LOCK, PORT)
DROP FUNCTION IF EXISTS public.verify_round_code(uuid, integer, text) CASCADE;
DROP FUNCTION IF EXISTS public.verify_round_code(text, integer, text) CASCADE;

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
    v_valid BOOLEAN := FALSE;
    v_word TEXT := '';
BEGIN
    v_code := UPPER(TRIM(p_submitted_code));

    IF p_round_number = 1 THEN
        v_word := 'THINK';
        IF v_code IN ('NODE', 'ONED', 'CYBR', 'CYBER1') THEN
            v_valid := TRUE;
        END IF;
    ELSIF p_round_number = 2 THEN
        v_word := 'BEFORE';
        IF v_code IN ('HASH', 'SHAH', 'GRID') THEN
            v_valid := TRUE;
        END IF;
    ELSIF p_round_number = 3 THEN
        v_word := 'YOU';
        IF v_code IN ('LOCK', 'CLKO', 'BYTE') THEN
            v_valid := TRUE;
        END IF;
    ELSIF p_round_number = 4 THEN
        v_word := 'ESCAPE';
        IF v_code IN ('PORT', 'OPTR', 'CODE') THEN
            v_valid := TRUE;
        END IF;
    ELSE
        RETURN jsonb_build_object('success', false, 'error', 'Invalid round');
    END IF;

    IF v_valid THEN
        INSERT INTO team_words (team_id, round_number, word, unlocked_at)
        VALUES (p_team_id, p_round_number, v_word, NOW())
        ON CONFLICT (team_id, round_number) 
        DO UPDATE SET word = v_word, unlocked_at = NOW();

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
            'error', 'Incorrect security code. Check your unlocked letters and try again.'
        );
    END IF;
END;
$$;

-- 5. SUBMIT FINAL RIDDLE ANSWER RPC (Supports Internet & A Map)
DROP FUNCTION IF EXISTS public.submit_final_riddle_answer(uuid, text) CASCADE;

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
    v_clean TEXT;
    v_now TIMESTAMPTZ := NOW();
BEGIN
    SELECT COUNT(*) INTO v_attempts_count 
    FROM final_attempts 
    WHERE team_id = p_team_id;

    IF v_attempts_count >= 2 THEN
        RETURN jsonb_build_object('success', false, 'error', 'No attempts remaining.');
    END IF;

    v_clean := UPPER(TRIM(p_submitted_answer));

    -- Validates both Master Riddle 1 (Internet) and Master Riddle 2 (A Map)
    IF v_clean IN ('INTERNET', 'THE INTERNET') OR v_clean IN ('A MAP', 'MAP', 'THE MAP') OR v_clean = 'CODE' THEN
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

-- 6. ADMIN TRANSITION GAME STATE RPC
DROP FUNCTION IF EXISTS public.admin_set_game_state(text, integer, text);
DROP FUNCTION IF EXISTS public.admin_set_game_state(text, text, integer);

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

-- 7. ADMIN CONFIRM & PUBLISH ROUND SELECTIONS RPC
DROP FUNCTION IF EXISTS public.admin_confirm_round_selections(text, integer, uuid[]) CASCADE;

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

    INSERT INTO round_selections (team_id, round_number, selected, notes, selected_at)
    SELECT id, p_round_number, (id = ANY(p_selected_team_ids)), 
           CASE WHEN id = ANY(p_selected_team_ids) THEN 'confirmed' ELSE 'eliminated' END, 
           NOW()
    FROM teams
    ON CONFLICT (team_id, round_number) 
    DO UPDATE SET selected = EXCLUDED.selected, 
                  notes = CASE WHEN EXCLUDED.selected THEN 'confirmed' ELSE 'eliminated' END,
                  selected_at = NOW();

    UPDATE teams 
    SET current_round = CASE WHEN id = ANY(p_selected_team_ids) THEN p_round_number + 1 ELSE current_round END,
        status = CASE WHEN id = ANY(p_selected_team_ids) THEN 'selected' ELSE 'eliminated' END
    WHERE id IS NOT NULL;

    INSERT INTO audit_logs (admin_id, action, round_number, metadata)
    VALUES ('admin', 'CONFIRM_SELECTION', p_round_number, jsonb_build_object('selected_count', array_length(p_selected_team_ids, 1)));

    RETURN jsonb_build_object('success', true, 'selected_count', array_length(p_selected_team_ids, 1));
END;
$$;

DROP FUNCTION IF EXISTS public.admin_publish_round_selections(text, integer, uuid[]) CASCADE;

CREATE OR REPLACE FUNCTION admin_publish_round_selections(
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

    INSERT INTO round_selections (team_id, round_number, selected, notes, selected_at)
    SELECT id, p_round_number, (id = ANY(p_selected_team_ids)), 
           CASE WHEN id = ANY(p_selected_team_ids) THEN 'published' ELSE 'pending' END, 
           NOW()
    FROM teams
    ON CONFLICT (team_id, round_number) 
    DO UPDATE SET selected = EXCLUDED.selected, 
                  notes = CASE WHEN EXCLUDED.selected THEN 'published' ELSE 'pending' END,
                  selected_at = NOW();

    UPDATE teams 
    SET status = 'selected'
    WHERE id = ANY(p_selected_team_ids);

    INSERT INTO audit_logs (admin_id, action, round_number, metadata)
    VALUES ('admin', 'PUBLISH_SELECTION', p_round_number, jsonb_build_object('selected_count', array_length(p_selected_team_ids, 1)));

    RETURN jsonb_build_object('success', true, 'selected_count', array_length(p_selected_team_ids, 1));
END;
$$;

-- 8. ATOMIC ADMIN RESET EVENT RPC
DROP FUNCTION IF EXISTS public.admin_reset_event(text) CASCADE;

CREATE OR REPLACE FUNCTION admin_reset_event(p_admin_key TEXT)
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
    SET current_state = 'LANDING',
        current_round = 1,
        round_timer_seconds = 300,
        timer_started_at = NOW(),
        started_at = NOW(),
        updated_at = NOW()
    WHERE id IS NOT NULL;

    UPDATE teams 
    SET status = 'active',
        current_round = 1,
        updated_at = NOW()
    WHERE id IS NOT NULL;

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

-- 9. SUBMIT QUESTION ANSWER RPC (Normalizes Whitespace & Commas)
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
    SELECT * INTO v_question 
    FROM questions 
    WHERE round_number = p_round_number AND question_number = p_question_number;
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Question not found');
    END IF;

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

    INSERT INTO team_questions (
        team_id, round_number, question_number, attempt_number,
        submitted_answer, is_correct, time_taken_seconds, submitted_at
    ) VALUES (
        p_team_id, p_round_number, p_question_number, v_attempt_count + 1,
        p_submitted_answer, v_is_correct, p_time_taken, NOW()
    );

    INSERT INTO round_results (team_id, round_number, score, questions_solved, total_time_seconds, attempts_count)
    VALUES (p_team_id, p_round_number, CASE WHEN v_is_correct THEN 10 ELSE 0 END, CASE WHEN v_is_correct THEN 1 ELSE 0 END, p_time_taken, 1)
    ON CONFLICT (team_id, round_number)
    DO UPDATE SET
        score = round_results.score + (CASE WHEN v_is_correct THEN 10 ELSE 0 END),
        questions_solved = round_results.questions_solved + (CASE WHEN v_is_correct THEN 1 ELSE 0 END),
        total_time_seconds = round_results.total_time_seconds + p_time_taken,
        attempts_count = round_results.attempts_count + 1,
        completed_at = NOW();

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

-- 10. CLEAR PREVIOUS QUESTIONS FOR ALL ROUNDS TO AVOID STALE QUESTIONS
DELETE FROM questions WHERE round_number IN (1, 2, 3, 4);

-- 11. INSERT ROUND 1 MCQs (15 User Questions)
INSERT INTO questions (round_number, question_number, question_type, difficulty, question_data, correct_answer, time_limit_seconds, hint_data)
VALUES
(1, 1, 'mcq', 'easy', '{
  "question": "Which device is commonly used to connect multiple computers in a network?",
  "options": ["Switch", "Keyboard", "Scanner", "Monitor"]
}', 'Switch', 60, 'It operates at the Data Link Layer and forwards frames to specific MAC addresses.'),

(1, 2, 'mcq', 'easy', '{
  "question": "Which one is NOT a programming language?",
  "options": ["Python", "Java", "C++", "Chrome"]
}', 'Chrome', 60, 'One of these is a web browser developed by Google.'),

(1, 3, 'mcq', 'easy', '{
  "question": "What will be the output of this Python code?\n\nx = 5\nx = x + 2\nprint(x)",
  "options": ["5", "7", "2", "52"]
}', '7', 60, 'Initial value is 5, then incremented by 2.'),

(1, 4, 'mcq', 'easy', '{
  "question": "What does == generally mean in programming?",
  "options": ["Assignment", "Comparison for equality", "Addition", "Not equal"]
}', 'Comparison for equality', 60, 'Single = assigns values; double == evaluates whether two expressions are equal.'),

(1, 5, 'mcq', 'medium', '{
  "question": "If a program takes 1 second to check each item in a list of 100 items one by one, what happens approximately if the list has 200 items?",
  "options": ["It may take around 2 seconds", "It will always take 1 second", "It will take 100 seconds", "It cannot be determined"]
}', 'It may take around 2 seconds', 60, 'Linear O(n) scan scales directly with the number of elements in the list.'),

(1, 6, 'mcq', 'easy', '{
  "question": "A website URL starts with https://. What does the S mainly indicate?",
  "options": ["The website is faster", "The connection is secured using encryption", "The website is free", "The website has no advertisements"]
}', 'The connection is secured using encryption', 60, 'It indicates SSL/TLS encrypted network communication.'),

(1, 7, 'mcq', 'medium', '{
  "question": "Which layer of the OSI model is responsible for routing packets?",
  "options": ["Data Link", "Network", "Transport", "Session"]
}', 'Network', 60, 'Routers inspect IP packet headers at Layer 3 of the OSI stack.'),

(1, 8, 'mcq', 'easy', '{
  "question": "What does URL stand for?",
  "options": ["Uniform Resource Locator", "Universal Routing Link", "Uniform Reference Link", "Unified Resource Location"]
}', 'Uniform Resource Locator', 60, 'The standard web address identifier specifying resource location.'),

(1, 9, 'mcq', 'easy', '{
  "question": "What does SQL primarily deal with?",
  "options": ["Image processing", "Databases", "Operating systems", "Network cables"]
}', 'Databases', 60, 'Structured Query Language manages relational database management systems.'),

(1, 10, 'mcq', 'easy', '{
  "question": "Which HTML tag is used to create a hyperlink?",
  "options": ["<link>", "<a>", "<href>", "<url>"]
}', '<a>', 60, 'The anchor tag with href attribute embeds hyperlinks in HTML documents.'),

(1, 11, 'mcq', 'easy', '{
  "question": "Which of the following is NOT an operating system?",
  "options": ["Linux", "Windows", "Oracle", "macOS"]
}', 'Oracle', 60, 'Oracle is renowned as an enterprise database and software vendor, not an OS.'),

(1, 12, 'mcq', 'medium', '{
  "question": "Which data structure follows the LIFO principle?",
  "options": ["Queue", "Stack", "Linked List", "Tree"]
}', 'Stack', 60, 'Last In, First Out like a stack of cafeteria trays or call stack frames.'),

(1, 13, 'mcq', 'medium', '{
  "question": "Which HTTP status code means \"Not Found\"?",
  "options": ["200", "301", "404", "500"]
}', '404', 60, 'Standard HTTP client error code returned when resource is missing.'),

(1, 14, 'mcq', 'medium', '{
  "question": "In Git, which command is used to create a copy of a remote repository?",
  "options": ["git push", "git clone", "git merge", "git commit"]
}', 'git clone', 60, 'Downloads the complete remote repository tree and git revision history.'),

(1, 15, 'mcq', 'hard', '{
  "question": "A user receives an email that appears to come from their bank and asks them to click a link and verify their password. What is the most likely attack?",
  "options": ["Phishing", "DDoS", "Buffer Overflow", "Port Scanning"]
}', 'Phishing', 60, 'Social engineering deception designed to steal authentication credentials.');

-- 12. INSERT ROUND 2 CROSSWORDS (2 Crosswords)
INSERT INTO questions (round_number, question_number, question_type, difficulty, question_data, correct_answer, time_limit_seconds, hint_data)
VALUES
(2, 1, 'crossword', 'easy', '{
  "title": "Crossword 1: Digital Basics",
  "difficultyLabel": "EASY - DIGITAL BASICS",
  "gridRows": 6,
  "gridCols": 9,
  "gridSize": 9,
  "words": [
    {"id": 1, "number": 1, "direction": "across", "clue": "A value that can be either True or False (7)", "answer": "BOOLEAN", "row": 0, "col": 0},
    {"id": 2, "number": 2, "direction": "across", "clue": "A step-by-step set of instructions used to solve a problem (9)", "answer": "ALGORITHM", "row": 1, "col": 0},
    {"id": 3, "number": 3, "direction": "across", "clue": "A collection of related files stored under one name (6)", "answer": "FOLDER", "row": 3, "col": 3},
    {"id": 4, "number": 4, "direction": "down", "clue": "A copy of important data kept so it can be recovered later (6)", "answer": "BACKUP", "row": 0, "col": 0},
    {"id": 5, "number": 5, "direction": "down", "clue": "A software problem that may cause a program to behave unexpectedly (5)", "answer": "ERROR", "row": 0, "col": 4}
  ]
}', 'COMPLETED', 300, 'Think about fundamental computing concepts: Algorithm, Boolean logic, Folders, Data Backups, and Software Errors.'),

(2, 2, 'crossword', 'medium', '{
  "title": "Crossword 2: Network & Programming",
  "difficultyLabel": "MEDIUM - NETWORK & PROGRAMMING",
  "gridRows": 8,
  "gridCols": 13,
  "gridSize": 13,
  "words": [
    {"id": 1, "number": 1, "direction": "across", "clue": "A variable that stores a sequence of characters (6)", "answer": "STRING", "row": 1, "col": 0},
    {"id": 2, "number": 2, "direction": "across", "clue": "A system used to store and organize large amounts of data (8)", "answer": "DATABASE", "row": 3, "col": 0},
    {"id": 3, "number": 3, "direction": "across", "clue": "Your code runs but gives the wrong answer. You search for the mistake and fix it. What is this process called? (9)", "answer": "DEBUGGING", "row": 6, "col": 4},
    {"id": 4, "number": 4, "direction": "down", "clue": "A set of rules that allows two devices or systems to communicate (8)", "answer": "PROTOCOL", "row": 0, "col": 2},
    {"id": 5, "number": 5, "direction": "down", "clue": "A message sent from one computer or device to another through a network (6)", "answer": "PACKET", "row": 2, "col": 5}
  ]
}', 'COMPLETED', 300, 'Consider key networking and programming practices: Debugging, Database systems, String variables, Network Protocols, and Data Packets.');

-- 13. INSERT ROUND 3 BINARY QUESTIONS (4 Questions)
INSERT INTO questions (round_number, question_number, question_type, difficulty, question_data, correct_answer, time_limit_seconds, hint_data)
VALUES
(3, 1, 'binary', 'easy', '{
  "binary": "01001100 01001111 01000011 01001011\n01001001 01010100",
  "instruction": "Decode the 2-word system instruction from the incoming 8-bit binary bitstream."
}', 'LOCK IT', 60, 'First word: L-O-C-K (76, 79, 67, 75); Second word: I-T (73, 84).'),

(3, 2, 'binary', 'easy', '{
  "binary": "01000011 01001000 01000101 01000011 01001011\n01001001 01010100",
  "instruction": "Decode the 2-word integrity verification command from the 8-bit stream."
}', 'CHECK IT', 60, 'First word: C-H-E-C-K (67, 72, 69, 67, 75); Second word: I-T (73, 84).'),

(3, 3, 'binary', 'medium', '{
  "binary": "01000110 01001001 01001110 01000100\n01010100 01001000 01000101\n01001011 01000101 01011001",
  "instruction": "Decode the 3-word cryptographic puzzle clue from the binary bitstream."
}', 'FIND THE KEY', 60, 'Three words: F-I-N-D (70, 73, 78, 68), T-H-E (84, 72, 69), K-E-Y (75, 69, 89).'),

(3, 4, 'binary', 'hard', '{
  "binary": "01000110 01001111 01001100 01001100 01001111 01010111\n01010100 01001000 01000101\n01010000 01000001 01010100 01001000",
  "instruction": "Decode the 3-word system navigation route instruction from the binary bitstream."
}', 'FOLLOW THE PATH', 60, 'Three words: F-O-L-L-O-W (70, 79, 76, 76, 79, 87), T-H-E (84, 72, 69), P-A-T-H (80, 65, 84, 72).');

-- 14. INSERT ROUND 4 CODE BLANKS (4 Questions)
INSERT INTO questions (round_number, question_number, question_type, difficulty, question_data, correct_answer, time_limit_seconds, hint_data)
VALUES
(4, 1, 'code_fill', 'easy', '{
  "title": "Vowel Filter Character Check",
  "description": "Inspect the vowel counter loop. Complete the condition by identifying the missing uppercase vowel character in BLANK_1.",
  "blanksCount": 1,
  "labels": ["Missing uppercase vowel (e.g. ''I'')"],
  "snippets": {
    "cpp": "string s = \"CYBER\";\nint count = 0;\n\nfor (char c : s) {\n    if (c == ''A'' || c == ''E'' || c == /* BLANK_1 */ ||\n        c == ''O'' || c == ''U'')\n        count++;\n}\n\ncout << count;",
    "python": "s = \"CYBER\"\ncount = 0\n\nfor c in s:\n    if c in [''A'', ''E'', /* BLANK_1 */, ''O'', ''U'']:\n        count += 1\n\nprint(count)",
    "java": "String s = \"CYBER\";\nint count = 0;\n\nfor (char c : s.toCharArray()) {\n    if (c == ''A'' || c == ''E'' || c == /* BLANK_1 */ ||\n        c == ''O'' || c == ''U'')\n        count++;\n}\n\nSystem.out.println(count);"
  }
}', '''I''', 90, 'The 5 standard vowels are A, E, I, O, U; BLANK_1 is character literal ''I''.'),

(4, 2, 'code_fill', 'medium', '{
  "title": "The Second Highest Signal",
  "description": "Fill the missing tracking assignments in BLANK_1 and BLANK_2 to accurately store the second highest value in the signal array.",
  "blanksCount": 2,
  "labels": ["Previous maximum assignment", "Update second largest from current element"],
  "snippets": {
    "cpp": "int a[] = {12, 5, 18, 7, 15};\nint max = a[0], second = a[1];\n\nfor (int i = 1; i < 5; i++) {\n    if (a[i] > max) {\n        second = /* BLANK_1 */;\n        max = a[i];\n    }\n    else if (a[i] > second)\n        second = /* BLANK_2 */;\n}\n\ncout << second;",
    "python": "a = [12, 5, 18, 7, 15]\nmax_val = a[0]\nsecond = a[1]\n\nfor i in range(1, 5):\n    if a[i] > max_val:\n        second = /* BLANK_1 */\n        max_val = a[i]\n    elif a[i] > second:\n        second = /* BLANK_2 */\n\nprint(second)",
    "java": "int a[] = {12, 5, 18, 7, 15};\nint max = a[0], second = a[1];\n\nfor (int i = 1; i < 5; i++) {\n    if (a[i] > max) {\n        second = /* BLANK_1 */;\n        max = a[i];\n    }\n    else if (a[i] > second)\n        second = /* BLANK_2 */;\n}\n\nSystem.out.println(second);"
  }
}', 'max,a[i]', 90, 'When a new max is found, second becomes the old max. If current element is between second and max, second becomes a[i].'),

(4, 3, 'code_fill', 'medium', '{
  "title": "Find the Second Largest Number",
  "description": "Initialize second largest in BLANK_1, update previous largest in BLANK_2, and capture alternate candidate in BLANK_3.",
  "blanksCount": 3,
  "labels": ["Initial second candidate", "Demoted largest variable", "Current candidate element"],
  "snippets": {
    "cpp": "int a[] = {12, 5, 18, 7};\nint largest = a[0];\nint second = /* BLANK_1 */;\n\nfor (int i = 1; i < 4; i++) {\n    if (a[i] > largest) {\n        second = /* BLANK_2 */;\n        largest = a[i];\n    }\n    else if (a[i] > second && a[i] != largest) {\n        second = /* BLANK_3 */;\n    }\n}\n\ncout << second;",
    "python": "a = [12, 5, 18, 7]\nlargest = a[0]\nsecond = /* BLANK_1 */\n\nfor i in range(1, 4):\n    if a[i] > largest:\n        second = /* BLANK_2 */\n        largest = a[i]\n    elif a[i] > second and a[i] != largest:\n        second = /* BLANK_3 */\n\nprint(second)",
    "java": "int a[] = {12, 5, 18, 7};\nint largest = a[0];\nint second = /* BLANK_1 */;\n\nfor (int i = 1; i < 4; i++) {\n    if (a[i] > largest) {\n        second = /* BLANK_2 */;\n        largest = a[i];\n    }\n    else if (a[i] > second && a[i] != largest) {\n        second = /* BLANK_3 */;\n    }\n}\n\nSystem.out.println(second);"
  }
}', 'a[1],largest,a[i]', 90, 'BLANK_1 initializes to a[1]; BLANK_2 demotes largest into second; BLANK_3 assigns current element a[i].'),

(4, 4, 'code_fill', 'hard', '{
  "title": "The Final Lock (Palindrome Verification)",
  "description": "Determine the arithmetic base constant required across all three operations to reverse the digits of integer n.",
  "blanksCount": 3,
  "labels": ["Digit multiplier (Base 10)", "Digit extraction modulo (Base 10)", "Digit reduction divisor (Base 10)"],
  "snippets": {
    "cpp": "int n = 1221;\nint original = n;\nint rev = 0;\n\nwhile (n > 0) {\n    rev = rev * /* BLANK_1 */ + n % /* BLANK_2 */;\n    n = n / /* BLANK_3 */;\n}\n\nif (original == rev)\n    cout << \"ACCESS GRANTED\";\nelse\n    cout << \"ACCESS DENIED\";",
    "python": "n = 1221\noriginal = n\nrev = 0\n\nwhile n > 0:\n    rev = rev * /* BLANK_1 */ + n % /* BLANK_2 */\n    n = n // /* BLANK_3 */\n\nif original == rev:\n    print(\"ACCESS GRANTED\")\nelse:\n    print(\"ACCESS DENIED\")",
    "java": "int n = 1221;\nint original = n;\nint rev = 0;\n\nwhile (n > 0) {\n    rev = rev * /* BLANK_1 */ + n % /* BLANK_2 */;\n    n = n / /* BLANK_3 */;\n}\n\nif (original == rev)\n    System.out.println(\"ACCESS GRANTED\");\nelse\n    System.out.println(\"ACCESS DENIED\");"
  }
}', '10,10,10', 90, 'Decimal integers are base 10; multiply rev by 10, extract remainder modulo 10, and divide n by 10.');

-- 12. RPC PERMISSIONS FOR CLIENT AND ANON ACCESS
GRANT EXECUTE ON FUNCTION validate_admin_key(TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION validate_team_key(TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION verify_round_code(UUID, INT, TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION submit_final_riddle_answer(UUID, TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION admin_set_game_state(TEXT, TEXT, INT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION admin_confirm_round_selections(TEXT, INT, UUID[]) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION admin_publish_round_selections(TEXT, INT, UUID[]) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION admin_reset_event(TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION submit_question_answer(UUID, INT, INT, TEXT, NUMERIC) TO anon, authenticated;

-- 13. PUBLIC QUESTIONS SECURE VIEW (Hides answers from clients while exposing options and questions)
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


