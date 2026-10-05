import { Pool } from 'pg';
import { withWeeklyAllocations, type Data } from '../lib/planner';

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false }
});

function convertSqlPlaceholders(sql: string): string {
  let paramIndex = 1;
  return sql.replace(/\?/g, () => `$${paramIndex++}`);
}

function createQueryMethods(pgSql: string, params: any[] = []) {
  return {
    run: async () => {
      const result = await pool.query(pgSql, params);
      return result;
    },
    first: async <T = any>() => {
      const result = await pool.query(pgSql, params);
      return result.rows[0] as T | undefined;
    },
    all: async <T = any>() => {
      const result = await pool.query(pgSql, params);
      return { results: result.rows as T[] };
    }
  };
}

export function database() {
  return {
    prepare: (sql: string) => {
      const pgSql = convertSqlPlaceholders(sql);
      return {
        bind: (...params: any[]) => createQueryMethods(pgSql, params),
        ...createQueryMethods(pgSql, []) // Support .first() without .bind()
      };
    },
    batch: async (statements: any[]) => {
      const client = await pool.connect();
      try {
        await client.query('BEGIN');
        for (const stmt of statements) {
          await stmt.run();
        }
        await client.query('COMMIT');
      } catch (error) {
        await client.query('ROLLBACK');
        throw error;
      } finally {
        client.release();
      }
    }
  };
}
const names=['Simon','Adam','Vicky','Cathi','Wamik','Sandeep','Stefano','Hail','NEW BC','Perry','Vamshi','Vashudha','Arun','Sanjoy','Mahesh','Lance','Samuta','Shameer','Unassigned row 10','Unassigned row 21'];
const projects=['EASTERN','JMP','AsuraExt Spt','Effiency','Yakult','BC Gains','Simple Support','OPC - BC','Misc'];
const cells=[[0,3,12],[0,7,20],[1,0,60],[1,5,20],[2,3,60],[2,4,40],[2,5,20],[3,1,40],[3,3,80],[4,1,10],[4,3,40],[5,0,20],[5,2,40],[5,3,40],[5,7,40],[7,6,20],[18,4,40],[18,7,80],[9,0,20],[9,3,20],[9,4,20],[9,7,10],[11,8,80],[13,0,40],[13,4,100],[13,5,40],[13,7,80],[14,0,80],[14,4,80],[17,1,80],[19,7,60]];
const rid=(i:number)=>`R${String(i+1).padStart(3,'0')}`;
const pid=(i:number)=>`P${String(i+1).padStart(3,'0')}`;
async function seed(){const db=database(),count=await db.prepare('SELECT count(*) AS n FROM resources').first<{n:number}>();if(count?.n)return;const statements=[db.prepare('INSERT OR IGNORE INTO months(month) VALUES (?)').bind('2026-09'),db.prepare('INSERT OR IGNORE INTO months(month) VALUES (?)').bind('2026-10'),db.prepare('INSERT OR IGNORE INTO settings(id,default_rate) VALUES (?,?)').bind('default',145)];names.forEach((name,i)=>statements.push(db.prepare('INSERT OR IGNORE INTO resources(id,name,role,weekly_hours,goal,active,eligible,notes) VALUES (?,?,?,?,?,?,?,?)').bind(rid(i),name,'Delivery',40,.75,1,i===8||i>=18?0:1,i>=18?'Name absent in September screenshot. Confirm resource.':i===8?'Recruiting placeholder.':'Capacity assumed at 40 hours per week.')));projects.forEach((name,i)=>statements.push(db.prepare('INSERT OR IGNORE INTO projects(id,name,billable,status,notes) VALUES (?,?,?,?,?)').bind(pid(i),name,i===8?0:1,'Active','September reference. Dates and budgets need confirmation.')));cells.forEach(([r,p,h],i)=>statements.push(db.prepare('INSERT OR IGNORE INTO allocations(id,resource_id,project_id,month,hours,notes) VALUES (?,?,?,?,?,?)').bind(`A${i+1}`,rid(r),pid(p),'2026-09',h,'Imported September screenshot. Weekly hours are estimates.')));await db.batch(statements)}
export async function readState():Promise<Data>{await seed();const db=database();const [resources,projects,months,allocations,capacity,setting,weekly]=await Promise.all([db.prepare('SELECT * FROM resources ORDER BY id').all(),db.prepare('SELECT * FROM projects ORDER BY id').all(),db.prepare('SELECT * FROM months ORDER BY month').all(),db.prepare('SELECT * FROM allocations ORDER BY month,resource_id,project_id').all(),db.prepare('SELECT * FROM capacity_adjustments').all(),db.prepare('SELECT default_rate FROM settings WHERE id=?').bind('default').first<{default_rate:number|null}>(),db.prepare('SELECT * FROM weekly_allocations ORDER BY week,resource_id,project_id').all()]);return withWeeklyAllocations({resources:resources.results,projects:projects.results,months:months.results,allocations:allocations.results,capacity:capacity.results,weekly:weekly.results,rate:setting?.default_rate??null} as Data)}
