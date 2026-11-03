(() => {
  window.disposeWaveLab?.();
  const root=document.querySelector('[data-education="waves"]');if(!root)return;
  const M=window.MarineModels, P=window.EducationPlots, abort=new AbortController(), signal=abort.signal;
  const $=id=>root.querySelector('#'+id), value=id=>Number($(id).value);
  const concepts=[
    ['Surface','Watch a wave travel','A crest moves to the right, while the first-order water-particle motion oscillates around a fixed position. This linear model leaves out the small net drift found at higher order.','η(x,t) = a cos(kx − ωt) · a = H/2 · ω = 2π/T'],
    ['Dispersion','Depth changes wavelength and speed','The period and water depth together determine the wavelength. Phase speed follows an individual crest; group velocity carries wave energy in this model.','ω² = gk tanh(kh) · L = 2π/k · c = ω/k'],
    ['Particles','Particle paths change with depth','In deep water, the paths approach circles near the surface and shrink with depth. In shallower water, they flatten into ellipses; vertical motion vanishes at the seabed.','u = aω cosh[k(z+h)] / sinh(kh) cos(kx−ωt) · w = aω sinh[k(z+h)] / sinh(kh) sin(kx−ωt)'],
    ['Pressure','Pressure also carries a wave signal','A passing crest raises the dynamic pressure at a fixed submerged point. The signal weakens with depth, especially for shorter waves. The plots below show pressure head and particle velocities at your chosen probe.','p′ = ρga cosh[k(z+h)] / cosh(kh) cos(kx−ωt)'],
    ['Energy','Follow energy at the group velocity','The time-averaged regular-wave energy combines equal kinetic and potential parts. Multiply it by group velocity to get incident power per metre of crest.','E = ρgH²/8 · Cg = ½c[1 + 2kh/sinh(2kh)] · P = E Cg']
  ];
  let q, elapsed=0, last=0, raf=0, inView=true, paused=matchMedia('(prefers-reduced-motion: reduce)').matches;
  const reduced=matchMedia('(prefers-reduced-motion: reduce)');
  function metrics(id,rows){$(id).innerHTML=rows.map(([label,val])=>`<div class="edu-metric"><small>${label}</small><b>${val}</b></div>`).join('');}
  function concept(i){$('wave-title').textContent=concepts[i][1];$('wave-description').textContent=concepts[i][2];$('wave-formula').textContent=concepts[i][3];$('wave-tabs').querySelectorAll('button').forEach((b,j)=>b.setAttribute('aria-pressed',String(i===j)));}
  $('wave-tabs').innerHTML=concepts.map((c,i)=>`<button type="button" class="edu-button" data-concept="${i}" aria-pressed="false">${c[0]}</button>`).join('');
  $('wave-tabs').addEventListener('click',e=>{const b=e.target.closest('[data-concept]');if(b)concept(Number(b.dataset.concept));},{signal});concept(0);
  function staticPlots(){
    const z=-value('wave-probe')*q.h, probe=M.sample(q,z,0), vertical=M.sample(q,z,q.T/4);
    const hidden=q.breaking, dash='Outside range';
    metrics('wave-probe-metrics',[['Probe elevation z',`${z.toFixed(1)} m`],['Horizontal speed amplitude',hidden?dash:`${Math.abs(probe.u).toFixed(3)} m/s`],['Vertical speed amplitude',hidden?dash:`${Math.abs(vertical.w).toFixed(3)} m/s`],['Dynamic pressure amplitude',hidden?dash:`${Math.abs(probe.p/1000).toFixed(3)} kPa`]]);
    const histories=[[],[],[],[]];for(let i=0;i<=240;i++){const t=i*2*q.T/240,s=M.sample(q,z,t);[s.eta,s.p/(M.rho*M.g),s.u,s.w].forEach((y,j)=>histories[j].push([t,hidden?null:y]));}
    P.plot($('wave-history'),[{name:'Surface η',data:histories[0]},{name:'Pressure head',data:histories[1]}],{xmin:0,xmax:2*q.T,xLabel:'Time (s)',yLabel:'m',message:hidden?'Reduce wave height to use this model.':''});
    P.plot($('wave-velocities'),[{name:'Horizontal u',data:histories[2]},{name:'Vertical w',data:histories[3]}],{xmin:0,xmax:2*q.T,xLabel:'Time (s)',yLabel:'m/s',message:hidden?'Outside the screening limit.':''});
    const power=[],depth=[];for(let i=0;i<=120;i++){const H=i*5/120,r=M.wave(H,q.T,q.h);power.push([H,r.breaking?null:r.P/1000]);const h=2+i*198/120;depth.push([h,M.wave(0,q.T,h).cg]);}
    P.plot($('wave-power'),[{data:power}],{xmin:0,xmax:5,xLabel:'Regular wave height H (m)',yLabel:'Incident power (kW/m)'});
    P.plot($('wave-depth'),[{data:depth}],{xmin:2,xmax:200,xLabel:'Water depth h (m)',yLabel:'Group velocity (m/s)'});
  }
  function draw(){
    const {ctx,width:W,height:H}=P.canvasContext($('wave-sea'));ctx.font='12px system-ui';ctx.fillStyle='#dcebf1';
    if(q.breaking){ctx.textAlign='center';ctx.fillText('This wave is beyond the Miche screening limit.',W/2,H/2-10);ctx.fillText('Reduce the height to resume the linear model.',W/2,H/2+14);return;}
    const left=30,right=W-25,seaY=68,bedY=H-31,span=2*q.L,magnify=Math.min(24,32/q.a),xScale=(right-left)/span;
    ctx.fillStyle='#154156';ctx.fillRect(left,seaY,right-left,bedY-seaY);ctx.strokeStyle='#53717f';ctx.lineWidth=1;ctx.beginPath();ctx.moveTo(left,seaY);ctx.lineTo(right,seaY);ctx.stroke();
    ctx.strokeStyle='#7bd2df';ctx.lineWidth=2;ctx.beginPath();for(let i=0;i<=200;i++){const x=span*i/200,eta=M.sample(q,0,elapsed,x).eta,py=seaY-eta*magnify;if(!i)ctx.moveTo(left,py);else ctx.lineTo(left+i*(right-left)/200,py);}ctx.stroke();
    ctx.strokeStyle='#8b9fa4';ctx.lineWidth=5;ctx.beginPath();ctx.moveTo(left,bedY);ctx.lineTo(right,bedY);ctx.stroke();
    for(const fraction of [.08,.35,.65,.93])for(let j=0;j<9;j++){
      const x=(j+.5)*span/9,z=-q.h*fraction,s=M.sample(q,z,elapsed,x),xx=left+x*xScale,yy=seaY+(bedY-seaY)*fraction;
      const ch=M.hyperbolicRatio(q.k*(z+q.h),q.kh,true),sh=M.hyperbolicRatio(q.k*(z+q.h),q.kh,false);
      ctx.beginPath();ctx.ellipse(xx,yy,q.a*ch*magnify,Math.max(.3,q.a*sh*magnify),0,0,M.tau);ctx.strokeStyle='#365e70';ctx.lineWidth=1;ctx.stroke();
      const px=xx+s.dx*magnify,py=yy-s.dz*magnify;ctx.beginPath();ctx.arc(px,py,2.8,0,M.tau);ctx.fillStyle='#efb478';ctx.fill();
      if($('wave-vectors').checked){const vx=s.u*magnify*.65,vy=-s.w*magnify*.65;ctx.beginPath();ctx.moveTo(px,py);ctx.lineTo(px+vx,py+vy);ctx.strokeStyle='#d9ecef';ctx.stroke();}
    }
    ctx.fillStyle='#dcebf1';ctx.textAlign='left';ctx.fillText('Wave travel →',left,24);ctx.fillText(`Two wavelengths · ${span.toFixed(1)} m`,left,H-10);ctx.textAlign='right';ctx.fillText(`Depth ${q.h.toFixed(0)} m`,right,H-10);
  }
  function step(now){raf=0;if(!paused&&inView&&!document.hidden&&!q.breaking){if(last)elapsed+=Math.min((now-last)/1000,.1);last=now;draw();raf=requestAnimationFrame(step);}else last=0;}
  function schedule(){cancelAnimationFrame(raf);raf=0;last=0;draw();if(!paused&&inView&&!document.hidden&&!q.breaking)raf=requestAnimationFrame(step);$('wave-pause').textContent=paused?'Play animation':'Pause animation';$('wave-pause').setAttribute('aria-pressed',String(paused));}
  function updateWave(){q=M.wave(value('wave-H'),value('wave-T'),value('wave-h'));['H','T','h'].forEach(k=>$('wave-'+k+'-out').textContent=`${value('wave-'+k)} ${k==='T'?'s':'m'}`);$('wave-validity').textContent=M.validity(q);$('wave-validity').className='edu-note'+(q.caution||q.breaking?' edu-warning':'');$('wave-validity').dataset.level=q.breaking?'error':q.caution?'caution':'ok';metrics('wave-metrics',[['Wavelength',`${q.L.toFixed(2)} m`],['Phase speed',`${q.c.toFixed(2)} m/s`],['Group velocity',`${q.cg.toFixed(2)} m/s`],['Incident regular-wave power',q.breaking?'Outside range':`${(q.P/1000).toFixed(2)} kW/m`]]);staticPlots();schedule();}
  function spectrum(){
    const Hm0=value('spectrum-H'),Tp=value('spectrum-T'),h=value('spectrum-h'),s=M.spectrum(Hm0,Tp,h),proxy=M.wave(Hm0,Tp,h);
    ['H','T','h'].forEach(k=>$('spectrum-'+k+'-out').textContent=`${value('spectrum-'+k)} ${k==='T'?'s':'m'}`);
    const warning=proxy.caution||proxy.breaking;$('spectrum-note').className='edu-note'+(warning?' edu-warning':'');$('spectrum-note').textContent=(warning?'These height, period, and depth settings suggest nonlinear or breaking effects may matter. Treat the flux as a formal linear-model result. ':'The spectrum is a teaching example, not a measured or site-validated sea state. ')+'Individual waves can be higher than Hm₀. This model does not simulate breaking or transform the spectrum for shallow-water conditions.';
    metrics('spectrum-metrics',[['Variance m₀',`${s.m0.toFixed(4)} m²`],['Recovered Hm₀',`${(4*Math.sqrt(s.components.reduce((sum,c)=>sum+c.S*s.df,0))).toFixed(2)} m`],['Energy period Te',`${s.Te.toFixed(2)} s`],['Linear-model incident flux',`${(s.flux/1000).toFixed(2)} kW/m`]]);
    P.plot($('wave-spectrum'),[{data:s.components.map(c=>[c.f,c.S])}],{xmin:s.fmin,xmax:s.fmax,xLabel:'Frequency (Hz)',yLabel:'S(f) (m²/Hz)'});
    const dt=Math.min(.1,1/(8*s.fmax)),N=Math.ceil(120/dt),record=[];for(let i=0;i<=N;i++){const t=i*120/N;let eta=0;for(const c of s.components)eta+=c.amplitude*Math.cos(M.tau*c.f*t+c.phase);record.push([t,eta]);}
    P.plot($('wave-irregular'),[{data:record}],{xmin:0,xmax:120,xLabel:'Time (s)',yLabel:'Surface elevation (m)'});
  }
  ['wave-H','wave-T','wave-h'].forEach(id=>$(id).addEventListener('input',updateWave,{signal}));$('wave-probe').addEventListener('change',staticPlots,{signal});$('wave-vectors').addEventListener('change',draw,{signal});
  ['spectrum-H','spectrum-T','spectrum-h'].forEach(id=>$(id).addEventListener('input',spectrum,{signal}));
  $('wave-reset').addEventListener('click',()=>{$('wave-H').value=1.5;$('wave-T').value=8;$('wave-h').value=50;$('wave-probe').value=.5;$('wave-vectors').checked=true;elapsed=0;updateWave();},{signal});
  $('wave-pause').addEventListener('click',()=>{paused=!paused;schedule();},{signal});document.addEventListener('visibilitychange',schedule,{signal});reduced.addEventListener('change',()=>{paused=reduced.matches;schedule();},{signal});
  updateWave();spectrum();
  const ro=new ResizeObserver(()=>{draw();staticPlots();spectrum();});ro.observe($('wave-sea'));
  const io=new IntersectionObserver(entries=>{inView=entries[0].isIntersecting;schedule();});io.observe($('wave-sea'));
  window.disposeWaveLab=()=>{abort.abort();ro.disconnect();io.disconnect();cancelAnimationFrame(raf);};
})();
