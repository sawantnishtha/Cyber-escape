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

-- 3. SEED 15 DEMO TEAMS
INSERT INTO teams (team_name, team_key_hash, current_round, status)
VALUES
('TEAM ALPHA', 'CE-DEMO-001', 1, 'active'),
('TEAM BETA', 'CE-DEMO-002', 1, 'active'),
('TEAM GAMMA', 'CE-DEMO-003', 1, 'active'),
('TEAM DELTA', 'CE-DEMO-004', 1, 'active'),
('TEAM EPSILON', 'CE-DEMO-005', 1, 'active'),
('TEAM ZETA', 'CE-DEMO-006', 1, 'active'),
('TEAM ETA', 'CE-DEMO-007', 1, 'active'),
('TEAM THETA', 'CE-DEMO-008', 1, 'active'),
('TEAM IOTA', 'CE-DEMO-009', 1, 'active'),
('TEAM KAPPA', 'CE-DEMO-010', 1, 'active'),
('TEAM LAMBDA', 'CE-DEMO-011', 1, 'active'),
('TEAM MU', 'CE-DEMO-012', 1, 'active'),
('TEAM NEXUS', 'CE-DEMO-013', 1, 'active'),
('TEAM QUANTUM', 'CE-DEMO-014', 1, 'active'),
('TEAM PHOENIX', 'CE-DEMO-015', 1, 'active')
ON CONFLICT (team_key_hash) DO NOTHING;

-- 4. SEED ADMIN USER
INSERT INTO admin_users (admin_name, admin_key_hash, role)
VALUES ('CESA Faculty & Organizers', 'ADMIN-CYBER-2026', 'superadmin')
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
  "title": "Crossword 1: Foundational Systems",
  "gridSize": 6,
  "words": [
    {"number": 1, "direction": "across", "clue": "Brain of the computer (3)", "answer": "CPU", "row": 0, "col": 0},
    {"number": 2, "direction": "down", "clue": "Volatile memory (3)", "answer": "RAM", "row": 0, "col": 2},
    {"number": 3, "direction": "across", "clue": "LIFO linear data structure (5)", "answer": "STACK", "row": 2, "col": 0},
    {"number": 4, "direction": "down", "clue": "Computer instructions written by developers (4)", "answer": "CODE", "row": 2, "col": 3}
  ]
}', 'COMPLETED', 300, 'All terms are fundamental hardware and software primitives.'),
(2, 2, 'crossword', 'hard', '{
  "title": "Crossword 2: Core Engineering Systems",
  "gridSize": 9,
  "words": [
    {"number": 1, "direction": "across", "clue": "Step-by-step computational procedure (9)", "answer": "ALGORITHM", "row": 0, "col": 0},
    {"number": 2, "direction": "down", "clue": "Translates high-level code to machine code (8)", "answer": "COMPILER", "row": 0, "col": 2},
    {"number": 3, "direction": "across", "clue": "Interconnected computing devices sharing resources (7)", "answer": "NETWORK", "row": 3, "col": 1},
    {"number": 4, "direction": "down", "clue": "Structured collection of stored data (8)", "answer": "DATABASE", "row": 1, "col": 7}
  ]
}', 'COMPLETED', 300, 'Think of core computer science curricula.')
ON CONFLICT (round_number, question_number) DO NOTHING;

-- 7. SEED ROUND 3 DEMO BINARY-TO-ASCII (4 questions)
INSERT INTO questions (round_number, question_number, question_type, difficulty, question_data, correct_answer, time_limit_seconds, hint_data)
VALUES
(3, 1, 'binary', 'easy', '{"binary": "01000001", "instruction": "Convert the 8-bit binary code to its corresponding ASCII character."}', 'A', 60, '01000001 in decimal is 64 + 1 = 65.'),
(3, 2, 'binary', 'easy', '{"binary": "01000010", "instruction": "Convert the 8-bit binary code to its corresponding ASCII character."}', 'B', 60, '01000010 in decimal is 64 + 2 = 66.'),
(3, 3, 'binary', 'medium', '{"binary": "01000011", "instruction": "Convert the 8-bit binary code to its corresponding ASCII character."}', 'C', 60, '01000011 in decimal is 64 + 2 + 1 = 67.'),
(3, 4, 'binary', 'medium', '{"binary": "01000100", "instruction": "Convert the 8-bit binary code to its corresponding ASCII character."}', 'D', 60, '01000100 in decimal is 64 + 4 = 68.')
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
