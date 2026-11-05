/* Interactive Potential Flow Module. */
(() => {
 window.disposePFlow?.();
 const root=document.querySelector('[data-pflow]');if(!root)return;
 const M=window.PFlow,$=s=>root.querySelector(s),id=s=>$('#pf-'+s),abort=new AbortController(),opts={signal:abort.signal};
 const symbols={source:'+',sink:'−',ccw:'↺',cw:'↻',doublet:'⇄'},names={source:'Source',sink:'Sink',ccw:'Counterclockwise vortex',cw:'Clockwise vortex',doublet:'Doublet'};
 const canvas=id('flow'),ctx=canvas.getContext('2d'),trail=id('trails'),tx=trail.getContext('2d'),stage=id('stage'),markers=id('markers');
 let s=M.preset('cylinder'),chosen=0,serial=0,W=600,H=420,dpr=1,body=null,raf=0,drawFrame=0,last=0,time=0,running=false,particles=[],dyes=[],age=0,placeDye=false,drag=null,probe=[-4,0],emitter=[-8,1],streams=[],modeName='cylinder';
 const f=(x,n=2)=>Number.isFinite(x)?x.toFixed(n):'—';
 const XY=(x,y)=>[(x+10)*W/20,(7-y)*H/14],world=(x,y)=>[20*x/W-10,7-14*y/H];
 s.e.forEach(e=>e.id=++serial);
 function textStatus(t){id('status').textContent=t;}
 function resetTracers(){particles=[];dyes=[];age=0;time=0;tx.clearRect(0,0,W,H);id('time').textContent='0.0';}
 function velocityRead(p){const v=M.valid(...p,s,body)?M.velocity(...p,s):null;id('location').textContent=f(p[0])+', '+f(p[1]);id('speed').textContent=v?f(Math.hypot(...v),3):'Excluded';id('components').textContent=v?f(v[0])+', '+f(v[1]):'—';}
 function inputs(){id('U').value=s.U;id('U-range').value=s.U;id('angle').value=s.angle;id('selected').innerHTML=s.e.map((q,i)=>'<option value="'+i+'">'+(i+1)+'. '+names[q.type]+'</option>').join('')||'<option>No elements yet</option>';id('selected').value=chosen;const e=s.e[chosen];
  id('inspector').hidden=!e;id('empty').hidden=!!e;
  if(e){for(const key of ['x','y','strength','angle'])id('element-'+key).value=e[key];id('strength-label').textContent=e.type==='doublet'?'Doublet coefficient D':'Strength |'+(['ccw','cw'].includes(e.type)?'Γ':'Q')+'|';id('orientation').hidden=e.type!=='doublet';}
  root.querySelectorAll('[data-add]').forEach(b=>b.disabled=s.e.length>=12);drawMarkers();
 }
 function drawMarkers(){markers.replaceChildren();for(let i=0;i<s.e.length;i++){const q=s.e[i],b=document.createElement('button');b.className='pf-point';b.type='button';b.dataset.point=i;b.dataset.kind=q.type;b.setAttribute('aria-label','Move '+names[q.type]+' '+(i+1));b.setAttribute('aria-pressed',String(i===chosen));b.textContent=symbols[q.type];b.style.left=((q.x+10)*5)+'%';b.style.top=((7-q.y)*100/14)+'%';b.title=names[q.type]+': drag, or use arrow keys';markers.append(b);}}
 function updateMarker(i){let q=s.e[i],b=$('[data-point="'+i+'"]');if(b){b.style.left=((q.x+10)*5)+'%';b.style.top=((7-q.y)*100/14)+'%';}}
 function boundaryText(){id('boundary').textContent=body?'The outlined circle is a streamline: radius R = √(D/U) = '+f(body.R)+'. The exterior flow has zero normal velocity there.':'No solid boundary is imposed. You are viewing the superposed flow outside the small excluded cores.';}
 function rebuild(){body=M.cylinder(s);resetTracers();boundaryText();streams=[];if(id('stream').checked){
   const seeds=[];
   if(s.U>0){for(let i=-6.6;i<=6.6;i+=.6){seeds.push([-9.95,i],[9.95,i]);}if(Math.abs(s.angle)>10)for(let i=-9.6;i<=9.6;i+=.8)seeds.push([i,6.95],[i,-6.95]);}
   for(const q of s.e){if(body&&Math.hypot(q.x-body.x,q.y-body.y)<.01)continue;
    if(q.type==='source'||q.type==='sink'||q.type==='doublet'){for(let i=0;i<16;i++){const a=i*M.tau/16+.015;seeds.push([q.x+.19*Math.cos(a),q.y+.19*Math.sin(a)]);}}
    if(q.type==='ccw'||q.type==='cw')for(let r=.5;r<=5;r+=.5)seeds.push([q.x+r,q.y]);
   }
   for(const p of seeds){if(M.valid(...p,s,body)){let a=M.trace(p,s,-1,.065,body),b=M.trace(p,s,1,.065,body);streams.push(a.reverse().concat(b.slice(1)));}}
  }paint();velocityRead(probe);
 }
 function schedule(){if(!drawFrame)drawFrame=requestAnimationFrame(()=>{drawFrame=0;rebuild();});}
 function drawPath(c,pts){if(!pts.length)return;c.beginPath();pts.forEach((p,i)=>{const xy=XY(...p);if(i)c.lineTo(...xy);else c.moveTo(...xy)});c.stroke();}
 function circle(c,x,y,r){let [a,b]=XY(x,y);c.beginPath();c.arc(a,b,r*W/20,0,M.tau);}
 function paint(){ctx.clearRect(0,0,W,H);ctx.fillStyle='#f7fafb';ctx.fillRect(0,0,W,H);
  ctx.strokeStyle='#e7eff1';ctx.lineWidth=.6;for(let x=-10;x<=10;x++){ctx.beginPath();ctx.moveTo(...XY(x,-7));ctx.lineTo(...XY(x,7));ctx.stroke();}for(let y=-7;y<=7;y++){ctx.beginPath();ctx.moveTo(...XY(-10,y));ctx.lineTo(...XY(10,y));ctx.stroke();}
  ctx.strokeStyle='#d1e0e5';ctx.lineWidth=1;ctx.beginPath();ctx.moveTo(...XY(-10,0));ctx.lineTo(...XY(10,0));ctx.moveTo(...XY(0,-7));ctx.lineTo(...XY(0,7));ctx.stroke();
  ctx.fillStyle='#65848e';ctx.font='10px system-ui';ctx.textAlign='center';for(let x=-8;x<=8;x+=4)ctx.fillText(String(x),XY(x,0)[0],H-7);ctx.textAlign='left';ctx.fillText('x',W-14,H-7);ctx.fillText('y',7,13);for(let y=-4;y<=4;y+=4)ctx.fillText(String(y),6,XY(0,y)[1]-3);
  if(id('vectors').checked){ctx.strokeStyle='#83aebb';ctx.lineWidth=.85;for(let y=-6.6;y<7;y+=.7)for(let x=-9.6;x<10;x+=.7){if(!M.valid(x,y,s,body))continue;let v=M.velocity(x,y,s);if(!v)continue;let mag=Math.hypot(...v);if(mag<1e-8)continue;let len=Math.min(.45,.24*mag),a=XY(x,y),b=XY(x+len*v[0]/mag,y+len*v[1]/mag),ang=Math.atan2(b[1]-a[1],b[0]-a[0]);ctx.beginPath();ctx.moveTo(...a);ctx.lineTo(...b);for(let da of [-.55,.55]){ctx.moveTo(...b);ctx.lineTo(b[0]-3.5*Math.cos(ang+da),b[1]-3.5*Math.sin(ang+da));}ctx.stroke();}}
  ctx.strokeStyle='#288193';ctx.lineWidth=1.1;ctx.globalAlpha=.76;for(const path of streams)drawPath(ctx,path);ctx.globalAlpha=1;
  if(body){circle(ctx,body.x,body.y,body.R);ctx.fillStyle='#e1ebee';ctx.fill();ctx.strokeStyle='#537b8b';ctx.lineWidth=1.5;ctx.stroke();}
  if(!body)for(const q of s.e){circle(ctx,q.x,q.y,M.core);ctx.fillStyle='#f0e8df';ctx.fill();}
  if(id('dye').checked){circle(ctx,...emitter,.10);ctx.fillStyle='#aa5924';ctx.fill();ctx.strokeStyle='#aa5924';ctx.lineWidth=1;circle(ctx,...emitter,.19);ctx.stroke();}
 }
 function particleSeed(){const sources=s.e.filter(q=>q.type==='source');if(sources.length&&Math.random()<.35){let q=sources[Math.floor(Math.random()*sources.length)],a=Math.random()*M.tau;return [q.x+.17*Math.cos(a),q.y+.17*Math.sin(a)];}
  if(s.U>.01&&Math.random()<.7){const a=s.angle*Math.PI/180,x=Math.cos(a),y=Math.sin(a);if(Math.random()<Math.abs(x)/(Math.abs(x)+Math.abs(y)))return [x>0?-9.97:9.97,(Math.random()*2-1)*6.9];return [(Math.random()*2-1)*9.9,y>0?-6.97:6.97];}
  return [(Math.random()*2-1)*9.9,(Math.random()*2-1)*6.9];
 }
 function animate(now){raf=0;if(!running||document.hidden)return;const dt=last?Math.min((now-last)/1000,.055):0;last=now;time+=dt;
  tx.clearRect(0,0,W,H);
  if(id('particles').checked){for(let i=0;i<3&&particles.length<160;i++){let p=particleSeed();if(M.valid(...p,s,body))particles.push({p,trail:[p],life:0});}
   for(let i=particles.length-1;i>=0;i--){let t=particles[i],p=M.advect(t.p,dt,s,body);if(!p||t.life>25){particles.splice(i,1);continue;}t.p=p;t.life+=dt;t.trail.push(p);if(t.trail.length>14)t.trail.shift();tx.strokeStyle='#526e86';tx.lineWidth=1.3;drawPath(tx,t.trail);circle(tx,...p,.028);tx.fillStyle='#526e86';tx.fill();}
  }
  if(id('dye').checked){age+=dt;if(age>=.13){age=0;if(M.valid(...emitter,s,body)&&dyes.length<200)dyes.unshift({p:[...emitter],life:0});}
   for(let i=dyes.length-1;i>=0;i--){const q=dyes[i],p=M.advect(q.p,dt,s,body);if(!p||q.life>25)dyes.splice(i,1);else{q.p=p;q.life+=dt;}}
   tx.strokeStyle='#b16228';tx.lineWidth=1.8;const ordered=dyes.map(t=>t.p);tx.beginPath();let prev=null;for(const p of ordered){if(prev&&Math.hypot(p[0]-prev[0],p[1]-prev[1])<.7)tx.lineTo(...XY(...p));else tx.moveTo(...XY(...p));prev=p;}tx.stroke();for(const t of dyes){circle(tx,...t.p,.035);tx.fillStyle='#b16228';tx.fill();}
  }
  id('time').textContent=f(time,1);raf=requestAnimationFrame(animate);
 }
 function stop(){running=false;last=0;cancelAnimationFrame(raf);raf=0;id('play').textContent='Play tracers';}
 function reset(name){stop();s=M.preset(name);modeName=name;s.e.forEach(q=>q.id=++serial);chosen=s.e.length?0:-1;emitter=[-8,1];placeDye=false;id('place-dye').setAttribute('aria-pressed','false');id('preset').value=name;inputs();rebuild();textStatus('Pattern loaded. Add an element, drag it, or change a setting.');}
 function custom(){modeName='custom';id('preset').value='custom';}
 const limits={'U':[0,3],'angle':[-180,180],'element-x':[-9.5,9.5],'element-y':[-6.5,6.5],'element-strength':[.1,60],'element-angle':[-180,180]};
 function valueInput(t,blur=false){const key=t.id.replace('pf-',''),lim=limits[key];if(!lim)return;let v=t.valueAsNumber;if(!Number.isFinite(v)||v<lim[0]||v>lim[1]){if(blur){t.value=key.startsWith('element-')?s.e[chosen]?.[key.slice(8)]:s[key];textStatus('Enter a number from '+lim[0]+' to '+lim[1]+'. The previous value was kept.');}return;}
  if(key.startsWith('element-')){if(!s.e[chosen])return;s.e[chosen][key.slice(8)]=v;updateMarker(chosen);}else{s[key]=v;if(key==='U')id('U-range').value=v;}custom();schedule();
 }
 root.addEventListener('input',e=>{if(e.target.id==='pf-U-range'){s.U=e.target.valueAsNumber;id('U').value=s.U;custom();schedule();}else valueInput(e.target);},opts);
 root.addEventListener('focusout',e=>valueInput(e.target,true),opts);
 root.addEventListener('change',e=>{const t=e.target;
  if(t.id==='pf-preset'){if(t.value!=='custom')reset(t.value);}
  if(t.id==='pf-selected'){chosen=+t.value;inputs();}
  if(['pf-stream','pf-vectors','pf-dye','pf-particles'].includes(t.id))rebuild();
 },opts);
 root.addEventListener('click',e=>{const b=e.target.closest('button');if(!b)return;
  if(b.dataset.add){if(s.e.length>=12)return;let i=s.e.length,p=[-3+(i%4)*2,-2+Math.floor(i/4)*2];s.e.push({...M.element(b.dataset.add,...p),id:++serial});chosen=s.e.length-1;custom();inputs();rebuild();textStatus(names[b.dataset.add]+' added. Drag its marker or edit its coordinates.');}
  if(b.id==='pf-delete'&&chosen>=0){s.e.splice(chosen,1);chosen=Math.min(chosen,s.e.length-1);custom();inputs();rebuild();textStatus('Selected element removed.');}
  if(b.id==='pf-reset')reset('cylinder');
  if(b.id==='pf-play'){if(running)stop();else{running=true;last=0;b.textContent='Pause tracers';raf=requestAnimationFrame(animate);}}
  if(b.id==='pf-clear'){resetTracers();textStatus('Tracer history cleared. The flow field is unchanged.');}
  if(b.id==='pf-place-dye'){placeDye=!placeDye;b.setAttribute('aria-pressed',String(placeDye));textStatus(placeDye?'Click or tap the flow panel to place the fixed dye emitter.':'Dye placement cancelled.');}
  if(b.id==='pf-check'){const c=M.checks();id('test-result').textContent=c.every(x=>x[1])?'All '+c.length+' checks passed: source, sink, circulation, cylinder boundary, stagnation points, and tracer motion.':'Check failed: '+c.filter(x=>!x[1]).map(x=>x[0]).join(', ');}
  if(b.id==='pf-export'){let rows=['# Potential Flow Module velocity field; illustrative model units','# U='+s.U+'; direction_deg='+s.angle,'# elements='+JSON.stringify(s.e),'x,y,u,v,speed,status'];for(let y=-7;y<=7;y+=.5)for(let x=-10;x<=10;x+=.5){let valid=M.valid(x,y,s,body),v=valid?M.velocity(x,y,s):null;rows.push([x,y,...(v?[...v,Math.hypot(...v),'valid']:['','','','excluded'])].join(','));}const url=URL.createObjectURL(new Blob([rows.join('\n')],{type:'text/csv;charset=utf-8'})),a=document.createElement('a');a.href=url;a.download='potential-flow-velocity-field.csv';a.click();setTimeout(()=>URL.revokeObjectURL(url),2000);textStatus('Velocity field exported, including the current settings and excluded locations.');}
 },opts);
 const pointerWorld=e=>{const r=stage.getBoundingClientRect();return world((e.clientX-r.left)/r.width*W,(e.clientY-r.top)/r.height*H);};
 stage.addEventListener('pointerdown',e=>{const b=e.target.closest('[data-point]');if(b){chosen=+b.dataset.point;drag={i:chosen,pointer:e.pointerId};stage.setPointerCapture(e.pointerId);inputs();e.preventDefault();}else if(placeDye){let p=pointerWorld(e);if(!M.valid(...p,s,body)){textStatus('Place the emitter outside the body and singularity cores.');return;}emitter=p;placeDye=false;id('dye').checked=true;id('place-dye').setAttribute('aria-pressed','false');rebuild();textStatus('Dye emitter placed. Press Play tracers to release dye.');}},opts);
 stage.addEventListener('pointermove',e=>{probe=pointerWorld(e);velocityRead(probe);if(drag){let q=s.e[drag.i];q.x=Math.max(-9.5,Math.min(9.5,Math.round(probe[0]*20)/20));q.y=Math.max(-6.5,Math.min(6.5,Math.round(probe[1]*20)/20));id('element-x').value=q.x;id('element-y').value=q.y;updateMarker(drag.i);custom();schedule();}},opts);
 const release=()=>{if(drag){drag=null;schedule();}};stage.addEventListener('pointerup',release,opts);stage.addEventListener('pointercancel',release,opts);
 stage.addEventListener('focusin',e=>{const b=e.target.closest('[data-point]');if(!b||chosen===+b.dataset.point)return;chosen=+b.dataset.point;const q=s.e[chosen];id('selected').value=chosen;id('inspector').hidden=false;id('empty').hidden=true;for(const k of ['x','y','strength','angle'])id('element-'+k).value=q[k];id('strength-label').textContent=q.type==='doublet'?'Doublet coefficient D':'Strength |'+(['ccw','cw'].includes(q.type)?'Γ':'Q')+'|';id('orientation').hidden=q.type!=='doublet';root.querySelectorAll('[data-point]').forEach(el=>el.setAttribute('aria-pressed',String(+el.dataset.point===chosen)));},opts);
 stage.addEventListener('keydown',e=>{const b=e.target.closest('[data-point]');if(!b)return;let k=e.key,i=+b.dataset.point;if(!['ArrowLeft','ArrowRight','ArrowUp','ArrowDown'].includes(k))return;e.preventDefault();chosen=i;let q=s.e[i],d=e.shiftKey?.05:.25;q.x=Math.max(-9.5,Math.min(9.5,q.x+(k==='ArrowRight'?d:k==='ArrowLeft'?-d:0)));q.y=Math.max(-6.5,Math.min(6.5,q.y+(k==='ArrowUp'?d:k==='ArrowDown'?-d:0)));id('element-x').value=q.x;id('element-y').value=q.y;updateMarker(i);custom();schedule();},opts);
 document.addEventListener('visibilitychange',()=>{if(document.hidden)stop();},opts);
 const resize=()=>{const r=stage.getBoundingClientRect();if(r.width<1)return;W=r.width;H=r.height;dpr=Math.min(window.devicePixelRatio||1,2);for(const c of [canvas,trail]){c.width=Math.round(W*dpr);c.height=Math.round(H*dpr);c.getContext('2d').setTransform(dpr,0,0,dpr,0,0);}paint();};
 const observer=new ResizeObserver(resize);observer.observe(stage);inputs();rebuild();resize();
 window.disposePFlow=()=>{stop();cancelAnimationFrame(drawFrame);abort.abort();observer.disconnect();};
})();
