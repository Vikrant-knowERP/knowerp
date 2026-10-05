# Code Migration Examples: Cloudflare → Azure

This document shows the exact code changes needed to migrate from Cloudflare Workers/D1 to Azure App Service/PostgreSQL.

---

## 1. PACKAGE.JSON CHANGES

### Current (Cloudflare/Wrangler)
```json
{
  "scripts": {
    "dev": "node scripts/run-framework.mjs dev",
    "build": "node scripts/run-framework.mjs build",
    "start": "node --import ./scripts/sites-env.mjs ./node_modules/wrangler/bin/wrangler.js dev --config dist/server/wrangler.json --local --persist-to .wrangler/state --ip 127.0.0.1 --inspector-port 0",
    "db:generate": "drizzle-kit generate"
  },
  "devDependencies": {
    "@cloudflare/vite-plugin": "1.37.1",
    "wrangler": "4.92.0",
    "vinext": "1.0.0-beta.5"
  }
}
```

### New (Azure/Node.js)
```json
{
  "scripts": {
    "dev": "node scripts/run-framework.mjs dev",
    "build": "node scripts/run-framework.mjs build",
    "start": "node dist/server.js",
    "db:generate": "drizzle-kit generate"
  },
  "dependencies": {
    "pg": "^8.11.0",        // NEW: PostgreSQL client
    "dotenv": "^16.3.1"     // NEW: Environment variables
  },
  "devDependencies": {
    "drizzle-orm": "^0.45.2",
    // Remove: @cloudflare/vite-plugin
    // Remove: wrangler
    // Remove: vinext (Cloudflare-specific)
  }
}
```

---

## 2. DATABASE ADAPTER - db/store.ts

### Current (Cloudflare D1)
```typescript
// db/store.ts - CLOUDFLARE VERSION
import { sql } from 'cloudflare:sql';

interface Database {
  env: {
    DB: D1Database;  // Cloudflare D1 binding
  };
}

export async function query(sql: string, params?: any[]) {
  const db = await getD1Database();  // Cloudflare-specific
  const stmt = db.prepare(sql);
  
  if (params) {
    return stmt.bind(...params).all();  // D1 syntax
  }
  return stmt.all();
}

export async function execute(sql: string, params?: any[]) {
  const db = await getD1Database();
  const stmt = db.prepare(sql);
  
  if (params) {
    return stmt.bind(...params).run();  // D1 syntax
  }
  return stmt.run();
}

// D1-specific transaction handling
export async function transaction(callback: (db: Database) => Promise<void>) {
  const db = await getD1Database();
  try {
    await db.exec('BEGIN TRANSACTION');
    await callback(db);
    await db.exec('COMMIT');
  } catch (error) {
    await db.exec('ROLLBACK');
    throw error;
  }
}
```

### New (PostgreSQL)
```typescript
// db/store.ts - AZURE VERSION
import { Pool, QueryResult } from 'pg';

// Create connection pool
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  // For local development:
  // host: process.env.DB_HOST || 'localhost',
  // port: parseInt(process.env.DB_PORT || '5432'),
  // database: process.env.DB_NAME || 'plannerhostingdb',
  // user: process.env.DB_USER || 'postgres',
  // password: process.env.DB_PASSWORD,
  ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false,
});

pool.on('error', (err) => {
  console.error('Unexpected error on idle client', err);
  process.exit(-1);
});

export async function query(sql: string, params?: any[]): Promise<QueryResult> {
  try {
    return await pool.query(sql, params || []);
  } catch (error) {
    console.error('Query error:', sql, params, error);
    throw error;
  }
}

export async function execute(sql: string, params?: any[]): Promise<QueryResult> {
  return query(sql, params);
}

// PostgreSQL transaction handling
export async function transaction<T>(
  callback: (client: any) => Promise<T>
): Promise<T> {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const result = await callback(client);
    await client.query('COMMIT');
    return result;
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

// Helper for running multiple queries in sequence
export async function batch(queries: Array<{ sql: string; params?: any[] }>) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const results = [];
    for (const { sql, params } of queries) {
      results.push(await client.query(sql, params));
    }
    await client.query('COMMIT');
    return results;
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

// Graceful shutdown
export async function closePool() {
  await pool.end();
}
```

---

## 3. DATABASE SCHEMA - db/schema.ts

### Current (SQLite - Drizzle)
```typescript
// SQLite uses different column types
import { sqliteTable, text, real, integer } from 'drizzle-orm/sqlite-core';

export const resources = sqliteTable('resources', {
  id: text('id').primaryKey(),
  name: text('name').notNull(),
  weekly_hours: real('weekly_hours').notNull().default(40),
  active: integer('active').notNull().default(1),
});

export const allocations = sqliteTable('allocations', {
  id: text('id').primaryKey(),
  resource_id: text('resource_id').notNull(),
  hours: real('hours').notNull().default(0),
  actual: real('actual'),  // Can be NULL
});
```

### New (PostgreSQL - Drizzle)
```typescript
// PostgreSQL uses different column types
import { 
  pgTable, 
  varchar, 
  numeric, 
  boolean,
  uuid,
  uniqueIndex,
  references
} from 'drizzle-orm/pg-core';

export const resources = pgTable('resources', {
  id: varchar('id', { length: 36 }).primaryKey(),
  name: varchar('name', { length: 255 }).notNull(),
  weekly_hours: numeric('weekly_hours', { precision: 10, scale: 2 }).notNull().default('40'),
  active: boolean('active').notNull().default(true),
});

export const allocations = pgTable(
  'allocations',
  {
    id: varchar('id', { length: 36 }).primaryKey(),
    resource_id: varchar('resource_id', { length: 36 })
      .notNull()
      .references(() => resources.id),
    hours: numeric('hours', { precision: 10, scale: 2 }).notNull().default('0'),
    actual: numeric('actual', { precision: 10, scale: 2}),  // Still NULL-able
  },
  (table) => [
    uniqueIndex('allocations_resource_project_month').on(
      table.resource_id,
      table.project_id,
      table.month
    ),
  ]
);
```

---

## 4. API ROUTE - app/api/planner/route.ts

### Current (Cloudflare D1)
```typescript
// app/api/planner/route.ts - SIMPLIFIED EXAMPLE
import { sql } from 'cloudflare:sql';

export async function POST(request: Request, env: any) {
  try {
    const body = await request.json();
    const db = env.DB;  // Cloudflare D1 binding

    // SQLite INSERT with ON CONFLICT
    const stmt = db.prepare(`
      INSERT INTO allocations (id, resource_id, project_id, month, hours)
      VALUES (?, ?, ?, ?, ?)
      ON CONFLICT(resource_id, project_id, month) 
      DO UPDATE SET hours = excluded.hours
    `);

    const result = stmt
      .bind(body.id, body.resourceId, body.projectId, body.month, body.hours)
      .run();

    // Fetch updated data
    const query = db.prepare(`
      SELECT a.*, r.name as resource_name, p.name as project_name
      FROM allocations a
      LEFT JOIN resources r ON a.resource_id = r.id
      LEFT JOIN projects p ON a.project_id = p.id
      WHERE a.month = ?
    `);

    const allocations = query.bind(body.month).all();

    return Response.json({
      success: true,
      allocations: allocations.results,
    });
  } catch (error) {
    console.error('Error:', error);
    return Response.json({ error: error.message }, { status: 500 });
  }
}
```

### New (PostgreSQL)
```typescript
// app/api/planner/route.ts - POSTGRESQL VERSION
import { query, transaction, batch } from '@/db/store';
import { requireAuth } from '@/middleware/auth';

export async function POST(request: Request) {
  try {
    // Check authentication (now using Entra ID)
    const user = await requireAuth(request);
    if (!user) {
      return Response.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const body = await request.json();

    // PostgreSQL INSERT with ON CONFLICT (upsert)
    const result = await query(`
      INSERT INTO allocations 
        (id, resource_id, project_id, month, hours, actual, notes, updated_at)
      VALUES ($1, $2, $3, $4, $5, $6, $7, NOW())
      ON CONFLICT(resource_id, project_id, month) 
      DO UPDATE SET 
        hours = $5,
        actual = $6,
        notes = $7,
        updated_at = NOW()
      RETURNING *
    `, [
      body.id,
      body.resourceId,
      body.projectId,
      body.month,
      body.hours,
      body.actual || null,  // NULL for null values
      body.notes || ''
    ]);

    // Fetch updated allocations with joins
    const allocations = await query(`
      SELECT 
        a.*,
        r.name as resource_name,
        r.weekly_hours,
        p.name as project_name,
        p.budget,
        p.rate
      FROM allocations a
      LEFT JOIN resources r ON a.resource_id = r.id
      LEFT JOIN projects p ON a.project_id = p.id
      WHERE a.month = $1
      ORDER BY a.resource_id, a.project_id
    `, [body.month]);

    return Response.json({
      success: true,
      allocation: result.rows[0],
      allocations: allocations.rows,
    });
  } catch (error) {
    console.error('API Error:', error);
    return Response.json(
      { error: error instanceof Error ? error.message : 'Unknown error' },
      { status: 500 }
    );
  }
}

// Batch update endpoint
export async function PUT(request: Request) {
  try {
    const user = await requireAuth(request);
    if (!user) return Response.json({ error: 'Unauthorized' }, { status: 401 });

    const body = await request.json();  // Array of updates

    const results = await batch(
      body.map((item: any) => ({
        sql: `
          INSERT INTO allocations 
            (id, resource_id, project_id, month, hours, actual, updated_at)
          VALUES ($1, $2, $3, $4, $5, $6, NOW())
          ON CONFLICT(resource_id, project_id, month)
          DO UPDATE SET hours = $5, actual = $6, updated_at = NOW()
        `,
        params: [
          item.id,
          item.resourceId,
          item.projectId,
          item.month,
          item.hours,
          item.actual || null
        ]
      }))
    );

    return Response.json({
      success: true,
      updated: results.length,
    });
  } catch (error) {
    console.error('Batch update error:', error);
    return Response.json({ error: error.message }, { status: 500 });
  }
}
```

---

## 5. AUTHENTICATION - app/chatgpt-auth.ts

### Current (ChatGPT)
```typescript
// CLOUDFLARE VERSION - ChatGPT Auth
import { jwtVerify } from 'jose';

const secret = new TextEncoder().encode(process.env.OPENAI_JWT_SECRET);

export async function requireChatGPTUser(request: Request): Promise<string> {
  const authHeader = request.headers.get('authorization');
  
  if (!authHeader?.startsWith('Bearer ')) {
    throw new Error('Missing auth header');
  }

  const token = authHeader.slice(7);

  try {
    const verified = await jwtVerify(token, secret);
    return verified.payload.sub as string;  // ChatGPT user ID
  } catch (error) {
    throw new Error('Invalid token');
  }
}

// Usage in API routes:
export async function POST(request: Request, env: any) {
  try {
    const userId = await requireChatGPTUser(request);
    // ... proceed with ChatGPT user
  } catch {
    return new Response('Unauthorized', { status: 401 });
  }
}
```

### New (Microsoft Entra ID / Azure AD)
```typescript
// AZURE VERSION - Microsoft Entra ID
import { jwtVerify } from 'jose';

// For App Service, Azure handles most of this automatically
// This is for custom validation if needed

export async function requireMicrosoftUser(request: Request) {
  // Azure App Service Platform Authentication provides:
  // - X-MS-CLIENT-PRINCIPAL-ID: User's object ID
  // - X-MS-CLIENT-PRINCIPAL-NAME: User's email/UPN
  // - X-MS-CLIENT-PRINCIPAL header: Full claims

  const principalId = request.headers.get('x-ms-client-principal-id');
  const principalName = request.headers.get('x-ms-client-principal-name');

  if (!principalId) {
    throw new Error('Not authenticated');
  }

  return {
    userId: principalId,
    email: principalName,
    authenticated: true,
  };
}

// Middleware for protecting routes
export async function authMiddleware(request: Request) {
  try {
    const user = await requireMicrosoftUser(request);
    return { success: true, user };
  } catch (error) {
    return {
      success: false,
      error: 'Authentication failed',
      status: 401,
    };
  }
}

// Usage in API routes (simpler!):
export async function POST(request: Request) {
  try {
    const user = await requireMicrosoftUser(request);
    // User is already authenticated by Azure!
    // No token verification needed

    // Use user.email or user.userId for logging, auditing, etc.
    console.log(`Request from: ${user.email}`);

    // ... proceed with authenticated user
  } catch (error) {
    return Response.json({ error: 'Unauthorized' }, { status: 401 });
  }
}
```

---

## 6. ENVIRONMENT VARIABLES

### Current (.env.local for Cloudflare)
```bash
# Cloudflare/Wrangler configuration
WRANGLER_CONFIG_DIR=.wrangler
CF_API_TOKEN=<cloudflare-api-token>
CF_ACCOUNT_ID=<account-id>

# Application
OPENAI_API_KEY=<openai-key>
OPENAI_JWT_SECRET=<jwt-secret>

# SQLite is embedded, no connection string needed
```

### New (.env.local for Azure)
```bash
# Node.js environment
NODE_ENV=development
PORT=3000

# PostgreSQL Connection
DATABASE_URL="postgresql://planner_admin:password@localhost:5432/plannerhostingdb?sslmode=disable"

# For local development (if not using connection string):
DB_HOST=localhost
DB_PORT=5432
DB_NAME=plannerhostingdb
DB_USER=planner_admin
DB_PASSWORD=password

# Application
AZURE_TENANT_ID=<your-tenant-id>
AZURE_CLIENT_ID=<your-client-id>

# For production (in Azure Key Vault):
# DATABASE_URL → Azure handles this
# AZURE_TENANT_ID → Managed Identity
```

---

## 7. NEXT.CONFIG.TS CHANGES

### Current (Cloudflare)
```typescript
// next.config.ts - CLOUDFLARE VERSION
import { VitePWAPlugin } from '@vitejs/plugin-vite-svg-loader';

const config: NextConfig = {
  // Cloudflare-specific config
  experimental: {
    serverComponentsExternalPackages: ['better-sqlite3'],
  },
};

export default config;
```

### New (Azure)
```typescript
// next.config.ts - AZURE VERSION
const config: NextConfig = {
  // Standard Node.js configuration
  reactStrictMode: true,
  
  // Ensure proper output for Node.js runtime
  output: 'standalone',  // Important for Node.js deployment
  
  // Environment variables
  env: {
    NEXT_PUBLIC_APP_NAME: 'Know Modern ERP',
  },
};

export default config;
```

---

## 8. STARTUP SCRIPT

### Current (Cloudflare)
```bash
# scripts/run-framework.mjs - CLOUDFLARE
export default async function ({ command, env } = {}) {
  if (command === 'dev') {
    // Runs Wrangler dev server
    exec('wrangler dev --config wrangler.json');
  } else if (command === 'build') {
    // Builds for Wrangler
    exec('npm run build');
  }
}
```

### New (Azure)
```bash
# scripts/run-framework.mjs - AZURE
export default async function ({ command, env } = {}) {
  if (command === 'dev') {
    // Local Next.js dev server (no Wrangler)
    exec('next dev');
  } else if (command === 'build') {
    // Standard Next.js build
    exec('next build');
  }
}
```

---

## 9. DRIZZLE MIGRATIONS EXAMPLE

### SQLite Migration → PostgreSQL Migration

#### Original (SQLite)
```sql
-- drizzle/0000_sudden_fabian_cortez.sql (SQLite)
CREATE TABLE resources (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'Delivery',
  location TEXT NOT NULL DEFAULT '',
  weekly_hours REAL NOT NULL DEFAULT 40,
  active INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE projects (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  budget REAL,
  start_date TEXT,
  end_date TEXT
);

CREATE UNIQUE INDEX allocations_uniq 
  ON allocations(resource_id, project_id, month);
```

#### Converted (PostgreSQL)
```sql
-- Migration for PostgreSQL
CREATE TABLE resources (
  id VARCHAR(36) PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  role VARCHAR(50) NOT NULL DEFAULT 'Delivery',
  location VARCHAR(255) NOT NULL DEFAULT '',
  weekly_hours DECIMAL(10,2) NOT NULL DEFAULT 40,
  active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE projects (
  id VARCHAR(36) PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  budget DECIMAL(15,2),
  start_date DATE,
  end_date DATE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX allocations_uniq 
  ON allocations(resource_id, project_id, month);

-- Note: Drizzle can generate these automatically
```

---

## 10. TESTING - LOCAL POSTGRESQL SETUP

### For Local Development

```bash
# 1. Install PostgreSQL locally (macOS example)
brew install postgresql@15

# 2. Start PostgreSQL service
brew services start postgresql@15

# 3. Create local database
createdb plannerhostingdb

# 4. Create user
createuser -P planner_admin  # Will prompt for password

# 5. Set permissions
psql -d plannerhostingdb -c "GRANT ALL ON SCHEMA public TO planner_admin;"

# 6. Update .env.local
echo "DATABASE_URL=postgresql://planner_admin:yourpassword@localhost:5432/plannerhostingdb" >> .env.local

# 7. Run migrations
npm run db:generate && drizzle-kit migrate:apply --config drizzle.config.ts

# 8. Test connection
psql -U planner_admin -d plannerhostingdb -c "SELECT version();"
```

---

## SUMMARY OF CHANGES

| Component | Cloudflare | Azure | Effort |
|-----------|-----------|-------|--------|
| **Database Client** | D1 SQL | pg | 1 hour |
| **Auth** | ChatGPT JWT | Entra ID | 1 hour |
| **Startup** | Wrangler | Node.js | 15 mins |
| **Schema** | SQLite → PostgreSQL syntax | Drizzle + SQL conversion | 1 hour |
| **Config** | next.config.ts | Standard Node.js | 30 mins |
| **Env Vars** | Wrangler secrets | Key Vault | 30 mins |
| **Total** | | | ~4 hours |

---

## TESTING CHECKLIST

After making these changes, test locally:

```bash
# 1. Install dependencies
npm install pg dotenv

# 2. Run migrations
npm run db:generate

# 3. Start dev server
npm run dev

# 4. Test API endpoints
curl http://localhost:3000/api/planner

# 5. Check database connection
psql -U planner_admin -d plannerhostingdb -c "SELECT COUNT(*) FROM resources;"

# 6. Verify authentication
curl -H "X-MS-CLIENT-PRINCIPAL-ID: test-user" http://localhost:3000/api/protected

# 7. Build for production
npm run build
npm start
```

---

This should cover all the major code changes needed!
