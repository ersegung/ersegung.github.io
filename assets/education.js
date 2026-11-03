/* Canvas plots and resource calculators shared by the teaching pages. */
(() => {
  window.disposeEnergyLabs?.();
  const M = window.MarineModels;
  if (!M) return;
  const colors = ['#8ed9e8', '#f3bb7c', '#d5afee'];
  function canvasContext(canvas) {
    const width = Math.max(220, canvas.clientWidth), height = Math.max(180, canvas.clientHeight);
    const dpr = Math.min(window.devicePixelRatio || 1, 2);
    canvas.width = Math.round(width * dpr); canvas.height = Math.round(height * dpr);
    const ctx = canvas.getContext('2d'); ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    ctx.fillStyle = '#08283c'; ctx.fillRect(0, 0, width, height);
    return { ctx, width, height };
  }
  function plot(canvas, series, options = {}) {
    if (!canvas) return;
    const { ctx, width: W, height: H } = canvasContext(canvas);
    const left = 55, right = W - 18, top = 36, bottom = H - 45;
    const all = series.flatMap(s => s.data).filter(p => Number.isFinite(p[0]) && Number.isFinite(p[1]));
    const xmin = options.xmin ?? Math.min(...all.map(p => p[0]));
    const xmax = options.xmax ?? Math.max(...all.map(p => p[0]));
    let ymin = options.ymin ?? Math.min(0, ...all.map(p => p[1]));
    let ymax = options.ymax ?? Math.max(...all.map(p => p[1]));
    if (!all.length || !Number.isFinite(ymax)) { ymin = 0; ymax = 1; }
    if (ymax === ymin) ymax = ymin + 1;
    const X = x => left + (x - xmin) / (xmax - xmin || 1) * (right - left);
    const Y = y => bottom - (y - ymin) / (ymax - ymin) * (bottom - top);
    const tick = n => Math.abs(n) < .001 && n !== 0 ? n.toExponential(1) : Number(n.toPrecision(3)).toString();
    ctx.font = '11px system-ui'; ctx.lineWidth = 1;
    for (let i = 0; i <= 4; i++) {
      const x = left + i * (right - left) / 4, y = top + i * (bottom - top) / 4;
      ctx.strokeStyle = '#25465a'; ctx.beginPath(); ctx.moveTo(left, y); ctx.lineTo(right, y); ctx.stroke();
      ctx.fillStyle = '#bfd4df'; ctx.textAlign = 'right'; ctx.fillText(tick(ymax - i * (ymax - ymin) / 4), left - 8, y + 4);
      ctx.textAlign = 'center'; ctx.fillText(tick(xmin + i * (xmax - xmin) / 4), x, bottom + 17);
    }
    ctx.save(); ctx.beginPath(); ctx.rect(left, top, right - left, bottom - top); ctx.clip();
    series.forEach((s, index) => {
      ctx.strokeStyle = s.color || colors[index % colors.length]; ctx.lineWidth = 2; ctx.beginPath(); let pen = false;
      s.data.forEach(([x, y]) => { if (!Number.isFinite(y)) { pen = false; return; } if (pen) ctx.lineTo(X(x), Y(y)); else ctx.moveTo(X(x), Y(y)); pen = true; }); ctx.stroke();
    }); ctx.restore();
    ctx.textAlign = 'left'; ctx.fillStyle = '#dcebf1'; ctx.fillText(options.yLabel || '', 12, 17);
    ctx.textAlign = 'center'; ctx.fillText(options.xLabel || '', (left + right) / 2, H - 8);
    let legendX = left;
    series.forEach((s, i) => { if (!s.name) return; ctx.fillStyle = s.color || colors[i % colors.length]; ctx.textAlign = 'left'; ctx.fillText(s.name, legendX, 31); legendX += ctx.measureText(s.name).width + 16; });
    if (options.message) { ctx.fillStyle = '#dcebf1'; ctx.textAlign = 'center'; const words=options.message.split(' ');let line='',lines=[];for(const word of words){const trial=line?line+' '+word:word;if(ctx.measureText(trial).width>right-left-12&&line){lines.push(line);line=word;}else line=trial;}if(line)lines.push(line);lines.forEach((text,i)=>ctx.fillText(text,(left+right)/2,(top+bottom)/2+(i-(lines.length-1)/2)*17)); }
  }
  window.EducationPlots = { plot, canvasContext, colors };
  const specs = {
    wave: { name: 'Wave power', title: 'How much power does a regular wave carry?', intro: 'Change one idealized, nonbreaking wave. The result is incident power per metre of crest, before any device captures it.',
      controls: [['H','Regular wave height H',.1,5,.1,2,'m'],['T','Wave period T',3,18,.5,8,'s'],['h','Water depth h',2,200,1,50,'m']],
      formula: 'ω² = gk tanh(kh) · E = ρgH²/8 · P = E Cg', result: 'Incident regular-wave power', assumptions: 'We use linear gravity-wave theory, ρ = 1025 kg/m³, and g = 9.81 m/s². Depth is constant, with no current or dissipation. H is a regular wave height, not a significant height.', x: [0,5,'Regular height H (m)'], y: 'kW/m', curve: (x,v) => { const q=M.wave(x,v.T,v.h);return q.breaking?null:q.P/1000; },
      evaluate: v => { const q=M.wave(v.H,v.T,v.h);return {value:q.breaking?'Outside model range':`${(q.P/1000).toFixed(2)} kW/m`,detail:`Wavelength: ${q.L.toFixed(1)} m. Group velocity: ${q.cg.toFixed(2)} m/s.`,warning:M.validity(q),level:q.breaking?'error':q.caution?'caution':'ok'}; } },
    current: { name:'Current power',title:'How does current speed affect a rotor?',intro:'Choose a speed, diameter, and power coefficient. This is mechanical power extracted at the rotor; electrical and transmission losses come later.',
      controls:[['U','Current speed U',0,4,.1,2,'m/s'],['D','Rotor diameter D',1,30,1,10,'m'],['Cp','Power coefficient Cp',.1,.59,.01,.4,'']],formula:'A = πD²/4 · P = ½ρA U³ Cp',result:'Mechanical rotor power',assumptions:'We use a uniform current and a fixed Cp. The ideal unconfined actuator-disc limit is 16/27; blockage and other configurations need their own analysis. This model has no rated-power limit or generator losses.',x:[0,4,'Current speed U (m/s)'],y:'kW',curve:(x,v)=>M.current(x,v.D,v.Cp).power/1000,
      evaluate:v=>{const q=M.current(v.U,v.D,v.Cp);return{value:`${(q.power/1000).toFixed(2)} kW`,detail:`Swept area: ${q.A.toFixed(1)} m². Incident kinetic-power flux through that area: ${(q.incident/1000).toFixed(1)} kW.`,warning:'The curve holds Cp fixed. A real turbine changes its controls, stops below cut-in speed, and may limit output at higher speeds.',level:'ok'};} },
    thermal: {name:'OTEC limit',title:'What is the ideal thermal-efficiency ceiling?',intro:'Compare warm surface water with a cold-water source. Carnot efficiency is an upper bound, not the efficiency of an OTEC plant.',
      controls:[['warm','Warm-water temperature',20,32,.5,27,'°C'],['cold','Cold-water temperature',2,15,.5,5,'°C']],formula:'ηCarnot = 1 − Tcold / Twarm (temperatures in kelvin)',result:'Ideal Carnot efficiency',assumptions:'We convert °C to kelvin before taking the ratio. Real cycles operate across smaller effective temperature differences, and pumps consume power. This calculation cannot predict net plant output.',x:[20,32,'Warm-water temperature (°C)'],y:'Efficiency (%)',curve:(x,v)=>100*M.carnot(x,v.cold),
      evaluate:v=>({value:`${(100*M.carnot(v.warm,v.cold)).toFixed(2)}%`,detail:`The source-water temperature difference is ${(v.warm-v.cold).toFixed(1)}°C.`,warning:v.warm-v.cold<20?'This difference is below the roughly 20°C often used when screening OTEC sites. That guideline is not a fundamental thermodynamic threshold.':'A difference of roughly 20°C or more can be useful for site screening, but it does not guarantee a practical or economical plant.',level:'ok'}) },
    pto: {name:'PTO oscillator',title:'Find the balance between damping and motion',intro:'Keep the forcing fixed and change the frequency and PTO damping. The damper extracts energy while also resisting the motion.',
      controls:[['force','Force amplitude F₀',1,50,1,25,'kN'],['ratio','Forcing / natural frequency',.2,2.5,.05,1,''],['zeta','PTO damping ratio',.01,1,.01,.25,'']],formula:'X = F₀ / √[(K − Mω²)² + (Bω)²] · Ppto = ½Bptoω²X²',result:'Mean PTO-damper power',assumptions:'This illustrative oscillator has M = 10,000 kg, natural frequency 1 rad/s, and intrinsic damping ratio 0.05. B includes intrinsic and PTO damping. Force and coefficients stay fixed; hydrodynamic radiation, stroke limits, control, and electrical losses are omitted.',x:[.01,1,'PTO damping ratio'],y:'kW',curve:(x,v)=>M.pto(v.force,v.ratio,x).power/1000,
      evaluate:v=>{const q=M.pto(v.force,v.ratio,v.zeta);return{value:`${(q.power/1000).toFixed(2)} kW`,detail:`Displacement amplitude: ${q.amplitude.toFixed(2)} m. Forcing frequency: ${q.omega.toFixed(2)} rad/s.`,warning:'The model allows large motions because it has no stroke or load limits. These numbers illustrate a mechanics relationship; they are not a prediction for a real device.',level:'ok'};} }
  };
  const abort = new AbortController(), observers=[];
  document.querySelectorAll('[data-energy-lab]').forEach((lab, index) => {
    const query = key => lab.querySelector(`[data-lab-${key}]`), modes=lab.dataset.modes.split(','); let mode=modes[0], values={};
    function render(){const s=specs[mode],r=s.evaluate(values);query('result').textContent=r.value;query('detail').textContent=r.detail;query('warning').textContent=r.warning;query('warning').className='edu-note'+(r.level==='ok'?'':' edu-warning');query('warning').dataset.level=r.level;
      const data=Array.from({length:101},(_,i)=>{const x=s.x[0]+i*(s.x[1]-s.x[0])/100;return[x,s.curve(x,values)];});plot(query('chart'),[{data}],{xmin:s.x[0],xmax:s.x[1],xLabel:s.x[2],yLabel:s.y}); }
    function select(next){mode=next;const s=specs[mode];values=Object.fromEntries(s.controls.map(c=>[c[0],c[5]]));query('title').textContent=s.title;query('intro').textContent=s.intro;query('formula').textContent=s.formula;query('result-label').textContent=s.result;query('assumptions').textContent=s.assumptions;query('chart-note').textContent='This curve changes the horizontal-axis parameter while holding the other settings fixed.';
      query('controls').innerHTML=s.controls.map(([key,label,min,max,step,val,unit])=>`<label for="lab-${index}-${key}">${label} <output data-value="${key}">${val} ${unit}</output><input id="lab-${index}-${key}" type="range" min="${min}" max="${max}" step="${step}" value="${val}" data-key="${key}" data-unit="${unit}"></label>`).join('');
      query('tabs').querySelectorAll('button').forEach(b=>b.setAttribute('aria-pressed',String(b.dataset.mode===mode)));render();}
    query('tabs').innerHTML=modes.map(m=>`<button class="edu-button" type="button" data-mode="${m}" aria-pressed="false">${specs[m].name}</button>`).join('');query('tabs').hidden=modes.length===1;
    query('tabs').addEventListener('click',e=>{const button=e.target.closest('[data-mode]');if(button)select(button.dataset.mode);},{signal:abort.signal});
    query('controls').addEventListener('input',e=>{if(!e.target.dataset.key)return;values[e.target.dataset.key]=Number(e.target.value);query('controls').querySelector(`[data-value="${e.target.dataset.key}"]`).textContent=`${e.target.value} ${e.target.dataset.unit}`;render();},{signal:abort.signal});
    query('reset').addEventListener('click',()=>select(mode),{signal:abort.signal});select(mode);const ro=new ResizeObserver(render);ro.observe(query('chart'));observers.push(ro);
  });
  window.disposeEnergyLabs=()=>{abort.abort();observers.forEach(o=>o.disconnect());};
})();
