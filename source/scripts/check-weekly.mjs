import http from 'node:http';import assert from 'node:assert/strict';import fs from 'node:fs/promises';
import {withWeeklyAllocations,weeklyResourceMetrics,projectWeek,totals} from '../lib/planner.ts';
let cookie='';const origin='http://127.0.0.1:5173';
async function request(path,body){return new Promise((resolve,reject)=>{const data=body?JSON.stringify(body):null;const r=http.request(origin+path,{method:body?'POST':'GET',headers:{...(cookie?{Cookie:cookie}:{}),...(body?{'Content-Type':'application/json','Content-Length':Buffer.byteLength(data),Origin:origin}:{})}},res=>{if(res.headers['set-cookie'])cookie=res.headers['set-cookie'].map(x=>x.split(';')[0]).join('; ');let text='';res.setEncoding('utf8');res.on('data',x=>text+=x);res.on('end',()=>resolve({status:res.statusCode,headers:res.headers,text}))});r.on('error',reject);if(data)r.write(data);r.end()})}
let path='/';for(let i=0;i<8;i++){const r=await request(path);if(r.status===200)break;const u=new URL(r.headers.location,origin);assert.equal(u.origin,origin);path=u.pathname+u.search}
async function save(b,code=200){const r=await request('/api/planner',b);assert.equal(r.status,code,r.text);return JSON.parse(r.text)}
const suffix=crypto.randomUUID(),rid='qa-week-r-'+suffix,pid='qa-week-p-'+suffix;
await fs.writeFile('../weekly-cleanup.sql',`DELETE FROM weekly_allocations WHERE resource_id='${rid}';\nDELETE FROM allocations WHERE resource_id='${rid}';\nDELETE FROM resources WHERE id='${rid}';\nDELETE FROM projects WHERE id='${pid}';\n`);
await save({kind:'resource',id:rid,name:'Weekly QA',weekly_hours:40,goal:.75,active:true,eligible:true});
await save({kind:'project',id:pid,name:'Weekly QA',start_date:'2026-09-01',end_date:'2026-12-31',budget:100,rate:145,billable:true,status:'Active'});
await save({kind:'allocation',resource_id:rid,project_id:pid,month:'2026-09',hours:100,actual:0,notes:'Monthly source retained'});
let d=await save({kind:'weekly',resource_id:rid,project_id:pid,week:'2026-09-28',hours:40});
const allocation=(m)=>d.allocations.find(a=>a.resource_id===rid&&a.project_id===pid&&a.month===m);
assert.equal(allocation('2026-09').hours,24);assert.equal(allocation('2026-10').hours,16);assert.equal(allocation('2026-09').actual,0);assert.equal(d.monthly_allocations.find(a=>a.resource_id===rid).hours,100);
let r=d.resources.find(r=>r.id===rid);assert.equal(weeklyResourceMetrics(d,r,'2026-09-28').total,40);assert.equal(weeklyResourceMetrics(d,r,'2026-09-28').target,30);
assert.equal(projectWeek({...d,projects:d.projects.filter(p=>p.id===pid),allocations:d.allocations.filter(a=>a.project_id===pid)},d.projects.find(p=>p.id===pid),'2026-09-28').planned,40);
d=await save({kind:'weekly',resource_id:rid,project_id:pid,week:'2026-09-21',hours:30});assert.equal(allocation('2026-09').hours,54);
await save({kind:'allocation',resource_id:rid,project_id:pid,month:'2026-09',hours:90},422);
await save({kind:'weekly',resource_id:rid,project_id:pid,week:'2026-09-29',hours:20},422);
await save({kind:'weekly',resource_id:rid,project_id:pid,week:'2027-01-04',hours:20},422);
// Avoid carrying any user records while testing the effective source for this pair.
assert.equal(d.allocations.find(a=>a.resource_id===rid&&a.month==='2026-10').hours,16);
d=await save({kind:'weekly',resource_id:rid,project_id:pid,week:'2026-09-28',hours:0});assert.equal(allocation('2026-09').hours,30);assert.equal(allocation('2026-10').hours,0);
const reloaded=await request('/api/planner');assert.equal(reloaded.status,200);d=JSON.parse(reloaded.text);assert.equal(d.weekly.find(a=>a.resource_id===rid&&a.week==='2026-09-28').hours,0);assert.equal(allocation('2026-09').hours,30);
console.log(JSON.stringify({status:'passed',checks:['saved weekly hours','cross-month split 24/16','monthly source preserved','no double counting','weekly report exact hours','75% of full weekly capacity','multiple weeks sum','zero overrides','monthly edits guarded','date boundaries','reload persistence']}));
