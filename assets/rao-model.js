/* Browser adaptation of E. D. Gedikli's HMEC MATLAB RAO teaching demos v1.0.
   SI internally; exp(+i wt); synthetic hydrodynamic coefficients. */
(function(root){
  'use strict';
  const rho=1025,g=9.81,tau=2*Math.PI,deg=180/Math.PI;
  const common={mass:rho*Math.PI*9*4/1000,pto:60,visc:20,stiff:0,as:1,bs:1,fs:1,a:.5,T:7};
  function defaults(mode){return mode==='heave'?{...common,r:3}:{...common,mass:420,pto:130,visc:30,I:13,area:80,c55:18,ppto:2.5,pvisc:.6,pstiff:0,couple:100,direct:true};}
  const cmul=(a,b)=>[a[0]*b[0]-a[1]*b[1],a[0]*b[1]+a[1]*b[0]];
  const csub=(a,b)=>[a[0]-b[0],a[1]-b[1]];
  const cdiv=(a,b)=>{const n=b[0]*b[0]+b[1]*b[1];return [(a[0]*b[0]+a[1]*b[1])/n,(a[1]*b[0]-a[0]*b[1])/n];};
  const abs=a=>Math.hypot(...a),phase=a=>abs(a)===0?null:(Math.atan2(a[1],a[0])*deg+540)%360-180;
  const gaussian=x=>Math.exp(-x*x);
  function kOf(w,h){let k=w*w/g;for(let n=0;n<40;n++){const t=Math.tanh(k*h),s=(g*k*t-w*w)/(g*(t+k*h*(1-t*t)));k=Math.max(k-s,1e-10);if(Math.abs(s)<1e-12)break;}return k;}
  function point(mode,p,T){
    const w=tau/T,w2=w*w;let A33,A35=0,A55=0,B33,B35=0,B55=0,C33,C35=0,C55=0,F3,F5=[0,0],H3,H5=[0,0];
    const k=kOf(w,mode==='heave'?60:80);let Z33,Z35=[0,0],Z55=[0,0];
    if(mode==='heave'){
      const area=Math.PI*p.r**2,md=rho*area*4,x=6/T;C33=rho*g*area;
      A33=p.as*md*(.62+.18/(1+x*x)+.12*gaussian((x-1)/.45));
      B33=p.bs*.66*Math.sqrt(C33*md)*x*x*Math.exp(1-x*x);
      F3=[p.fs*C33*(1+.18*x*x)/Math.sqrt(1+(x/1.55)**6),0];
      Z33=[C33+p.stiff*1000-w2*(p.mass*1000+A33),w*(B33+(p.pto+p.visc)*1000)];
      H3=cdiv(F3,Z33);
    }else{
      const draft=420000/(rho*80), md=rho*p.area*draft,J=md*(18**2+draft**2)/12,x=7.2/T,y=8.8/T,mean=(x+y)/2,c=p.couple/100;
      C33=rho*g*p.area;C55=p.c55*1e6;C35=.10*c*Math.sqrt(C33*C55);
      A33=p.as*md*(.52+.20/(1+x*x)+.16*gaussian((x-1)/.50));
      A55=p.as*J*(.60+.16/(1+y*y)+.12*gaussian((y-1)/.55));
      A35=.18*c*gaussian((mean-1)/1.4)*Math.sqrt(A33*A55);
      B33=p.bs*.55*Math.sqrt(C33*md)*x*x*Math.exp(1-x*x);
      B55=p.bs*.35*Math.sqrt(C55*J)*y*y*Math.exp(1-y*y);
      B35=-.22*c*gaussian((mean-1)/1.2)*Math.sqrt(B33*B55);
      const shape=(1+.12*x*x)/Math.sqrt(1+(x/1.65)**6),slope=-k*Math.exp(-.1*y*y)/Math.sqrt(1+(y/1.8)**4);
      F3=[p.fs*C33*shape,p.fs*.25*C35*slope];F5=p.direct?[p.fs*C35*shape,p.fs*C55*slope]:[0,0];
      Z33=[C33+p.stiff*1000-w2*(p.mass*1000+A33),w*(B33+(p.pto+p.visc)*1000)];
      Z55=[C55+p.pstiff*1e6-w2*(p.I*1e6+A55),w*(B55+(p.ppto+p.pvisc)*1e6)];
      Z35=[C35-w2*A35,w*B35];
      const det=csub(cmul(Z33,Z55),cmul(Z35,Z35));H3=cdiv(csub(cmul(F3,Z55),cmul(F5,Z35)),det);H5=cdiv(csub(cmul(F5,Z33),cmul(F3,Z35)),det);
    }
    const power3=.5*p.pto*1000*(w*p.a*abs(H3))**2,power5=mode==='heave'?0:.5*p.ppto*1e6*(w*p.a*abs(H5))**2;
    return {T,w,k,A33,A35,A55,B33,B35,B55,C33,C35,C55,F3,F5,Z33,Z35,Z55,H3,H5,power3,power5,power:power3+power5};
  }
  function sweep(mode,p){const [min,max,n]=mode==='heave'?[2.5,15,520]:[3,16,560];return Array.from({length:n},(_,i)=>point(mode,p,min+(max-min)*i/(n-1)));}
  // Uniform-grid PCHIP. MATLAB interpolates the real and imaginary parts separately.
  function at(grid,T,field){
    const min=grid[0].T,N=grid.length,h=(grid[N-1].T-min)/(N-1),u=Math.min(N-1,Math.max(0,(T-min)/h));
    const i=Math.min(Math.floor(u),N-2),t=u-i;
    const v=j=>field(grid[j]),d=j=>v(j+1)-v(j);
    function end(a,b){let m=(3*a-b)/2;if(Math.sign(m)!==Math.sign(a))return 0;if(Math.sign(a)!==Math.sign(b)&&Math.abs(m)>Math.abs(3*a))return 3*a;return m;}
    function slope(j){if(j===0)return end(d(0),d(1));if(j===N-1)return end(d(N-2),d(N-3));let l=d(j-1),r=d(j);return l*r>0?2*l*r/(l+r):0;}
    return (2*t**3-3*t*t+1)*v(i)+(t**3-2*t*t+t)*slope(i)+(-2*t**3+3*t*t)*v(i+1)+(t**3-t*t)*slope(i+1);
  }
  function selected(mode,p,grid){const T=p.T,o={T,w:tau/T,k:kOf(tau/T,mode==='heave'?60:80)};
    for(const key of ['A33','A35','A55','B33','B35','B55','C33','C35','C55','power3','power5','power'])o[key]=at(grid,T,d=>d[key]);
    for(const key of ['H3','H5','F3','F5'])o[key]=[0,1].map(j=>at(grid,T,d=>d[key][j]));
    o.Z33=[o.C33+p.stiff*1e3-o.w**2*(p.mass*1e3+o.A33),o.w*(o.B33+(p.pto+p.visc)*1e3)];
    o.Z35=[o.C35-o.w**2*o.A35,o.w*o.B35];o.Z55=mode==='heave'?[0,0]:[o.C55+p.pstiff*1e6-o.w**2*(p.I*1e6+o.A55),o.w*(o.B55+(p.ppto+p.pvisc)*1e6)];
    return o;
  }
  function selftest(){
    const checks=[], c=(label,state)=>checks.push([label,!!state]),near=(a,b,t=1e-7)=>Math.abs(a-b)<=t*Math.max(1,Math.abs(b));
    for(const mode of ['heave','coupled']){
      const p=defaults(mode),grid=sweep(mode,p),larger=sweep(mode,{...p,a:2*p.a});
      const peak=key=>grid.reduce((a,b)=>abs(a[key])>=abs(b[key])?a:b);
      c(mode+' finite sweep',grid.every(d=>[...d.H3,...d.H5,d.power].every(Number.isFinite)));
      c(mode+' input coefficient checks',grid.every(d=>d.A33>0&&d.B33>=0&&d.C33>0&&(mode==='heave'||(d.A33*d.A55>=d.A35**2&&d.B33*d.B55>=d.B35**2&&d.C33*d.C55>d.C35**2))));
      c(mode+' amplitude scaling',grid.every((d,i)=>near(abs(d.H3),abs(larger[i].H3))&&near(abs(d.H5),abs(larger[i].H5))&&near(larger[i].power,4*d.power)));
      c(mode+' reference heave peak',near(peak('H3').T,mode==='heave'?6.666666667:6.697674419)&&near(abs(peak('H3').H3),mode==='heave'?1.528973146:1.9495805));
      if(mode==='coupled'){
        c('pitch reference peak',near(peak('H5').T,6.348837209)&&near(abs(peak('H5').H5),.1705276));
        c('indirect pitch through coupling',sweep(mode,{...p,direct:false}).some(d=>abs(d.H5)>1e-5));
        c('zero pitch without coupling or moment',sweep(mode,{...p,couple:0,direct:false}).every(d=>abs(d.H5)<1e-12));
      }
    }
    return checks;
  }
  const model={defaults,point,sweep,selected,abs,phase,deg,kOf,selftest};
  if(typeof module==='object'&&module.exports)module.exports=model;else root.HMEC_RAO=model;
})(typeof window!=='undefined'?window:globalThis);
