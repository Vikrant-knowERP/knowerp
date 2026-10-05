KNOW MODERN ERP — AZURE IT HANDOFF
Prepared October 5, 2026

STATUS: SOURCE AND DATA MIGRATION PACKAGE. NOT AN AZURE DEPLOYMENT ZIP.
The current app runs locally with Vinext/React, Cloudflare Workers, Cloudflare D1 (SQLite), and Sites/ChatGPT authentication. No Azure runtime, Azure database adapter, or Microsoft Entra sign-in adapter has been implemented or tested. Do not use the current npm start command to deploy it to Azure: it starts local Wrangler.

CONTENTS
source/: current app source, dependency lockfile, original schema migrations and framework configuration.
data/planner-data.json: raw persisted business records exported from the running planner. Derived weekly-to-monthly rollups are deliberately excluded to avoid double counting.
data/planner-sqlite.sql: schema plus inserts, independently restored and checked in SQLite. It is SQLite SQL, not Azure SQL/T-SQL or PostgreSQL syntax.
data/export-summary.json: record counts and October 5 weekly control total.

AZURE IMPLEMENTATION STEPS FOR IT
1. Choose Azure App Service (Node.js) or Azure Container Apps and a managed database, such as Azure Database for PostgreSQL or Azure SQL.
2. Replace the Cloudflare Workers/Vinext runtime with an Azure-compatible Node server/build. Configure a production start command and the platform's assigned port. Review vite.config.ts, next.config.ts, package.json and scripts/run-framework.mjs. Reuse the existing React screens and calculation functions.
3. Replace cloudflare:workers and D1 access in db/store.ts with the chosen database driver. Adapt prepared statements, transactions/batches, ON CONFLICT syntax and result shapes in app/api/planner/route.ts. Preserve parameterized queries, uniqueness keys, validation and transactions.
4. Translate db/schema.ts / drizzle migrations into the target database schema. Import JSON records in order: resources, projects, months, settings, allocations, capacity_adjustments, weekly_allocations. Preserve IDs and explicit zero vs null. Import allocations from the raw monthly table only; the app computes effective monthly totals from weekly records.
5. Replace app/chatgpt-auth.ts and requireChatGPTUser usages with Microsoft Entra authentication. For App Service, configure platform authentication to require sign-in; restrict access to the organization's tenant and approved users/group. Validate platform-supplied identity and block any bypass path. Do not trust the original oai-authenticated-user headers on Azure.
6. Replace starter seed-on-empty behavior for production with an explicit controlled initialization/import. Do not reseed the September screenshot over restored records.
7. Put database connection settings and secrets in Azure configuration/Key Vault; no credentials are included here. Configure backups and HTTPS.
8. Build and deploy the adapted app to a staging environment. Confirm two authorized team members can view and edit the same saved plan. Confirm unauthorized requests are rejected.
9. Reconcile all exported counts, project/resource totals, and the October 5 weekly plan (34 entries / 271.5 hours). Test save/reload, explicit zero, blank actuals, 75% billable goal, overload above 100% capacity, week/month boundary splits, and no duplicate monthly hours. Monthly source allocations must remain preserved.
10. Connect planner.<company-domain> using the Azure custom-domain instructions and the required DNS records in GoDaddy, then share the HTTPS link after testing.

KNOWN BUSINESS ITEMS
Advanced Turf has 120 budget hours but no confirmed start/end dates. Existing project names include source spellings/aliases (Infors=Infor, Effiency=Efficiency, EASTERN=Eastern Quality Foods, OPC - BC=OPC, Buttara=Buttura). Preserve IDs rather than duplicating these projects on import.
Project budget forecasting currently treats budget as the whole-project total spread across working days between project dates; monthly recurring budget semantics were not confirmed.
Vicky's October 5 weekly hours are 48.25 and Sanjoy's 43.75, exceeding their saved 40-hour capacities. Perry retains 20-hour weekly capacity.
The included data is private company planning information; provide it to the authorized IT team.

MICROSOFT DOCUMENTATION
Node app deployment: https://learn.microsoft.com/en-us/azure/developer/javascript/how-to/deploy-web-app
Microsoft Entra authentication: https://learn.microsoft.com/en-us/azure/app-service/configure-authentication-provider-aad
Storage guidance (do not put SQLite on Azure Storage mounts): https://learn.microsoft.com/en-us/azure/app-service/configure-connect-to-azure-storage?pivots=container-linux&tabs=portal
