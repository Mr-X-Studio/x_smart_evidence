const $ = (q) => document.querySelector(q);
const $$ = (q) => [...document.querySelectorAll(q)];
let state = {cases:[], evidence:{}, audit:[], types:[], statuses:[], locations:[], permissions:{}};

function post(action, data={}) {
  return fetch(`https://${GetParentResourceName()}/${action}`, {
    method:'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify(data)
  });
}
function esc(v=''){return String(v).replace(/[&<>"']/g,m=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#039;'}[m]));}
function arrEvidence(){return Object.values(state.evidence||{});}
function typeLabel(v){return (state.types.find(x=>x.value===v)||{label:v}).label;}
function statusLabel(v){return (state.statuses.find(x=>x.value===v)||{label:v}).label;}
function caseById(id){return state.cases.find(c=>c.id===id);}
function fmt(d){if(!d)return '-';try{return new Date(d).toLocaleString()}catch{return d}}
function showView(name){
  $$('.view').forEach(x=>x.classList.toggle('active',x.id===name));
  $$('.nav').forEach(x=>x.classList.toggle('active',x.dataset.view===name));
}
function refresh(){
  const ev=arrEvidence();
  $('#statCases').textContent=state.cases.filter(c=>c.status==='open').length;
  $('#statEvidence').textContent=ev.length;
  $('#statChecked').textContent=ev.filter(e=>e.status==='checked_out').length;
  $('#statStored').textContent=ev.filter(e=>e.status==='stored').length;
  renderRecent();
  renderCases($('#caseSearch')?.value||'');
  renderEvidence($('#evidenceSearch')?.value||'');
  renderAudit();
}
function renderRecent(){
  $('#recentCases').innerHTML=state.cases.slice(0,5).map(c=>`<div class="list-row" data-case="${c.id}"><strong>${esc(c.caseNumber)} — ${esc(c.title)}</strong><div class="muted">${esc(c.location||'No location')} • ${fmt(c.createdAt)}</div></div>`).join('') || '<div class="empty">No cases yet.</div>';
  $('#recentEvidence').innerHTML=arrEvidence().sort((a,b)=>String(b.createdAt).localeCompare(String(a.createdAt))).slice(0,5).map(e=>`<div class="list-row" data-evidence="${e.id}"><strong>${esc(e.evidenceNumber)} — ${esc(e.title)}</strong><div class="muted">${esc(typeLabel(e.type))} • ${esc(statusLabel(e.status))}</div></div>`).join('') || '<div class="empty">No evidence yet.</div>';
  $$('[data-case]').forEach(x=>x.onclick=()=>openCase(x.dataset.case));
  $$('[data-evidence]').forEach(x=>x.onclick=()=>openEvidence(x.dataset.evidence));
}
function renderCases(q=''){
  q=q.toLowerCase();
  const list=state.cases.filter(c=>[c.caseNumber,c.title,c.description,c.location].join(' ').toLowerCase().includes(q));
  $('#caseList').innerHTML=list.map(c=>`<article class="card">
    <div class="card-head"><div><h3>${esc(c.caseNumber)}</h3><div class="muted">${esc(c.title)}</div></div><span class="badge">${esc(c.priority||'normal')}</span></div>
    <div class="meta"><div><span>Status</span><b>${esc(c.status)}</b></div><div><span>Evidence</span><b>${c.evidenceCount||0}</b></div><div><span>Location</span><b>${esc(c.location||'-')}</b></div><div><span>Created</span><b>${esc(fmt(c.createdAt))}</b></div></div>
    <div class="actions"><button class="small-btn" onclick="openCase('${c.id}')">Open Case</button>${state.permissions.canDelete?`<button class="small-btn danger" onclick="deleteCase('${c.id}')">Delete</button>`:''}</div>
  </article>`).join('') || '<div class="empty">No matching cases.</div>';
}
function renderEvidence(q=''){
  q=q.toLowerCase();
  const list=arrEvidence().filter(e=>[e.evidenceNumber,e.title,e.description,e.serial,e.tags,e.type].join(' ').toLowerCase().includes(q));
  $('#evidenceList').innerHTML=list.map(e=>{
    const c=caseById(e.caseId);
    return `<article class="card">
      <div class="card-head"><div><h3>${esc(e.evidenceNumber)}</h3><div class="muted">${esc(e.title)}</div></div><span class="badge">${esc(statusLabel(e.status))}</span></div>
      <div class="meta"><div><span>Type</span><b>${esc(typeLabel(e.type))}</b></div><div><span>Case</span><b>${esc(c?.caseNumber||'Unknown')}</b></div><div><span>Location</span><b>${esc(e.location||'-')}</b></div><div><span>Serial</span><b>${esc(e.serial||'-')}</b></div></div>
      <div class="actions"><button class="small-btn" onclick="openEvidence('${e.id}')">Inspect</button>${e.status==='stored'?`<button class="small-btn" onclick="checkout('${e.id}')">Check Out</button>`:''}${e.status==='checked_out'?`<button class="small-btn" onclick="returnEvidence('${e.id}')">Return</button>`:''}${e.status!=='released'&&e.status!=='destroyed'?`<button class="small-btn" onclick="releaseEvidence('${e.id}')">Release</button>`:''}${state.permissions.canDestroy&&e.status!=='destroyed'?`<button class="small-btn danger" onclick="destroyEvidence('${e.id}')">Destroy</button>`:''}${state.permissions.canDelete&&e.status==='destroyed'?`<button class="small-btn danger" onclick="deleteEvidence('${e.id}')">Delete</button>`:''}</div>
    </article>`
  }).join('') || '<div class="empty">No matching evidence.</div>';
}
function renderAudit(){
  $('#auditList').innerHTML=(state.audit||[]).slice(0,200).map(a=>`<div class="audit-row"><strong>${esc(a.action)}</strong><div class="muted">${esc(a.actor?.name||'Unknown')} • ${esc(fmt(a.timestamp))} • ${esc(a.targetId||'')}</div><div class="muted">${esc(a.details||'')}</div></div>`).join('') || '<div class="empty">No audit events.</div>';
}
function openModal(title, body){$('#modalTitle').textContent=title;$('#modalBody').innerHTML=body;$('#modal').classList.remove('hidden');}
function closeModal(){$('#modal').classList.add('hidden');}
function openCase(id){
  const c=caseById(id); if(!c)return;
  const ev=arrEvidence().filter(e=>e.caseId===id);
  openModal(`${esc(c.caseNumber)} — ${esc(c.title)}`,`<div class="detail">
    <div class="muted">${esc(c.description||'No description')}</div>
    <div class="meta"><div><span>Location</span><b>${esc(c.location||'-')}</b></div><div><span>Priority</span><b>${esc(c.priority||'normal')}</b></div><div><span>Created By</span><b>${esc(c.createdBy)}</b></div><div><span>Created</span><b>${esc(fmt(c.createdAt))}</b></div></div>
    <h4>Evidence (${ev.length})</h4>${ev.map(e=>`<div class="list-row" onclick="closeModal();openEvidence('${e.id}')"><strong>${esc(e.evidenceNumber)} — ${esc(e.title)}</strong><div class="muted">${esc(typeLabel(e.type))} • ${esc(statusLabel(e.status))}</div></div>`).join('')||'<div class="empty">No evidence attached.</div>'}
  </div>`);
}
function openEvidence(id){
  const e=state.evidence[id]; if(!e)return;
  const c=caseById(e.caseId);
  const custody=e.custody||[];
  openModal(`${esc(e.evidenceNumber)} — ${esc(e.title)}`,`<div class="detail">
    <div class="muted">${esc(e.description||'No description')}</div>
    <div class="meta"><div><span>Type</span><b>${esc(typeLabel(e.type))}</b></div><div><span>Status</span><b>${esc(statusLabel(e.status))}</b></div><div><span>Case</span><b>${esc(c?.caseNumber||'Unknown')}</b></div><div><span>Serial</span><b>${esc(e.serial||'-')}</b></div><div><span>Location</span><b>${esc(e.location||'-')}</b></div><div><span>Quantity</span><b>${esc(e.quantity||1)}</b></div></div>
    <h4>Tags</h4><div class="muted">${esc(e.tags||'None')}</div>
    <h4>Chain of Custody</h4><div class="custody">${custody.map(x=>`<div class="custody-row"><strong>${esc(x.action)}</strong><div class="muted">${esc(x.actor)} • ${esc(fmt(x.timestamp))}</div><div class="muted">${esc(x.note||'')}</div></div>`).join('')||'<div class="empty">No custody records.</div>'}</div>
    <div class="form-actions"><button class="small-btn" onclick="addNote('${id}')">Add Note</button></div>
  </div>`);
}
function caseForm(){
  return `<div class="form"><div class="field"><label>Case Title</label><input id="fTitle" maxlength="80"></div><div class="field"><label>Description</label><textarea id="fDesc" maxlength="500"></textarea></div><div class="field"><label>Location</label><input id="fLoc" maxlength="100"></div><div class="field"><label>Priority</label><select id="fPriority"><option value="low">Low</option><option value="normal" selected>Normal</option><option value="high">High</option><option value="critical">Critical</option></select></div><div class="form-actions"><button class="small-btn" onclick="closeModal()">Cancel</button><button class="primary" onclick="submitCase()">Create Case</button></div></div>`;
}
function evidenceForm(){
  const cases=state.cases.map(c=>`<option value="${c.id}">${esc(c.caseNumber)} — ${esc(c.title)}</option>`).join('');
  const types=state.types.map(t=>`<option value="${t.value}">${esc(t.label)}</option>`).join('');
  const locs=state.locations.map(x=>`<option>${esc(x)}</option>`).join('');
  return `<div class="form"><div class="field"><label>Case</label><select id="eCase">${cases}</select></div><div class="field"><label>Evidence Type</label><select id="eType">${types}</select></div><div class="field"><label>Title</label><input id="eTitle" maxlength="80"></div><div class="field"><label>Description</label><textarea id="eDesc" maxlength="500"></textarea></div><div class="field"><label>Storage Location</label><select id="eLoc">${locs}</select></div><div class="field"><label>Serial / Identifier</label><input id="eSerial" maxlength="100"></div><div class="field"><label>Quantity</label><input id="eQty" type="number" min="1" value="1"></div><div class="field"><label>Tags</label><input id="eTags" maxlength="200" placeholder="comma,separated,tags"></div><div class="form-actions"><button class="small-btn" onclick="closeModal()">Cancel</button><button class="primary" onclick="submitEvidence()">Add Evidence</button></div></div>`;
}
function submitCase(){post('createCase',{title:$('#fTitle').value,description:$('#fDesc').value,location:$('#fLoc').value,priority:$('#fPriority').value});closeModal();}
function submitEvidence(){post('createEvidence',{caseId:$('#eCase').value,type:$('#eType').value,title:$('#eTitle').value,description:$('#eDesc').value,location:$('#eLoc').value,serial:$('#eSerial').value,quantity:$('#eQty').value,tags:$('#eTags').value});closeModal();}
function newCase(){openModal('Create New Case',caseForm())}
function newEvidence(){if(!state.cases.length){alert('Create a case first.');return}openModal('Add Evidence',evidenceForm())}
function actionNote(title, action, id){openModal(title,`<div class="form"><div class="field"><label>Note</label><textarea id="actionNote" maxlength="500"></textarea></div><div class="form-actions"><button class="small-btn" onclick="closeModal()">Cancel</button><button class="primary" onclick="post('${action}',{id:'${id}',note:$('#actionNote').value});closeModal()">Confirm</button></div></div>`)}
function checkout(id){actionNote('Check Out Evidence','checkoutEvidence',id)}
function returnEvidence(id){actionNote('Return Evidence','returnEvidence',id)}
function releaseEvidence(id){actionNote('Release Evidence','releaseEvidence',id)}
function destroyEvidence(id){if(confirm('Mark this evidence as destroyed?'))actionNote('Destroy Evidence','destroyEvidence',id)}
function addNote(id){actionNote('Add Custody Note','addNote',id)}
function deleteCase(id){if(confirm('Delete this case?'))post('deleteCase',{id})}
function deleteEvidence(id){if(confirm('Permanently delete this evidence?'))post('deleteEvidence',{id})}

window.addEventListener('message',e=>{
  if(e.data.action==='open'){
    state=e.data.payload||state;
    $('#operator').textContent='AUTHORIZED OPERATOR';
    $('#app').classList.remove('hidden');
    refresh();
    showView('dashboard');
  }
  if(e.data.action==='close')$('#app').classList.add('hidden');
  if(e.data.action==='sync'){state=e.data.payload||state;refresh();}
});
$('#closeBtn').onclick=()=>post('close');
$('#modalClose').onclick=closeModal;
$('#modal').addEventListener('click',e=>{if(e.target.id==='modal')closeModal()});
$('#newCaseBtn').onclick=newCase;
$('#newCaseDash').onclick=newCase;
$('#newEvidenceBtn').onclick=newEvidence;
$('#caseSearch').oninput=e=>renderCases(e.target.value);
$('#evidenceSearch').oninput=e=>renderEvidence(e.target.value);
$$('.nav').forEach(x=>x.onclick=()=>showView(x.dataset.view));
$$('[data-view-target]').forEach(x=>x.onclick=()=>showView(x.dataset.viewTarget));
