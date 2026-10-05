# 🎮 Cyber Escape Room Competition Platform

A full-scale cyber security escape room competition platform built with **React (Vite)** on the frontend and **Supabase (PostgreSQL + Realtime)** on the backend.

---

## 📂 Project Structure

```
Cyber escape/
├── frontend/                       # 🌐 Standalone Frontend Application (Deployable to Vercel)
│   ├── src/
│   │   ├── api/                    # 📡 Dedicated API Layer calling Backend (Supabase / RPC)
│   │   │   ├── apiClient.js        # Core API client & health checks
│   │   │   ├── authApi.js          # Team & Admin authentication
│   │   │   ├── gameApi.js          # Session state & progress
│   │   │   ├── questionApi.js      # Questions, hints & answer submissions
│   │   │   ├── codeApi.js          # 4-Letter security key verification & final riddle
│   │   │   ├── adminApi.js         # Master game state, selections & event reset
│   │   │   ├── leaderboardApi.js   # Live rankings & realtime subscription
│   │   │   └── index.js            # Barrel export
│   │   ├── components/             # Reusable UI components (Navbar, ProctoringGuard, Modals)
│   │   ├── pages/                  # Landing, AdminDashboard, TeamApp, Rounds 1-4
│   │   ├── services/               # Application services
│   │   └── ...
│   ├── public/                     # Static assets
│   ├── package.json                # Frontend dependencies & scripts
│   ├── vite.config.js              # Vite configuration
│   └── vercel.json                 # Vercel SPA routing configuration
│
├── backend/                        # 🗄️ Backend Schemas, Migrations & Database Setup
│   ├── README.md                   # Backend setup & schema documentation
│   ├── api-spec.md                 # API & RPC endpoints specification
│   └── supabase/
│       ├── COMPLETE_SETUP_ALL_IN_ONE.sql       # Complete database creation script
│       ├── RUN_THIS_IN_SUPABASE_SQL_EDITOR.sql # Master patch script
│       ├── migrations/                         # Schema & RPC migrations
│       └── seed/                               # Default seed data
│
├── DEPLOYMENT.md                   # 🚀 Step-by-step Vercel deployment guide
└── package.json                    # Root workspace configuration
```

---

## ⚡ Quick Start (Local Development)

### Run from Root:
```bash
npm run dev
```
Starts the Vite dev server at `http://localhost:3000`.

### Build Frontend:
```bash
npm run build
```
Creates production bundle in `frontend/dist`.

---

## 🚀 Deploying Frontend Only to Vercel

See the complete guide in [DEPLOYMENT.md](file:///c:/Users/Nishtha%20Sawant/OneDrive/Desktop/Cyber%20escape/DEPLOYMENT.md).

Quick summary:
1. Connect your repo in [Vercel](https://vercel.com).
2. Set **Root Directory** to `frontend`.
3. Add Environment Variables:
   - `VITE_SUPABASE_URL`
   - `VITE_SUPABASE_ANON_KEY`
   - `VITE_DEMO_MODE=false`
   - `VITE_DEFAULT_ADMIN_KEY=ADMIN-CYBER-2026`
4. Click **Deploy**!
