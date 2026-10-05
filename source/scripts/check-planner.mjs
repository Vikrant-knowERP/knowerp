import http from 'node:http';
import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
let cookie='';
const origin='http://127.0.0.1:5173';
async function request(path,body){return await new Promise((resolve,reject)=>{const data=body?JSON.stringify(body):null;const r=http.request(origin+path,{method:body?'POST':'GET',headers:{...(cookie?{Cookie:cookie}:{}),...(body?{'Content-Type':'application/json','Content-Length':Buffer.byteLength(data),Origin:origin}:{})}},res=>{const set=res.headers['set-cookie'];if(set)cookie=set.map(x=>x.split(';')[0]).join('; ');let text='';res.setEncoding('utf8');res.on('data',x=>text+=x);res.on('end',()=>resolve({status:res.statusCode,headers:res.headers,text}));});r.on('error',reject);if(data)r.write(data);r.end()})}
// The local starter's native mock sign-in uses cookies, just as a browser does.
let path='/';let page;
for(let i=0;i<8;i++){page=await request(path);if(page.status===200)break;assert.ok(page.status>=300&&page.status<400);const u=new URL(page.headers.location,origin);assert.equal(u.origin,origin);path=u.pathname+u.search;}
assert.equal(page.status,200);assert.ok(page.text.includes('Resource workspace'));
async function state(){const r=await request('/api/planner');assert.equal(r.status,200,r.text);return JSON.parse(r.text)}
async function save(b,code=200){const r=await request('/api/planner',b);assert.equal(r.status,code,r.text);return JSON.parse(r.text)}
const original=await state();assert.equal(original.resources.length,20);assert.equal(original.projects.length,9);assert.equal(original.allocations.reduce((s,a)=>s+a.hours,0),1392);
const suffix=crypto.randomUUID(),rid='qa-resource-'+suffix,pid='qa-project-'+suffix;
await save({kind:'resource',id:rid,name:'QA resource',role:'Delivery',location:'',weekly_hours:40,goal:.75,active:true,eligible:true,notes:'Local test'});
await save({kind:'project',id:pid,name:'QA project',client:'',manager:'',start_date:'2026-10-01',end_date:'2027-02-28',budget:500,rate:0,billable:true,status:'Active',notes:'Local test'});
await save({kind:'allocation',resource_id:rid,project_id:pid,month:'2026-10',hours:80,actual:0,notes:''});
await save({kind:'allocation',resource_id:rid,project_id:pid,month:'2026-11',hours:90,actual:null,notes:''});
await save({kind:'capacity',resource_id:rid,month:'2026-10',leave_hours:0,capacity_override:0});
let d=await state();assert.equal(d.allocations.find(a=>a.resource_id===rid&&a.month==='2026-10').actual,0);assert.equal(d.projects.find(p=>p.id===pid).rate,0);assert.equal(d.capacity.find(c=>c.resource_id===rid).capacity_override,0);
await save({kind:'month',month:'2026-12',copy:true});d=await state();assert.equal(d.allocations.find(a=>a.resource_id===rid&&a.month==='2026-12').hours,90);assert.equal(d.allocations.find(a=>a.resource_id===rid&&a.month==='2026-12').actual,null);
await save({kind:'allocation',resource_id:rid,project_id:pid,month:'2027-03',hours:20,actual:null,notes:''},422);
await save({kind:'project',id:pid,name:'QA project',start_date:'2026-12-01',end_date:'2027-02-28',budget:500,rate:0,billable:true,status:'Active'},422);
await save({kind:'project',id:pid,name:'QA project',start_date:'2026-10-01',end_date:'2027-03-31',budget:500,rate:0,billable:true,status:'Active'});
await save({kind:'allocation',resource_id:rid,project_id:pid,month:'2027-03',hours:20,actual:null,notes:''});
await fs.writeFile('../qa-cleanup.sql',`DELETE FROM allocations WHERE resource_id='${rid}';\nDELETE FROM capacity_adjustments WHERE resource_id='${rid}';\nDELETE FROM projects WHERE id='${pid}';\nDELETE FROM resources WHERE id='${rid}';\nDELETE FROM months WHERE month NOT IN ('2026-09','2026-10') AND month NOT IN (SELECT month FROM allocations);\n`);
console.log(JSON.stringify({status:'passed',checks:['source import','new resource','multi-month project','editable hours','reported zero actuals','zero rate','zero capacity','carry-forward','date constraints','extended dates','reload persistence']}));
