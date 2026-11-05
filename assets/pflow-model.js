/* Potential Flow Module: analytical 2D elementary flows in model units.
   Cartesian axes: x right, y up; positive circulation is counterclockwise. */
(function(root){
 'use strict';
 const tau=2*Math.PI,core=.13,bounds={xmin:-10,xmax:10,ymin:-7,ymax:7};
 function element(type,x=0,y=0,strength){return {type,x,y,strength:strength??(type==='doublet'?6.25:5*Math.PI),angle:0};}
 function preset(name){let U=1,angle=0,e=[];
  if(name==='cylinder')e=[element('doublet')];
  if(name==='circulation')e=[element('doublet'),element('ccw')];
  if(name==='pair')e=[element('source',-3,0),element('sink',3,0)];
  if(name==='vortex'){U=0;e=[element('ccw')];}
  if(name==='doublet'){U=0;e=[element('doublet')];}
  if(name==='blank')U=0;
  return {U,angle,e};
 }
 function velocity(x,y,s){const a=s.angle*Math.PI/180;let u=s.U*Math.cos(a),v=s.U*Math.sin(a);
  for(const q of s.e){const dx=x-q.x,dy=y-q.y,r2=dx*dx+dy*dy;if(r2<1e-20)return null;
   if(q.type==='source'||q.type==='sink'){const c=(q.type==='sink'?-1:1)*q.strength/tau/r2;u+=c*dx;v+=c*dy;}
   else if(q.type==='ccw'||q.type==='cw'){const c=(q.type==='cw'?-1:1)*q.strength/tau/r2;u-=c*dy;v+=c*dx;}
   else {const a=q.angle*Math.PI/180,ex=Math.cos(a),ey=Math.sin(a),d=ex*dx+ey*dy,c=q.strength/r2;u+=c*(ex-2*d*dx/r2);v+=c*(ey-2*d*dy/r2);}
  }return [u,v];
 }
 function psi(x,y,s){let a=s.angle*Math.PI/180,z=s.U*(y*Math.cos(a)-x*Math.sin(a));
  for(const q of s.e){let dx=x-q.x,dy=y-q.y,r2=dx*dx+dy*dy;if(r2<1e-20)return null;
   if(q.type==='source'||q.type==='sink')z+=(q.type==='sink'?-1:1)*q.strength/tau*Math.atan2(dy,dx);
   else if(q.type==='ccw'||q.type==='cw')z-=(q.type==='cw'?-1:1)*q.strength/tau*.5*Math.log(r2);
   else {a=q.angle*Math.PI/180;z-=q.strength*(Math.cos(a)*dy-Math.sin(a)*dx)/r2;}
  }return z;
 }
 function cylinder(s){const ds=s.e.filter(q=>q.type==='doublet');if(ds.length!==1||s.U<=1e-10)return null;const d=ds[0];
  if(Math.abs(Math.sin((s.angle-d.angle)*Math.PI/180))>1e-9||Math.cos((s.angle-d.angle)*Math.PI/180)<0)return null;
  if(s.e.some(q=>q!==d&&(!['ccw','cw'].includes(q.type)||Math.hypot(q.x-d.x,q.y-d.y)>1e-9)))return null;
  return {x:d.x,y:d.y,R:Math.sqrt(d.strength/s.U)};
 }
 function valid(x,y,s,c=cylinder(s)){
  return x>=-10&&x<=10&&y>=-7&&y<=7&&!s.e.some(q=>Math.hypot(x-q.x,y-q.y)<core)&&!(c&&Math.hypot(x-c.x,y-c.y)<c.R*(1-1e-8));
 }
 function rk4(p,h,s,arc=false,c=cylinder(s)){
  const f=(x,y)=>{if(!valid(x,y,s,c))return null;let v=velocity(x,y,s);if(!v)return null;const m=Math.hypot(...v);return arc?(m>1e-8?v.map(z=>z/m):null):v;};
  const a=f(...p);if(!a)return null;const b=f(p[0]+h*a[0]/2,p[1]+h*a[1]/2);if(!b)return null;const d=f(p[0]+h*b[0]/2,p[1]+h*b[1]/2);if(!d)return null;const e=f(p[0]+h*d[0],p[1]+h*d[1]);if(!e)return null;
  const out=p.map((x,i)=>x+h*(a[i]+2*b[i]+2*d[i]+e[i])/6);return valid(...out,s,c)?out:null;
 }
 function trace(seed,s,sign=1,step=.055,c=cylinder(s)){let p=seed,points=[p];for(let j=0;j<1000;j++){const next=rk4(p,sign*step,s,true,c);if(!next)break;points.push(next);p=next;if(j>35&&Math.hypot(p[0]-seed[0],p[1]-seed[1])<step*1.1)break;}return points;}
 function advect(p,dt,s,c=cylinder(s)){let left=dt;for(let i=0;i<100&&left>1e-8;i++){if(!valid(...p,s,c))return null;const v=velocity(...p,s);if(!v)return null;const h=Math.min(left,.035,.045/Math.max(.01,Math.hypot(...v)));p=rk4(p,h,s,false,c);if(!p)return null;left-=h;}return left<1e-8?p:null;}
 function checks(){let out=[],ok=(n,b)=>out.push([n,!!b]),near=(a,b)=>Math.abs(a-b)<1e-8;
  let s={U:0,angle:0,e:[element('source',0,0,tau)]};ok('Source speed halves when radius doubles',near(velocity(2,0,s)[0],.5)&&near(velocity(4,0,s)[0],.25));
  s.e[0].type='sink';ok('A sink reverses the radial velocity',near(velocity(2,0,s)[0],-.5));
  s.e[0].type='ccw';ok('Positive circulation turns counterclockwise',near(velocity(2,0,s)[1],.5));
  s.e.push(element('cw',0,0,tau));ok('Equal opposite vortices cancel',Math.hypot(...velocity(2,1,s))<1e-9);
  s=preset('cylinder');let err=0;for(let j=0;j<180;j++){let a=j*tau/180,v=velocity(2.5*Math.cos(a),2.5*Math.sin(a),s);err=Math.max(err,Math.abs(v[0]*Math.cos(a)+v[1]*Math.sin(a)));}ok('The cylinder boundary has no normal velocity',err<1e-9);
  ok('Cylinder front and rear stagnation points',Math.hypot(...velocity(2.5,0,s))<1e-9&&Math.hypot(...velocity(-2.5,0,s))<1e-9);
  ok('Cylinder side speed equals twice the free stream',near(Math.hypot(...velocity(0,2.5,s)),2));
  s=preset('blank');s.U=1;let p=advect([0,0],1,s);ok('A tracer travels U times elapsed time in uniform flow',p&&near(p[0],1)&&near(p[1],0));return out;
 }
 const model={tau,core,bounds,element,preset,velocity,psi,cylinder,valid,rk4,trace,advect,checks};
 if(typeof module==='object'&&module.exports)module.exports=model;else root.PFlow=model;
})(typeof window!=='undefined'?window:globalThis);
