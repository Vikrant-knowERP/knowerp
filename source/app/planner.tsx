'use client';

import {useEffect,useRef,useState,type FormEvent} from 'react';

import {Plus,ChevronLeft,ChevronRight,CalendarDays,Users,BriefcaseBusiness,LayoutGrid,BarChart3,FileText,Settings2,X,CheckCircle2,AlertCircle} from 'lucide-react';

import {empty,type Data,type Resource,type Project,type Allocation,type HoursDraft,allocationKey,withHoursDrafts,budgetForecast,resourceMetrics,totals,hours,percent,money,monthLabel,shiftMonth,inMonth} from '../lib/planner';

import {Forecast,Weekly} from './reports';
import {WeeklyPlan} from './weekly-plan';

type Modal={kind:string;value?:any;resource?:Resource;project?:Project};

function Status({value}:{value:string}){return <span className={'status '+(value==='Overallocated'?'red':value==='Under target'||value==='Bench'||value==='No capacity'?'amber':'neutral')}>{value}</span>}

function HoursCell({label,value,disabled,stage,commit}:{label:string;value:number|undefined;disabled:boolean;stage:(n:number)=>HoursDraft;commit:(d:HoursDraft)=>Promise<void>}){

 const [text,setText]=useState(value===undefined?'':String(value));const focused=useRef(false),pending=useRef<HoursDraft|null>(null),timer=useRef<ReturnType<typeof setTimeout>|null>(null);

 useEffect(()=>{if(!focused.current&&!pending.current)setText(value===undefined?'':String(value))},[value]);

 async function flush(){if(timer.current)clearTimeout(timer.current);const draft=pending.current;if(!draft)return;pending.current=null;await commit(draft)}

 useEffect(()=>()=>{if(timer.current)clearTimeout(timer.current);if(pending.current)void commit(pending.current)},[]);

 return <input aria-label={label} type="number" min="0" step="0.5" placeholder="—" value={text} disabled={disabled} onFocus={()=>{focused.current=true}} onChange={e=>{const v=e.target.value;setText(v);const n=v===''?0:Number(v);if(!Number.isFinite(n)||n<0)return;pending.current=stage(n);if(timer.current)clearTimeout(timer.current);timer.current=setTimeout(()=>void flush(),650)}} onBlur={()=>{focused.current=false;void flush()}} onKeyDown={e=>{if(e.key==='Enter')e.currentTarget.blur()}}/>;

}

export default function Planner(){const [stored,setData]=useState<Data>(empty),[drafts,setDrafts]=useState<Record<string,HoursDraft>>({}),[loading,setLoading]=useState(true),[month,setMonth]=useState('2026-09'),[view,setView]=useState('Monthly plan'),[modal,setModal]=useState<Modal|null>(null),[busy,setBusy]=useState(false),[error,setError]=useState(''),[saved,setSaved]=useState(''),[query,setQuery]=useState('');const dialog=useRef<HTMLDialogElement>(null);const queue=useRef<Promise<unknown>>(Promise.resolve());

 const draftRef=useRef<Record<string,HoursDraft>>({}),revision=useRef(0),queued=useRef<Record<string,number>>({});const data=withHoursDrafts(stored,drafts);

 function stageHours(resource_id:string,project_id:string,n:number){const key=allocationKey(resource_id,project_id,month),draft={resource_id,project_id,month,hours:n,revision:++revision.current};draftRef.current={...draftRef.current,[key]:draft};setDrafts(draftRef.current);setSaved('');return draft}

 async function commitHours(draft:HoursDraft){const key=allocationKey(draft.resource_id,draft.project_id,draft.month);if(queued.current[key]===draft.revision)return;queued.current[key]=draft.revision;const ok=await save({kind:'allocation',resource_id:draft.resource_id,project_id:draft.project_id,month:draft.month,hours:draft.hours});if(ok&&draftRef.current[key]?.revision===draft.revision){const next={...draftRef.current};delete next[key];draftRef.current=next;setDrafts(next)}else if(!ok)delete queued.current[key]}

 const load=async()=>{setError('');setLoading(true);try{const r=await fetch('/api/planner',{cache:'no-store'}),d=await r.json() as Data & {error:string};if(!r.ok)throw new Error(d.error);setData(d)}catch(e){setError(e instanceof Error?e.message:'Could not load plans.')}finally{setLoading(false)}};

 useEffect(()=>{const selected=localStorage.getItem('know-planning-month');if(selected&&/^\d{4}-(0[1-9]|1[0-2])$/.test(selected))setMonth(selected);void load()},[]);

 useEffect(()=>{if(!loading)localStorage.setItem('know-planning-month',month)},[month,loading]);

 useEffect(()=>{if(modal&&!dialog.current?.open)dialog.current?.showModal()},[modal]);
 useEffect(()=>{if(loading||modal)return;let cancelled=false;
 const refresh=async()=>{if(document.hidden||Object.keys(draftRef.current).length)return;const pending=queue.current;await pending;if(cancelled)return;try{const r=await fetch('/api/planner',{cache:'no-store'});if(!r.ok)return;const latest=await r.json() as Data;if(!cancelled&&queue.current===pending&&!Object.keys(draftRef.current).length)setData(latest)}catch{}};
 const timer=setInterval(()=>void refresh(),15000);window.addEventListener('focus',refresh);document.addEventListener('visibilitychange',refresh);
 return()=>{cancelled=true;clearInterval(timer);window.removeEventListener('focus',refresh);document.removeEventListener('visibilitychange',refresh)};
 },[loading,modal]);
 async function save(body:any){let result=false;const task=async()=>{setBusy(true);setError('');setSaved('');try{const response=await fetch('/api/planner',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(body)}),d=await response.json() as Data & {error:string};if(!response.ok)throw new Error(d.error||'Could not save.');setData(d);setSaved('All changes saved');result=true}catch(e){setError(e instanceof Error?e.message:'Could not save. Your input is still here.')}finally{setBusy(false)}};const next=queue.current.then(task,task);queue.current=next;await next;return result}

 async function navigate(m:string){if(!data.months.some(x=>x.month===m)){if(!await save({kind:'month',month:m,copy:false}))return}setMonth(m)}

 function open(kind:string,value?:any,resource?:Resource,project?:Project){setError('');setModal({kind,value,resource,project})}

 function selectAllocation(resource:string,project:string){const a=data.allocations.find(x=>x.resource_id===resource&&x.project_id===project&&x.month===month);setModal({kind:'allocation',value:a??{resource_id:resource,project_id:project,hours:0,actual:null}})}

 function close(){if(busy)return;dialog.current?.close();setModal(null);setError('')}

 async function submit(e:FormEvent<HTMLFormElement>){e.preventDefault();const f=new FormData(e.currentTarget),get=(n:string)=>String(f.get(n)??''),nullable=(n:string)=>get(n)===''?null:Number(get(n)),kind=modal!.kind;let b:any={kind,id:modal?.value?.id};

 if(kind==='resource')b={...b,name:get('name'),role:get('role'),location:get('location'),weekly_hours:Number(get('weekly_hours')),goal:Number(get('goal'))/100,active:f.has('active'),eligible:f.has('eligible'),notes:get('notes')};

 if(kind==='project')b={...b,name:get('name'),client:get('client'),manager:get('manager'),start_date:get('start_date')||null,end_date:get('end_date')||null,budget:nullable('budget'),rate:nullable('rate'),billable:f.has('billable'),status:get('status'),notes:get('notes')};

 if(kind==='month')b={kind,month:get('month'),copy:f.has('copy')};

 if(kind==='allocation')b={...b,resource_id:get('resource_id'),project_id:get('project_id'),month,hours:Number(get('hours')),actual:nullable('actual'),notes:get('notes')};

 if(kind==='capacity')b={...b,resource_id:modal!.resource!.id,month,leave_hours:Number(get('leave_hours')),capacity_override:nullable('capacity_override')};

 if(kind==='settings')b={kind,rate:nullable('rate')};if(await save(b)){if(kind==='month')setMonth(b.month);close()}}

 const metric=totals(data,month),resources=data.resources.filter(r=>r.name.toLowerCase().includes(query.toLowerCase())),projects=data.projects.filter(p=>inMonth(p,month)||data.allocations.some(a=>a.project_id===p.id&&a.month===month&&a.hours>0));

 const title=modal?.kind==='capacity'?'Monthly capacity':modal?.kind==='allocation'?'Edit planned and actual hours':modal?.kind==='settings'?'Forecast rate':modal?.kind==='source'?'September source review':`${modal?.value?.id?'Edit':'Add'} ${modal?.kind}`;

 function input(label:string,name:string,type='text',initial:any='',extra:any={}){return <label className="field">{label}<input name={name} type={type} defaultValue={initial??''} {...extra}/></label>}

 return <div className="app"><aside className="sidebar"><a className="brand" href="/"><span className="mark">K</span><span>KNOW<span className="brand-sub">MODERN ERP</span></span></a><div className="side-heading">DELIVERY PLANNING</div><nav aria-label="Planner views">{[['Monthly plan',LayoutGrid],['Weekly plan',CalendarDays],['Projects',BriefcaseBusiness],['Resources',Users],['Forecast',BarChart3],['Weekly report',FileText]].map(([label,Icon]:any)=><button key={label} className={view===label?'nav selected':'nav'} onClick={()=>{setView(label);setQuery('')}}><Icon size={18}/>{label}</button>)}</nav><div className="sidebar-bottom"><div className="goal-note"><strong>75%</strong><span>Default billable goal</span></div><p>Overload starts above 100% of available capacity.</p><button className="nav" onClick={()=>open('settings')}><Settings2 size={18}/>Forecast settings</button></div></aside>

 <main><header className="topbar"><span className="workspace-name">Resource workspace</span><span className="save-state" aria-live="polite">{busy?'Saving changes…':Object.keys(drafts).length?'Unsaved hours':saved?<><CheckCircle2 size={15}/>{saved}</>:'Private planner'}</span></header><section className="main-content"><div className="page-heading"><div><div className="eyebrow">KNOW MODERN ERP</div><h1>{view}</h1></div><div className="actions"><button className="button" onClick={()=>open('resource')}><Plus size={17}/>Add resource</button><button className="button primary" onClick={()=>open('project')}><Plus size={17}/>Add project</button></div></div>

 <div className="period-row"><div className="month-picker"><button aria-label="Previous month" onClick={()=>void navigate(shiftMonth(month,-1))}><ChevronLeft size={18}/></button><CalendarDays size={18}/><select aria-label="Planning month" value={month} onChange={e=>void navigate(e.target.value)}>{Array.from(new Set([...data.months.map(m=>m.month),month])).sort().map(m=><option key={m} value={m}>{monthLabel(m)}</option>)}</select><button aria-label="Next month" onClick={()=>void navigate(shiftMonth(month,1))}><ChevronRight size={18}/></button></div><button className="button small" onClick={()=>open('month',{month:shiftMonth(month,1)})}><Plus size={16}/>Add month</button><span className="period-note">Capacity and targets update with the calendar.</span></div>

 {error&&!modal&&<div className="alert error" role="alert"><AlertCircle size={18}/>{error}{Object.keys(drafts).length>0&&<button onClick={()=>Object.values(draftRef.current).forEach(d=>void commitHours(d))}>Retry saving hours</button>}{loading===false&&data.resources.length===0&&<button onClick={()=>void load()}>Try again</button>}</div>}

 {loading?<div className="loading" role="status">Loading your saved planner…</div>:<><div className="metrics" style={view==='Weekly plan'?{display:'none'}:undefined}><article><span>Available capacity</span><strong>{hours(metric.capacity)}<small>hrs</small></strong><p>{hours(metric.target)} hrs billable target</p></article><article><span>Assigned billable hours</span><strong>{hours(metric.billable)}<small>hrs</small></strong><p>{hours(metric.total)} hrs total work</p></article><article><span>Billable utilization</span><strong>{percent(metric.util)}</strong><p>Goal 75% · overload above 100% total load</p></article><article className={metric.gap<0?'metric-warn':''}><span>Billable plan vs target</span><strong>{metric.gap>0?'+':''}{hours(metric.gap)}<small>hrs</small></strong><p>{metric.gap<0?'More billable work needed':'At or above the target'}</p></article></div>

 {month==='2026-09'&&<div className="source-alert"><AlertCircle size={18}/><span>September reference: 120-hour total difference and 180 hours without resource names.</span><button onClick={()=>open('source')}>Review source</button></div>}

 {view==='Monthly plan'&&<section className="panel"><div className="panel-heading"><div><h2>Resource and project plan</h2><p>Totals update while you type; hours save automatically. Click a project name to edit dates.</p></div><div className="table-tools"><input className="search" aria-label="Find a resource" placeholder="Find a resource" value={query} onChange={e=>setQuery(e.target.value)}/><button className="button small" onClick={()=>open('allocation')}><Plus size={16}/>Edit allocation</button></div></div><div className="grid-scroll"><table className="planning-table"><thead><tr><th className="resource-col">Resource</th><th>Capacity</th><th>Target</th>{projects.map(p=><th key={p.id}><button className="project-head" onClick={()=>open('project',p)}>{p.name}</button><span>{p.billable?'Billable':'Internal'}</span></th>)}<th>Total planned</th><th>Utilization</th><th>Status</th></tr></thead><tbody>{resources.map(r=>{const m=resourceMetrics(data,r,month);return <tr key={r.id}><th className="resource-col"><button className="person" onClick={()=>open('resource',r)}><span className="avatar">{r.name.slice(0,2).toUpperCase()}</span><span>{r.name}<small>{r.role||'Resource'}</small></span></button></th><td><button className="number-button" title="Edit monthly capacity and leave" onClick={()=>open('capacity',data.capacity.find(c=>c.resource_id===r.id&&c.month===month),r)}>{hours(m.capacity)}</button></td><td className="muted number">{hours(m.target)}</td>{projects.map(p=>{const a=data.allocations.find(a=>a.resource_id===r.id&&a.project_id===p.id&&a.month===month);return <td key={p.id} className="hours-cell"><HoursCell key={`${month}-${r.id}-${p.id}`} label={`${r.name}, ${p.name}, ${monthLabel(month)} planned hours`} value={a?.hours} disabled={!!a?.weekly_managed||(!inMonth(p,month)&&!a)} stage={n=>stageHours(r.id,p.id,n)} commit={commitHours}/>{a?.weekly_managed&&<small>Weekly plan</small>}</td>})}<td className="number strong">{hours(m.total)}</td><td className="util-cell"><span>{percent(m.util)}</span><div className="util-track"><i style={{width:`${Math.min((m.util??0)*100,100)}%`,background:m.total>m.capacity?'#c93c43':(m.util??0)<r.goal?'#ba7b20':'#2262d5'}}/><em style={{left:`${r.goal*100}%`}}/></div></td><td><Status value={m.status}/></td></tr>})}</tbody><tfoot><tr><th className="resource-col">Company total</th><td className="number">{hours(metric.capacity)}</td><td className="number">{hours(metric.target)}</td>{projects.map(p=><td className="number" key={p.id}>{hours(data.allocations.filter(a=>a.project_id===p.id&&a.month===month).reduce((s,a)=>s+a.hours,0))}</td>)}<td className="number">{hours(metric.total)}</td><td>{percent(metric.util)}</td><td/></tr></tfoot></table>{resources.length===0&&<div className="empty">No resources match. Add a resource or clear the search.</div>}</div><div className="panel-footer"><span>Hours are editable. Capacity starts from weekday hours less leave.</span><span>Revenue forecast <strong>{money(metric.revenue)}</strong>{metric.unpriced>0&&` · ${hours(metric.unpriced)} billable hours need a rate`}</span></div></section>}

 {view==='Projects'&&<section className="panel"><div className="panel-heading"><div><h2>Projects across months</h2><p>One project record carries its dates, budget and rate into every month.</p></div></div><div className="grid-scroll"><table><thead><tr><th>Project</th><th>Client / manager</th><th>Start</th><th>End</th><th>Budget hours</th><th>Hourly rate</th><th>Status</th><th/></tr></thead><tbody>{data.projects.map(p=><tr key={p.id}><th>{p.name}<small>{p.billable?'Billable':'Nonbillable'}</small></th><td>{p.client||'—'}<small>{p.manager||'Manager not set'}</small></td><td>{p.start_date||<span className="warning-text">Not set</span>}</td><td>{p.end_date||<span className="warning-text">Not set</span>}</td><td>{p.budget===null?'Not set':hours(p.budget)}</td><td>{p.billable?(p.rate===null?(data.rate===null?'Not set':`${money(data.rate)} default`):money(p.rate)):'—'}</td><td>{p.status}</td><td><button className="button small" onClick={()=>open('project',p)}>Edit project</button></td></tr>)}</tbody></table></div></section>}

 {view==='Resources'&&<section className="panel"><div className="panel-heading"><div><h2>Resource master</h2><p>Defaults: 40 hours per week and 75% billable utilization. Confirm each person’s capacity.</p></div></div><div className="grid-scroll"><table><thead><tr><th>Resource</th><th>Role</th><th>Location</th><th>Weekly hours</th><th>Goal</th><th>Capacity</th><th/></tr></thead><tbody>{data.resources.map(r=><tr key={r.id}><th>{r.name}</th><td>{r.role}</td><td>{r.location||'—'}</td><td>{hours(r.weekly_hours)}</td><td>{percent(r.goal)}</td><td>{r.active&&r.eligible?'Included':'Excluded / placeholder'}</td><td><button className="button small" onClick={()=>open('resource',r)}>Edit resource</button></td></tr>)}</tbody></table></div></section>}

 {view==='Weekly plan'&&<WeeklyPlan key={month} data={data} month={month} save={save}/>}{view==='Forecast'&&<Forecast data={data} month={month} edit={p=>open('project',p)} go={m=>{void navigate(m);setView('Monthly plan')}}/>}{view==='Weekly report'&&<Weekly key={month} data={data} month={month}/>}

 </>}

 <footer className="app-footer"><span>75% billable goal. Overload compares all planned hours to available capacity.</span><span>Saved plans · USD</span></footer></section></main>

 <dialog ref={dialog} onCancel={e=>{e.preventDefault();close()}} onClick={e=>{if(e.target===e.currentTarget)close()}}>{modal&&<><div className="dialog-title"><div><div className="eyebrow">RESOURCE PLANNER</div><h2>{title}</h2></div><button aria-label="Close form" className="icon-button" disabled={busy} onClick={close}><X size={20}/></button></div>{modal.kind==='source'?<div className="dialog-content"><p>The September screenshot’s visible detail totals <strong>1,392 hours</strong>. Its footer totals <strong>1,272 hours</strong>. The app preserves the visible detail.</p><p>Two unnamed rows hold <strong>180 hours</strong>. They remain separate placeholders until you confirm their resource names.</p><p>The 40-hour workweek, $145 blended rate and Misc as nonbillable are editable assumptions. Project dates, budgets and actuals were not provided.</p><button className="button primary" onClick={close}>Back to plan</button></div>:<form key={modal.kind+String(modal.value?.id??modal.value?.resource_id??"new")+String(modal.value?.project_id??"")} onSubmit={submit} className="dialog-content"><div className="form-grid">

 {modal.kind==='resource'&&<>{input('Resource name','name','text',modal.value?.name,{required:true})}{input('Role','role','text',modal.value?.role??'Delivery')}{input('Location','location','text',modal.value?.location)}{input('Weekly available hours','weekly_hours','number',modal.value?.weekly_hours??40,{required:true,min:0,step:.5})}{input('Billable utilization goal (%)','goal','number',(modal.value?.goal??.75)*100,{required:true,min:0,max:100,step:.1})}<div className="field checks"><label><input type="checkbox" name="active" defaultChecked={modal.value?!!modal.value.active:true}/>Active resource</label><label><input type="checkbox" name="eligible" defaultChecked={modal.value?!!modal.value.eligible:true}/>Include in available capacity</label></div>{input('Notes','notes','text',modal.value?.notes)}</>}

 {modal.kind==='project'&&<>{input('Project name','name','text',modal.value?.name,{required:true})}{input('Client','client','text',modal.value?.client)}{input('Project manager','manager','text',modal.value?.manager)}<label className="field">Status<select name="status" defaultValue={modal.value?.status??'Active'}>{['Active','Pipeline','On hold','Complete'].map(x=><option key={x}>{x}</option>)}</select></label>{input('Start date','start_date','date',modal.value?.start_date,{required:!modal.value?.id})}{input('End date','end_date','date',modal.value?.end_date,{required:!modal.value?.id})}{input('Budget / contracted hours','budget','number',modal.value?.budget,{min:0,step:.5})}{input('Hourly rate (USD)','rate','number',modal.value?.rate,{min:0,step:.01,placeholder:data.rate===null?'No default rate':`${data.rate} default`})}<label className="check"><input type="checkbox" name="billable" defaultChecked={modal.value?!!modal.value.billable:true}/>Billable project</label>{input('Notes','notes','text',modal.value?.notes)}<p className="field-help wide">Blank rate uses the forecast default. Budget hours are spread across project dates in the budget forecast. Assign hours to resources to calculate utilization. Existing monthly hours must remain inside the project dates.</p></>}

 {modal.kind==='month'&&<>{input('New planning month','month','month',modal.value?.month,{required:true,min:'2000-01',max:'2199-12'})}<label className="check wide"><input type="checkbox" name="copy"/>Carry the previous month’s planned hours</label><p className="field-help wide">Capacity calculates automatically. Carry-forward keeps ongoing projects and excludes completed projects or dates outside the new month. Actuals are left blank.</p></>}

 {modal.kind==='allocation'&&<><label className="field">Resource<select name="resource_id" required onChange={e=>selectAllocation(e.target.value,modal.value?.project_id??"")} defaultValue={modal.value?.resource_id??modal.resource?.id??''}><option value="">Choose resource</option>{data.resources.map(r=><option key={r.id} value={r.id}>{r.name}</option>)}</select></label><label className="field">Project<select name="project_id" required onChange={e=>selectAllocation(modal.value?.resource_id??"",e.target.value)} defaultValue={modal.value?.project_id??''}><option value="">Choose project</option>{data.projects.map(p=><option key={p.id} value={p.id}>{p.name}</option>)}</select></label>{input('Planned hours','hours','number',modal.value?.hours??0,{required:true,min:0,step:.5})}{input('Actual hours (blank = not reported)','actual','number',modal.value?.actual,{min:0,step:.5})}{input('Notes','notes','text',modal.value?.notes)}<p className="field-help">Allocation month: {monthLabel(month)}. Enter 0 to report a genuine zero actual value.</p></>}

 {modal.kind==='capacity'&&<><p className="wide">{modal.resource?.name} · {monthLabel(month)}</p>{input('Leave / holiday hours','leave_hours','number',modal.value?.leave_hours??0,{required:true,min:0,step:.5})}{input('Available capacity override','capacity_override','number',modal.value?.capacity_override,{min:0,step:.5,placeholder:'Use weekday capacity'})}<p className="field-help wide">Leave reduces normal capacity. An override replaces the calculation. A zero override means no available capacity.</p></>}

 {modal.kind==='settings'&&<>{input('Default billable rate (USD / hour)','rate','number',data.rate,{min:0,step:.01})}<p className="field-help wide">The September footer used $145/hour. Confirm your forecast rate. Individual project rates take priority. Blank means the rate is unknown.</p></>}

 </div>{error&&<div role="alert" className="alert error">{error}</div>}<div className="form-actions"><button type="button" className="button" onClick={close} disabled={busy}>Cancel</button><button type="submit" className="button primary" disabled={busy}>{busy?'Saving…':'Save '+(modal.kind==='settings'?'settings':modal.kind==='capacity'?'capacity':modal.kind==='allocation'?'hours':modal.kind)}</button></div></form>}</>}</dialog></div>}







