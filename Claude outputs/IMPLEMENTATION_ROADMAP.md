# Azure Migration Implementation Roadmap
## Know Modern ERP - Financial Planner

**Prepared:** October 5, 2026  
**Status:** Ready to Execute  
**Timeline:** 2-4 weeks  
**Owner:** Vikrant (vikrantu@knowerp.com)

---

## EXECUTIVE SUMMARY

Your Next.js financial planning application is currently hosted on Cloudflare Workers with a SQLite database. This document outlines the complete migration to Azure App Service with PostgreSQL.

### Key Decisions Made:
| Decision | Choice | Rationale |
|----------|--------|-----------|
| **Hosting Platform** | Azure App Service B2 | Managed Node.js, auto-scaling, Microsoft Entra integration |
| **Database** | PostgreSQL (not Azure SQL) | Cheaper, easier migration from SQLite, better for web apps |
| **Authentication** | Microsoft Entra ID | Built-in with App Service, works with Microsoft 365 |
| **Use Dataverse** | Not now (Phase 2) | Too expensive for transactional data; save for Power BI |
| **Cost Model** | Fixed B2 tier | $145/month; predictable, room to scale |

---

## PHASE 1: DISCOVERY & PREPARATION (Week 1)

### 1.1 Get Azure Access
- [ ] **Action:** Obtain Azure subscription ID
- [ ] **Action:** Confirm resource group naming: `knowerp-resources`
- [ ] **Action:** Choose region: **eastus** (default) or specify other
- [ ] **Responsible:** IT/Admin
- [ ] **Time:** 1 day
- [ ] **Blocker?** No access to Azure = cannot proceed

**What you need to provide:**
```
- Azure subscription ID: ________________
- Tenant ID (from Azure AD): ________________
- Preferred region: ________________
- Service principal name: ________________
```

### 1.2 Entra ID Setup
- [ ] **Action:** Contact IT to create Entra ID Service Principal
- [ ] **Action:** Get Entra ID tenant ID
- [ ] **Action:** Create security group for app access
- [ ] **Responsible:** IT/Security team
- [ ] **Time:** 1-2 days
- [ ] **Details needed:**
  - App registration name: `know-erp-planner`
  - Redirect URI: `https://<app-service-name>.azurewebsites.net/.auth/login/aad/callback`
  - User group: Who should have access?

### 1.3 Document Current State
- [ ] **Action:** Export all data from Cloudflare D1
  - ✅ Already done: `data/planner-sqlite.sql`
  - ✅ Already done: `data/planner-data.json`
  - ✅ Already done: `data/export-summary.json`
- [ ] **Action:** Document current usage patterns
  - How many daily active users? ___
  - Peak hours? ___
  - Current load? ___
- [ ] **Responsible:** You / Operations
- [ ] **Time:** A few hours

### 1.4 Review Architecture
- [ ] **Action:** Review Azure_Hosting_Guide.md (Part 1-3)
- [ ] **Action:** Review Code_Migration_Examples.md
- [ ] **Action:** Identify which developers will own code migration
- [ ] **Responsible:** Tech lead / Development team
- [ ] **Time:** 2-3 hours

### 1.5 Create Test Plan
- [ ] **Action:** Document test scenarios (see validation checklist below)
- [ ] **Action:** Identify staging environment users
- [ ] **Action:** Plan data validation approach
- [ ] **Responsible:** QA / Product
- [ ] **Time:** 1-2 hours

**Deliverables from Phase 1:**
- ✅ Azure subscription access confirmed
- ✅ Entra ID setup initiated
- ✅ Development team briefed and roles assigned
- ✅ Test plan documented
- ✅ Current data backed up and cataloged

---

## PHASE 2: INFRASTRUCTURE SETUP (Days 3-5)

### 2.1 Provision Azure Resources

**Option A: Automated (Recommended)**
```bash
# Run the provided script
bash azure_deploy.sh

# This creates:
# - Resource Group
# - App Service Plan (B2)
# - App Service (Node.js)
# - PostgreSQL Flexible Server
# - Key Vault
# - Application Insights
# - Firewall rules
```

**Option B: Manual (Azure Portal)**
- [ ] **Action:** Create Resource Group: `knowerp-resources`
- [ ] **Action:** Create App Service Plan: `knowerp-plan` (B2, Linux, Node.js 20 LTS)
- [ ] **Action:** Create App Service: `knowerp-app`
- [ ] **Action:** Create PostgreSQL Server: `knowerp-db`
  - Admin: `planner_admin`
  - Storage: 32GB
  - Backups: 7-day retention
- [ ] **Action:** Create Key Vault: `knowerp-vault`

**Responsible:** DevOps / IT  
**Time:** 30 minutes (automated) or 2-3 hours (manual)  
**Cost:** $0 (first 1 month free if Azure credits available)

### 2.2 Store Secrets in Key Vault
- [ ] **Action:** Create secrets:
  - `database-connection-string`
  - `database-password`
  - `azure-tenant-id`
  - `azure-client-id` (if not using Managed Identity)

```bash
az keyvault secret set --vault-name knowerp-vault \
  --name database-connection-string \
  --value "postgresql://planner_admin:PASSWORD@knowerp-db.postgres.database.azure.com:5432/plannerhostingdb?sslmode=require"
```

**Responsible:** DevOps  
**Time:** 15 minutes

### 2.3 Configure Database
- [ ] **Action:** Disable public access (allow only Azure services)
- [ ] **Action:** Configure SSL requirement
- [ ] **Action:** Set backup retention to 7 days
- [ ] **Action:** Enable monitoring/alerts

```sql
-- Test connection from local machine (for migration)
psql -h knowerp-db.postgres.database.azure.com \
     -U planner_admin \
     -d plannerhostingdb

-- Should show: "psql (x.x.x, server x.x.x)"
```

**Responsible:** DevOps  
**Time:** 20 minutes

### 2.4 Configure App Service
- [ ] **Action:** Set startup command: `npm start`
- [ ] **Action:** Configure environment variables:
  - `NODE_ENV=production`
  - `WEBSITE_NODE_DEFAULT_VERSION=20-lts`
- [ ] **Action:** Enable logging/diagnostics
- [ ] **Action:** Grant Managed Identity access to Key Vault

**Responsible:** DevOps  
**Time:** 15 minutes

**Deliverables from Phase 2:**
- ✅ All Azure resources provisioned
- ✅ Database created and accessible
- ✅ Secrets stored in Key Vault
- ✅ App Service configured and ready
- ✅ Monitoring enabled

---

## PHASE 3: CODE MIGRATION (Days 6-9)

### 3.1 Prepare Development Environment
- [ ] **Action:** Clone repository
- [ ] **Action:** Create feature branch: `feature/azure-migration`
- [ ] **Action:** Create `.env.local` with PostgreSQL connection
```bash
DATABASE_URL="postgresql://planner_admin:password@localhost:5432/plannerhostingdb?sslmode=disable"
NODE_ENV=development
```
- [ ] **Action:** Set up local PostgreSQL test database
  - See Code_Migration_Examples.md section 10
  - Or use Docker: `docker run -d -e POSTGRES_PASSWORD=password -p 5432:5432 postgres:15`

**Responsible:** Development team  
**Time:** 30 minutes

### 3.2 Update Dependencies
- [ ] **Action:** Update `package.json`
```bash
npm install pg dotenv
npm uninstall @cloudflare/vite-plugin wrangler vinext
```
- [ ] **Action:** Update `drizzle.config.ts` for PostgreSQL dialect
- [ ] **Action:** Run `npm install` to verify no conflicts

**Time:** 15 minutes

### 3.3 Implement Database Adapter
- [ ] **File:** `db/store.ts`
  - Replace D1 adapter with PostgreSQL pool
  - Implement connection pooling
  - Update transaction handling
  - Reference: Code_Migration_Examples.md section 2
- [ ] **Action:** Test connection locally
```bash
npm run dev
# Should log: "Database connection successful"
```
- [ ] **Responsible:** Backend developer
- [ ] **Time:** 1-2 hours

### 3.4 Implement Authentication
- [ ] **File:** `app/chatgpt-auth.ts`
  - Replace ChatGPT token validation
  - Implement Entra ID header parsing
  - Update `requireAuth` middleware
  - Reference: Code_Migration_Examples.md section 5
- [ ] **Action:** Test authentication locally
  - Inject test headers: `X-MS-CLIENT-PRINCIPAL-ID: test-user`
  - Should pass auth checks
- [ ] **Responsible:** Auth/Security developer
- [ ] **Time:** 1-1.5 hours

### 3.5 Update API Routes
- [ ] **Files affected:**
  - `app/api/planner/route.ts` (main allocation endpoint)
  - Any other API routes using D1
- [ ] **Changes:**
  - Replace D1 SQL with PostgreSQL parameterized queries
  - Update ON CONFLICT syntax (D1 → PostgreSQL)
  - Update result shape handling
  - Reference: Code_Migration_Examples.md section 4
- [ ] **Action:** Test each endpoint locally
- [ ] **Responsible:** Backend team
- [ ] **Time:** 2-3 hours

### 3.6 Update Configuration Files
- [ ] **File:** `next.config.ts`
  - Set `output: 'standalone'` for Node.js
  - Remove Cloudflare-specific config
  - Reference: Code_Migration_Examples.md section 7
- [ ] **File:** `package.json`
  - Update `start` script: `node dist/server.js`
  - Reference: Code_Migration_Examples.md section 1
- [ ] **Time:** 30 minutes

### 3.7 Local Testing
- [ ] **Action:** `npm run build`
  - Should complete without errors
  - Check for any migration-related warnings
- [ ] **Action:** `npm start` locally
  - Should start on port 3000
  - Should connect to local PostgreSQL
  - Check logs for errors
- [ ] **Action:** Test key workflows:
  - Login (inject test Entra ID headers)
  - Create allocation
  - Update allocation
  - View weekly summary
  - Export data
- [ ] **Responsible:** QA / Development
- [ ] **Time:** 2 hours

### 3.8 Code Review
- [ ] **Action:** Submit PR for review
- [ ] **Action:** Address review comments
- [ ] **Action:** Get approval from tech lead
- [ ] **Time:** 1-2 hours

**Deliverables from Phase 3:**
- ✅ All code changes implemented
- ✅ Local testing passed
- ✅ Code reviewed and approved
- ✅ Ready for staging deployment

---

## PHASE 4: STAGING DEPLOYMENT (Days 10-11)

### 4.1 Deploy to Staging
- [ ] **Action:** Merge feature branch to `staging` (or `develop`)
- [ ] **Action:** Configure Git deployment
```bash
# Add Azure as remote
git remote add azure <deployment-url-from-script>

# Push to Azure
git push azure staging:main  # or git push azure main
```
- [ ] **Action:** Monitor deployment logs
```bash
az webapp log tail --name knowerp-app --resource-group knowerp-resources
```
- [ ] **Action:** Wait for build to complete
  - Usually takes 2-5 minutes
  - Watch for npm install, build, start commands

**Responsible:** DevOps / Developer  
**Time:** 10-15 minutes

### 4.2 Verify Staging Deployment
- [ ] **Action:** Check application health
```bash
curl https://knowerp-app-staging.azurewebsites.net/
# Should return HTML or API response
```
- [ ] **Action:** Check Application Insights
  - Go to Azure Portal
  - View logs and performance metrics
  - Look for any error patterns
- [ ] **Action:** Test application manually
  - Load main page
  - Check console for JavaScript errors
  - Verify styling/UI renders correctly

**Time:** 15 minutes

---

## PHASE 5: DATA MIGRATION (Days 12-13)

### 5.1 Create PostgreSQL Schema
- [ ] **Action:** Generate Drizzle migration for PostgreSQL
```bash
npm run db:generate
```
- [ ] **Action:** Apply migrations to Azure PostgreSQL
```bash
# Via psql from local machine
psql -h knowerp-db.postgres.database.azure.com \
     -U planner_admin \
     -d plannerhostingdb \
     -f drizzle/schema.sql
```
- [ ] **Action:** Verify schema creation
```sql
\dt  -- should list all 7 tables
SELECT COUNT(*) FROM resources;  -- should be 0 initially
```

**Responsible:** DevOps / DBA  
**Time:** 30 minutes

### 5.2 Import Data from Cloudflare
- [ ] **Option A: From JSON export** (recommended)
  ```bash
  # Use app endpoint to import
  curl -X POST https://knowerp-app-staging.azurewebsites.net/api/import \
    -H "Content-Type: application/json" \
    -d @data/planner-data.json
  ```
- [ ] **Option B: From SQLite export** (if needed)
  ```bash
  # Convert SQLite dump to PostgreSQL syntax
  # Then import via psql
  psql -h knowerp-db.postgres.database.azure.com \
       -U planner_admin \
       -d plannerhostingdb \
       -f data/planner-sqlite.sql
  ```
- [ ] **Action:** Monitor import progress
  - Watch Application Insights logs
  - Check database size growth

**Responsible:** DevOps / Data engineer  
**Time:** 30-45 minutes

### 5.3 Validate Data Integrity
Reference: `data/export-summary.json`

**Critical Validations:**
- [ ] **Resource count:** Should match export
```sql
SELECT COUNT(*) FROM resources;  -- Expected: X
SELECT COUNT(*) FROM projects;   -- Expected: Y
SELECT COUNT(*) FROM allocations; -- Expected: Z
```

- [ ] **October 5 Weekly Total:** 271.5 hours
```sql
SELECT SUM(hours) FROM weekly_allocations 
WHERE week = '2026-10-05';  -- Should be 271.5
```

- [ ] **Individual resource totals:**
  - Vicky: 48.25 hours
  - Sanjoy: 43.75 hours
  - Perry: 20 hours capacity (check weekly_allocations)

- [ ] **Project budget preservation:**
```sql
SELECT id, name, budget FROM projects 
WHERE budget IS NOT NULL;  -- Verify budgets match export
```

- [ ] **No duplicate allocations:**
```sql
SELECT resource_id, project_id, month, COUNT(*) 
FROM allocations 
GROUP BY resource_id, project_id, month 
HAVING COUNT(*) > 1;  -- Should return 0 rows
```

- [ ] **Data types correct:**
  - Numeric fields should be DECIMAL, not text
  - Boolean fields should be boolean (true/false), not 1/0
  - Dates should be valid DATE/TIMESTAMP

**Validation checklist:**
```
✓ All record counts match export-summary.json
✓ Weekly allocation total = 271.5 hours
✓ Individual resource allocations correct
✓ Project budgets preserved with correct IDs
✓ No duplicates in unique indices
✓ All foreign key relationships intact
✓ Null/zero handling matches business rules
✓ Calculated fields (totals, averages) work correctly
```

**Responsible:** QA / Data validation team  
**Time:** 1-2 hours

### 5.4 Create Data Backup
- [ ] **Action:** Create backup of staging database
```bash
az postgres flexible-server backup create \
  --resource-group knowerp-resources \
  --server-name knowerp-db \
  --backup-name pre-production-backup
```
- [ ] **Action:** Test restore from backup
  - Document restore procedure
  - Verify restore point-in-time recovery works
- [ ] **Responsible:** DevOps
- [ ] **Time:** 30 minutes

**Deliverables from Phase 5:**
- ✅ PostgreSQL schema created
- ✅ Data imported from Cloudflare
- ✅ All validations passed
- ✅ Database backup created
- ✅ Ready for user testing

---

## PHASE 6: STAGING TESTING (Days 14-15)

### 6.1 Functional Testing
- [ ] **Action:** Test all planner features:
  - [ ] View weekly planner
  - [ ] Create new allocation
  - [ ] Edit existing allocation
  - [ ] Delete allocation
  - [ ] Update resource capacity
  - [ ] View monthly summary
  - [ ] Export data
  - [ ] Generate reports

- [ ] **Action:** Test edge cases:
  - [ ] Allocations exceeding 100% capacity
  - [ ] Year/month boundary splits
  - [ ] Decimal hour handling (e.g., 7.5 hours)
  - [ ] Null vs zero differentiation
  - [ ] Special characters in names
  - [ ] Concurrent user edits

**Responsible:** QA / Product  
**Time:** 4 hours

### 6.2 Performance Testing
- [ ] **Action:** Simulate load (5-10 concurrent users)
```bash
# Example with Apache Bench
ab -n 100 -c 10 https://knowerp-app-staging.azurewebsites.net/api/planner
```
- [ ] **Metrics to check:**
  - Response time < 1 second (p95)
  - Error rate < 0.1%
  - Database query time < 200ms
  - Memory usage stable

**Responsible:** DevOps / Performance engineer  
**Time:** 1 hour

### 6.3 Security Testing
- [ ] **Action:** Verify authentication enforced
  - Unauthenticated requests should get 401
  - Only authorized users see data
- [ ] **Action:** Check for SQL injection vulnerabilities
  - Test with special characters: `'; DROP TABLE--`
  - Parameterized queries should prevent this
- [ ] **Action:** Verify HTTPS enforced
- [ ] **Action:** Check secret handling
  - No secrets in logs
  - Secrets come from Key Vault

**Responsible:** Security team  
**Time:** 2 hours

### 6.4 User Acceptance Testing (UAT)
- [ ] **Action:** Invite 2-3 end users to test
- [ ] **Action:** Provide UAT checklist
- [ ] **Action:** Collect feedback
- [ ] **Action:** Address critical issues before production

**Responsible:** Product / Stakeholders  
**Time:** 4-6 hours

**Deliverables from Phase 6:**
- ✅ All functional tests passed
- ✅ Performance acceptable
- ✅ Security validated
- ✅ User acceptance obtained
- ✅ Approved for production

---

## PHASE 7: PRODUCTION DEPLOYMENT (Day 16)

### 7.1 Final Checks
- [ ] **Action:** Verify production database is ready
- [ ] **Action:** Verify all secrets are in production Key Vault
- [ ] **Action:** Create final backup of Cloudflare data
- [ ] **Action:** Get stakeholder sign-off
- [ ] **Time:** 30 minutes

### 7.2 Deploy to Production
- [ ] **Action:** Create production deployment slot
  - Allows zero-downtime deployment
  - Swap after verification
- [ ] **Action:** Merge to `main` branch
- [ ] **Action:** Push to production
```bash
git push azure main
```
- [ ] **Action:** Monitor deployment logs
- [ ] **Action:** Test production environment
- [ ] **Responsible:** DevOps
- [ ] **Time:** 15 minutes

### 7.3 Data Migration to Production
- [ ] **Action:** Repeat data import to production
  - Same process as staging (Phase 5.2)
  - Different database server
- [ ] **Action:** Validate production data
  - Same validation checklist (Phase 5.3)
- [ ] **Action:** Create production backup
- [ ] **Time:** 45 minutes

### 7.4 Switch DNS/Domain
- [ ] **Action:** Update DNS records to point to Azure
  - From: Cloudflare Workers
  - To: Azure App Service
  - TXT record: Azure verification
  - CNAME record: knowerp-app.azurewebsites.net
- [ ] **Action:** Wait for DNS propagation (15-30 minutes)
- [ ] **Action:** Verify HTTPS certificate (auto-managed by Azure)
- [ ] **Action:** Test custom domain access
- [ ] **Responsible:** IT / Network
- [ ] **Time:** 1 hour (including propagation)

### 7.5 Post-Launch Monitoring
- [ ] **Action:** Monitor for first 4 hours:
  - Watch Application Insights dashboard
  - Check error logs
  - Monitor database performance
  - Watch user activity
- [ ] **Action:** Set up alerts
  - HTTP 5xx errors > 5 in 5 minutes
  - Database connection failures
  - High CPU usage (> 80%)
  - High memory usage (> 90%)
- [ ] **Action:** Be on-call for urgent issues
- [ ] **Responsible:** DevOps / On-call
- [ ] **Time:** 4+ hours

**Deliverables from Phase 7:**
- ✅ Production deployment complete
- ✅ DNS/Domain migrated
- ✅ Production data validated
- ✅ Team notified of live status
- ✅ Monitoring active

---

## PHASE 8: CLEANUP & DOCUMENTATION (Days 17-18)

### 8.1 Decommission Cloudflare
- [ ] **Action:** Disable Cloudflare Workers deployment
- [ ] **Action:** Disable D1 database backups
- [ ] **Action:** Archive Wrangler configuration
- [ ] **Action:** Keep Cloudflare DNS active (fallback)
  - Don't delete immediately
  - Keep for 30 days as rollback option

**Responsible:** DevOps  
**Time:** 1 hour

### 8.2 Update Documentation
- [ ] **Action:** Create Azure runbooks
  - How to restart app
  - How to scale up/down
  - How to access database
  - How to view logs
- [ ] **Action:** Document emergency procedures
  - How to rollback to Cloudflare
  - How to restore from backup
  - How to get support
- [ ] **Action:** Update team onboarding docs
- [ ] **Action:** Archive migration documentation

**Responsible:** DevOps / Tech lead  
**Time:** 2 hours

### 8.3 Schedule First Backup Recovery Test
- [ ] **Action:** Plan for Day 30 (November 4)
- [ ] **Action:** Create test database from backup
- [ ] **Action:** Verify recovery process works
- [ ] **Action:** Document results
- [ ] **Time:** Will be scheduled for later

### 8.4 Plan Phase 2: Dataverse Integration (Optional)
- [ ] **Action:** Document use case for Dataverse
- [ ] **Action:** Estimate effort and cost
- [ ] **Action:** Schedule for Q4/Q1 if approved
- [ ] **Time:** Planning only

**Deliverables from Phase 8:**
- ✅ Cloudflare decommissioned
- ✅ Comprehensive runbooks created
- ✅ Team trained on new environment
- ✅ Documentation complete
- ✅ Ready for ongoing operations

---

## DECISION GATES & APPROVALS

### Gate 1: Architecture Approval (End of Phase 1)
**Required Approvers:** CTO, Security, Operations  
**Criteria:**
- ✅ All architecture decisions agreed
- ✅ Budget approved
- ✅ Timeline acceptable
- ✅ Risk assessment completed

### Gate 2: Infrastructure Ready (End of Phase 2)
**Required Approvers:** DevOps lead  
**Criteria:**
- ✅ All Azure resources provisioned
- ✅ Database accessible and tested
- ✅ Monitoring configured
- ✅ Backups working

### Gate 3: Code Ready (End of Phase 3)
**Required Approvers:** Tech lead, Security  
**Criteria:**
- ✅ All code changes complete
- ✅ Code reviewed
- ✅ Local testing passed
- ✅ No security vulnerabilities

### Gate 4: Staging Validated (End of Phase 6)
**Required Approvers:** QA, Product, Security  
**Criteria:**
- ✅ All tests passed
- ✅ Performance acceptable
- ✅ UAT approved
- ✅ No critical bugs

### Gate 5: Ready for Production (Day 16)
**Required Approvers:** CTO, DevOps, Product, Security  
**Criteria:**
- ✅ Staging approved
- ✅ Rollback plan documented
- ✅ On-call team ready
- ✅ Communication sent to users

---

## RISK MITIGATION

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| Data loss in migration | Low | Critical | Daily backups, validation checks, rollback plan |
| Authentication failures | Medium | High | Thorough testing in staging, IT support on-call |
| Performance degradation | Medium | High | Load testing, resource scaling prepared |
| Incomplete code migration | Low | High | Checklist, code review, staging testing |
| Downtime during cutover | Low | Critical | Zero-downtime deployment slots, DNS failover |
| Cost overruns | Low | Medium | Price alerts configured, auto-scale limits set |

---

## ROLLBACK PLAN

If production deployment fails:

### Option 1: Quick Rollback (< 1 hour)
```bash
# Switch back to Cloudflare Workers
# DNS points back to Cloudflare
# Users redirected to old system
# Data kept in Azure (not deleted)
```

**Requirements:**
- Keep Cloudflare deployment running for 48 hours after cutover
- Keep DNS routing flexible
- Document exact DNS records needed

### Option 2: Restore from Backup (2-4 hours)
```bash
# Restore PostgreSQL from pre-migration backup
# Restore app to previous stable build
# Resume with Cloudflare
```

**Requirements:**
- Backup verified before deployment
- Restore procedure documented and tested
- IT team available

### Option 3: Hot Fix (depends on issue)
```bash
# Deploy code fix
# Update configuration
# Restart services
```

**Requirements:**
- Fast deployment pipeline
- Monitoring to catch issues immediately

**Chosen Strategy:** Option 1 (safest) during first 48 hours, then Option 2

---

## COMMUNICATION PLAN

### Pre-Launch
- [ ] Day 1: Announce migration to team
- [ ] Day 7: Notify key stakeholders of start
- [ ] Day 13: Announce staging testing date
- [ ] Day 15: 24-hour pre-launch notice

### Launch Day
- [ ] 30 min before: "Deployment beginning"
- [ ] During: Monitor and provide updates every 15 min
- [ ] At go-live: "System live" notification
- [ ] +30 min: "Stability check complete"
- [ ] +4 hours: "Production stable, monitoring ongoing"
- [ ] +48 hours: "All-clear, Cloudflare decommissioned"

### Post-Launch
- [ ] Weekly status updates (first month)
- [ ] Monthly performance reports
- [ ] Document lessons learned

---

## SUCCESS METRICS

### Technical Metrics
```
Response Time:      < 1 second (p95)
Uptime:             99.5%+
Error Rate:         < 0.1%
Database Latency:   < 200ms (p95)
Page Load:          < 2 seconds
```

### Business Metrics
```
User Adoption:      100% (all team members)
Data Accuracy:      100% (all records matched)
Cost on Target:     ~$145/month
Team Satisfaction:  8/10 or higher
```

### Migration Success
```
Timeline:           Met or ahead of schedule
Budget:             Within estimates
Zero Data Loss:     ✅ Confirmed
Zero Production Down: ✅ Verified
All Features Work:  ✅ Tested
```

---

## APPENDIX: QUICK REFERENCE

### Important URLs
- **Azure Portal:** https://portal.azure.com
- **Application:** https://<your-domain>.azurewebsites.net
- **Key Vault:** https://knowerp-vault.vault.azure.net
- **Database:** knowerp-db.postgres.database.azure.com:5432

### Important Commands
```bash
# View logs
az webapp log tail -n knowerp-app -g knowerp-resources

# Restart app
az webapp restart -n knowerp-app -g knowerp-resources

# Scale app
az appservice plan update -n knowerp-plan -g knowerp-resources --sku P1v3

# Database backup
az postgres flexible-server backup create -n knowerp-db -g knowerp-resources

# Check deployment status
git log --oneline | head -5
```

### Support Contacts
- Azure Support: support@microsoft.com
- Your IT Team: [contact info]
- DevOps On-Call: [phone number]

### Emergency Procedures
- **App won't start?** Check logs with `az webapp log tail`
- **Database connection fails?** Verify connection string in Key Vault
- **Auth not working?** Check Entra ID configuration
- **Data looks wrong?** Restore from backup and rerun validation

---

## FINAL CHECKLIST

### Before Starting
- [ ] All stakeholders aware and approved
- [ ] Developers trained on Azure architecture
- [ ] DevOps team prepared
- [ ] Security review completed
- [ ] IT team ready for Entra ID setup

### During Migration
- [ ] Each phase has explicit sign-off
- [ ] Issues tracked and documented
- [ ] Team communication active
- [ ] Backups created at each phase
- [ ] Rollback plan practiced

### After Migration
- [ ] Production validated and stable
- [ ] Cloudflare safely decommissioned
- [ ] Runbooks documented
- [ ] Team trained on new procedures
- [ ] Monitoring alerts configured
- [ ] Budget tracking active

---

## NEXT STEPS

1. **TODAY:** Review this document with your team
2. **TOMORROW:** Provide Azure subscription details
3. **THIS WEEK:** Start Phase 1 preparation
4. **NEXT WEEK:** Execute Phases 1-2 (infrastructure)
5. **WEEK 2:** Execute Phase 3 (code migration)
6. **WEEK 3:** Execute Phases 4-6 (staging & testing)
7. **WEEK 4:** Execute Phase 7 (production launch)

---

**Document Owner:** Claude (AI Assistant)  
**Last Updated:** October 5, 2026  
**Status:** Ready for Execution  
**Contact for Questions:** vikrantu@knowerp.com  

---

**Approve and Sign Off Below:**

```
CTO/Tech Lead Approval: ______________________ Date: ______
Security Team Approval: ______________________ Date: ______
Operations Lead Approval: ______________________ Date: ______
Project Owner Approval: ______________________ Date: ______
```

Once signed, you're ready to proceed with Phase 1!
