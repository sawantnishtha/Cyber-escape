# 🚀 Vercel Deployment Guide: Frontend Only

This step-by-step guide explains how to deploy **ONLY the frontend** of the Cyber Escape platform to **Vercel** with full backend Supabase integration.

---

## 📌 Architecture Summary

- **Frontend**: React + Vite SPA located in [`frontend/`](file:///c:/Users/Nishtha%20Sawant/OneDrive/Desktop/Cyber%20escape/frontend).
- **Backend**: Managed PostgreSQL & RPCs located in Supabase (SQL files in [`backend/supabase/`](file:///c:/Users/Nishtha%20Sawant/OneDrive/Desktop/Cyber%20escape/backend/supabase)).
- **Communication**: Frontend calls backend via the dedicated API layer in [`frontend/src/api/`](file:///c:/Users/Nishtha%20Sawant/OneDrive/Desktop/Cyber%20escape/frontend/src/api).

---

## 🛠️ Step-by-Step Vercel Deployment

### Method 1: Deploy via Vercel Web Dashboard (Recommended)

1. **Push your code to GitHub / GitLab / Bitbucket**:
   ```bash
   git add .
   git commit -m "Separate frontend and backend with dedicated API layer"
   git push origin main
   ```

2. **Import Project to Vercel**:
   - Go to [https://vercel.com/new](https://vercel.com/new).
   - Sign in with your GitHub account.
   - Find your repository and click **Import**.

3. **Configure Project Settings**:
   - **Project Name**: `cyber-escape` (or your choice).
   - **Framework Preset**: `Vite` (Vercel will auto-detect this).
   - **Root Directory**:
     - Click **Edit** next to Root Directory.
     - Select the **`frontend`** directory.
     - Click **Continue**.

4. **Verify Build & Output Settings**:
   - **Build Command**: `npm run build` (or `vite build`)
   - **Output Directory**: `dist`
   - **Install Command**: `npm install`

5. **Add Environment Variables**:
   Under **Environment Variables**, add the following 4 keys:

   | Key | Value | Notes |
   |---|---|---|
   | `VITE_SUPABASE_URL` | `https://axwoerwkfcvmaisqkzur.supabase.co` | Your live Supabase URL |
   | `VITE_SUPABASE_ANON_KEY` | *(Your Supabase Anon Public Key)* | Copy from `.env` or Supabase Dashboard |
   | `VITE_DEMO_MODE` | `false` | Enables live database mode |
   | `VITE_DEFAULT_ADMIN_KEY` | `ADMIN-CYBER-2026` | Master access key for Admin dashboard |

6. **Deploy**:
   - Click **Deploy**.
   - Vercel will build the frontend and deploy it globally within 30-45 seconds.
   - You will receive a live URL like `https://cyber-escape.vercel.app`.

---

### Method 2: Deploy via Vercel CLI (Alternative)

If you prefer deploying from your terminal:

1. **Install Vercel CLI** (if not already installed):
   ```bash
   npm i -g vercel
   ```

2. **Navigate to the frontend directory**:
   ```bash
   cd frontend
   ```

3. **Run Vercel Deploy**:
   ```bash
   vercel
   ```
   - Follow prompts:
     - Set up and deploy: **Y**
     - Link to existing project: **N**
     - Project name: `cyber-escape`
     - In which directory is your code located: `./`
   
4. **Deploy to Production with Environment Variables**:
   ```bash
   vercel --prod
   ```

---

## 🔒 SPA Routing & Rewrites

Vercel is already pre-configured with [`frontend/vercel.json`](file:///c:/Users/Nishtha%20Sawant/OneDrive/Desktop/Cyber%20escape/frontend/vercel.json):
```json
{
  "buildCommand": "npm run build",
  "outputDirectory": "dist",
  "framework": "vite",
  "rewrites": [
    {
      "source": "/(.*)",
      "destination": "/index.html"
    }
  ]
}
```
This guarantees that refreshing pages or navigating between `/admin`, `/team`, and game round routes works without 404 errors.

---

## ✅ Post-Deployment Verification Checklist

1. **Landing Page**: Open your deployed Vercel URL. The neon Cyber Escape interface should load instantly.
2. **Team Login**:
   - Test Team Key: `ALPHA-2026`
   - Should log in smoothly, enter the countdown/lobby, and sync with backend.
3. **Admin Dashboard**:
   - Access: `/admin` or click Admin Access.
   - Admin Key: `ADMIN-CYBER-2026`
   - Verify game state controls and the red `RESTART EVENT` button.
4. **Testing Reset**:
   - If proctoring strikes ever trigger during testing, click the green `[ RESET & RE-ENTER FROM BEGINNING ]` button on the disqualified screen or click `RESTART EVENT` in the Admin Dashboard.
