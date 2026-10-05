export type Resource={id:string;name:string;role:string;location:string;weekly_hours:number;goal:number;active:number;eligible:number;notes:string};
export type Project={id:string;name:string;client:string;manager:string;start_date:string|null;end_date:string|null;budget:number|null;rate:number|null;billable:number;status:string;notes:string};
export type Allocation={id:string;resource_id:string;project_id:string;month:string;hours:number;actual:number|null;notes:string;weekly_managed?:boolean};
export type WeeklyEntry={id:string;resource_id:string;project_id:string;week:string;hours:number;actual:number|null;notes:string};
export type Capacity={id:string;resource_id:string;month:string;leave_hours:number;capacity_override:number|null};
export type Data={resources:Resource[];projects:Project[];months:{month:string}[];allocations:Allocation[];weekly?:WeeklyEntry[];monthly_allocations?:Allocation[];capacity:Capacity[];rate:number|null};
export const empty:Data={resources:[],projects:[],months:[],allocations:[],capacity:[],rate:145};
export type HoursDraft={resource_id:string;project_id:string;month:string;hours:number;revision:number};
export const allocationKey=(resource:string,project:string,month:string)=>`${resource}|${project}|${month}`;
export function withHoursDrafts(data:Data,drafts:Record<string,HoursDraft>):Data{
 const allocations=data.allocations.map(a=>({...a,hours:drafts[allocationKey(a.resource_id,a.project_id,a.month)]?.hours??a.hours}));
 for(const [key,draft] of Object.entries(drafts))if(!allocations.some(a=>allocationKey(a.resource_id,a.project_id,a.month)===key))allocations.push({id:`draft:${key}`,resource_id:draft.resource_id,project_id:draft.project_id,month:draft.month,hours:draft.hours,actual:null,notes:''});
 return {...data,allocations};
}
export const date=(s:string)=>new Date(s+'T00:00:00Z');
export const iso=(d:Date)=>d.toISOString().slice(0,10);
export function shiftMonth(m:string,n:number){const d=date(m+'-01');d.setUTCMonth(d.getUTCMonth()+n);return iso(d).slice(0,7)}
export function monthEnd(m:string){return iso(new Date(Date.UTC(+m.slice(0,4),+m.slice(5,7),0)))}
export function weekdays(start:string,end:string){if(start>end)return 0;let d=date(start),n=0;for(;iso(d)<=end;d.setUTCDate(d.getUTCDate()+1))if(d.getUTCDay()!==0&&d.getUTCDay()!==6)n++;return n}
export function inMonth(p:Project,m:string){return (!p.start_date||p.start_date<=monthEnd(m))&&(!p.end_date||p.end_date>=m+'-01')}
export function shiftDay(s:string,n:number){const d=date(s);d.setUTCDate(d.getUTCDate()+n);return iso(d)}
export function monday(s:string){const d=date(s);d.setUTCDate(d.getUTCDate()-(d.getUTCDay()+6)%7);return iso(d)}
export function weekWindow(p:Project|undefined,w:string){return {start:p?.start_date&&p.start_date>w?p.start_date:w,end:p?.end_date&&p.end_date<shiftDay(w,6)?p.end_date:shiftDay(w,6)}}
export function weeklyMonthFraction(p:Project|undefined,w:string,m:string){const {start,end}=weekWindow(p,w),n=weekdays(start,end);return n?weekdays(start>m+'-01'?start:m+'-01',end<monthEnd(m)?end:monthEnd(m))/n:0}
export function withWeeklyAllocations(d:Data):Data{
 const base=d.monthly_allocations??d.allocations,groups=new Map<string,Allocation>();
 for(const w of d.weekly??[]){const p=d.projects.find(p=>p.id===w.project_id);for(const m of new Set([w.week.slice(0,7),shiftDay(w.week,6).slice(0,7)])){const fraction=weeklyMonthFraction(p,w.week,m);if(!fraction)continue;const key=allocationKey(w.resource_id,w.project_id,m);let a=groups.get(key);if(!a){const old=base.find(x=>allocationKey(x.resource_id,x.project_id,x.month)===key);a={id:old?.id??`weekly:${key}`,resource_id:w.resource_id,project_id:w.project_id,month:m,hours:0,actual:old?.actual??null,notes:'Planned by week',weekly_managed:true};groups.set(key,a)}a.hours+=w.hours*fraction}}
 return {...d,monthly_allocations:base,allocations:[...base.filter(a=>!groups.has(allocationKey(a.resource_id,a.project_id,a.month))),...groups.values()]};
}
export function projectWeek(d:Data,p:Project,w:string){const entries=(d.weekly??[]).filter(a=>a.project_id===p.id&&a.week===w);let planned=entries.reduce((s,a)=>s+a.hours,0),actual=entries.reduce((s,a)=>s+(a.actual??0),0),missing=entries.some(a=>a.hours>0&&a.actual===null),estimated=0;for(const a of d.allocations.filter(a=>a.project_id===p.id&&!a.weekly_managed)){const f=weeklyAllocation(d,a,w);planned+=a.hours*f;estimated+=a.hours*f;actual+=(a.actual??0)*f;if(f&&a.hours>0&&a.actual===null)missing=true}return {planned,actual,missing,estimated}}
export function weeklyResourceMetrics(d:Data,r:Resource,w:string,explicit=false){const rows=(d.weekly??[]).filter(a=>a.resource_id===r.id&&a.week===w);let total=rows.reduce((s,a)=>s+a.hours,0),billable=rows.reduce((s,a)=>s+(d.projects.find(p=>p.id===a.project_id)?.billable?a.hours:0),0);if(!explicit)for(const a of d.allocations.filter(a=>a.resource_id===r.id&&!a.weekly_managed)){const n=a.hours*weeklyAllocation(d,a,w);total+=n;if(d.projects.find(p=>p.id===a.project_id)?.billable)billable+=n}const capacity=weeklyAvailable(d,r,w),target=capacity*r.goal;return {total,billable,capacity,target,gap:billable-target,util:capacity?billable/capacity:null,status:capacity===0?(total>0?'No capacity':'Inactive'):total>capacity?'Overallocated':billable===0?'Bench':billable<target?'Under target':'At target'}}
export function projectBudgetHours(p:Project,m:string){
 if(p.budget===null||!p.start_date||!p.end_date)return null;
 const count=weekdays(p.start_date,p.end_date);if(!count)return p.start_date.slice(0,7)===m?p.budget:0;
 const first=p.start_date>m+'-01'?p.start_date:m+'-01',last=p.end_date<monthEnd(m)?p.end_date:monthEnd(m);
 return p.budget*weekdays(first,last)/count;
}
export function budgetForecast(d:Data,m:string){let hours=0,billable=0,revenue=0,unpriced=0,undated=0;
 for(const p of d.projects){const h=projectBudgetHours(p,m);if(h===null){if(p.budget!==null&&!p.start_date&&!p.end_date)undated+=p.budget;continue}hours+=h;if(p.billable){billable+=h;const rate=p.rate??d.rate;if(rate===null)unpriced+=h;else revenue+=h*rate}}
 return {hours,billable,revenue,unpriced,undated};
}
export function available(d:Data,r:Resource,m:string){const c=d.capacity.find(x=>x.resource_id===r.id&&x.month===m);const base=r.active&&r.eligible?weekdays(m+'-01',monthEnd(m))*r.weekly_hours/5:0;return c?.capacity_override??Math.max(0,base-(c?.leave_hours??0))}
export function resourceMetrics(d:Data,r:Resource,m:string){const rows=d.allocations.filter(a=>a.resource_id===r.id&&a.month===m),total=rows.reduce((s,a)=>s+a.hours,0),billable=rows.reduce((s,a)=>s+(d.projects.find(p=>p.id===a.project_id)?.billable?a.hours:0),0),capacity=available(d,r,m),target=capacity*r.goal;return {total,billable,capacity,target,gap:billable-target,util:capacity?billable/capacity:null,status:capacity===0?(total>0?'No capacity':'Inactive'):total>capacity?'Overallocated':billable===0?'Bench':billable<target?'Under target':'At target'}}
export function revenue(d:Data,rows:Allocation[]){let total=0,unpriced=0;for(const a of rows){const p=d.projects.find(p=>p.id===a.project_id);if(!p?.billable)continue;const rate=p.rate??d.rate;if(rate===null)unpriced+=a.hours;else total+=a.hours*rate}return {revenue:total,unpriced}}
export function totals(d:Data,m:string){const rs=d.resources.map(r=>resourceMetrics(d,r,m));const capacity=rs.reduce((s,r)=>s+r.capacity,0),billable=rs.reduce((s,r)=>s+r.billable,0),target=rs.reduce((s,r)=>s+r.target,0),total=rs.reduce((s,r)=>s+r.total,0);return {capacity,billable,target,total,gap:billable-target,util:capacity?billable/capacity:null,...revenue(d,d.allocations.filter(a=>a.month===m))}}
export function weeklyAllocation(d:Data,a:Allocation,week:string){const p=d.projects.find(p=>p.id===a.project_id);let start=a.month+'-01',end=monthEnd(a.month);if(p?.start_date&&p.start_date>start)start=p.start_date;if(p?.end_date&&p.end_date<end)end=p.end_date;const wend=date(week);wend.setUTCDate(wend.getUTCDate()+6);const first=start>week?start:week,last=end<iso(wend)?end:iso(wend),denom=weekdays(start,end);return denom?weekdays(first,last)/denom:0}
export function weeklyAvailable(d:Data,r:Resource,week:string){const end=date(week);end.setUTCDate(end.getUTCDate()+6);const em=iso(end).slice(0,7),wm=week.slice(0,7);return [wm,...(em!==wm?[em]:[])].reduce((s,m)=>s+available(d,r,m)*weekdays(week>m+'-01'?week:m+'-01',iso(end)<monthEnd(m)?iso(end):monthEnd(m))/weekdays(m+'-01',monthEnd(m)),0)}
export const hours=(n:number)=>new Intl.NumberFormat('en-US',{maximumFractionDigits:1}).format(n);
export const money=(n:number)=>new Intl.NumberFormat('en-US',{style:'currency',currency:'USD',maximumFractionDigits:0}).format(n);
export const percent=(n:number|null)=>n===null?'—':new Intl.NumberFormat('en-US',{style:'percent',maximumFractionDigits:1}).format(n);
export const monthLabel=(m:string)=>new Intl.DateTimeFormat('en-US',{month:'long',year:'numeric',timeZone:'UTC'}).format(date(m+'-01'));
