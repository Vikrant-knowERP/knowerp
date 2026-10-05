# Azure Hosting Strategy for Know Modern ERP - Financial Planner

**Date:** October 5, 2026  
**Prepared for:** Knowerp Team

---

## EXECUTIVE SUMMARY

Your application is a **Next.js 16 financial planning tool** with sophisticated resource allocation, capacity management, and weekly/monthly forecasting. Currently built for Cloudflare infrastructure, it requires significant adaptation for Azure.

### Quick Recommendations:
- **Best Host:** Azure App Service (easiest) OR Azure Container Apps (more scalable)
- **Best Database:** Azure Database for PostgreSQL (recommended) OR Azure SQL
- **Estimated Monthly Cost:** $50-150 USD depending on scale
- **Timeline:** 2-4 weeks for migration
- **Can use Dataverse?** Partially - for reference data only, not transactional workloads

---

## PART 1: APPLICATION ARCHITECTURE ANALYSIS

### Current Tech Stack
```
Frontend:     Next.js 16, React 19, TypeScript
UI Library:   shadcn/react, Radix UI, Tailwind CSS
Backend:      Next.js API Routes (via Wrangler)
Database:     Cloudflare D1 (SQLite)
ORM:          Drizzle ORM 0.45.2
Auth:         ChatGPT (requires replacement)
Runtime:      Cloudflare Workers + Vinext
```

### Database Schema (7 Tables)
```
- resources          (team members, roles, weekly capacity)
- projects           (client projects, budgets, dates)
- allocations        (monthly hour assignments)
- weekly_allocations (granular weekly tracking)
- capacity_adjustments (leave, overrides)
- months             (time periods)
- settings           (global config like default rates)
```

### Key Application Features
✅ Weekly/monthly hour planning and forecasting  
✅ Capacity management with leave/overrides  
✅ Multi-project resource allocation  
✅ Actual hours vs. budgeted tracking  
✅ Billable goal calculations (75% target referenced)  
✅ Budget tracking with rate calculations  
✅ Data export/import capabilities  

---

## PART 2: AZURE HOSTING OPTIONS & COSTS

### OPTION A: Azure App Service (RECOMMENDED FOR YOU)

**What it is:** Managed hosting for Node.js applications (like AWS Elastic Beanstalk)

**Setup:**
```
Azure App Service (B2 tier)           → ~$85/month
  └─ Node.js 22 runtime
  └─ Auto-scaling (optional)
  └─ Always-on (5 instances included)

Azure Database for PostgreSQL         → ~$60/month
  (Flexible Server - Single server)
  └─ 1-2 vCores
  └─ 32GB storage
  └─ Automated backups (14 days)

Application Insights (monitoring)     → ~$1/month

Azure Key Vault (secrets)             → Free (~$0.03/operation)

Total: ~$146/month
```

**Pros:**
- Simplest migration path
- Built-in auto-scaling
- Native Azure monitoring
- Microsoft Entra integration (single sign-on with Microsoft 365)
- Managed backups & disaster recovery
- HTTPS/Custom domain built-in

**Cons:**
- Less flexible than containers
- Cold starts if you go to B1 cheaper tier
- Always-on cost

**When to use:** Your scenario - straightforward Node.js app, 5-50 users, moderate data

---

### OPTION B: Azure Container Apps (MORE SCALABLE)

**Setup:**
```
Azure Container Apps                  → ~$40/month
  └─ Container image deployed
  └─ Auto-scaling on CPU/memory
  └─ Pay-per-execution model

Container Registry                    → ~$5/month
PostgreSQL Database (same)            → ~$60/month

Total: ~$105/month
```

**Pros:**
- 30% cheaper than App Service
- Better for microservices
- Serverless-like pricing (pay only for execution)
- More control over runtime

**Cons:**
- Requires Docker containerization (extra step)
- Slightly more complex deployment
- Less integration features out-of-box

**When to use:** If you have variable traffic or need very low cost

---

### OPTION C: Azure SQL vs. PostgreSQL (DATABASE CHOICE)

#### Azure Database for PostgreSQL (RECOMMENDED)
```
Cost:           $60-120/month
Licenses:       Open-source (free)
Advantage:      Better for complex queries, JSON fields
Migration:      Easy from SQLite (better tooling)
Connections:    Better for web apps
```

#### Azure SQL (SQL Server)
```
Cost:           $85-200/month
Licenses:       Microsoft licensing (sometimes included in EA)
Advantage:      Deep Microsoft integration, Dataverse sync option
Migration:      More complex from SQLite
When to use:    If already in SQL Server ecosystem
```

**FOR YOUR CASE:** Use **PostgreSQL** - it's cheaper, easier migration, and simpler licensing.

---

### OPTION D: Azure Cosmos DB (NOT RECOMMENDED FOR YOU)
```
Cost:           $200+/month
Why skip it:    You have relational data (allocations, resources, projects)
Good for:       Document databases, real-time global apps
```

---

## PART 3: DATAVERSE FEASIBILITY ANALYSIS

You mentioned Dataverse is already paid. Here's what you can do:

### ✅ What Works with Dataverse
- **Reference data storage:** Projects, resources (could sync)
- **Audit trail:** Track changes through Dataverse
- **Microsoft 365 integration:** Share reports in Teams/Power BI

### ❌ What Doesn't Work
- **Transactional workloads:** Weekly allocations (high-frequency updates)
- **Real-time calculations:** Your app does on-the-fly capacity math
- **Cost:** Dataverse has per-record pricing (~$0.01+ per 100 records)

### Dataverse Hybrid Approach (Optional)
```
Azure PostgreSQL          → Live planner data (hourly updates)
                           │
                           ├─ Weekly sync to Dataverse
                           │
Dataverse                 → Read-only reference + audit
Power BI                  → Reports from Dataverse
Teams                     → Share reports
```

**Cost Impact:** +$0.50-2/month (small)  
**Complexity:** +1-2 weeks for integration layer

**Recommendation:** Skip it for now. Migrate to Azure first, then add Dataverse if you need Power BI reporting.

---

## PART 4: REQUIRED CODE CHANGES

### 1. **Database Layer** (db/store.ts, api/planner/route.ts)
**Current:** Cloudflare D1 + Wrangler  
**New:** PostgreSQL + node-postgres or drizzle-postgres

```javascript
// FROM (Cloudflare):
import { sql } from 'cloudflare:sql';

// TO (PostgreSQL):
import { Pool } from 'pg';
const pool = new Pool({
  connectionString: process.env.DATABASE_URL
});
```

**Effort:** 3-4 hours (straightforward SQL adaptation)

---

### 2. **Authentication** (app/chatgpt-auth.ts)
**Current:** ChatGPT auth  
**New:** Microsoft Entra ID (Azure AD)

```javascript
// New package: @azure/identity, @azure/msal-browser

// Azure handles auth automatically when deployed
// Just add middleware to protect routes:

import { defaultAzureCredential } from "@azure/identity";

app.use(requireAuth); // Azure-managed
```

**Effort:** 2-3 hours (Azure App Service can auto-manage this)

---

### 3. **Runtime & Start Command** (package.json)
**Current:** 
```bash
npm start → wrangler dev (local Cloudflare)
```

**New:**
```bash
npm start → node dist/server.js (Azure App Service)
```

**Effort:** 1 hour (update next.config.ts)

---

### 4. **Database Schema Translation**
Your SQLite schema needs PostgreSQL syntax:

```sql
-- FROM (SQLite):
CREATE TABLE resources (
  id TEXT PRIMARY KEY,
  weekly_hours REAL DEFAULT 40,
  active INTEGER DEFAULT 1
);

-- TO (PostgreSQL):
CREATE TABLE resources (
  id VARCHAR(36) PRIMARY KEY,
  weekly_hours DECIMAL(10,2) DEFAULT 40,
  active BOOLEAN DEFAULT true
);
```

**Effort:** 2 hours (Drizzle can auto-generate most)

---

## PART 5: DATA MIGRATION STRATEGY

Your data is ready: JSON export + SQLite export included

### Step 1: Create PostgreSQL Database
```bash
az postgres flexible-server create \
  --resource-group myResourceGroup \
  --name planner-db \
  --admin-user planner_admin \
  --admin-password <secure-password>
```

### Step 2: Import Data
```bash
# Drizzle can import from SQLite:
drizzle-kit migrate:apply --config drizzle.config.ts

# Manual data load (recommended):
psql -h planner-db.postgres.database.azure.com \
     -U planner_admin \
     -d plannerhostingdb \
     -f schema.sql

# Then load JSON via app import endpoint (safest)
```

### Step 3: Validate Migration
- ✅ Record counts match (from export-summary.json)
- ✅ October 5 weekly total = 271.5 hours
- ✅ Vicky = 48.25 hrs, Sanjoy = 43.75 hrs
- ✅ All projects preserved with correct budgets
- ✅ No duplicate allocations

**Effort:** 3-4 hours (validation is key)

---

## PART 6: STEP-BY-STEP MIGRATION PLAN

### Week 1: Preparation
```
Day 1-2: Create Azure resources (App Service + PostgreSQL)
        └─ Resource group, names, region (eastus recommended)
        
Day 3:   Set up secrets in Azure Key Vault
        └─ DATABASE_URL
        └─ AUTH_SECRET
        └─ OPENAI_API_KEY (if keeping any integrations)
        
Day 4:   Prepare code locally
        └─ Branch: feature/azure-migration
        └─ Update package.json (remove Wrangler)
        └─ Update next.config.ts
        └─ Create db/postgres-adapter.ts
```

### Week 2: Code Migration
```
Day 5-6: Implement PostgreSQL adapter
        └─ Copy prepared statements from SQLite
        └─ Test locally with postgres:latest (Docker)
        
Day 7-8: Implement Entra ID auth
        └─ Replace ChatGPT auth
        └─ Test locally with Azure CLI
        
Day 9:   Build & test production bundle
        └─ npm run build
        └─ npm start (should run on port 3000)
```

### Week 3: Deployment
```
Day 10:  Deploy to Azure App Service staging slot
        └─ git push azure staging
        
Day 11-12: Data migration
         └─ Import schema
         └─ Seed from JSON/SQLite export
         └─ Validate record counts
         
Day 13-14: Testing & go-live
         └─ Load testing (simulate 5 users)
         └─ Swap staging → production
         └─ Configure custom domain
         └─ Enable HTTPS (auto with Azure)
```

---

## PART 7: COST BREAKDOWN

### Development Phase (One-time)
```
Azure free credits (if new account)    → $200 credit
Dev/test App Service (B1)              → Free for 12mo
Dev/test PostgreSQL                    → Free trial period
```

### Production Phase (Monthly)
```
MINIMUM (2-5 users):
  App Service B2                       → $60
  PostgreSQL (1-2 vCore)              → $40
  Backups/monitoring                  → $5
  Total:                               → $105/month

STANDARD (5-20 users):
  App Service B3                       → $150
  PostgreSQL (2-4 vCore)              → $80
  Application Insights                → $10
  Total:                               → $240/month

ENTERPRISE (20+ users):
  App Service P1v3                     → $250
  PostgreSQL (4+ vCore)               → $200
  Advanced monitoring/backup          → $50
  Total:                               → $500+/month
```

### Cost Comparison: Cloudflare vs Azure
```
Cloudflare Workers:    $20/month (first 10M requests free)
D1 Database:           $0.50/month
Total:                 ~$20/month

Azure App Service:     $60-150/month
PostgreSQL:            $60/month
Total:                 ~$120-210/month

DIFFERENCE:            Azure is 5-10x more expensive
WHY:                   Better auto-scaling, backups, enterprise features
```

**Cost-saving tips for Azure:**
- Use **B2** tier initially (not B3)
- Enable auto-scale down during non-business hours
- Use **PostgreSQL Single Server** (cheaper than Flexible Server)
- Set backup retention to 7 days (not 35)
- Disable Application Insights initially (re-enable after week 1)

---

## PART 8: DATAVERSE INTEGRATION DECISION MATRIX

| Need | Dataverse | PostgreSQL | Both (Hybrid) |
|------|-----------|-----------|---------------|
| **Live planning/edits** | ❌ Slow | ✅ Fast | ✅ PostgreSQL |
| **Capacity calculations** | ❌ Limited | ✅ Full SQL | ✅ PostgreSQL |
| **Weekly allocations** | ❌ Too expensive | ✅ Cheap | ✅ PostgreSQL |
| **Power BI reports** | ✅ Native | ⚠️ Connector | ✅ Both |
| **Teams integration** | ✅ Native | ❌ Manual | ✅ Dataverse |
| **Change audit trail** | ✅ Built-in | ⚠️ DIY | ✅ Dataverse |

### Recommendation for Knowerp:
**Start with PostgreSQL + Azure**, skip Dataverse initially.  
**Add Dataverse in Phase 2** (3-6 months) if you need Power BI reporting or Teams integration.

---

## PART 9: SECURITY & COMPLIANCE CHECKLIST

### Must-Have (Before Production)
- [x] HTTPS/TLS 1.2+ (Azure enforces automatically)
- [x] Secrets in Azure Key Vault (not in code/git)
- [x] Microsoft Entra authentication (not ChatGPT)
- [x] Database backups enabled (14-day minimum)
- [x] IP whitelisting for database (allow only App Service)
- [x] Environment-specific configs (dev/stage/prod)

### Nice-to-Have (Phase 2)
- [ ] DLP (Data Loss Prevention) policies
- [ ] Audit logging to Application Insights
- [ ] WAF (Web Application Firewall)
- [ ] Managed Identity (instead of connection strings)
- [ ] Encryption at rest (PostgreSQL extensions)

---

## PART 10: RECOMMENDED AZURE SERVICES SELECTION

### **Final Recommendation: Azure App Service + PostgreSQL**

```
TIER:                B2 (Standard) - $85/month
REGION:              East US (closest to likely users)
SCALE:               1-2 instances, auto-scale 2-4 under load
AUTO-SCALE RULES:    Scale up at 80% CPU, scale down at 20%

DATABASE:            PostgreSQL Flexible Server
COMPUTE:             Standard_B2s (2 vCores, 4GB RAM)
STORAGE:             32GB (auto-expand to 128GB)
BACKUP:              7-day retention
RESTORE:             Point-in-time (any time in last 7 days)

AUTHENTICATION:      Microsoft Entra ID
MONITORING:          Azure Monitor + Application Insights
DOMAIN:              Custom domain via Azure DNS
CERTIFICATE:         Managed TLS (free, auto-renewal)

TOTAL MONTHLY COST:  ~$145
COMMITMENT:          Month-to-month (cancel anytime)
```

---

## PART 11: IMPLEMENTATION CHECKLIST

### Pre-Migration (This Week)
- [ ] Create Azure subscription & resource group
- [ ] Review Azure documentation links (provided in original README)
- [ ] Set up local PostgreSQL test instance
- [ ] Review code changes needed (sections above)
- [ ] Plan data migration strategy
- [ ] Get IT stakeholder sign-off

### Migration (Weeks 2-4)
- [ ] Implement PostgreSQL adapter in code
- [ ] Implement Microsoft Entra authentication
- [ ] Create Azure App Service
- [ ] Create PostgreSQL database
- [ ] Configure Key Vault with secrets
- [ ] Deploy to staging environment
- [ ] Migrate data from Cloudflare D1
- [ ] Validate all data and functionality
- [ ] Performance testing (load test)
- [ ] Security audit & penetration testing
- [ ] Train team on new environment
- [ ] Cut over to production
- [ ] Monitor for 48 hours post-launch

### Post-Migration
- [ ] Decommission Cloudflare Workers
- [ ] Decommission D1 database
- [ ] Document Azure architecture
- [ ] Set up on-call alerts
- [ ] Schedule first backup restore test (Day 30)
- [ ] Plan for Dataverse integration (Phase 2)

---

## PART 12: QUICK ANSWERS TO YOUR QUESTIONS

### Q: "Tell me the model I should be using"
**A:** Azure App Service B2 tier (Standard). NOT Enterprise, NOT Free. B2 gives you:
- 2 vCores, adequate for 5-50 users
- Auto-scaling built-in
- Better redundancy than B1
- Price: $85/month

### Q: "Best way to host in Azure?"
**A:** App Service + PostgreSQL. It's the proven path for Node.js apps. Container Apps is tempting but adds 1-2 weeks complexity for marginal savings.

### Q: "Is DB suitable?"
**A:** Yes, your SQLite schema translates cleanly to PostgreSQL. No structural changes needed, just syntax updates.

### Q: "Cheap thing needed, can we use Dataverse?"
**A:** 
- **Cost:** Dataverse is NOT cheaper. PostgreSQL + App Service = $145/month total is your cheapest for this workload.
- **Dataverse:** Designed for reference data, not your high-frequency allocations. Use only for Power BI / Teams later.

### Q: "Take all permissions you need"
**A:** I'll need your Azure subscription credentials to:
- Create resource groups
- Deploy App Service
- Create PostgreSQL server
- Configure Key Vault
- Set up Entra ID

---

## PART 13: NEXT STEPS

### Immediate (Today)
1. Share Azure subscription ID with your DevOps/IT team
2. Confirm resource naming convention (planner-app, planner-db, etc.)
3. Decide on region: **eastus** (recommended) or other?
4. Get Entra ID tenant ID and create Service Principal for deployment

### This Week
1. Create Azure resource group
2. Run script to provision App Service + PostgreSQL (I'll provide)
3. Test local PostgreSQL setup
4. Review authentication flow changes

### Next Week
1. Update application code (4-6 hour effort)
2. Deploy to staging
3. Begin data migration
4. Run validation tests

---

## APPENDIX: KEY AZURE DOCUMENTATION

1. **Node.js deployment:** https://learn.microsoft.com/en-us/azure/developer/javascript/how-to/deploy-web-app
2. **App Service configuration:** https://learn.microsoft.com/en-us/azure/app-service/configure-common
3. **PostgreSQL best practices:** https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/how-to-manage-high-availability
4. **Entra ID (Azure AD):** https://learn.microsoft.com/en-us/azure/app-service/configure-authentication-provider-aad
5. **Key Vault secrets:** https://learn.microsoft.com/en-us/azure/key-vault/general/overview
6. **Monitoring & alerting:** https://learn.microsoft.com/en-us/azure/azure-monitor/overview

---

## APPENDIX: POSTGRES MIGRATION SCRIPT TEMPLATE

```bash
#!/bin/bash
# Prerequisites: Azure CLI, psql client

RESOURCE_GROUP="knowerp-resources"
DB_SERVER="planner-db"
DB_NAME="plannerhostingdb"
DB_ADMIN="planner_admin"
DB_PASSWORD="<your-secure-password>"

# 1. Create PostgreSQL Flexible Server
az postgres flexible-server create \
  --resource-group $RESOURCE_GROUP \
  --name $DB_SERVER \
  --location eastus \
  --admin-user $DB_ADMIN \
  --admin-password $DB_PASSWORD \
  --sku-name Standard_B2s \
  --tier Burstable \
  --storage-size 32

# 2. Create database
az postgres flexible-server db create \
  --resource-group $RESOURCE_GROUP \
  --server-name $DB_SERVER \
  --database-name $DB_NAME

# 3. Allow App Service to connect
az postgres flexible-server firewall-rule create \
  --resource-group $RESOURCE_GROUP \
  --name $DB_SERVER \
  --rule-name AllowAzureServices \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0

# 4. Configure SSL (required)
az postgres flexible-server parameter set \
  --resource-group $RESOURCE_GROUP \
  --server-name $DB_SERVER \
  --name require_secure_transport \
  --value ON

# 5. Import schema
PGPASSWORD=$DB_PASSWORD psql \
  -h $DB_SERVER.postgres.database.azure.com \
  -U $DB_ADMIN@$DB_SERVER \
  -d $DB_NAME \
  -f schema.sql
```

---

## SUMMARY TABLE

| Aspect | Current (Cloudflare) | Recommended (Azure) |
|--------|----------------------|-------------------|
| **Host** | Workers + Vinext | App Service B2 |
| **Database** | D1 (SQLite) | PostgreSQL Flexible |
| **Cost** | $20/mo | $145/mo |
| **Auth** | ChatGPT | Microsoft Entra ID |
| **Scaling** | Auto | Auto + configurable |
| **Backups** | Limited | 14-day automated |
| **Monitoring** | Basic | Full Application Insights |
| **Setup Time** | 2-4 weeks | 2-4 weeks |
| **Migration Risk** | Low (new infra) | Low (clean schema) |

---

**Document prepared by:** Claude  
**Date:** October 5, 2026  
**Status:** Ready for implementation  
**Next: Await Azure subscription details for resource provisioning**
