# 📡 Cyber Escape — Backend API & RPC Specification

This document details the interface between the **Frontend API Layer** (`frontend/src/api/`) and the **Backend Database & RPC Layer** (`backend/supabase/`).

---

## 1. Authentication Endpoints

### `validate_team_key`
- **Type**: RPC Function
- **Endpoint**: `POST /rest/v1/rpc/validate_team_key`
- **Payload**:
  ```json
  {
    "p_key": "ALPHA-2026"
  }
  ```
- **Response**:
  ```json
  {
    "success": true,
    "team": {
      "id": "11111111-1111-1111-1111-111111111111",
      "team_name": "Alpha Squad",
      "status": "active",
      "current_round": 1
    }
  }
  ```

### `validate_admin_key`
- **Type**: RPC Function
- **Endpoint**: `POST /rest/v1/rpc/validate_admin_key`
- **Payload**:
  ```json
  {
    "p_key": "ADMIN-CYBER-2026"
  }
  ```
- **Response**:
  ```json
  {
    "success": true,
    "admin": {
      "id": "admin",
      "username": "SuperAdmin",
      "role": "superadmin"
    }
  }
  ```

---

## 2. Game Session Endpoints

### `getGameSession`
- **Type**: Table Query
- **Endpoint**: `GET /rest/v1/game_session?select=*&limit=1`
- **Response**:
  ```json
  {
    "id": "e0000000-0000-0000-0000-000000000001",
    "session_name": "CYBER_ESCAPE_2026",
    "current_state": "LANDING",
    "current_round": 1,
    "round_timer_seconds": 300,
    "timer_started_at": "2026-10-05T14:00:00Z"
  }
  ```

---

## 3. Question & Answer Endpoints

### `public_questions`
- **Type**: View Query
- **Endpoint**: `GET /rest/v1/public_questions?round_number=eq.1&order=question_number.asc`
- **Description**: Returns questions with all clues and options, but answers stripped for security.

### `submit_question_answer`
- **Type**: RPC Function
- **Endpoint**: `POST /rest/v1/rpc/submit_question_answer`
- **Payload**:
  ```json
  {
    "p_team_id": "11111111-1111-1111-1111-111111111111",
    "p_round_number": 1,
    "p_question_number": 1,
    "p_submitted_answer": "B",
    "p_time_taken": 8.5
  }
  ```
- **Response**:
  ```json
  {
    "success": true,
    "is_correct": true,
    "points_awarded": 100,
    "time_bonus": 15,
    "total_score": 115,
    "attempts_left": 1
  }
  ```

---

## 4. Security Code Verification Endpoints

### `verify_round_code`
- **Type**: RPC Function
- **Endpoint**: `POST /rest/v1/rpc/verify_round_code`
- **Payload**:
  ```json
  {
    "p_team_id": "11111111-1111-1111-1111-111111111111",
    "p_round_number": 1,
    "p_submitted_code": "CYBR"
  }
  ```
- **Response**:
  ```json
  {
    "success": true,
    "valid": true,
    "word": "THINK",
    "message": "Security code verified! Keyword unlocked: THINK"
  }
  ```

### `submit_final_riddle_answer`
- **Type**: RPC Function
- **Endpoint**: `POST /rest/v1/rpc/submit_final_riddle_answer`
- **Payload**:
  ```json
  {
    "p_team_id": "11111111-1111-1111-1111-111111111111",
    "p_submitted_answer": "THINK CYBER STAY SAFE"
  }
  ```
- **Response**:
  ```json
  {
    "success": true,
    "is_correct": true,
    "submitted_at": "2026-10-05T14:45:00.123456Z"
  }
  ```

---

## 5. Admin Tournament Control Endpoints

### `admin_set_game_state`
- **Type**: RPC Function
- **Endpoint**: `POST /rest/v1/rpc/admin_set_game_state`
- **Payload**:
  ```json
  {
    "p_admin_key": "ADMIN-CYBER-2026",
    "p_new_state": "R1_ACTIVE",
    "p_new_round": 1
  }
  ```

### `admin_confirm_round_selections`
- **Type**: RPC Function
- **Endpoint**: `POST /rest/v1/rpc/admin_confirm_round_selections`
- **Payload**:
  ```json
  {
    "p_admin_key": "ADMIN-CYBER-2026",
    "p_round_number": 1,
    "p_selected_team_ids": [
      "11111111-1111-1111-1111-111111111111",
      "22222222-2222-2222-2222-222222222222",
      "33333333-3333-3333-3333-333333333333"
    ]
  }
  ```

### `admin_reset_event`
- **Type**: RPC Function
- **Endpoint**: `POST /rest/v1/rpc/admin_reset_event`
- **Payload**:
  ```json
  {
    "p_admin_key": "ADMIN-CYBER-2026"
  }
  ```
