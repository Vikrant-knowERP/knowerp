# TECHNICAL ARCHITECTURE: 3 OPTIONS EXPLAINED
## Visual & Technical Breakdown for Technical Review

---

## OPTION 1: POSTGRESQL (RECOMMENDED)

### System Architecture Diagram
```
┌─────────────────────────────────────────────────────────┐
│                   Azure Cloud                            │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  ┌─────────────────────────────┐                        │
│  │   Your Next.js App          │                        │
│  │   (App Service B2)          │                        │
│  │                             │                        │
│  │  • Resource Planning UI     │                        │
│  │  • Weekly/Monthly Views     │                        │
│  │  • API Endpoints            │                        │
│  └────────────┬────────────────┘                        │
│               │                                          │
│      ┌────────▼─────────┐                               │
│      │  PostgreSQL DB   │                               │
│      │  (Flexible Svr)  │                               │
│      │                  │                               │
│      │ • Allocations    │                               │
│      │ • Resources      │                               │
│      │ • Projects       │                               │
│      │ • Capacity Data  │                               │
│      └──────────────────┘                               │
│               │                                          │
│      ┌────────▼─────────┐                               │
│      │ Microsoft Entra  │                               │
│      │      (Auth)      │                               │
│      │                  │                               │
│      │ Single Sign-On   │                               │
│      │ Role Management  │                               │
│      └──────────────────┘                               │
│               │                                          │
│      ┌────────▼──────────────┐                          │
│      │ Key Vault (Secrets)   │                          │
│      │ Application Insights  │                          │
│      │ (Monitoring)          │                          │
│      └───────────────────────┘                          │
│                                                          │
└─────────────────────────────────────────────────────────┘

Users
  ↓
Browser (HTTPS)
  ↓
App Service → PostgreSQL → Fast (50-100ms)
```

### Data Flow Example: Save Allocation
```
User clicks "Save" in UI
    ↓
POST /api/planner/allocations
    ↓
App Server validates input
    ↓
Database Query:
    INSERT INTO allocations (resource_id, project_id, month, hours)
    VALUES ($1, $2, $3, $4)
    ON CONFLICT(resource_id, project_id, month) DO UPDATE
    SET hours = $4
    ↓
PostgreSQL executes → Response in 5-50ms
    ↓
App returns {success: true, hours: 8.5}
    ↓
UI updates immediately (fast!)
    ↓
TOTAL TIME: 50-100ms ✅
```

### What Makes This Work
```
✅ SQL Queries: Direct, fast, simple
✅ Transactions: ACID guarantees
✅ Connections: Connection pooling (reuse connections)
✅ Scaling: Add vertical resources (more CPU/RAM)
✅ Backups: Automated, point-in-time recovery
✅ Monitoring: Built-in Azure monitoring
```

### Code Example (What Dev Writes)
```javascript
// Simple, clean SQL
const result = await db.query(`
  INSERT INTO allocations 
    (id, resource_id, project_id, month, hours, actual)
  VALUES ($1, $2, $3, $4, $5, $6)
  ON CONFLICT(resource_id, project_id, month)
  DO UPDATE SET hours = $5
  RETURNING *
`, [id, resourceId, projectId, month, hours, actual]);
```

---

## OPTION 2: DATAVERSE HYBRID (BALANCED APPROACH)

### System Architecture Diagram
```
┌────────────────────────────────────────────────────────────┐
│                     Azure Cloud                             │
├────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────────────────────┐                          │
│  │   Your Next.js App           │                          │
│  │   (App Service B2)           │                          │
│  │                              │                          │
│  │ • Planning UI                │                          │
│  │ • Fast API calls             │                          │
│  │ • Allocation Logic           │                          │
│  └────────┬─────────────────────┘                          │
│           │                                                  │
│  ┌────────┴─────────┬──────────────┐                       │
│  │                  │              │                       │
│  ▼                  ▼              ▼                       │
│  ┌──────────┐  ┌──────────────┐  ┌─────────────────┐     │
│  │Dataverse │  │  PostgreSQL  │  │ Microsoft Entra │     │
│  │Web API   │  │     DB       │  │  (Auth)         │     │
│  │          │  │              │  │                 │     │
│  │Resources │  │ Allocations  │  │ Single Sign-On  │     │
│  │Projects  │  │ Weekly Plans │  │ Role Management │     │
│  │(Master)  │  │ (Transactions)  │                 │     │
│  └──────────┘  └──────────────┘  └─────────────────┘     │
│       │                ▲                                    │
│       └────────────────┘                                    │
│                │                                            │
│    ┌──────────▼─────────┐                                  │
│    │  Weekly Sync Job   │                                  │
│    │  (Every night)     │                                  │
│    │                    │                                  │
│    │ Copy allocations   │                                  │
│    │ Aggregate to       │                                  │
│    │ Dataverse          │                                  │
│    └────────┬───────────┘                                  │
│             │                                              │
│             ▼                                              │
│    ┌────────────────────┐                                 │
│    │  Power BI / Dashboards                               │
│    │  Teams Sharing                                       │
│    │  Reporting                                           │
│    └────────────────────┘                                 │
│                                                            │
└────────────────────────────────────────────────────────────┘

Users
  ↓
Browser
  ↓
Fast Path (Daily):        Reporting Path (Weekly):
App → PostgreSQL (50ms)   Dataverse → Power BI
```

### Data Flow Example: Save + Report
```
LIVE OPERATION (Fast):
User saves allocation
    ↓
POST /api/planner/allocations
    ↓
PostgreSQL UPDATE → 50-100ms response ✅
    ↓
UI updates immediately

REPORT GENERATION (Background):
Every night at 2 AM:
    ↓
Sync Job reads PostgreSQL allocations
    ↓
Aggregates by project, resource, month
    ↓
Writes summary to Dataverse
    ↓
Power BI refreshes from Dataverse
    ↓
Dashboard shows totals, trends, budget status
```

### What Makes This Work
```
✅ Transaction Speed: PostgreSQL (50-100ms)
✅ Master Data: Dataverse resources/projects
✅ Reporting: Power BI native integration
✅ Governance: Audit trail in Dataverse
✅ Analytics: BI dashboards in Teams
✅ Sync: Automated nightly, 5-10 min process
```

### Code Example (Dual System)
```javascript
// Live allocation (fast path, PostgreSQL)
const allocation = await db.query(`
  INSERT INTO allocations (...)
  VALUES ($1, $2, ...)
`, [data]);

// Nightly sync job (write to Dataverse)
const sync = () => {
  // Read from PostgreSQL
  const totals = await db.query(`
    SELECT project_id, SUM(hours) as total
    FROM allocations WHERE month = $1
    GROUP BY project_id
  `, [month]);
  
  // Write to Dataverse
  for (const {project_id, total} of totals) {
    await dataverse.update(`/projects(${project_id})`, {
      totalAllocatedHours: total
    });
  }
};
```

---

## OPTION 3: DATAVERSE ONLY (NOT RECOMMENDED)

### System Architecture Diagram
```
┌────────────────────────────────────────────────────────────┐
│                     Azure Cloud                             │
├────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────────────────────┐                          │
│  │   Your Next.js App           │                          │
│  │   (App Service B2)           │                          │
│  │                              │                          │
│  │ • All API calls to           │                          │
│  │   Dataverse Web API          │                          │
│  │ • No local database          │                          │
│  └────────┬─────────────────────┘                          │
│           │                                                  │
│  ┌────────▼──────────────────┐     ┌──────────────────┐    │
│  │  Dataverse Web API        │     │ Microsoft Entra  │    │
│  │                           │     │  (Auth)          │    │
│  │ • Resources (REST call)   │     │                  │    │
│  │ • Projects (REST call)    │     │ Single Sign-On   │    │
│  │ • Allocations (REST call) │     │ Role Management  │    │
│  │ • Weekly Plans (REST)     │     │                  │    │
│  │                           │     └──────────────────┘    │
│  │ ⚠️ EVERY operation goes   │                              │
│  │    through Web API        │                              │
│  │    2,000 calls/min limit  │                              │
│  └─────────────────────┬─────┘                              │
│                        │                                     │
│             ┌──────────▼─────────┐                          │
│             │  Power BI (Direct) │                          │
│             │  Teams Integration │                          │
│             └────────────────────┘                          │
│                                                              │
└────────────────────────────────────────────────────────────┘

Users
  ↓
Browser
  ↓
App Service
  ↓
All operations via REST API (Slow!)
  ↓
300-500ms per operation (waiting...)
```

### Data Flow Example: Save Allocation
```
User clicks "Save"
    ↓
POST /api/planner/allocations
    ↓
App builds HTTP request:
    PATCH /api/data/v9.2/allocations(id=xxx)
    Headers: {Authorization: Bearer token, ...}
    Body: {resource_id: "R1", hours: 8.5}
    ↓
NETWORK LATENCY: +20ms
    ↓
Dataverse API receives request
    ↓
Dataverse processes: +200-300ms
    ↓
Checks permissions, validates, writes
    ↓
Returns response
    ↓
NETWORK LATENCY: +20ms
    ↓
App receives response
    ↓
UI updates
    ↓
TOTAL TIME: 300-500ms ❌ (User waits, feels slow)

Problem: Each operation is a separate API call
Save 10 allocations = 10 REST calls = 3-5 seconds wait!
```

### What Makes This Difficult
```
❌ REST API Overhead: 200-400ms per call vs 5-50ms SQL
❌ No Transactions: Batch updates hard/impossible
❌ Rate Limiting: 2,000 calls/minute = easily hit
❌ Async Operations: Some writes become delayed
❌ Error Handling: More complex with API failures
❌ Scaling: Cost goes up with every record added
```

### Code Example (Verbose, Complex)
```javascript
// Need auth token
const token = await getDataverseToken();

// Single allocation save (SLOW)
const response = await fetch(
  `https://org.crm.dynamics.com/api/data/v9.2/allocations(${id})`,
  {
    method: 'PATCH',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      resource_id: resourceId,
      hours: hours
    })
  }
);

// Saving 100 allocations needs:
for (let i = 0; i < 100; i++) {
  // 100 separate fetch calls!
  // Takes 5-10 seconds
  // Might hit rate limits!
}
```

---

## COMPARISON TABLE: TECHNICAL

| Aspect | PostgreSQL | Dataverse Hybrid | Dataverse Only |
|--------|-----------|-----------------|----------------|
| **Single Request Time** | 50-100ms | 50-100ms (SQL) | 300-500ms |
| **Bulk Insert 100 rows** | 200-500ms | 200-500ms | 5-10 seconds |
| **Transaction Support** | ✅ ACID | ✅ (SQL side) | ⚠️ Limited |
| **Complex Joins** | ✅ Easy SQL | ✅ (SQL side) | ❌ Hard API calls |
| **Rate Limiting** | None | None | 2,000/min ⚠️ |
| **Scaling Approach** | Vertical | Vertical (SQL) | Horizontal (pay per record) |
| **Code Complexity** | ✅ Simple | ⚠️ Medium | ❌ Complex |
| **Error Handling** | Simple | Simple (SQL) | Complex (HTTP) |
| **Async/Batch Ops** | ✅ Native | ✅ (SQL side) | ⚠️ Difficult |
| **Import Large Dataset** | ✅ Fast (minutes) | ✅ Fast (minutes) | ❌ Slow (hours) |
| **Daily Growth** | Handles easily | Handles easily | Cost ↑ |
| **Team Understanding** | ✅ High | ⚠️ Medium | ❌ Low |

---

## INFRASTRUCTURE LAYERS

### PostgreSQL & Dataverse Hybrid
```
┌─────────────────────────────────┐
│      Browser / Client           │
├─────────────────────────────────┤
│   HTTPS / Network Layer         │
├─────────────────────────────────┤
│   App Service (Node.js)         │
├─────────────────────────────────┤
│   Business Logic Layer          │
├──────────────┬──────────────────┤
│ SQL Queries  │ API Calls        │
│ (Fast)       │ (Sync job only)  │
├──────────────┼──────────────────┤
│ PostgreSQL   │ Dataverse        │
│ (Persistent) │ (Master data)    │
└──────────────┴──────────────────┘
```

### Dataverse Only
```
┌─────────────────────────────────┐
│      Browser / Client           │
├─────────────────────────────────┤
│   HTTPS / Network Layer         │
├─────────────────────────────────┤
│   App Service (Node.js)         │
├─────────────────────────────────┤
│   HTTP REST Client              │
│ (Every operation = API call)    │
├─────────────────────────────────┤
│ Dataverse Web API               │
│ (Slower, more overhead)         │
├─────────────────────────────────┤
│ Dataverse (All data here)       │
└─────────────────────────────────┘
```

---

## SCALING SCENARIOS

### Scenario: Growing from 500 to 5,000 Allocations

**PostgreSQL:**
```
Year 1: 500 allocations
  • Response: 50-100ms
  • Bulk import: 200-500ms
  • Cost: $150/month

Year 2: 2,000 allocations  
  • Response: 50-100ms (unchanged!)
  • Bulk import: 200-500ms (unchanged!)
  • Cost: $150/month (unchanged!)

Year 3: 5,000 allocations
  • Response: 50-100ms (unchanged!)
  • Bulk import: 200-500ms (unchanged!)
  • Cost: $150/month (unchanged!)

✅ Performance stable, cost stable
```

**Dataverse Only:**
```
Year 1: 500 allocations
  • Response: 300-400ms
  • Bulk import: 5-10 seconds
  • Cost: $0-10/month

Year 2: 2,000 allocations
  • Response: 400-500ms (slower!)
  • Bulk import: 10-20 seconds (slower!)
  • Rate limiting hits: Yes
  • Cost: $20-30/month (↑ growing)

Year 3: 5,000 allocations
  • Response: 500ms+ (noticeably slow)
  • Bulk import: 30-60 seconds (very slow!)
  • Rate limiting hits: Often
  • Cost: $50-70/month (↑↑ keep growing!)

❌ Performance degrades, cost keeps climbing
```

---

## DEPLOYMENT & OPERATIONS

### PostgreSQL Deployment
```
1. Build Docker image (if needed)
2. Deploy to App Service
3. Connection string → Key Vault
4. Done! (Azure handles DB)

Maintenance:
  • Weekly backups (automatic)
  • Monitoring (built-in)
  • Scaling (2 clicks)
  • Updates (transparent)
```

### Dataverse Hybrid Deployment
```
1. Build Docker image
2. Deploy to App Service
3. Configure dual connections
4. Set up nightly sync job
5. Configure Power BI dataset

Maintenance:
  • Monitor sync job logs
  • Handle Dataverse limits
  • Manage two systems
```

### Dataverse Only Deployment
```
1. Build Docker image
2. Deploy to App Service
3. Configure Dataverse token refresh
4. Handle rate limiting logic
5. Implement retry/backoff logic

Maintenance:
  • Monitor API call logs
  • Handle rate limits
  • Monitor costs/record count
  • Optimize API calls
  • Debug slower operations
```

---

## RECOMMENDATION SUMMARY

| Scenario | Recommend |
|----------|-----------|
| **You want simplicity** | PostgreSQL ✅ |
| **You want performance** | PostgreSQL ✅ |
| **You want Power BI NOW** | Dataverse Hybrid |
| **You want to leverage Dataverse** | Dataverse Hybrid |
| **You want lowest cost today** | Dataverse Only (NOT RECOMMENDED) |
| **You want predictable growth** | PostgreSQL ✅ |
| **You want easy maintenance** | PostgreSQL ✅ |

---

**Document Purpose:** Technical decision support  
**Audience:** CTO, Tech Lead, Architecture Committee  
**Status:** Ready for review
