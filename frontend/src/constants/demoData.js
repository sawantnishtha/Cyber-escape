// DEMO GAME DATA FOR CYBER ESCAPE
// Can be cleanly replaced by actual contest content from Supabase.

export const DEMO_TEAMS = [
  { id: 'team-001', team_name: 'TEAM ALPHA', team_key_hash: 'CE-DEMO-001', current_round: 1, status: 'active' },
  { id: 'team-002', team_name: 'TEAM BETA', team_key_hash: 'CE-DEMO-002', current_round: 1, status: 'active' },
  { id: 'team-003', team_name: 'TEAM GAMMA', team_key_hash: 'CE-DEMO-003', current_round: 1, status: 'active' },
  { id: 'team-004', team_name: 'TEAM DELTA', team_key_hash: 'CE-DEMO-004', current_round: 1, status: 'active' },
  { id: 'team-005', team_name: 'TEAM EPSILON', team_key_hash: 'CE-DEMO-005', current_round: 1, status: 'active' },
  { id: 'team-006', team_name: 'TEAM ZETA', team_key_hash: 'CE-DEMO-006', current_round: 1, status: 'active' },
  { id: 'team-007', team_name: 'TEAM ETA', team_key_hash: 'CE-DEMO-007', current_round: 1, status: 'active' },
  { id: 'team-008', team_name: 'TEAM THETA', team_key_hash: 'CE-DEMO-008', current_round: 1, status: 'active' },
  { id: 'team-009', team_name: 'TEAM IOTA', team_key_hash: 'CE-DEMO-009', current_round: 1, status: 'active' },
  { id: 'team-010', team_name: 'TEAM KAPPA', team_key_hash: 'CE-DEMO-010', current_round: 1, status: 'active' },
  { id: 'team-011', team_name: 'TEAM LAMBDA', team_key_hash: 'CE-DEMO-011', current_round: 1, status: 'active' },
  { id: 'team-012', team_name: 'TEAM MU', team_key_hash: 'CE-DEMO-012', current_round: 1, status: 'active' },
  { id: 'team-013', team_name: 'TEAM NEXUS', team_key_hash: 'CE-DEMO-013', current_round: 1, status: 'active' },
  { id: 'team-014', team_name: 'TEAM QUANTUM', team_key_hash: 'CE-DEMO-014', current_round: 1, status: 'active' },
  { id: 'team-015', team_name: 'TEAM PHOENIX', team_key_hash: 'CE-DEMO-015', current_round: 1, status: 'active' }
];

// ROUND 1: 8 Multiple Choice Questions
export const DEMO_ROUND_1_QUESTIONS = [
  {
    round_number: 1,
    question_number: 1,
    question_type: 'mcq',
    difficulty: 'easy',
    time_limit_seconds: 45,
    question_data: {
      question: 'What does CPU stand for in computer hardware architecture?',
      options: [
        'Central Processing Unit',
        'Computer Processing Utility',
        'Central Program Unit',
        'Core Processing Utility'
      ]
    },
    correct_answer: 'Central Processing Unit',
    hint_data: 'Often referred to as the computational brain of a computing system.'
  },
  {
    round_number: 1,
    question_number: 2,
    question_type: 'mcq',
    difficulty: 'easy',
    time_limit_seconds: 45,
    question_data: {
      question: 'Which linear data structure strictly adheres to the First-In-First-Out (FIFO) access order?',
      options: [
        'Stack',
        'Queue',
        'Binary Search Tree',
        'Max Heap'
      ]
    },
    correct_answer: 'Queue',
    hint_data: 'Analogous to a line of people waiting for their turn at an airport gate.'
  },
  {
    round_number: 1,
    question_number: 3,
    question_type: 'mcq',
    difficulty: 'medium',
    time_limit_seconds: 45,
    question_data: {
      question: 'Which internet protocol guarantees encrypted transmission of web pages using TLS/SSL?',
      options: [
        'HTTP',
        'FTP',
        'HTTPS',
        'SMTP'
      ]
    },
    correct_answer: 'HTTPS',
    hint_data: 'It renders a green lock icon next to the browser URL.'
  },
  {
    round_number: 1,
    question_number: 4,
    question_type: 'mcq',
    difficulty: 'medium',
    time_limit_seconds: 45,
    question_data: {
      question: 'What is the average-case time complexity of searching a value in a balanced Binary Search Tree (AVL/Red-Black)?',
      options: [
        'O(1)',
        'O(n)',
        'O(log n)',
        'O(n log n)'
      ]
    },
    correct_answer: 'O(log n)',
    hint_data: 'At each comparison, half of the remaining subtrees are eliminated.'
  },
  {
    round_number: 1,
    question_number: 5,
    question_type: 'mcq',
    difficulty: 'medium',
    time_limit_seconds: 45,
    question_data: {
      question: 'In SQL, which clause is specifically used to filter groups of records resulting from a GROUP BY aggregate?',
      options: [
        'WHERE',
        'HAVING',
        'ORDER BY',
        'LIMIT'
      ]
    },
    correct_answer: 'HAVING',
    hint_data: 'WHERE filters rows before aggregation; this clause filters afterwards.'
  },
  {
    round_number: 1,
    question_number: 6,
    question_type: 'mcq',
    difficulty: 'hard',
    time_limit_seconds: 45,
    question_data: {
      question: 'Which CPU scheduling strategy is provably optimal in terms of minimizing average waiting time for a set of stationary processes?',
      options: [
        'First-Come, First-Served (FCFS)',
        'Shortest Job First (SJF)',
        'Round Robin (RR)',
        'Priority Scheduling'
      ]
    },
    correct_answer: 'Shortest Job First (SJF)',
    hint_data: 'Processes with the smallest CPU burst times execute first.'
  },
  {
    round_number: 1,
    question_number: 7,
    question_type: 'mcq',
    difficulty: 'hard',
    time_limit_seconds: 45,
    question_data: {
      question: 'Which layer of the 7-layer OSI reference model provides end-to-end communication services and port multiplexing?',
      options: [
        'Network Layer',
        'Data Link Layer',
        'Transport Layer',
        'Session Layer'
      ]
    },
    correct_answer: 'Transport Layer',
    hint_data: 'The home layer of TCP and UDP.'
  },
  {
    round_number: 1,
    question_number: 8,
    question_type: 'mcq',
    difficulty: 'hard',
    time_limit_seconds: 45,
    question_data: {
      question: 'In asymmetric public-key cryptography, which mathematical property enables secure digital signatures and key exchange?',
      options: [
        'XOR bitwise permutations',
        'One-way trapdoor functions with prime factorization or elliptic curves',
        'Linear feedback shift registers',
        'Caesar substitution arrays'
      ]
    },
    correct_answer: 'One-way trapdoor functions with prime factorization or elliptic curves',
    hint_data: 'Easy to compute in one direction, virtually impossible to invert without the private trapdoor.'
  }
];

// ROUND 2: 2 Technical Crosswords (100% mathematically verified letter intersections)
export const DEMO_ROUND_2_CROSSWORDS = [
  {
    round_number: 2,
    question_number: 1,
    question_type: 'crossword',
    difficulty: 'easy',
    time_limit_seconds: 300,
    question_data: {
      title: 'Cryptographic Grid 1: Computing Architecture & Security',
      gridRows: 5,
      gridCols: 6,
      gridSize: 6,
      words: [
        { id: 1, number: 1, direction: 'across', clue: 'High-speed auxiliary hardware memory buffer (5)', answer: 'CACHE', row: 0, col: 1 },
        { id: 2, number: 1, direction: 'down', clue: 'Prefix relating to information technology and network security (5)', answer: 'CYBER', row: 0, col: 1 },
        { id: 3, number: 2, direction: 'down', clue: 'Distributed remote servers hosting scalable storage and compute (5)', answer: 'CLOUD', row: 0, col: 3 },
        { id: 4, number: 3, direction: 'across', clue: 'Firmware initializing hardware components during system boot (4)', answer: 'BIOS', row: 2, col: 1 },
        { id: 5, number: 4, direction: 'across', clue: 'Systematic process of finding and eliminating software defects (5)', answer: 'DEBUG', row: 3, col: 0 }
      ]
    },
    correct_answer: 'COMPLETED',
    hint_data: 'Focus on computer architecture: Cache memory, Cyber domain, Cloud infrastructure, BIOS firmware, and Debugging.'
  },
  {
    round_number: 2,
    question_number: 2,
    question_type: 'crossword',
    difficulty: 'hard',
    time_limit_seconds: 300,
    question_data: {
      title: 'Cryptographic Grid 2: Advanced Systems & Protocols',
      gridRows: 6,
      gridCols: 8,
      gridSize: 8,
      words: [
        { id: 1, number: 1, direction: 'across', clue: 'Formatted unit of digital data routed across a packet-switched network (6)', answer: 'PACKET', row: 0, col: 0 },
        { id: 2, number: 1, direction: 'down', clue: 'Interpreted high-level programming language widely used in AI & automation (6)', answer: 'PYTHON', row: 0, col: 0 },
        { id: 3, number: 2, direction: 'down', clue: 'Cryptographic algorithm performing reversible encryption and decryption (6)', answer: 'CIPHER', row: 0, col: 2 },
        { id: 4, number: 3, direction: 'down', clue: 'Redundant auxiliary failover or surplus computing capacity (5)', answer: 'EXTRA', row: 0, col: 4 },
        { id: 5, number: 4, direction: 'across', clue: 'Core transmission protocol that guarantees reliable, ordered byte delivery (3)', answer: 'TCP', row: 2, col: 0 },
        { id: 6, number: 5, direction: 'across', clue: 'Symbol or keyword specifying an arithmetic or logical calculation in code (8)', answer: 'OPERATOR', row: 4, col: 0 }
      ]
    },
    correct_answer: 'COMPLETED',
    hint_data: 'Think about packets, Python scripts, cryptographic ciphers, redundant resources, TCP connections, and mathematical operators.'
  }
];

// ROUND 3: 4 Binary-to-ASCII questions
export const DEMO_ROUND_3_QUESTIONS = [
  {
    round_number: 3,
    question_number: 1,
    question_type: 'binary',
    difficulty: 'easy',
    time_limit_seconds: 60,
    question_data: {
      binary: '01000001',
      instruction: 'Convert the 8-bit binary word into its corresponding uppercase ASCII character.'
    },
    correct_answer: 'A',
    hint_data: '01000001 in decimal is 64 + 1 = 65, which corresponds to the first capital letter.'
  },
  {
    round_number: 3,
    question_number: 2,
    question_type: 'binary',
    difficulty: 'easy',
    time_limit_seconds: 60,
    question_data: {
      binary: '01000010',
      instruction: 'Convert the 8-bit binary word into its corresponding uppercase ASCII character.'
    },
    correct_answer: 'B',
    hint_data: '01000010 in decimal is 64 + 2 = 66.'
  },
  {
    round_number: 3,
    question_number: 3,
    question_type: 'binary',
    difficulty: 'medium',
    time_limit_seconds: 60,
    question_data: {
      binary: '01000011',
      instruction: 'Convert the 8-bit binary word into its corresponding uppercase ASCII character.'
    },
    correct_answer: 'C',
    hint_data: '01000011 in decimal is 64 + 2 + 1 = 67.'
  },
  {
    round_number: 3,
    question_number: 4,
    question_type: 'binary',
    difficulty: 'medium',
    time_limit_seconds: 60,
    question_data: {
      binary: '01000100',
      instruction: 'Convert the 8-bit binary word into its corresponding uppercase ASCII character.'
    },
    correct_answer: 'D',
    hint_data: '01000100 in decimal is 64 + 4 = 68.'
  }
];

// ROUND 4: 4 Coding questions with blanks in C++, Python, Java
export const DEMO_ROUND_4_QUESTIONS = [
  {
    round_number: 4,
    question_number: 1,
    question_type: 'code_fill',
    difficulty: 'easy',
    time_limit_seconds: 90,
    question_data: {
      title: 'Calculate Sum of Two Operands',
      description: 'Fill in the blanks to correctly sum variable a with variable b and output the result.',
      blanksCount: 2,
      labels: ['First operand variable', 'Output variable'],
      snippets: {
        cpp: `int a = 5;
int b = 3;
int sum = /* blank_0 */ + b;
cout << /* blank_1 */;`,
        python: `a = 5
b = 3
sum = /* blank_0 */ + b
print(/* blank_1 */)`,
        java: `int a = 5;
int b = 3;
int sum = /* blank_0 */ + b;
System.out.println(/* blank_1 */);`
      }
    },
    correct_answer: 'a,sum',
    hint_data: 'The first blank is variable a; the second blank outputs the sum variable.'
  },
  {
    round_number: 4,
    question_number: 2,
    question_type: 'code_fill',
    difficulty: 'easy',
    time_limit_seconds: 90,
    question_data: {
      title: 'Ternary Maximum Comparison',
      description: 'Complete the comparison condition to pick the larger number between x and y.',
      blanksCount: 2,
      labels: ['Comparison operator', 'Alternate value'],
      snippets: {
        cpp: `int x = 10, y = 20;
int max_val = (x /* blank_0 */ y) ? x : /* blank_1 */;
cout << max_val;`,
        python: `x = 10
y = 20
max_val = x if x /* blank_0 */ y else /* blank_1 */
print(max_val)`,
        java: `int x = 10, y = 20;
int max_val = (x /* blank_0 */ y) ? x : /* blank_1 */;
System.out.println(max_val);`
      }
    },
    correct_answer: '>,y',
    hint_data: 'Check if x is greater than y (>) and assign y when false.'
  },
  {
    round_number: 4,
    question_number: 3,
    question_type: 'code_fill',
    difficulty: 'medium',
    time_limit_seconds: 90,
    question_data: {
      title: 'Iterative Factorial Calculation',
      description: 'Fill the loop boundary condition and multiplicative accumulator to compute n factorial.',
      blanksCount: 2,
      labels: ['Loop boundary operator / step', 'Accumulator operator'],
      snippets: {
        cpp: `int n = 5, fact = 1;
for (int i = 1; i /* blank_0 */ n; i++) {
    fact = fact /* blank_1 */ i;
}
cout << fact;`,
        python: `n = 5
fact = 1
for i in range(1, n /* blank_0 */ 1):
    fact = fact /* blank_1 */ i
print(fact)`,
        java: `int n = 5, fact = 1;
for (int i = 1; i /* blank_0 */ n; i++) {
    fact = fact /* blank_1 */ i;
}
System.out.println(fact);`
      }
    },
    correct_answer: '<=,*',
    hint_data: 'Loop runs while i <= n and multiplies using * operator.'
  },
  {
    round_number: 4,
    question_number: 4,
    question_type: 'code_fill',
    difficulty: 'hard',
    time_limit_seconds: 90,
    question_data: {
      title: 'Overflow-Safe Binary Search Midpoint',
      description: 'Fill in the blanks to calculate the binary search midpoint without triggering 32-bit integer overflow.',
      blanksCount: 2,
      labels: ['Upper bound variable', 'Arithmetic division operator'],
      snippets: {
        cpp: `int low = 0, high = 100;
int mid = low + (/* blank_0 */ - low) /* blank_1 */ 2;
cout << mid;`,
        python: `low = 0
high = 100
mid = low + (/* blank_0 */ - low) /* blank_1 */ 2
print(mid)`,
        java: `int low = 0, high = 100;
int mid = low + (/* blank_0 */ - low) /* blank_1 */ 2;
System.out.println(mid);`
      }
    },
    correct_answer: 'high,/',
    hint_data: 'The classic formula is low + (high - low) / 2.'
  }
];

// ASCII Table for quick reference in Round 3
export const ASCII_REFERENCE_TABLE = [
  { char: 'A', dec: 65, bin: '01000001' },
  { char: 'B', dec: 66, bin: '01000010' },
  { char: 'C', dec: 67, bin: '01000011' },
  { char: 'D', dec: 68, bin: '01000100' },
  { char: 'E', dec: 69, bin: '01000101' },
  { char: 'F', dec: 70, bin: '01000110' },
  { char: 'G', dec: 71, dec_str: '71', bin: '01000111' },
  { char: 'H', dec: 72, bin: '01001000' },
  { char: 'I', dec: 73, bin: '01001001' },
  { char: 'J', dec: 74, bin: '01001010' },
  { char: 'K', dec: 75, bin: '01001011' },
  { char: 'L', dec: 76, bin: '01001100' },
  { char: 'M', dec: 77, bin: '01001101' },
  { char: 'N', dec: 78, bin: '01001110' },
  { char: 'O', dec: 79, bin: '01001111' },
  { char: 'P', dec: 80, bin: '01010000' },
  { char: 'Q', dec: 81, bin: '01010001' },
  { char: 'R', dec: 82, bin: '01010010' },
  { char: 'S', dec: 83, bin: '01010011' },
  { char: 'T', dec: 84, bin: '01010100' },
  { char: 'U', dec: 85, bin: '01010101' },
  { char: 'V', dec: 86, bin: '01010110' },
  { char: 'W', dec: 87, bin: '01010111' },
  { char: 'X', dec: 88, bin: '01011000' },
  { char: 'Y', dec: 89, bin: '01011001' },
  { char: 'Z', dec: 90, bin: '01011010' }
];
