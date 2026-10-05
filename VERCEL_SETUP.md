# Vercel + Supabase Setup Guide

## ✅ What We've Done
- Updated `package.json` to remove Cloudflare, add PostgreSQL driver
- Changed database schema from SQLite to PostgreSQL
- Updated all SQL queries for PostgreSQL syntax
- Created environment variable template

## 📋 Your Next Steps

### Step 1: Create Supabase Database (5 min)
1. Go to https://supabase.com
2. Sign up free (GitHub account easiest)
3. Click "New Project"
4. Fill in:
   - Project Name: `knowerp`
   - Database Password: Something strong (save this!)
   - Region: Pick closest to you
5. Wait 2-3 minutes for database to create
6. Go to **Settings → Database** and copy the **Connection String (URI)**
   - It looks like: `postgresql://postgres:PASSWORD@db.PROJECT_ID.supabase.co:5432/postgres`

### Step 2: Create Database Tables
1. In Supabase, go to **SQL Editor** (left sidebar)
2. Click **"New Query"**
3. Copy and paste this SQL:

```sql
-- Create tables for KnowERP
CREATE TABLE resources (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'Delivery',
  location TEXT NOT NULL DEFAULT '',
  weekly_hours DOUBLE PRECISION NOT NULL DEFAULT 40,
  goal DOUBLE PRECISION NOT NULL DEFAULT 0.75,
  active INTEGER NOT NULL DEFAULT 1,
  eligible INTEGER NOT NULL DEFAULT 1,
  notes TEXT NOT NULL DEFAULT ''
);

CREATE TABLE projects (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  client TEXT NOT NULL DEFAULT '',
  manager TEXT NOT NULL DEFAULT '',
  start_date TEXT,
  end_date TEXT,
  budget DOUBLE PRECISION,
  rate DOUBLE PRECISION,
  billable INTEGER NOT NULL DEFAULT 1,
  status TEXT NOT NULL DEFAULT 'Active',
  notes TEXT NOT NULL DEFAULT ''
);

CREATE TABLE months (
  month TEXT PRIMARY KEY
);

CREATE TABLE allocations (
  id TEXT PRIMARY KEY,
  resource_id TEXT NOT NULL REFERENCES resources(id),
  project_id TEXT NOT NULL REFERENCES projects(id),
  month TEXT NOT NULL REFERENCES months(month),
  hours DOUBLE PRECISION NOT NULL DEFAULT 0,
  actual DOUBLE PRECISION,
  notes TEXT NOT NULL DEFAULT '',
  UNIQUE(resource_id, project_id, month)
);

CREATE TABLE capacity_adjustments (
  id TEXT PRIMARY KEY,
  resource_id TEXT NOT NULL REFERENCES resources(id),
  month TEXT NOT NULL REFERENCES months(month),
  leave_hours DOUBLE PRECISION NOT NULL DEFAULT 0,
  capacity_override DOUBLE PRECISION,
  UNIQUE(resource_id, month)
);

CREATE TABLE settings (
  id TEXT PRIMARY KEY,
  default_rate DOUBLE PRECISION
);

CREATE TABLE weekly_allocations (
  id TEXT PRIMARY KEY,
  resource_id TEXT NOT NULL REFERENCES resources(id),
  project_id TEXT NOT NULL REFERENCES projects(id),
  week TEXT NOT NULL,
  hours DOUBLE PRECISION NOT NULL DEFAULT 0,
  actual DOUBLE PRECISION,
  notes TEXT NOT NULL DEFAULT '',
  UNIQUE(resource_id, project_id, week)
);
```

4. Click **Run** (play button)
5. Done! Your database is ready.

### Step 3: Set Up Environment Variables Locally
1. Create `.env.local` file in the `source/` folder:
   ```
   DATABASE_URL=postgresql://postgres:PASSWORD@db.PROJECT_ID.supabase.co:5432/postgres
   ```
   (Paste your connection string from Supabase)

2. Install dependencies:
   ```bash
   cd source
   npm install
   ```

3. Test it locally:
   ```bash
   npm run dev
   ```
   - Should start on http://localhost:3000
   - Try creating a resource or project to test the database

### Step 4: Deploy to Vercel
1. Push your code to GitHub:
   ```bash
   git add .
   git commit -m "Migrate to Vercel + Supabase"
   git push origin main
   ```

2. Go to https://vercel.com
3. Click **"New Project"**
4. Import your GitHub repository
5. In **Environment Variables** section, add:
   ```
   DATABASE_URL=postgresql://postgres:PASSWORD@db.PROJECT_ID.supabase.co:5432/postgres
   ```
6. Click **Deploy**
7. Wait 2-5 minutes...
8. Your app should be live! 🎉

## 🆘 Troubleshooting

### "Cannot find module 'pg'"
- Run: `npm install pg @types/pg`

### Database connection fails
- Check your `DATABASE_URL` is correct
- Make sure Supabase project is created
- Verify password doesn't have special characters that need escaping

### Deployment fails
- Check Vercel build logs
- Ensure all `.env` variables are in Vercel settings
- Check that Next.js build completes without errors

## 📊 What You Get
- **Free Vercel hosting** (up to 12 deployments/day)
- **Free Supabase database** (500MB, perfect for this app)
- **Auto-scaling** - grows with your users
- **Easy GitHub integration** - push to deploy

## 💰 Cost
- **Total: $0/month** (generous free tiers)
- When you scale, Vercel starts at $5/month, Supabase at $25/month

## Next: Optional but Recommended
- Add a custom domain (Vercel has free `.vercel.app` domain)
- Enable GitHub Actions for automated testing
- Set up Vercel Analytics to monitor performance
