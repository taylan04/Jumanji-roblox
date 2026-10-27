"""Editable creature study for Blender 5.2. Run with --background --python this_file -- --render.
Only creates a named scene. Existing output is preserved as .previous.blend.
"""
import bpy, math, random, sys, json, shutil
from pathlib import Path
from mathutils import Vector, noise as organic_noise
from math import sin,cos,pi
ROOT=Path(__file__).resolve().parents[1]
random.seed(47)
scene=bpy.data.scenes.new('CarnivorousPlant_Presentation')
bpy.context.window.scene=scene
G={}
for name in ['MainBody','UpperJaw','LowerJaw','Teeth','Tongue','RearBulb','Roots','Limbs','Tentacles','Leaves','Spines','Studio']:
 c=bpy.data.collections.new('CP_'+name);scene.collection.children.link(c);G[name]=c

def material(name,dark,light,rough=.5,scale=8,bump=.15,wet=0,stretch=(1,1,1)):
 m=bpy.data.materials.new('CP_'+name);m.use_nodes=True;n=m.node_tree.nodes;n.clear();l=m.node_tree.links;p=n.get('Principled BSDF') or n.new('ShaderNodeBsdfPrincipled');out=n.get('Material Output') or n.new('ShaderNodeOutputMaterial');l.new(p.outputs['BSDF'],out.inputs['Surface'])
 p.inputs['Roughness'].default_value=rough;p.inputs['Coat Weight'].default_value=wet;p.inputs['Coat Roughness'].default_value=.21
 tc=n.new('ShaderNodeTexCoord');mp=n.new('ShaderNodeVectorMath');mp.operation='MULTIPLY';mp.inputs[1].default_value=stretch;l.new(tc.outputs['Generated'],mp.inputs[0])
 noise=n.new('ShaderNodeTexNoise');noise.inputs['Scale'].default_value=scale;noise.inputs['Detail'].default_value=5;noise.inputs['Roughness'].default_value=.73;l.new(mp.outputs[0],noise.inputs['Vector'])
 ramp=n.new('ShaderNodeValToRGB');ramp.color_ramp.elements[0].position=.22;ramp.color_ramp.elements[0].color=(*dark,1);ramp.color_ramp.elements[1].position=.8;ramp.color_ramp.elements[1].color=(*light,1)
 l.new(noise.outputs['Fac'],ramp.inputs[0]);l.new(ramp.outputs[0],p.inputs['Base Color'])
 fine=n.new('ShaderNodeTexNoise');fine.inputs['Scale'].default_value=scale*8;fine.inputs['Detail'].default_value=3;l.new(mp.outputs[0],fine.inputs['Vector'])
 b=n.new('ShaderNodeBump');b.inputs['Strength'].default_value=bump;b.inputs['Distance'].default_value=.07;l.new(fine.outputs['Fac'],b.inputs['Height']);l.new(b.outputs[0],p.inputs['Normal']);m.diffuse_color=(*light,1)
 return m
bark=material('Bark_fibrous',(.025,.019,.008),(.12,.095,.029),.72,9,.5,stretch=(3,3,.35))
rootmat=material('Roots_moss',(.018,.027,.009),(.085,.12,.022),.63,7,.45,stretch=(2,2,.3))
leafmat=material('Olive_leaf',(.018,.035,.007),(.12,.17,.025),.46,5,.24,.15)
leafgold=material('Leaf_weathered_edges',(.07,.062,.016),(.20,.19,.05),.56,6,.25)
redleaf=material('Inner_red_bracts',(.065,.008,.007),(.29,.065,.038),.48,5,.2)
veinmat=material('Raised_leaf_veins',(.10,.13,.027),(.20,.23,.063),.6,6,.18)
spinemat=material('Crimson_thorns',(.10,.016,.009),(.55,.12,.065),.4,3,.15)
gum=material('Gums',(.13,.022,.019),(.32,.080,.055),.33,5,.15,.35)
flesh=material('Oral_tissue',(.018,.002,.004),(.14,.018,.018),.3,5,.2,.4)
tonguemat=material('Tongue',(.12,.012,.02),(.46,.10,.095),.28,5,.2,.45)
toothmat=material('Ivory_dentine',(.30,.16,.047),(.88,.72,.36),.31,3,.1,.2,stretch=(4,4,.4))

def mesh(name,v,f,mat,g):
 assert v and all(0 <= idx < len(v) for face in f for idx in face), name
 me=bpy.data.meshes.new(name);me.from_pydata(v,[],f);me.update();ob=bpy.data.objects.new(name,me);G[g].objects.link(ob);me.materials.append(mat)
 for p in me.polygons:p.use_smooth=True
 return ob

def catmull(points,radii,steps):
 pts=[Vector(p) for p in points];out=[];rs=[]
 for k in range(len(pts)-1):
  a=pts[max(0,k-1)];b=pts[k];c=pts[k+1];d=pts[min(len(pts)-1,k+2)]
  for j in range(steps):
   t=j/steps;out.append(.5*(2*b+(-a+c)*t+(2*a-5*b+4*c-d)*t*t+(-a+3*b-3*c+d)*t*t*t));rs.append(radii[k]*(1-t)+radii[k+1]*t)
 out.append(pts[-1]);rs.append(radii[-1]);return out,rs

def tube(name,points,radii,mat,g,steps=7,sides=12,lobes=0,flat=1):
 pts,rs=catmull(points,radii,steps);v=[];f=[];last=None
 for i,(p,r) in enumerate(zip(pts,rs)):
  t=(pts[min(i+1,len(pts)-1)]-pts[max(i-1,0)]).normalized();up=Vector((0,0,1)) if abs(t.z)<.95 else Vector((0,1,0))
  u=t.cross(up).normalized() if last is None else (last-t*last.dot(t)).normalized();w=t.cross(u).normalized();last=u
  for j in range(sides):
   a=j*2*pi/sides;rj=r*(1+lobes*(.65*sin(5*a+i*.09)+.35*sin(9*a-i*.1)))
   if lobes:rj*=1+.10*organic_noise.noise_vector(p*7+Vector((cos(a),sin(a),0)))[0]
   v.append(p+rj*(u*cos(a)+w*sin(a)*flat))
  if i:
   for j in range(sides):
    a=(i-1)*sides+j;b=(i-1)*sides+(j+1)%sides;f.append((a,b,b+sides,a+sides))
 f.extend([tuple(reversed(range(sides))),tuple((len(pts)-1)*sides+j for j in range(sides))]);return mesh(name,v,f,mat,g)

def thorn(name,p,d,length=.25,radius=.07,g='Spines',mat=spinemat):
 p=Vector(p);d=Vector(d).normalized();bend=Vector((0,-.10,.02))*length
 return tube(name,[p,p+d*length*.45,p+d*length*.83+bend,p+d*length+bend*2],[radius,radius*.72,radius*.26,.001],mat,g,5,12)

def ellipsoid(name,center,size,mat,g,ribs=0,nu=64,nv=32):
 v=[];f=[]
 for i in range(nv+1):
  t=pi*i/nv
  for j in range(nu):
   a=2*pi*j/nu;fac=1+ribs*cos(10*a)*sin(t)**2+.012*sin(23*a+7*t)
   v.append((center[0]+size[0]*sin(t)*cos(a)*fac,center[1]+size[1]*sin(t)*sin(a)*fac,center[2]+size[2]*cos(t)*fac))
   if i:
    q=(i-1)*nu+j;b=(i-1)*nu+(j+1)%nu;f.append((q,b,b+nu,q+nu))
 return mesh(name,v,f,mat,g)

def leaf(name,points,width,mat=leafmat,g='Leaves',normal=(0,-1,.4)):
 pts,_=catmull(points,[1]*len(points),16);normal=Vector(normal).normalized();frames=[];v=[];f=[];n=len(pts)
 for i,p in enumerate(pts):
  t=i/(n-1);tangent=(pts[min(n-1,i+1)]-pts[max(0,i-1)]).normalized();side=tangent.cross(normal).normalized();norm=side.cross(tangent).normalized()
  w=width*sin(pi*t)**.72*(.78+.22*(1-abs((t*12)%1*2-1)))+.004;frames.append((side,norm,w,tangent))
  for j in range(7):
   q=(j-3)/3;v.append(p+side*w*q+norm*(-abs(q)**1.3*w*.24+.025*sin(t*19+q*3)*abs(q)))
  if i:
   for j in range(6):
    a=(i-1)*7+j;f.append((a,a+1,a+8,a+7))
 ob=mesh(name,v,f,mat,g);sol=ob.modifiers.new('Leaf lamina thickness','SOLIDIFY');sol.thickness=.022
 mid=pts[::4]+[pts[-1]];tube(name+'_midrib',mid,[.025*(1-i/(len(mid)-1))+.003 for i in range(len(mid))],veinmat,g,2,7)
 for i in range(5,n-3,6):
  side,norm,w,tangent=frames[i]
  for s in [-1,1]:
   tip=pts[min(n-1,i+2)]+side*w*.94*s-norm*w*.20
   tube(name+'_vein',[pts[i-2],pts[i]+side*w*.48*s,tip],[.012,.009,.002],veinmat,g,3,6)
   if i%12==5:thorn(name+'_edge_barb',tip,side*s+tangent*.5,.10+width*.15,.024,g)
 return ob

def build_body():
 ellipsoid('Interwoven_core',(0,.80,1.1),(1.22,1.10,.93),bark,'MainBody',.06)
 ellipsoid('Posterior_seed_capsule',(0,1.37,1.37),(1.13,1.03,1.19),leafmat,'RearBulb',.07)
 for j in range(12):
  a=2*pi*j/12;pts=[]
  for i in range(6):
   t=.13+(pi-.30)*i/5;pts.append((1.17*sin(t)*cos(a),1.37+1.08*sin(t)*sin(a),1.37-1.20*cos(t)))
  leaf('Capsule_sepal_%02d'%j,pts,.31,leafmat,'RearBulb',(cos(a),sin(a),.15))
  for i in [2,3,4]:thorn('Capsule_crimson_spine',pts[i],(cos(a)*.7,sin(a)*.7,.8),.2+i*.025,.065)
 for s in [-1,1]:
  for j in range(9):
   y=-.7+j*.29;tube('Torso_braided_root',[(s*.65,y,1.9),(s*1.23,y+.14,1.43),(s*1.37,y+.15,.7),(s*1.1,y+.4,.24)],[.11,.16,.12,.03],rootmat,'MainBody',9,12,.15)

def rim(a):return Vector((1.04*cos(a)*(1+.035*sin(7*a)),-.78-1.1*abs(sin(a))+.24*sin(a),1.68+1.25*sin(a)))

def build_head():
 v=[];f=[];nu=128;nv=32
 for k in range(nv+1):
  t=k/nv;shrink=(1-t)**.8
  for j in range(nu):
   a=2*pi*j/nu;e=rim(a);r=shrink*(1+.025*sin(t*16*pi)*sin(pi*t));v.append((e.x*r,e.y*(1-t)-.42*t,1.65+(e.z-1.65)*r))
   if k:
    q=(k-1)*nu+j;q2=(k-1)*nu+(j+1)%nu;f.append((q,q2,q2+nu,q+nu))
 mesh('Deep_recessed_oral_cavity',v,f,flesh,'UpperJaw')
 for upper in [True,False]:
  name='UpperJaw' if upper else 'LowerJaw';start=0 if upper else pi;v=[];f=[];na=64;nd=18
  for k in range(nd+1):
   t=k/nd
   for j in range(na+1):
    a=start+pi*j/na;e=rim(a);v.append((e.x*(1-.43*t)*(1+.06*sin(pi*t)),e.y*(1-t)+.12*t,1.65+(e.z-1.65)*(1-.48*t)+(.15 if upper else -.15)*sin(pi*t)))
    if k and j:
     q=(k-1)*(na+1)+j-1;f.append((q,q+1,q+na+2,q+na+1))
  ob=mesh(name+'_bark_carapace',v,f,rootmat,name);mod=ob.modifiers.new('Thick jaw shell','SOLIDIFY');mod.thickness=.14
  pts=[rim(start+pi*j/32) for j in range(33)];tube(name+'_fleshy_lip',pts,[.10+.018*sin(j*1.7) for j in range(33)],gum,name,3,14,.06)
  pts2=[p+Vector((p.x*.06,.04,(p.z-1.68)*.045)) for p in pts];tube(name+'_armored_border',pts2,[.095]*33,leafgold,name,3,12,.12)
  for row in range(2):
   count=25 if row==0 else 21
   for i in range(count):
    a=start+.06+(pi-.12)*(i+.5)/count;p=rim(a)+Vector((0,row*.15,0));p.x*=1-row*.05;p.z=1.68+(p.z-1.68)*(1-row*.06)
    d=Vector((-p.x*.22,-.17,-1 if upper else 1)).normalized();length=(.29+.24*abs(sin(a)))*random.uniform(.78,1.17)*(1-row*.26)
    tube(name+'_tooth_%d_%02d'%(row,i),[p,p+d*length*.32+Vector((0,-.045,0)),p+d*length*.72,p+d*length+Vector((0,.09,0))],[.073*(1-row*.2),.059*(1-row*.2),.028,.0015],toothmat,'Teeth',6,14)
    if row==0:ellipsoid('Gingival_socket',p,(.089,.087,.105),gum,name,nu=24,nv=12)
 for k in range(7):
  t=.17+k*.095;pts=[]
  for j in range(49):
   a=2*pi*j/48;e=rim(a);pts.append((e.x*(1-t),e.y*(1-t)-.42*t,1.65+(e.z-1.65)*(1-t)))
  tube('Palatal_concentric_fold',pts,[.028*(1-t)]*len(pts),gum,'UpperJaw',2,7)
 tube('Tongue_muscular_body',[(0,-.67,1.23),(0,-1.05,1.24),(.04,-1.49,1.24),(.14,-1.96,1.16),(.35,-2.2,1.25),(.49,-2.18,1.11)],[.31,.30,.25,.17,.10,.018],tonguemat,'Tongue',12,24,.04,.48)
 for s in [-1,1]:tube('Tongue_longitudinal_crease',[(s*.06,-.72,1.38),(s*.06,-1.2,1.40),(.10+s*.04,-1.7,1.37),(.32,-2.1,1.30)],[.015,.012,.009,.002],gum,'Tongue',8,7)
 for j in range(11):
  x=(j-5)*.22;leaf('Crown_armored_leaf',[(x,-1.42,2.75+.1*(1-abs(x))),(x*1.08,-.92,3.05),(x*1.2,-.27,3.13+random.uniform(-.15,.15))],.24,normal=(0,-.3,1));thorn('Crown_red_spike',(x,-.87,3.03),(x*.4,-.15,1),random.uniform(.18,.36),.065)
 for s in [-1,1]:
  for j in range(9):
   z=.64+j*.245;x=s*(.83+.18*sin(j*pi/8));end=(s*(1.17+.45*sin(j*pi/8)+random.uniform(-.12,.12)),-.43,z+random.uniform(.23,.52))
   leaf('Jaw_flared_bract',[(x,-1.15,z),(s*1.4,-.96,z+.21),end],.26,redleaf if j%3==0 else leafmat,normal=(s*.3,-1,.2))

def build_roots():
 for s in [-1,1]:
  for j in range(3):
   y=-.8+j*1.04;shoulder=(s*.95,y,1.36 if j<2 else .96);elbow=(s*(1.65+j*.08),y-.12,.73);wrist=(s*(1.72+j*.12),y-.58,.23)
   tube('Load_bearing_limb_%s_%d'%(s,j),[shoulder,(s*1.39,y+.13,1.10),elbow,wrist],[.31,.28,.25,.20],bark,'Limbs',12,20,.16)
   for k in range(5):
    off=(k-2)*.16;tip=(wrist[0]+off*1.9+s*.12,wrist[1]-.62+.09*abs(k-2),.075)
    tube('Root_finger',[(wrist[0]+off,wrist[1],.26),(wrist[0]+off*1.7,wrist[1]-.23,.13),tip],[.095,.075,.024],rootmat,'Roots',8,12,.13);thorn('Root_ivory_claw',tip,(s*.2,-1,-.05),.18,.04,'Roots',toothmat)
   for k in range(5):
    delta=(k-2)*.06;tube('Limb_bark_tendon',[(shoulder[0]+delta,y-.21,1.4),(elbow[0]+delta,y-.30,.78),(wrist[0]+delta,y-.67,.24)],[.037,.045,.018],rootmat,'Limbs',10,8,.15)
  for j in range(16):
   y=random.uniform(-.3,2.2);x=random.uniform(.65,1.15);p0=(s*x,y,.65);p1=(s*(x+.6),y+random.uniform(-.3,.3),.25);p2=(s*(x+1.1),y+random.uniform(-.55,.55),.08);p3=(s*(x+1.5),p2[1]-.2,.055)
   tube('Trailing_root',[p0,p1,p2,p3],[.11,.083,.034,.003],bark,'Roots',8,10,.17);tube('Root_branch',[p1,(p2[0]*.97,p2[1]+.30,.09),(p3[0]*.95,p3[1]+.5,.04)],[.05,.025,.002],rootmat,'Roots',7,8,.1)

def build_tentacles():
 for s in [-1,1]:
  for j in range(3):
   y=.15+j*.79;h=[2.75,1.85,2.90][j]+(.16 if s<0 else -.08);reach=[2.57,3.12,2.60][j]+(.13 if s<0 and j==1 else 0)
   pts=[(s*.99,y,.9),(s*1.8,y+.25,1.3),(s*(1.83+.19*j),y+.1,h-.12),(s*(reach-.2),y-.15,h+.18),(s*reach,y-.35,h-.04)]
   tube('Hook_vine_%s_%d'%(s,j),pts,[.19,.14,.11,.075,.035],bark,'Tentacles',14,16,.16)
   for k in range(3):
    off=(k-1)*.045;tube('Vine_helical_fiber',[(p[0]+off*sin(i*2),p[1]-.10+off*cos(i*2),p[2]+off) for i,p in enumerate(pts)],[.025,.022,.016,.01,.003],rootmat,'Tentacles',10,7,.1)
   leaf('Serrated_hook_blade',[(s*(reach-.65),y-.15,h+.12),(s*reach,y-.32,h+.06),(s*(reach+.45),y-.42,h-.35),(s*(reach+.49),y-.5,h-.85)],.29,leafmat,'Tentacles',(0,-1,.4))
   thorn('Hook_terminal_talon',(s*(reach+.43),y-.47,h-.66),(s*-.04,-.06,-1),.38,.065,'Tentacles')
   dense,_=catmull(pts,[1]*len(pts),3)
   for k in range(2,len(dense)-1,2):thorn('Vine_barb',dense[k],(s*.8,-.3,.9),.14,.04,'Tentacles')
 for s in [-1,1]:
  for j in range(13):
   y=-.1+j*.17;z=1.5+.4*sin(j*pi/13)
   leaf('Layered_shoulder_foliage',[(s*.72,y,z),(s*1.15,y+.12,z+.4),(s*(1.49+random.uniform(0,.2)),y+.42,z+.44)],.29,leafmat if j%4 else leafgold,normal=(s*.5,-.3,1))

def point_at(ob,target):ob.rotation_euler=(Vector(target)-ob.location).to_track_quat('-Z','Y').to_euler()

def presentation():
 floor=material('Studio_charcoal',(.018,.021,.022),(.028,.031,.032),.86,4,.08);mesh('Ground',[(-200,-200,-.04),(200,-200,-.04),(200,200,-.04),(-200,200,-.04)],[(0,1,2,3)],floor,'Studio')
 world=bpy.data.worlds.new('CP_DarkStudio');world.use_nodes=True;wn=world.node_tree.nodes;wn.clear();bg=wn.get('Background') or wn.new('ShaderNodeBackground');wo=wn.get('World Output') or wn.new('ShaderNodeOutputWorld');world.node_tree.links.new(bg.outputs[0],wo.inputs['Surface']);bg.inputs[0].default_value=(.055,.065,.08,1);bg.inputs[1].default_value=.35;scene.world=world
 for name,pos,power,color,size in [('Softbox',(-4,-6,7),1500,(1,.86,.66),5),('Fill',(5,-3,4),1000,(.76,.85,1),4),('Rim',(1,5,6),1800,(1,.72,.43),3),('Top',(-3,2,6),1000,(.8,1,.77),3)]:
  data=bpy.data.lights.new(name,'AREA');data.energy=power;data.color=color;data.shape='DISK';data.size=size;ob=bpy.data.objects.new(name,data);G['Studio'].objects.link(ob);ob.location=pos;point_at(ob,(0,0,1))
 target=bpy.data.objects.new('Turntable_Target',None);G['Studio'].objects.link(target);target.location=(0,.15,1.5)
 data=bpy.data.cameras.new('Eight_view_camera');cam=bpy.data.objects.new('Eight_view_camera',data);G['Studio'].objects.link(cam);data.type='ORTHO';data.ortho_scale=8.4;scene.camera=cam
 for frame in range(1,242):
  a=2*pi*(frame-1)/240;cam.location=(10*sin(a),.15-10*cos(a),3.15);point_at(cam,target.location);cam.keyframe_insert('location',frame=frame);cam.keyframe_insert('rotation_euler',frame=frame)
 scene.frame_start=1;scene.frame_end=240;scene.render.engine='CYCLES';scene.cycles.samples=40;scene.cycles.use_denoising=True
 scene.render.resolution_x=1200;scene.render.resolution_y=800;scene.render.resolution_percentage=100;scene.render.image_settings.file_format='PNG';scene.view_settings.view_transform='AgX';scene.frame_set(31)
 for screen in bpy.data.screens:
  for area in screen.areas:
   if area.type=='VIEW_3D':area.spaces.active.region_3d.view_perspective='CAMERA'

def save_and_render():
 file=ROOT/'carnivorous_plant.blend'
 if file.exists():shutil.copy2(file,ROOT/'carnivorous_plant.previous.blend')
 scene['reference_note']='Procedural 3D interpretation of supplied eight-view creature. No rig or game export.'
 bpy.ops.wm.save_as_mainfile(filepath=str(file))
 meshes=[o for o in scene.objects if o.type=='MESH'];stats={'blender':bpy.app.version_string,'mesh_objects':len(meshes),'vertices_base':sum(len(o.data.vertices) for o in meshes),'polygons_base':sum(len(o.data.polygons) for o in meshes),'materials':len({m.name for o in meshes for m in o.data.materials}),'turntable_frames':240,'fps':scene.render.fps}
 (ROOT/'geometry.json').write_text(json.dumps(stats,indent=2),encoding='utf8')
 if '--render' in sys.argv:
  for i,name in enumerate(['01_front','02_front_left','03_left','04_rear_left','05_back','06_rear_right','07_right','08_front_right']):
   scene.frame_set(1+i*30);scene.render.filepath=str(ROOT/'renders'/name);bpy.ops.render.render(write_still=True)
  scene.frame_set(31);bpy.ops.wm.save_as_mainfile(filepath=str(file))

def finalize_anatomy():
 # Flared burgundy bracts behind the cheeks, as visible in the reference.
 for side in [-1,1]:
  for j in range(4):
   z=1.30+j*.39
   leaf('Large_crimson_neck_bract',[(side*.8,-.61,z),(side*1.32,-.51,z+.34),(side*(1.60+.12*j),-.30,z+.64)],.32,redleaf,normal=(side*.2,-1,.25))
 # Organic longitudinal ridges on the thick cranial shell.
 for j in range(13):
  a=.09+(pi-.18)*j/12;e=rim(a)
  pts=[]
  for k in range(6):
   t=k/5
   pts.append((e.x*(1-.43*t)*(1+.06*sin(pi*t)),e.y*(1-t)+.12*t,1.65+(e.z-1.65)*(1-.48*t)+.15*sin(pi*t)+.035))
  tube('Cranial_bark_ridge',pts,[.035,.055,.07,.07,.055,.02],bark,'UpperJaw',7,9,.15)
  if j%2:
   leaf('Cranial_overlapping_scale',[pts[2],pts[3],(pts[4][0],pts[4][1]+.2,pts[4][2]+.15)],.21,leafmat,normal=(e.x*.3,-.2,1))
 # Hinge groups keep the parts addressable for a future rig.
 for group in ['UpperJaw','LowerJaw','Tongue']:
  pivot=bpy.data.objects.new(group+'_ANIMATION_PIVOT',None);G[group].objects.link(pivot);pivot.location=(0,-.35,1.65);bpy.context.view_layer.update()
  objs=list(G[group].objects)
  if group!='Tongue':objs += [o for o in G['Teeth'].objects if o.name.startswith(group)]
  for ob in objs:
   if ob==pivot:continue
   world=ob.matrix_world.copy();ob.parent=pivot;ob.matrix_world=world
 scene['animation_note']='Jaw pivots provided for future rigging; no skinning or closure validation.'

build_body();build_head();build_roots();build_tentacles();finalize_anatomy();presentation();save_and_render()





