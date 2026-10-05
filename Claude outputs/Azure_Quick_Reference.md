# Azure Migration - Quick Reference Card

## 🎯 THE ANSWER (TL;DR)

### Model to Use
```
Azure App Service - B2 tier (Standard)
├─ 2 vCores
├─ Cost: $85/month
└─ Handles 5-50 concurrent users
```

### Best Way to Host
```
┌─────────────────────────────┐
│   Azure App Service (B2)    │  ← Your Node.js app runs here
├─────────────────────────────┤
│ PostgreSQL Flexible Server  │  ← Your database (replaces D1)
├─────────────────────────────┤
│ Microsoft Entra ID          │  ← Auth (replaces ChatGPT)
├─────────────────────────────┤
│ Azure Key Vault             │  ← Secrets management
└─────────────────────────────┘
```

### Is Database Suitable? 
✅ **YES** - SQLite schema maps cleanly to PostgreSQL

### Dataverse?
❌ **NOT NOW** - Too expensive for transactional data  
⏳ **MAYBE LATER** - Phase 2 for Power BI reports

### Cost
```
Monthly:  $145/month
├─ App Service B2:     $85
├─ PostgreSQL:         $60
└─ Monitoring:          $5

First Year: ~$1,740 (vs Cloudflare ~$240)
```

---

## 📋 WHAT NEEDS TO CHANGE IN YOUR CODE

### 1. Database (30 mins)
```javascript
// Replace: db/store.ts
FROM: import { sql } from 'cloudflare:sql'
TO:   import { Pool } from 'pg'
```

### 2. Authentication (30 mins)
```javascript
// Replace: app/chatgpt-auth.ts
FROM: ChatGPT tokens
TO:   Microsoft Entra ID (Azure handles it)
```

### 3. Startup Command (15 mins)
```json
// Replace: package.json "start" script
FROM: "wrangler dev"
TO:   "node dist/server.js"
```

### 4. Database Schema (1 hour)
```sql
-- SQLite → PostgreSQL syntax
-- Drizzle can auto-convert most
-- Test locally first
```

**Total dev time: ~3-4 hours**

---

## ⏱️ TIMELINE

```
Week 1:  Setup Azure + plan migration
Week 2:  Code changes + local testing
Week 3:  Deploy to staging + data migration
Week 4:  Testing + go-live

Total: 2-4 weeks
```

---

## 💰 COST COMPARISON

```
CURRENT (Cloudflare)
├─ Workers:      $20/month
├─ D1 Database:  $0.50/month
└─ Total:        $20.50/month

NEW (Azure)
├─ App Service:  $85/month
├─ PostgreSQL:   $60/month
└─ Total:        $145/month

DIFFERENCE:      +$125/month (+608%)
WHY:             Better features, backups, auto-scaling
CAN REDUCE TO:   ~$100/mo by using B1 tier (not recommended)
```

---

## 🚀 ACTION ITEMS FOR YOU

### Today
- [ ] Read the full guide (Azure_Hosting_Guide.md)
- [ ] Share Azure subscription ID with IT
- [ ] Confirm team members authorized for Entra ID setup

### This Week
- [ ] Create Azure resource group
- [ ] Run provisioning script (I'll provide)
- [ ] Set up local PostgreSQL test environment

### Next Week
- [ ] Update application code (3-4 hours dev work)
- [ ] Deploy to staging environment
- [ ] Validate data migration

### Week 3-4
- [ ] Production deployment
- [ ] Training + monitoring setup
- [ ] Decommission Cloudflare

---

## 📞 SUPPORT NEEDED FROM YOU

To proceed, I need:
1. **Azure subscription ID**: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`
2. **Preferred region**: eastus, westus, canadaeast, etc.
3. **Resource naming prefix**: e.g., "knowerp" or "know-erp"
4. **Entra ID tenant ID**: Available in Azure portal
5. **Team members for Entra ID groups**: Who should have access?

---

## ✅ VALIDATION CHECKLIST (After Migration)

Your data must match:
- [ ] Total records match export-summary.json
- [ ] October 5 weekly allocation = 271.5 hours
- [ ] Vicky's hours = 48.25 hrs
- [ ] Sanjoy's hours = 43.75 hrs
- [ ] Perry's capacity = 20 hrs/week
- [ ] All projects preserved with correct IDs
- [ ] No duplicate allocations
- [ ] All 7 tables populated correctly

---

## 🔒 SECURITY SETTINGS (Pre-Launch)

```
☑ HTTPS enforced (automatic with Azure)
☑ Secrets in Key Vault (not in code)
☑ Database IP whitelist (App Service only)
☑ Microsoft Entra authentication required
☑ Automated daily backups (14-day retention)
☑ Monitor failed login attempts
☑ SSL/TLS 1.2+ enforced
```

---

## 🎓 DATAVERSE DECISION

| Scenario | Answer |
|----------|--------|
| "Need cheap hosting?" | Use PostgreSQL + App Service ($145/mo) |
| "Can I use Dataverse instead?" | No - too expensive for live data |
| "Should I use Dataverse at all?" | Later (Phase 2) for Power BI reports |
| "What's the hybrid approach?" | PostgreSQL for live data + Dataverse for reporting |
| "Cost impact of Dataverse?" | +$0.50-2/month (minimal) |

**Bottom line:** Dataverse doesn't replace your database, it supplements it later.

---

## 📊 ARCHITECTURE DIAGRAM

```
┌─────────────────────────────────────────────┐
│            Azure Portal                      │
│  (Resource Group: knowerp-resources)         │
└──────────────┬──────────────────────────────┘
               │
    ┌──────────┼──────────┐
    │          │          │
    ▼          ▼          ▼
┌────────┐ ┌────────┐ ┌──────────┐
│ App    │ │Database│ │   Key    │
│Service │ │(Postgres)│ │  Vault   │
│ B2     │ │        │ │(Secrets) │
└───┬────┘ └──┬─────┘ └──────────┘
    │         │
    │         ▼
    │    ┌─────────────────┐
    │    │   Backups       │
    │    │  (14-day)       │
    │    └─────────────────┘
    │
    ▼
┌──────────────┐
│   Entra ID   │
│ (Auth: SSO)  │
└──────────────┘
```

---

## 🛠️ COMMANDS YOU'LL RUN (Examples)

```bash
# Create resource group
az group create --name knowerp-resources --location eastus

# Create App Service
az appservice plan create --name knowerp-plan --resource-group knowerp-resources --sku B2

# Create PostgreSQL
az postgres flexible-server create --name knowerp-db --resource-group knowerp-resources --admin-user planneradmin

# Deploy app
git push azure main

# Check logs
az webapp log tail --name knowerp-app --resource-group knowerp-resources
```

---

## 📚 DOCUMENTATION LINKS

These are your go-to references:

1. [Node.js on Azure](https://learn.microsoft.com/en-us/azure/developer/javascript/how-to/deploy-web-app)
2. [App Service Configuration](https://learn.microsoft.com/en-us/azure/app-service/configure-common)
3. [PostgreSQL Setup](https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/quickstart-create-server-portal)
4. [Entra ID Integration](https://learn.microsoft.com/en-us/azure/app-service/configure-authentication-provider-aad)
5. [Key Vault Secrets](https://learn.microsoft.com/en-us/azure/key-vault/general/overview)

---

## ⚠️ COMMON MISTAKES TO AVOID

1. ❌ Using B1 tier (too slow, painful)  
   ✅ Use B2 minimum

2. ❌ Putting secrets in code or GitHub  
   ✅ Use Azure Key Vault always

3. ❌ Using Azure SQL instead of PostgreSQL  
   ✅ PostgreSQL is cheaper + easier migration

4. ❌ Trying to run Wrangler on App Service  
   ✅ Update startup command to run Node directly

5. ❌ Keeping ChatGPT authentication  
   ✅ Switch to Microsoft Entra ID (built-in)

6. ❌ Assuming Dataverse can replace your database  
   ✅ Use it for reporting only, later

7. ❌ Not testing data migration validation  
   ✅ Validate all record counts before production

---

## 🎯 SUCCESS CRITERIA

After migration, you should see:
- ✅ App loads in <2 seconds
- ✅ Team can log in with Microsoft 365 accounts
- ✅ All historical data preserved and accessible
- ✅ Weekly/monthly calculations work correctly
- ✅ Can edit and save allocations without errors
- ✅ Backups running automatically
- ✅ Costs are stable at ~$145/month

---

## 📞 READY TO PROCEED?

I can handle:
- ✅ Creating Azure resources
- ✅ Writing deployment scripts
- ✅ Code migration (PostgreSQL adapter)
- ✅ Data migration validation
- ✅ Testing & troubleshooting

You need to provide:
- Azure subscription details
- Team authorization approvals
- Entra ID setup (IT team)
- Final sign-off before go-live

**Next step:** Reply with your Azure subscription ID and we'll start provisioning.
