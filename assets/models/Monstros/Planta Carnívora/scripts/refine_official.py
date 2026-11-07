"""Official candidate: targeted sculptural revision of saved V2. Keeps V1/V2 intact."""
import bpy,ast,math,random,json,sys
from math import sin,cos,pi
from mathutils import Vector,noise as organic_noise
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
bpy.ops.wm.open_mainfile(filepath=str(ROOT/'source/version_2.blend'))
scene=bpy.data.scenes['CarnivorousPlant_Presentation'];bpy.context.window.scene=scene
G={name:bpy.data.collections['CP_'+name] for name in ['MainBody','UpperJaw','LowerJaw','Teeth','Tongue','RearBulb','Roots','Limbs','Tentacles','Leaves','Spines','Studio']}
for var,name in {'bark':'Bark_fibrous','rootmat':'Roots_moss','leafmat':'Olive_leaf','leafgold':'Leaf_weathered_edges','redleaf':'Inner_red_bracts','veinmat':'Raised_leaf_veins','spinemat':'Crimson_thorns','gum':'Gums','flesh':'Oral_tissue','tonguemat':'Tongue','toothmat':'Ivory_dentine'}.items():globals()[var]=bpy.data.materials['CP_'+name]
tree=ast.parse((ROOT/'scripts/geometry_helpers.py').read_text(encoding='utf-8-sig'))
functions=[n for n in tree.body if isinstance(n,ast.FunctionDef) and n.name in {'mesh','catmull','tube','thorn','leaf','ellipsoid'}]
exec(compile(ast.Module(body=functions,type_ignores=[]),'geometry_helpers','exec'))
random.seed(803)
# Replace only jaw tissues, teeth, tongue and major vines; retain V2 torso and limbs.
removed=0
for name in ['UpperJaw','LowerJaw','Teeth','Tongue','Tentacles']:
 for ob in list(G[name].objects):bpy.data.objects.remove(ob,do_unlink=True);removed+=1
for ob in list(scene.objects):
 if ob.name.startswith(('Jaw_flared_bract','Large_crimson_neck_bract','V2_Flaring_serrated_bract','V2_Bract_crimson_tip','Crown_armored_leaf','Crown_red_spike','Cranial_overlapping_scale')):
  bpy.data.objects.remove(ob,do_unlink=True);removed+=1
retained=len([o for o in scene.objects if o.type=='MESH'])

def rim(a):
 s=sin(a);upper=s>=0
 x=1.24*cos(a)*(1+.025*sin(7*a))*(1 if upper else .91)
 z=1.49+(1.08*s**.48 if upper else -1.04*(-s)**.72)
 y=-1.26-1.15*abs(s)**.68+.16*s
 return Vector((x,y,z))

def build_mouth():
 # Deep continuous oral surface, closed at a throat in front of the retained body.
 v=[];f=[];nu=160;nv=48
 for k in range(nv+1):
  t=k/nv;r=(1-t)**.78
  for j in range(nu):
   a=2*pi*j/nu;e=rim(a);ripple=.018*sin(15*a+14*t)*sin(pi*t)
   v.append((e.x*r*(1+ripple),e.y*(1-t)-.67*t,1.48+(e.z-1.48)*r*(1+ripple)))
   if k:
    q=(k-1)*nu+j;b=(k-1)*nu+(j+1)%nu;f.append((q,b,b+nu,q+nu))
 mesh('Official_deep_oral_cavity',v,f,flesh,'UpperJaw')
 for upper in [True,False]:
  group='UpperJaw' if upper else 'LowerJaw';start=0 if upper else pi
  # Volumetric jaw shell tapers into the existing neck.
  v=[];f=[];na=90;nd=24
  for k in range(nd+1):
   t=k/nd
   for j in range(na+1):
    a=start+pi*j/na;e=rim(a);n=.025*sin(j*.7+k*.4)*sin(pi*t)
    v.append((e.x*(1-.43*t),e.y*(1-t)+.20*t,1.49+(e.z-1.49)*(1-.36*t)+(.15 if upper else -.18)*sin(pi*t)+n))
    if k and j:
     q=(k-1)*(na+1)+j-1;f.append((q,q+1,q+na+2,q+na+1))
  ob=mesh('Official_'+group+'_shell',v,f,rootmat,group);mod=ob.modifiers.new('Jaw_thickness','SOLIDIFY');mod.thickness=.14
  pts=[rim(start+pi*i/60) for i in range(61)]
  tube('Official_'+group+'_living_lip',pts,[.083+.013*sin(i*1.4)+.009*sin(i*3.7) for i in range(61)],gum,group,3,16,.09)
  tube('Official_'+group+'_outer_ridge',[p+Vector((p.x*.07,.05,(p.z-1.49)*.07)) for p in pts],[.075]*61,leafgold,group,3,12,.18)
  # Uneven sockets and recurved fangs: irregular pairs, secondary interior rows.
  for row,count in [(0,25 if upper else 23),(1,21),(2,17)]:
   for i in range(count):
    a=start+.07+(pi-.14)*(i+.5)/count+random.uniform(-.012,.012)
    p=rim(a);p.y+=row*.13;p.x*=1-row*.052;p.z=1.49+(p.z-1.49)*(1-row*.055)
    length=(.33+.16*abs(sin(a)))*random.uniform(.76,1.24)*(1-.18*row)
    if row==0 and i%6==2:length*=1.23
    d=Vector((-p.x*.18,-.08,-1 if upper else 1)).normalized();radius=random.uniform(.049,.075)*(1-.18*row)
    tube('Official_'+group+'_fang_%d_%02d'%(row,i),[p,p+d*length*.27+Vector((0,-.055,0)),p+d*length*.68,p+d*length+Vector((0,.12,0))],[radius,radius*.82,radius*.39,.001],toothmat,'Teeth',8,16)
    if row==0:
     ellipsoid('Official_gingival_socket',p,(radius*1.32,.085,.08),gum,group,nu=24,nv=12)
     q=p+Vector((p.x*.04,.055,.11 if upper else -.11))
     tube('Official_gingival_fold',[q,p+Vector((-.04,0,.015)),p+Vector((.04,-.015,0))],[.026,.024,.010],gum,group,5,8)
 # Longitudinal ridges lead into the throat, avoiding the previous uniform rings.
 for j in range(28):
  a=2*pi*j/28;e=rim(a);pts=[]
  for k in range(7):
   t=.13+k*.105;r=(1-t)**.78
   pts.append((e.x*r,e.y*(1-t)-.67*t-.014,1.48+(e.z-1.48)*r))
  tube('Official_palatal_ruffle',pts,[.018,.030,.035,.027,.022,.014,.003],gum,'UpperJaw',6,9,.12)
 for k in range(3):
  t=.58+k*.10;pts=[]
  for j in range(49):
   a=2*pi*j/48;e=rim(a);r=(1-t)**.78
   pts.append((e.x*r,e.y*(1-t)-.67*t-.01,1.48+(e.z-1.48)*r))
  tube('Official_throat_fold',pts,[.015]*49,flesh,'UpperJaw',2,8)
 # Broad muscular tongue with a curled, raised tip and central groove.
 pts=[(0,-.76,1.15),(-.03,-1.25,1.22),(.02,-1.72,1.25),(.12,-2.16,1.07),(.28,-2.55,.94),(.46,-2.74,1.08),(.48,-2.61,1.18)]
 tube('Official_Tongue',pts,[.29,.34,.29,.23,.16,.085,.014],tonguemat,'Tongue',14,28,.035,.62)
 for side in [-1,1]:
  tube('Official_tongue_groove',[(side*.055,-.91,1.32),(side*.065,-1.38,1.43),(.07+side*.05,-1.86,1.38),(.19+side*.03,-2.30,1.17),(.37,-2.63,1.17)],[.009,.012,.010,.007,.002],gum,'Tongue',9,7)
 for j in range(18):
  y=-1.1-j*.067;cx=.08*max(0,-y-1.1)
  z=1.44-max(0,-y-1.5)*.34
  tube('Official_tongue_transverse_fiber',[(cx-.20,y,z-.045),(cx-.1,y-.025,z),(cx+.1,y-.02,z),(cx+.2,y,z-.04)],[.002,.005,.005,.001],gum,'Tongue',4,6)
 # Thin saliva strands remain secondary to anatomy.
 saliva=bpy.data.materials.new('Official_saliva');saliva.use_nodes=True;n=saliva.node_tree.nodes;n.clear();p=n.new('ShaderNodeBsdfPrincipled');out=n.new('ShaderNodeOutputMaterial');saliva.node_tree.links.new(p.outputs[0],out.inputs[0]);p.inputs['Base Color'].default_value=(.28,.18,.12,1);p.inputs['Roughness'].default_value=.12;p.inputs['Transmission Weight'].default_value=.8
 for side in [-1,1]:
  for i in range(2):
   x=side*(.75+i*.13)
   tube('Official_saliva_filament',[(x,-1.79,2.16),(x+.015,-1.84,1.55),(x+.035,-1.88,.92)],[.004,.003,.004],saliva,'UpperJaw',10,6)

def build_bracts():
 for side in [-1,1]:
  for j in range(7):
   z=.75+j*.265;x=side*(1.02+.06*sin(j));reach=1.49+.20*sin(j*.7)
   pts=[(x,-.93,z),(side*1.35,-.72,z+.23),(side*reach,-.38,z+.48),(side*(reach+.16),-.09,z+.63)]
   leaf('Official_cheek_bract',pts,.29+random.uniform(-.04,.08),redleaf if j in [2,4,6] else leafmat,normal=(side*.3,-1,.3))
   thorn('Official_bract_tip',pts[-1],(side*.55,.1,.8),.23,.048)
 for row in range(2):
  for j in range(9):
   x=(j-4)*.28;z=2.53+.10*(1-abs(x));y=-1.85+row*.7
   pts=[(x,y,z),(x*1.08,y+.32,z+.18),(x*1.12,y+.65,z+.28+random.uniform(-.08,.12))]
   leaf('Official_crown_scale',pts,.24,leafmat if j%4 else leafgold,normal=(0,-.3,1));thorn('Official_crown_spike',pts[-1],(x*.3,-.08,1),random.uniform(.16,.29),.055)
 # Armor tesserae and ridges cover the lower jaw's formerly smooth shell.
 for side in [-1,1]:
  for j in range(8):
   a=pi+.15+(pi-.3)*j/7;e=rim(a)
   pts=[e+Vector((0,.08,-.08)),Vector((e.x*.85,-1.1,.83)),Vector((e.x*.7,-.3,1.05))]
   tube('Official_mandibular_fiber',pts,[.024,.047,.015],bark,'LowerJaw',10,9,.22)


def build_branching_vines():
 for side in [-1,1]:
  for j in range(3):
   y=[.1,.7,1.6][j];h=[2.7,1.65,2.5][j]+(.13 if side<0 else 0);reach=[2.65,3.15,2.67][j]
   pts=[(side*1.05,y,.72),(side*1.67,y+.22,1.0),(side*1.98,y+.13,h-.35),(side*1.86,y-.04,h+.12),(side*2.25,y-.25,h+.34),(side*reach,y-.39,h+.15)]
   tube('Official_hooked_vine',pts,[.16,.13,.09,.075,.054,.027],bark,'Tentacles',13,16,.22)
   dense,r=catmull(pts,[.16,.13,.09,.075,.054,.027],7)
   for strand in range(3):
    cord=[]
    for i,p in enumerate(dense):
     a=strand*2*pi/3+i*.33;cord.append(p+Vector((cos(a)*r[i]*.85,sin(a)*r[i]*.85,0)))
    tube('Official_vine_twisted_fiber',cord,[.018*(1-i/(len(cord)*1.15)) for i in range(len(cord))],rootmat,'Tentacles',2,7,.12)
   blade=[(side*(reach-.52),y-.32,h+.28),(side*(reach+.05),y-.45,h+.19),(side*(reach+.47),y-.54,h-.18),(side*(reach+.52),y-.61,h-.67)]
   leaf('Official_hook_leaf',blade,.33,leafmat,'Tentacles',(0,-1,.3));thorn('Official_hook_talon',blade[-1],(-side*.15,-.08,-1),.32,.045,'Tentacles')
   for k in range(4,len(dense)-3,5):
    thorn('Official_vine_thorn',dense[k],(side*.5,-.65,.8),.12+random.random()*.08,.028,'Tentacles')
   # Branches emerge from the parent vine and taper to secondary leaf tips.
   branch=[dense[9],(side*2.2,y+.12,1.13),(side*(2.62+.12*j),y-.03,1.32),(side*(2.95+.08*j),y-.20,1.15)]
   tube('Official_vine_bifurcation',branch,[.07,.055,.034,.003],rootmat,'Tentacles',10,11,.21)
   if j!=1:leaf('Official_secondary_leaf',[branch[1],branch[2],branch[3]],.17,leafmat,'Tentacles',(0,-1,.7))
 # Lateral root network links torso, ankles and soil instead of isolated tendrils.
 for side in [-1,1]:
  for j in range(24):
   y=random.uniform(-.8,2.0);x=random.uniform(.85,1.3)
   pts=[(side*x,y,.85),(side*(x+.48),y-.15,.48),(side*(x+.85),y-.45,.16),(side*(x+1.2),y-.69,.07),(side*(x+1.50),y-.8,.035)]
   tube('Official_branching_root',pts,[.065,.080,.050,.026,.002],rootmat if j%3 else bark,'Roots',9,10,.24)
   tube('Official_root_fork',[pts[2],(pts[3][0]+side*.10,pts[3][1]+.2,.10),(pts[4][0],pts[4][1]+.45,.03)],[.029,.020,.002],bark,'Roots',7,8,.19)

build_mouth();build_bracts();build_branching_vines()
# Pebbled plant armor follows the lip rather than leaving a smooth snout band.
for upper in [True,False]:
 for row in range(2):
  for j in range(25):
   a=(0 if upper else pi)+.06+(pi-.12)*(j+.5)/25
   p=rim(a);p.x*=1.04+row*.025;p.y+=.10+row*.12;p.z+=(.10+row*.05)*(1 if upper else -1)
   ob=ellipsoid('Official_jaw_armor_scale',p,(random.uniform(.047,.080),.092,.039),leafgold if j%4==0 else rootmat,'UpperJaw' if upper else 'LowerJaw',nu=20,nv=12)
for mat,high in [(bark,(.070,.055,.022,1)),(rootmat,(.065,.085,.018,1))]:
 for node in mat.node_tree.nodes:
  if node.bl_idname=='ShaderNodeValToRGB' and any(link.from_node.bl_idname=='ShaderNodeTexVoronoi' for link in node.inputs[0].links):node.color_ramp.elements[1].color=high
  if node.bl_idname=='ShaderNodeBsdfPrincipled':node.inputs['Roughness'].default_value=.58

# Restrained palette adjustment: mossy greens, burgundy tissue and ivory teeth.
for mat in [leafmat,leafgold,veinmat]:
 for node in mat.node_tree.nodes:
  if node.bl_idname=='ShaderNodeValToRGB':
   for e in node.color_ramp.elements:
    c=e.color;e.color=(c[0]*.87,c[1]*.88,c[2]*.58,1)
  if node.bl_idname=='ShaderNodeBsdfPrincipled':node.inputs['Coat Weight'].default_value=.23;node.inputs['Roughness'].default_value=.39
for mat in [gum,tonguemat,flesh]:
 for node in mat.node_tree.nodes:
  if node.bl_idname=='ShaderNodeBsdfPrincipled':node.inputs['Coat Weight'].default_value=.48;node.inputs['Roughness'].default_value=.29
for group in ['UpperJaw','LowerJaw','Tongue']:
 pivot=bpy.data.objects.new('Official_'+group+'_Pivot',None);G[group].objects.link(pivot);pivot.location=(0,-.45,1.45);bpy.context.view_layer.update()
 objs=list(G[group].objects)+([o for o in G['Teeth'].objects if group in o.name] if group!='Tongue' else [])
 for ob in objs:
  if ob==pivot:continue
  world=ob.matrix_world.copy();ob.parent=pivot;ob.matrix_world=world
scene['version']='Official visual candidate — targeted V2 revision'
scene['revision']='Rebuilt mouth with layered fangs, thick curled tongue, fleshy folds; branching curved vines, fine root forks and layered crown.'
# Sculpt the tongue groove into its surface; remove floating guide fibers.
for ob in list(G['Tongue'].objects):
 if ob.name.startswith(('Official_tongue_transverse_fiber','Official_tongue_groove')):bpy.data.objects.remove(ob,do_unlink=True)
ob=bpy.data.objects['Official_Tongue'];vs=ob.data.vertices
for i in range(len(vs)//28):
 ring=[vs[i*28+j] for j in range(28)];c=sum((v.co for v in ring),Vector())/28
 for v in ring:
  if v.co.z>c.z:
   v.co.z-=.018*math.exp(-((v.co.x-c.x)/.045)**2)*sin(pi*i/(len(vs)//28-1))
ob.data.update()
# Close the nape-to-torso transition visible in the rear inspection.
ellipsoid('Official_connected_nape',(0,.10,1.79),(.86,.62,.45),rootmat,'MainBody',.035)
for j in range(9):
 x=(j-4)*.14
 tube('Official_nape_tendon',[(x,-.2,2.12),(x,.16,2.19),(x*.95,.56,1.96),(x*.85,.83,1.81)],[.018,.027,.030,.009],bark,'MainBody',8,8,.13)
scene.cycles.samples=32;scene.cycles.max_bounces=6;scene.cycles.transmission_bounces=4
scene.cycles.use_adaptive_sampling=True;scene.cycles.adaptive_threshold=.035
scene.camera.data.ortho_scale=9.15
scene.frame_set(31)
for ob in scene.objects:ob.select_set(False)
file=ROOT/'carnivorous_plant_official.blend'
bpy.ops.wm.save_as_mainfile(filepath=str(file))
meshes=[o for o in scene.objects if o.type=='MESH' and o.name!='Ground']
stats={'blender':bpy.app.version_string,'meshes':len(meshes),'vertices':sum(len(o.data.vertices) for o in meshes),'polygons':sum(len(o.data.polygons) for o in meshes),'retained_from_v2':retained-1,'teeth':len(G['Teeth'].objects),'frames':240}
(ROOT/'geometry.json').write_text(json.dumps(stats,indent=2),encoding='utf8')
views=['01_front','02_front_left','03_left','04_rear_left','05_back','06_rear_right','07_right','08_front_right']
for i,name in enumerate(views):
 if '--build-only' in sys.argv:continue
 if '--preview' in sys.argv and i!=1:continue
 scene.frame_set(1+i*30);scene.render.filepath=str(ROOT/'renders'/name);bpy.ops.render.render(write_still=True)
print('OFFICIAL_COMPLETE',json.dumps(stats))
