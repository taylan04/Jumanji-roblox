"""Alligator creature: anatomical lofts, modeled scale armor and separate jaws.
Blender 5.2.3. Run --build-only, --preview, or no flag for eight views.
"""
import bpy,math,random,json,sys,shutil
from math import sin,cos,pi
from mathutils import Vector,noise as organic_noise
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];random.seed(129)
scene=bpy.data.scenes.new('Alligator_Presentation');bpy.context.window.scene=scene
G={}
for key in ['Body','Head','UpperJaw','LowerJaw','Teeth','Mouth','Eyes','Limbs','Feet','Tail','DorsalArmor','Studio']:
 c=bpy.data.collections.new('AG_'+key);scene.collection.children.link(c);G[key]=c
exec(compile((ROOT/'scripts/geometry.py').read_text(),'geometry.py','exec'))
skin=material('Reptile_dark_dermis',(.010,.009,.005),(.036,.029,.013),.53,6,.36,.08)
armor=material('Charcoal_osteoderms',(.012,.011,.006),(.045,.037,.017),.48,7,.27,.13)
armor2=material('Weathered_olive_armor',(.020,.019,.008),(.066,.056,.024),.52,6,.32,.08)
edge=material('Worn_bronze_edges',(.040,.024,.009),(.20,.12,.042),.46,9,.27)
belly=material('Ochre_ventral_scales',(.12,.08,.033),(.34,.24,.10),.57,5,.25)
face=material('Snout_mottled_scales',(.014,.011,.006),(.095,.068,.030),.49,8,.33,.1)
gum=material('Gums',(.075,.012,.010),(.22,.060,.040),.35,6,.18,.32)
flesh=material('Dark_oral_tissue',(.009,.001,.002),(.082,.009,.011),.36,5,.19,.25)
tonguemat=material('Tongue',(.070,.009,.012),(.25,.047,.046),.34,6,.20,.32)
ivory=material('Aged_ivory',(.18,.105,.040),(.68,.51,.27),.35,6,.14,.13)
claw=material('Claw_horn',(.025,.022,.016),(.25,.20,.12),.36,5,.18)
eye=material('Amber_iris',(.24,.075,.003),(.95,.48,.025),.23,5,.15,.5)
black=material('Pupil_and_nostrils',(.001,.001,.001),(.004,.005,.003),.32,3,.03)
# Restrained reptilian sheen: broad white highlights must not wash out the armor.
for m in [skin,armor,armor2,edge,face,belly]:
 p=next(n for n in m.node_tree.nodes if n.bl_idname=='ShaderNodeBsdfPrincipled')
 p.inputs['Specular IOR Level'].default_value=.16
 p.inputs['Coat Weight'].default_value=.025
 p.inputs['Roughness'].default_value=.60
 for n in m.node_tree.nodes:
  if n.bl_idname=='ShaderNodeBump':n.inputs['Distance'].default_value=.016
# Fine polygonal dermis under the true geometric scales.
for mat in [skin,face]:
 n=mat.node_tree.nodes;l=mat.node_tree.links;p=next(x for x in n if x.bl_idname=='ShaderNodeBsdfPrincipled');tc=next(x for x in n if x.bl_idname=='ShaderNodeTexCoord')
 vor=n.new('ShaderNodeTexVoronoi');vor.feature='DISTANCE_TO_EDGE';vor.inputs['Scale'].default_value=40;l.new(tc.outputs['Generated'],vor.inputs['Vector'])
 b=n.new('ShaderNodeBump');b.inputs['Strength'].default_value=.32;b.inputs['Distance'].default_value=.035;l.new(vor.outputs['Distance'],b.inputs['Height']);l.new(p.inputs['Normal'].links[0].from_socket,b.inputs['Normal']);l.new(b.outputs[0],p.inputs['Normal'])

# A compact mesh batch keeps thousands of individually modeled plates editable
# per anatomical region without thousands of scene objects.
class Plates:
 def __init__(self):self.v=[];self.f=[];self.mi=[]
 def add(self,p,u,w,normal,halfwidth,halflength,height,kind=0,keel=0):
  p=Vector(p);u=Vector(u).normalized();w=Vector(w).normalized();normal=Vector(normal).normalized();base=len(self.v)
  outline=[(-.67,-1),(.67,-1),(1,-.60),(1,.60),(.67,1),(-.67,1),(-1,.60),(-1,-.60)]
  for scale,z in [(1,0),(.79,height*.58)]:
   for x,y in outline:self.v.append(p+u*x*halfwidth*scale+w*y*halflength*scale+normal*z)
  self.v.append(p+normal*(height+keel)+w*halflength*.12)
  for i in range(8):
   self.f.append((base+i,base+(i+1)%8,base+(i+1)%8+8,base+i+8));self.mi.append(3 if kind<3 else 4)
   self.f.append((base+i+8,base+(i+1)%8+8,base+16));self.mi.append(kind)
 def finish(self,name,group):
  ob=mesh(name,self.v,self.f,armor,group)
  for mat in [armor2,face,edge,belly]:ob.data.materials.append(mat)
  for poly,idx in zip(ob.data.polygons,self.mi):poly.material_index=idx;poly.use_smooth=False
  bevel=ob.modifiers.new('Soft scale edges','BEVEL');bevel.width=.006;bevel.segments=1;bevel.limit_method='ANGLE';bevel.angle_limit=.6
  return ob

def frames(points,widths,heights,steps=8):
 pts,rs=catmull(points,widths,steps);_,hs=catmull(points,heights,steps);out=[];last=None
 for i,p in enumerate(pts):
  t=(pts[min(i+1,len(pts)-1)]-pts[max(i-1,0)]).normalized();up=Vector((0,0,1))
  u=t.cross(up).normalized() if last is None else (last-t*last.dot(t)).normalized()
  w=u.cross(t).normalized();last=u;out.append((p,t,u,w,rs[i],hs[i]))
 return out

def sample_frame(fr,t):
 a=max(0,min(len(fr)-1,t));i=min(len(fr)-2,int(a));f=a-i
 return tuple(fr[i][k]*(1-f)+fr[i+1][k]*f for k in range(6))

def loft(name,points,widths,heights,group,scale_rows=28,around=28,mat=skin):
 fr=frames(points,widths,heights,10);v=[];f=[];n=48
 for i,(p,t,u,w,rx,rz) in enumerate(fr):
  for j in range(n):
   a=2*pi*j/n;v.append(p+u*cos(a)*rx+w*sin(a)*rz)
   if i:
    q=(i-1)*n+j;b=(i-1)*n+(j+1)%n;f.append((q,b,b+n,q+n))
 f.extend([tuple(reversed(range(n))),tuple((len(fr)-1)*n+i for i in range(n))]);ob=mesh(name,v,f,mat,group)
 plates=Plates()
 for row in range(1,scale_rows):
  i=row*(len(fr)-1)/scale_rows;p,t,u,w,rx,rz=sample_frame(fr,i)
  ip=(row-.5)*(len(fr)-1)/scale_rows;inext=(row+.5)*(len(fr)-1)/scale_rows;length=(sample_frame(fr,inext)[0]-sample_frame(fr,ip)[0]).length*.48
  for j in range(around):
   a=2*pi*(j+.5*(row%2))/around;normal=(u*cos(a)/max(rx,.01)+w*sin(a)/max(rz,.01)).normalized();cross=(-u*sin(a)*rx+w*cos(a)*rz).normalized()
   q=p+u*cos(a)*rx+w*sin(a)*rz
   width=pi*math.sqrt((rx*sin(a))**2+(rz*cos(a))**2)/around*.94
   kind=4 if sin(a)<-.18 else (1 if random.random()<.20 else 0)
   plates.add(q,cross,t,normal,width,length,.014+rx*.016,kind)
 plates.finish(name+'_scale_lattice',group)
 return fr

def ridge_spike(name,p,normal,length,width,group='DorsalArmor'):
 p=Vector(p);n=Vector(normal).normalized();t=Vector((0,1,0));u=t.cross(n).normalized()
 if u.length<.1:u=Vector((1,0,0))
 # Broad bony triangular keel with a swept rear tip, not a thin cone.
 v=[p-u*width-t*width,p+u*width-t*width,p+u*width+t*width,p-u*width+t*width,p+n*length+t*width*.8]
 ob=mesh(name,v,[(0,1,4),(1,2,4),(2,3,4),(3,0,4),(3,2,1,0)],armor2,group);ob.data.materials.append(edge)
 ob.data.polygons[0].material_index=1
 bevel=ob.modifiers.new('Worn bony edges','BEVEL');bevel.width=.012;bevel.segments=2

LIMBS={}
body=loft('Heavy_torso',[(0,-2.00,1.02),(0,-1.05,1.00),(0,0,.89),(0,1.05,.88),(0,2.0,.90),(0,2.7,.89)],[.50,.68,.80,.78,.70,.56],[.44,.60,.66,.64,.58,.48],'Body',46,32)
tailpts=[(0,2.6,.88),(.02,3.4,.76),(.24,4.3,.60),(.70,5.2,.48),(1.25,6.0,.40),(1.58,6.9,.36),(1.40,7.7,.36),(.95,8.3,.38)]
tail=loft('Powerful_curled_tail',tailpts,[.56,.50,.43,.35,.27,.20,.10,.018],[.48,.43,.36,.29,.22,.16,.09,.015],'Tail',66,22)
# Rows of strongly raised dorsal osteoderms follow the actual body surface.
for label,fr,rows in [('Back',body,16),('Tail',tail,36)]:
 armorbatch=Plates()
 for k in range(1,rows):
  idx=round(k*(len(fr)-1)/rows);p,t,u,w,rx,rz=fr[idx]
  for j,a in enumerate([pi*.17,pi*.29,pi*.40,pi*.5,pi*.60,pi*.71,pi*.83]):
   if label=='Tail' and j not in [1,3,5]:continue
   normal=(u*cos(a)/max(rx,.02)+w*sin(a)/max(rz,.02)).normalized();q=p+u*cos(a)*rx+w*sin(a)*rz
   span=.15 if label=='Back' else max(.035,rx*.26)
   armorbatch.add(q,u,t,normal,span,span*1.25,.07,1,.05)
   length=random.uniform(.8,1.15)*(.34 if j==3 else .21)*(1 if label=='Back' else max(.3,rx/.5))
   ridge_spike(label+'_keeled_spine',q+normal*.04,normal,length,span*.66,'DorsalArmor')
 armorbatch.finish(label+'_armored_scutes','DorsalArmor')

# Four muscular, bent limbs with armor following the joints.
for side in [-1,1]:
 for front in [True,False]:
  groupname=('Fore' if front else 'Hind')+('_L' if side>0 else '_R')
  if front:
   pts=[(side*.50,-1.20,.94),(side*1.05,-1.12,.80),(side*1.58,-1.22,.56),(side*1.52,-1.78,.24),(side*1.58,-2.00,.15)]
   widths=[.38,.45,.35,.25,.23];heights=[.36,.38,.28,.20,.13]
  else:
   pts=[(side*.50,1.95,.86),(side*1.05,2.2,.74),(side*1.42,2.3,.52),(side*1.46,1.88,.23),(side*1.52,1.62,.15)]
   widths=[.42,.50,.38,.26,.24];heights=[.40,.42,.30,.20,.13]
  loft(groupname+'_muscular_limb',pts,widths,heights,'Limbs',19,20);LIMBS[groupname]=pts
  wrist=Vector(pts[-1])
  for digit in range(4):
   off=(digit-1.5)*.2;start=wrist+Vector((off,.02,0));end=wrist+Vector((off*1.75,-.64+.08*abs(digit-1.5),-.06))
   mid=(start+end)/2+Vector((0,-.04,.035))
   tube(groupname+'_toe_%d'%digit,[start,mid,end],[.078,.066,.036],skin,'Feet',9,12,.05,.78)
   for k in range(4):
    q=start.lerp(end,(k+.4)/4);q.z+=.065
    tile=Plates();tile.add(q,(1,0,0),(0,1,0),(0,0,1),.072,.052,.022,1);tile.finish(groupname+'_toe_scute','Feet')
   tip=end+Vector((side*.03,-.32,-.02))
   tube(groupname+'_claw',[end,end+Vector((0,-.09,.025)),tip],[.058,.046,.001],claw,'Feet',8,12)

# Skull and jaws are lofted flattened crocodilian forms, not a spherical head.
UP=[(-3.66,.47,1.73,.17),(-3.38,.57,1.78,.22),(-2.90,.59,1.83,.22),(-2.38,.63,1.90,.29),(-1.90,.69,1.91,.43),(-1.52,.57,1.62,.46)]
LOW=[(-3.58,.39,.62,.12),(-3.32,.48,.68,.14),(-2.88,.51,.83,.15),(-2.38,.55,1.03,.19),(-1.90,.55,1.28,.23),(-1.65,.43,1.39,.20)]
def jaw(name,sections,upper):
 pts=[(0,y,z) for y,r,z,h in sections];widths=[r for y,r,z,h in sections];heights=[h for y,r,z,h in sections]
 fr=frames(pts,widths,heights,10);v=[];f=[];nu=56
 for i,(p,t,u,w,rx,rz) in enumerate(fr):
  for j in range(nu):
   a=2*pi*j/nu
   # Superellipse gives a broad flattened snout, with softened corners.
   x=math.copysign(abs(cos(a))**.84,cos(a))*rx
   z=math.copysign(abs(sin(a))**.90,sin(a))*rz
   v.append(p+Vector((x,0,z)))
   if i:
    q=(i-1)*nu+j;b=(i-1)*nu+(j+1)%nu;f.append((q,b,b+nu,q+nu))
 f.extend([tuple(reversed(range(nu))),tuple((len(fr)-1)*nu+j for j in range(nu))])
 group='UpperJaw' if upper else 'LowerJaw';ob=mesh(name,v,f,face if upper else belly,group)
 # Skin plates on the crown and underside; the visible oral surfaces use tissue.
 batch=Plates()
 for row in range(1,27):
  idx=round(row*(len(fr)-1)/27);p,t,u,w,rx,rz=fr[idx]
  for j in range(16):
   a=2*pi*j/16
   if (upper and sin(a)<-.40) or (not upper and sin(a)>.35):continue
   x=math.copysign(abs(cos(a))**.84,cos(a))*rx;z=math.copysign(abs(sin(a))**.90,sin(a))*rz
   normal=Vector((cos(a)*.65,0,sin(a))).normalized();cross=Vector((-sin(a),0,cos(a))).normalized()
   batch.add(p+Vector((x,0,z)),cross,(0,1,0),normal,.071,.043,.009,2 if upper else 4)
 batch.finish(name+'_facial_scales',group)
 return fr
upper=jaw('Broad_predatory_skull',UP,True);lower=jaw('Open_lower_mandible',LOW,False)

def lookup(sections,y):
 for i in range(len(sections)-1):
  a=sections[i];b=sections[i+1]
  if a[0]<=y<=b[0]:
   t=(y-a[0])/(b[0]-a[0]);return [a[k]*(1-t)+b[k]*t for k in range(1,4)]
 return list(sections[0][1:] if y<sections[0][0] else sections[-1][1:])

def tooth(name,p,d,length,radius,group='Teeth'):
 p=Vector(p);d=Vector(d).normalized()
 tube(name,[p,p+d*length*.25+Vector((0,-.025,0)),p+d*length*.7,p+d*length+Vector((0,.045,0))],[radius,radius*.86,radius*.42,.001],ivory,group,7,12)
for isupper,sections in [(True,UP),(False,LOW)]:
 group='UpperJaw' if isupper else 'LowerJaw'
 for side in [-1,1]:
  gumpts=[]
  for i in range(27):
   y=-3.54+i*1.68/26;rx,z,rz=lookup(sections,y);gumpts.append((side*rx*.89,y,z+(-.83 if isupper else .84)*rz))
  tube(group+'_side_gum',gumpts,[.038]*27,gum,group,3,9)
  for i in range(19):
   y=-3.49+i*1.58/18+(0 if isupper else .035);rx,z,rz=lookup(sections,y);p=(side*rx*.88,y,z+(-.87 if isupper else .87)*rz)
   length=(random.uniform(.26,.42) if isupper else random.uniform(.18,.30))*(1.38 if i in [2,9,16] and isupper else 1)
   tooth(group+'_tooth_%s_%02d'%(side,i),p,(-side*.16,.03,-1 if isupper else 1),length,.052 if isupper else .037)
 # Rounded snout-front tooth arc.
 y0=sections[0][0];rx,z,rz=lookup(sections,y0)
 for i in range(5):
  a=pi*(i+.5)/5;p=(rx*.88*cos(a),y0-.035*sin(a),z+(-.8 if isupper else .85)*rz)
  tooth(group+'_front_fang',p,(-.12*cos(a),.03,-1 if isupper else 1),random.uniform(.19,.29),.038)
 # Organic lining over inner jaw surface.
 v=[];f=[];nr=34;nc=18
 for i in range(nr+1):
  y=-3.49+i*1.81/nr;rx,z,rz=lookup(sections,y)
  for j in range(nc+1):
   x=rx*.83*(2*j/nc-1);zz=z+(-1 if isupper else 1)*rz*1.04
   zz+=(-.018 if isupper else .018)*(1-(x/(rx*.84))**2)
   v.append((x,y,zz))
   if i and j:
    q=(i-1)*(nc+1)+j-1;f.append((q,q+1,q+nc+2,q+nc+1))
 mesh(group+'_oral_lining',v,f,flesh,'Mouth')
# The rear commissures physically connect both jaws behind the teeth.
for side in [-1,1]:
 mesh('Mouth_corner_membrane',[(side*.49,-2.03,1.15),(side*.57,-1.89,1.55),(side*.50,-1.60,1.53),(side*.41,-1.65,1.26)],[(0,1,2,3)],gum,'Mouth')
 tube('Rear_mouth_fold',[(side*.45,-1.96,1.18),(side*.39,-1.78,1.37),(side*.49,-1.84,1.56)],[.07,.10,.07],gum,'Mouth',10,12)
ellipsoid('Throat',(0,-1.66,1.39),(.46,.10,.32),flesh,'Mouth',nu=40,nv=24)
tube('Attached_crocodilian_tongue',[(0,-1.91,1.39),(0,-2.25,1.23),(0,-2.66,1.07),(0,-3.03,.95),(0,-3.23,.92)],[.25,.28,.25,.18,.06],tonguemat,'Mouth',12,22,0,.33)
# Eyelids enclose small forward-looking amber eyes, with a sharp dark pupil.
for side in [-1,1]:
 ellipsoid('Recessed_eye_socket',(side*.59,-2.04,2.08),(.14,.19,.075),skin,'Eyes',nu=32,nv=20)
 ellipsoid('Amber_eye',(side*.69,-2.10,2.13),(.065,.095,.050),eye,'Eyes',nu=32,nv=20)
 ellipsoid('Vertical_predator_pupil',(side*.742,-2.14,2.136),(.010,.027,.043),black,'Eyes',nu=24,nv=16)
 tube('Heavy_angry_brow',[(side*.43,-2.37,2.16),(side*.58,-2.20,2.20),(side*.70,-1.96,2.20),(side*.61,-1.72,2.13)],[.035,.055,.052,.025],armor,'Head',10,14,.06)
 tube('Lower_eyelid',[(side*.65,-2.25,2.09),(side*.74,-2.09,2.065),(side*.69,-1.94,2.09)],[.024,.032,.022],face,'Eyes',7,9)
 ellipsoid('Nostril_ridge',(side*.31,-3.40,1.97),(.16,.21,.075),face,'Head',nu=28,nv=16)
 ellipsoid('Dark_nostril',(side*.31,-3.45,2.026),(.049,.081,.013),black,'Head',nu=24,nv=12)
# Interlocking nuchal shields join skull and dorsal armor.
for i in range(5):
 y=-2.00+i*.18
 for j in range(3):
  x=(j-1)*.28;z=2.18-.06*i+.035*(j==1)
  ridge_spike('Nuchal_crest',(x,y,z),(x*.2,0,1),.16+.04*i,.12,'Head')

# Continuous armored brows replace the exposed, round eye appearance.
for side in [-1,1]:
 batch=Plates()
 for j in range(5):
  y=-2.35+j*.12
  batch.add((side*.61,y,2.19),(1,0,0),(0,1,0),(0,0,1),.12,.082,.043,0,.018)
 batch.finish('Armored_orbital_ridge','Head')
# Broaden the skull, retaining attached dental and ocular anatomy.
for group in ['Head','UpperJaw','LowerJaw','Teeth','Mouth','Eyes']:
 for ob in G[group].objects:
  if ob.type=='MESH':
   for v in ob.data.vertices:v.co=Vector((0,-1.7,1.4))+(v.co-Vector((0,-1.7,1.4)))*1.15;v.co.x*=1.12;v.co.z-=.42
   ob.data.update()
exec(compile((ROOT/'scripts/rig.py').read_text(),'rig.py','exec'))

def point_at(ob,p):ob.rotation_euler=(Vector(p)-ob.location).to_track_quat('-Z','Y').to_euler()
floormat=material('Studio_floor',(.004,.004,.005),(.013,.013,.015),.9,5,.05);next(n for n in floormat.node_tree.nodes if n.bl_idname=='ShaderNodeBsdfPrincipled').inputs['Specular IOR Level'].default_value=0
mesh('Ground',[(-100,-100,-.04),(100,-100,-.04),(100,100,-.04),(-100,100,-.04)],[(0,1,2,3)],floormat,'Studio')
world=bpy.data.worlds.new('Alligator_world');world.use_nodes=True;n=world.node_tree.nodes;n.clear();bg=n.new('ShaderNodeBackground');out=n.new('ShaderNodeOutputWorld');world.node_tree.links.new(bg.outputs[0],out.inputs[0]);bg.inputs[0].default_value=(.012,.013,.016,1);bg.inputs[1].default_value=.3;scene.world=world
for name,pos,power,color,size in [('Key',(-4,-5,7),1050,(1,.87,.71),5),('Fill',(5,-3,4),650,(.86,.88,1),4),('Rim',(0,5,6),1400,(1,.78,.52),4),('Top',(-3,2,6),600,(.85,.90,1),3)]:
 data=bpy.data.lights.new(name,'AREA');data.energy=power;data.color=color;data.shape='DISK';data.size=size;ob=bpy.data.objects.new(name,data);G['Studio'].objects.link(ob);ob.location=(pos[0]*1.3,pos[1]*1.3+2.2,pos[2]);point_at(ob,(0,2.2,1.0))
data=bpy.data.cameras.new('Alligator_turntable');cam=bpy.data.objects.new('Alligator_turntable',data);G['Studio'].objects.link(cam);cam.data.type='ORTHO';cam.data.ortho_scale=15.0;scene.camera=cam
for frame in range(1,242):
 a=2*pi*(frame-1)/240;cam.location=(40*sin(a),2.2-40*cos(a),8.4);point_at(cam,(0,2.2,1.0));cam.data.clip_end=400;cam.data.ortho_scale=7.2+6.0*abs(sin(a));cam.keyframe_insert('location',frame=frame);cam.keyframe_insert('rotation_euler',frame=frame);cam.data.keyframe_insert('ortho_scale',frame=frame)
scene.frame_start=1;scene.frame_end=240;scene.render.fps=24
scene.render.engine='CYCLES';scene.cycles.samples=32;scene.cycles.use_denoising=True;scene.cycles.use_adaptive_sampling=True;scene.cycles.adaptive_threshold=.035;scene.cycles.max_bounces=6
scene.render.resolution_x=1200;scene.render.resolution_y=800;scene.render.resolution_percentage=100;scene.render.image_settings.file_format='PNG';scene.view_settings.view_transform='AgX';scene.frame_set(31)
ref=bpy.data.images.load(str(ROOT/'source/reference.png'));ref.name='Alligator_original_reference';ref.use_fake_user=True;ref.pack()
for screen in bpy.data.screens:
 for area in screen.areas:
  if area.type=='VIEW_3D':area.spaces.active.region_3d.view_perspective='CAMERA';area.spaces.active.shading.color_type='MATERIAL'
scene['scope']='V2: corpo longo e esguio, rig completo (Alligator_Armature) com pesos automaticos e 3 acoes (Bite, Idle_Menace, Walk).'
file=ROOT/'alligator_v2.blend'
if file.exists():shutil.copy2(file,ROOT/'alligator.previous.blend')
bpy.ops.wm.save_as_mainfile(filepath=str(file))
obs=[o for o in scene.objects if o.type=='MESH' and o.name!='Ground']
stats={'blender':bpy.app.version_string,'mesh_objects':len(obs),'vertices_base':sum(len(o.data.vertices) for o in obs),'faces_base':sum(len(o.data.polygons) for o in obs),'triangles_base':sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in obs),'teeth':len(G['Teeth'].objects),'turntable_frames':240}
(ROOT/'geometry.json').write_text(json.dumps(stats,indent=2),encoding='utf8')
views=['01_front','02_front_left','03_left','04_rear_left','05_back','06_rear_right','07_right','08_front_right']
for i,name in enumerate(views):
 if '--build-only' in sys.argv:continue
 if '--preview' in sys.argv and i!=1:continue
 scene.frame_set(1+i*30);scene.render.filepath=str(ROOT/'renders'/name);bpy.ops.render.render(write_still=True)
print('ALLIGATOR_CREATED',json.dumps(stats))
