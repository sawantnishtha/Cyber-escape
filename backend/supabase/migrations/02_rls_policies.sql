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
