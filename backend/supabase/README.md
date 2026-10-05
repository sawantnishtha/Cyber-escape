# CYBER ESCAPE — SUPABASE DATABASE SETUP & CONTENT REPLACEMENT GUIDE
Presented by **CESA — Department of Computer Engineering**

This directory contains the database migration scripts, Row-Level-Security (RLS) policies, secure evaluation procedures (RPC), and demo seed data.

---

## 1. Quick Setup in Supabase Dashboard

1. Create a project at [supabase.com](https://supabase.com).
2. Go to the **SQL Editor** tab in your Supabase project dashboard.
3. Execute the SQL scripts in this exact order:
   - `migrations/01_initial_schema.sql` (Creates all tables, relationships, and enables Realtime publication)
   - `migrations/02_rls_policies.sql` (Applies security policies and creates `public_questions` view)
   - `migrations/03_rpc_functions.sql` (Installs server-side evaluation functions for questions, codes, and state transitions)
   - `seed/seed_demo_data.sql` (Seeds 15 demo teams, round configurations, 8 MCQs, 2 crosswords, 4 binary questions, 4 coding questions)
4. Under **Project Settings -> API**, copy:
   - `Project URL` -> Paste into `.env` as `VITE_SUPABASE_URL`
   - `Project API anon key` -> Paste into `.env` as `VITE_SUPABASE_ANON_KEY`
5. Ensure Realtime is enabled for the project (under Database -> Replication, `supabase_realtime` publication should be active).

---

## 2. Replacing Demo Content with Actual Competition Content

You **do not need to rebuild or touch any React code** to replace the questions, answers, codes, or words. All content is entirely data-driven!

### A. Updating Round 1 (MCQs)
In the `questions` table where `round_number = 1`:
```sql
UPDATE questions 
SET question_data = jsonb_build_object(
      'question', 'Your actual question text here',
      'options', jsonb_build_array('Option A', 'Option B', 'Option C', 'Option D')
    ),
    correct_answer = 'Option A',
    hint_data = 'Your hint text'
WHERE round_number = 1 AND question_number = 1;
```

### B. Updating Round 2 (Crosswords)
In the `questions` table where `round_number = 2`:
Modify `question_data` JSON with your custom words, clues, and coordinates (`row`, `col`, `direction`, `clue`, `answer`).

### C. Updating Round 3 (Binary-to-ASCII)
In the `questions` table where `round_number = 3`:
```sql
UPDATE questions 
SET question_data = jsonb_build_object('binary', '01001011', 'instruction', 'Decode 8-bit binary to ASCII'),
    correct_answer = 'K',
    hint_data = 'Decimal value is 75'
WHERE round_number = 3 AND question_number = 1;
```

### D. Updating Round 4 (Coding Blanks)
In the `questions` table where `round_number = 4`:
Update `snippets` (`cpp`, `python`, `java`) containing `/* blank_0 */`, `/* blank_1 */`, and set `correct_answer` to comma-separated expected values (e.g. `low,+`).

### E. Updating Secret Codes and Round Words
In `03_rpc_functions.sql`, the function `verify_round_code()` controls the expected codes and revealed words:
- Round 1 Word: e.g. `THINK` (Code: `CYBER1`)
- Round 2 Word: e.g. `BEFORE` (Code: `TECH2`)
- Round 3 Word: e.g. `YOU` (Code: `BYTE3`)
- Round 4 Word: e.g. `ESCAPE` (Code: `CODE4`)

### F. Updating Final Riddle & Final Answer
In `03_rpc_functions.sql`, `submit_final_riddle_answer()` holds the target answer for the combined riddle formed by the 4 round words.

---

## 3. Team Management
- Add teams by inserting into the `teams` table with `team_name` and a unique `team_key_hash` (e.g. `CE-98X2-KP`).
- Teams authenticate purely via their key; the system automatically retrieves their assigned name and active round.
