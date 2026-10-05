# 🛡️ Cyber Escape — Backend Documentation

This directory contains the database schemas, SQL migrations, triggers, security policies (Row-Level Security), and RPC functions that power the **Cyber Escape Room Competition Platform**.

---

## 📁 Directory Structure

```
backend/
├── README.md                               # This documentation file
├── api-spec.md                             # Complete specification of backend tables & RPC endpoints
└── supabase/
    ├── COMPLETE_SETUP_ALL_IN_ONE.sql       # Full database creation script with initial seeds
    ├── RUN_THIS_IN_SUPABASE_SQL_EDITOR.sql # Master patch containing all updated RPCs & seeds
    ├── migrations/
    │   ├── 01_initial_schema.sql           # Tables, constraints, and indexes
    │   ├── 02_rls_policies.sql             # Row Level Security (RLS) policies
    │   └── 03_rpc_functions.sql            # Stored procedures & anti-cheat verification RPCs
    └── seed/
        └── seed_demo_data.sql              # Seed teams, questions, and session defaults
```

---

## 🗄️ Database Architecture

The backend is built on **PostgreSQL via Supabase**. The frontend connects directly via the **Supabase JavaScript Client** (`@supabase/supabase-js`) using the `anon` public key, guarded by strict Row Level Security (RLS) and server-side RPC functions.

### Core Tables:

1. **`game_session`**:
   - Single-row table tracking competition state: `LANDING`, `R1_ACTIVE`, `R1_WAITING`, `R1_RESULT`, `R2_ACTIVE`, `R2_WAITING`, `R2_RESULT`, `R3_ACTIVE`, `R3_WAITING`, `R3_RESULT`, `R4_ACTIVE`, `R4_WAITING`, `R4_RESULT`, `FINAL_RESULT`.
   - Stores current round timer, countdown timestamps, and session ID.

2. **`teams`**:
   - All 8 competing teams (`Alpha Squad`, `Byte Bandits`, `Cipher Core`, `Data Dynamos`, `Echo Enigma`, `Firewall Force`, `Glitch Guardians`, `Hex Heroes`).
   - Stores team credentials (`team_key`), qualification status (`active`, `waiting`, `selected`, `not_selected`, `disqualified`), and current round.

3. **`questions` & `public_questions` (View)**:
   - Contains challenge questions across all 4 rounds.
   - `public_questions` securely strips sensitive answers so clients cannot inspect answers in the network tab.

4. **`team_questions`**:
   - Stores team attempts, correctness (`is_correct`), hints requested, and response times.

5. **`round_results`**:
   - Aggregated team scores, questions solved, total elapsed time, hints count, and code completion status (`code_completed`).

6. **`team_words`**:
   - Stores unlocked secret key words (`THINK`, `CYBER`, `STAY`, `SAFE`) when teams successfully submit the 4-letter round security codes.

7. **`round_selections`**:
   - Tracks which teams were selected by the Admin to advance past each round's cutoff.

8. **`final_attempts`**:
   - Tracks final riddle answer submissions for the championship tiebreaker.

9. **`audit_logs`**:
   - Immutable security and admin activity logs (game state changes, resets, winner declarations).

---

## ⚡ Stored Procedures / RPC Functions

All critical game logic executes server-side to guarantee fairness and eliminate client-side cheating:

| Function Name | Parameters | Purpose |
|---|---|---|
| `validate_team_key(p_key)` | `p_key text` | Validates team login key and returns team details |
| `validate_admin_key(p_key)` | `p_key text` | Validates admin master key |
| `verify_round_code(p_team_id, p_round_number, p_submitted_code)` | `uuid, int, text` | Verifies the 4-letter round code (`CYBR`, `TECH`, `BYTE`, `CODE`), unlocks the secret word, and sets `code_completed = true` |
| `submit_question_answer(p_team_id, p_round_number, p_question_number, p_submitted_answer, p_time_taken)` | `uuid, int, int, text, numeric` | Evaluates submitted answer, limits attempts, awards points, and calculates time bonuses |
| `request_question_hint(p_team_id, p_round_number, p_question_number)` | `uuid, int, int` | Deducts points and reveals a hint |
| `submit_final_riddle_answer(p_team_id, p_submitted_answer)` | `uuid, text` | Evaluates the 4-word final riddle solution and records microsecond timestamp |
| `admin_set_game_state(p_admin_key, p_new_state, p_new_round)` | `text, text, int` | Transitions tournament state and syncs timers across all participants |
| `admin_confirm_round_selections(p_admin_key, p_round_number, p_selected_team_ids)` | `text, int, uuid[]` | Advances selected teams and marks non-selected teams for elimination |
| `admin_reset_event(p_admin_key)` | `text` | Resets the tournament back to Round 1, clears all progress, resets teams to active |

---

## 🚀 How to Setup / Update Supabase

1. Open your Supabase Dashboard: [https://supabase.com/dashboard](https://supabase.com/dashboard).
2. Go to the **SQL Editor** on the left menu.
3. Open `backend/supabase/RUN_THIS_IN_SUPABASE_SQL_EDITOR.sql` (or copy its contents).
4. Paste it into the SQL Editor and click **Run**.
5. Once complete, your backend database is fully equipped and ready!
