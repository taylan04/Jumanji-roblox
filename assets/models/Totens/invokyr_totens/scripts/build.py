import bpy, math, random, json, pathlib, numpy as np
from mathutils import Vector
from math import sin,cos,pi
ROOT=pathlib.Path(__file__).resolve().parents[1]
random.seed(34)
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
for c in list(bpy.data.collections):
    if c.name!='Collection': bpy.data.collections.remove(c)
scene=bpy.context.scene
scene.unit_settings.system='METRIC'
scene.render.engine='CYCLES'; scene.cycles.samples=24
scene.cycles.use_denoising=True
scene.render.resolution_percentage=100
scene.world.color=(.18,.18,.18)
scene.view_settings.view_transform='AgX'
CURRENT=None
def reg(o,name,mat):
    o.name=name
    for c in list(o.users_collection): c.objects.unlink(o)
    CURRENT.objects.link(o)
    if mat:o.data.materials.append(mat)
    return o
def apply(o):
    bpy.context.view_layer.objects.active=o
    for m in list(o.modifiers):bpy.ops.object.modifier_apply(modifier=m.name)
def smooth(o):
    for p in o.data.polygons:p.use_smooth=True
    return o
def ell(name,loc,scale,mat,seg=40,rings=24):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=seg,ring_count=rings,location=loc)
    o=reg(bpy.context.object,name,mat);o.scale=scale
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    return smooth(o)
def cube(name,loc,scale,mat,bevel=.07):
    bpy.ops.mesh.primitive_cube_add(size=1,location=loc)
    o=reg(bpy.context.object,name,mat);o.scale=scale
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    m=o.modifiers.new('Rounded carved edges','BEVEL');m.width=bevel;m.segments=3
    apply(o);return o
def cyl(name,z,r,depth,mat,verts=64):
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts,radius=r,depth=depth,location=(0,0,z))
    o=reg(bpy.context.object,name,mat)
    m=o.modifiers.new('Worn edge','BEVEL');m.width=.035;m.segments=3;apply(o)
    return o
def tube(name,pts,r,mat,closed=False):
    cu=bpy.data.curves.new(name,'CURVE');cu.dimensions='3D';cu.resolution_u=16;cu.bevel_depth=r;cu.bevel_resolution=3
    s=cu.splines.new('BEZIER');s.bezier_points.add(len(pts)-1)
    for b,p in zip(s.bezier_points,pts):b.co=p;b.handle_left_type='AUTO';b.handle_right_type='AUTO'
    s.use_cyclic_u=closed;cu.use_fill_caps=True
    o=bpy.data.objects.new(name,cu);CURRENT.objects.link(o);cu.materials.append(mat)
    bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o
    bpy.ops.object.convert(target='MESH');return o
def ring(name,center,rx,rz,r,mat):
    return tube(name,[(center[0]+rx*cos(i*2*pi/12),center[1],center[2]+rz*sin(i*2*pi/12)) for i in range(12)],r,mat,True)
def gem(name,loc,r,h,mat,lean=0):
    n=7;verts=[(loc[0]+r*cos(i*2*pi/n),loc[1]+r*sin(i*2*pi/n),loc[2]) for i in range(n)]
    verts += [(loc[0]+r*.68*cos(i*2*pi/n+.12),loc[1]+r*.68*sin(i*2*pi/n+.12),loc[2]+h*.55) for i in range(n)]
    verts += [(loc[0]+lean,loc[1],loc[2]+h),(loc[0],loc[1],loc[2]-.12)]
    faces=[]
    for i in range(n):j=(i+1)%n;faces.extend([(i,j,n+j,n+i),(n+i,n+j,2*n),(j,i,2*n+1)])
    me=bpy.data.meshes.new(name);me.from_pydata(verts,[],faces);me.update()
    o=bpy.data.objects.new(name,me);CURRENT.objects.link(o);me.materials.append(mat);return o
def material(name,color,metal=.0,rough=.4,glow=0):
    m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True
    m.node_tree.nodes.clear();p=m.node_tree.nodes.new('ShaderNodeBsdfPrincipled');out=m.node_tree.nodes.new('ShaderNodeOutputMaterial');m.node_tree.links.new(p.outputs['BSDF'],out.inputs['Surface']);p.inputs['Metallic'].default_value=metal;p.inputs['Roughness'].default_value=rough
    # Real image textures survive export; deliberately no Blender-only procedural shader.
    n=256;yy,xx=np.mgrid[0:n,0:n];rng=np.random.default_rng(sum(map(ord,name)))
    noise=rng.random((n,n));grain=.80+.16*np.sin(xx*.07+np.sin(yy*.055)*3)*np.sin(yy*.09)+.12*noise
    pixels=np.ones((n,n,4),dtype=np.float32)
    for k in range(3):pixels[:,:,k]=np.clip(color[k]*grain,0,1)
    im=bpy.data.images.new(name+'_BaseColor',width=n,height=n);im.pixels.foreach_set(pixels.ravel());im.pack()
    tex=m.node_tree.nodes.new('ShaderNodeTexImage');tex.image=im;m.node_tree.links.new(tex.outputs['Color'],p.inputs['Base Color'])
    if glow:p.inputs['Emission Color'].default_value=(*color,1);p.inputs['Emission Strength'].default_value=glow
    return m
dark=material('Cavity_obsidian',(.012,.017,.023),.35,.32)
gold=material('Antique_champagne_brass',(.47,.30,.12),.78,.30)
silver=material('Brushed_silver',(.48,.60,.66),.82,.27)
configs=[('01_Fogo',(.095,.037,.022),(1,.18,.025),gold),('02_Gelo',(.045,.13,.17),(.13,.75,1),silver),('03_Teleporte',(.065,.035,.105),(.60,.15,1),gold),('04_Raio',(.035,.065,.085),(1,.70,.09),gold),('05_Diamante_Raro',(.12,.20,.23),(.50,.95,1),silver)]
collections=[]
for idx,(name,col,energy,trim) in enumerate(configs):
    CURRENT=bpy.data.collections.new(name);scene.collection.children.link(CURRENT);collections.append(CURRENT)
    body=material(name+'_patinated_metal',col,.70,.34)
    emissive=material(name+'_Luminous',energy,.20,.24,2.8)
    crystal=material(name+'_cut_crystal',tuple(min(1,c*.65+.1) for c in energy),.58,.19,.25)
    # Weighted stepped plinth, waist and shoulder ornaments.
    cyl('Foot_dark',.105,1.04,.21,body,8);cyl('Foot_inlay',.23,1.00,.065,trim,8);cyl('Pedestal',.40,.91,.29,body,8)
    cyl('Pedestal_upper_bead',.56,.86,.08,trim)
    cube('Torso', (0,.02,1.02),(1.34,1.00,.90),body,.16)
    cyl('Neck_collar',1.52,.72,.18,trim);cyl('Neck',1.66,.62,.16,body)
    for side in [-1,1]:
        ell('Shoulder', (side*.71,0,1.19),(.27,.43,.32),body)
        ring('Shoulder_inlay',(side*.73,-.36,1.20),.14,.22,.035,trim)
        tube('Folded_arm',[(side*.81,-.05,1.23),(side*.85,-.45,.94),(side*.49,-.61,.80)],.105,body)
        for f in range(3):tube('Carved_finger',[(side*(.45+f*.07),-.61,.86),(side*(.43+f*.07),-.64,.73)],.023,trim)
    cube('Chest_frame',(0,-.535,1.02),(.82,.10,.73),trim,.06)
    cube('Chest_recess',(0,-.60,1.02),(.68,.08,.59),dark,.05)
    # A fully volumetric mask, with recessed sockets and an excavated mouth.
    head=ell('Mask_shell',(0,0,2.59),(.88,.65,1.00),body,64,40)
    for kind,loc,scale in [('mouth',(0,-.59,2.15),(.54,.46,.38)),('eyeL',(-.43,-.57,2.85),(.32,.32,.32)),('eyeR',(.43,-.57,2.85),(.32,.32,.32))]:
        cut=ell('cutter',loc,scale,None)
        m=head.modifiers.new(kind,'BOOLEAN');m.operation='DIFFERENCE';m.object=cut;apply(head);bpy.data.objects.remove(cut,do_unlink=True)
    for side in [-1,1]:
        # Nested socket rings surround faceted glowing stones, not cartoon eyeballs.
        ring('Socket_outer',(side*.43,-.625,2.86),.31,.30,.064,trim)
        ring('Socket_inner',(side*.43,-.68,2.86),.247,.245,.028,dark)
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2,radius=1,location=(side*.43,-.67,2.86))
        o=reg(bpy.context.object,'Glow_Eye',emissive);o.scale=(.211,.13,.211);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
        tube('Heavy_brow',[(side*.10,-.65,3.10),(side*.40,-.69,3.22),(side*.73,-.52,3.12)],.10,body)
        tube('Brow_gold_edge',[(side*.13,-.74,3.13),(side*.41,-.77,3.22),(side*.71,-.60,3.14)],.022,trim)
        tube('Cheek_scroll',[(side*.76,-.45,2.65),(side*.71,-.62,2.40),(side*.56,-.65,2.32)],.06,trim)
        tube('Temple_engraving',[(side*.82,-.20,3.10),(side*.87,-.18,2.75),(side*.79,-.30,2.42)],.021,trim)
        ring('Ear_hoop',(side*.88,0,2.62),.15,.26,.065,trim)
    # Sharp tapered bridge and broad lower nostril wings.
    nose=gem('Chiseled_nose',(0,-.78,2.52),.16,.63,trim);nose.rotation_euler[0]=-.12
    for s in [-1,1]:ell('Nostril',(s*.12,-.85,2.51),(.064,.028,.037),dark,24,12)
    ring('Mouth_lip',(0,-.625,2.15),.52,.37,.065,trim)
    ell('Mouth_dark_inner',(0,-.24,2.16),(.43,.055,.30),dark)
    for s in [-1,1]:
        for k in range(2):
            bpy.ops.mesh.primitive_cone_add(vertices=16,radius1=.012,radius2=.065,depth=.17,location=(s*(.28-k*.16),-.64,2.40))
            reg(bpy.context.object,'Upper_fang',trim)
    tube('Chin_plate',[(-.50,-.50,1.93),(0,-.66,1.80),(.50,-.50,1.93)],.065,body)
    # Circlet goes all the way around, with a rear crest and engraved back plate.
    for z in [3.34,3.48]:
        tube('Crown_band',[(.79*cos(t*2*pi/24),.53*sin(t*2*pi/24),z) for t in range(24)],.055,trim,True)
    for i in range(12):
        a=i*2*pi/12
        ell('Crown_rivet',(.79*cos(a),.54*sin(a),3.40),(.043,.043,.043),trim,16,8)
    for z in [1.03,2.50]:
        ring('Rear_seal',(0,.62 if z>2 else .55,z),.29,.32,.035,trim)
    tube('Back_rune',[(0,.67,2.20),(-.16,.67,2.48),(0,.67,2.76),(.16,.67,2.48),(0,.67,2.20)],.025,emissive)
    # Each silhouette and chest emblem is distinct.
    if idx==0:
        for i in range(7):
            x=(i-3)*.23;h=.60+.34*(1-abs(i-3)/3)
            gem('Flame_crown',(x,.03,3.42),.16,h,body,lean=x*.20)
            gem('Ember_inlay',(x,-.075,3.48),.065,h*.65,crystal,lean=x*.15)
        tube('Flame_sigil',[(-.16,-.67,.85),(-.21,-.67,1.04),(-.05,-.67,1.24),(0,-.67,1.08),(.13,-.67,1.20),(.19,-.67,.97),(0,-.67,.83)],.031,emissive,True)
    elif idx==1:
        for i in range(9):
            a=i*2*pi/9;gem('Ice_shard',(.65*cos(a),.38*sin(a),3.40),.13,.47+.39*(.5+.5*cos(a*3)),crystal,lean=.16*cos(a))
        for a in [0,pi/3,2*pi/3]:
            dx=.23*cos(a);dz=.23*sin(a)
            tube('Snowflake',[(-dx,-.67,1.02-dz),(dx,-.67,1.02+dz)],.026,emissive)
            for s in [-1,1]:
                for t in [-1,1]:tube('Frost_branch',[(s*dx*.65,-.67,1.02+s*dz*.65),(s*dx*.65+.085*cos(a+t*pi/3),-.67,1.02+s*dz*.65+.085*sin(a+t*pi/3))],.016,emissive)
    elif idx==2:
        ring('Portal_crown',(0,.12,3.77),.64,.65,.075,trim)
        ring('Portal_energy',(0,.12,3.77),.54,.55,.025,emissive)
        gem('Portal_keystone',(0,.12,4.22),.16,.32,crystal)
        for s in [-1,1]:gem('Side_prong',(s*.74,0,3.4),.14,.52,body,lean=s*.16)
        pts=[]
        for j in range(30):
            a=j/29*pi*3.7;r=.23*(1-j/36);pts.append((r*cos(a),-.67,1.02+r*sin(a)))
        tube('Spiral_sigil',pts,.025,emissive)
    elif idx==3:
        for s in [-1,1]:
            tube('Thunder_horn',[(s*.63,0,3.42),(s*.94,.04,3.76),(s*.62,.04,4.03),(s*.70,.04,4.28)],.095,trim)
        gem('Storm_crystal',(0,0,3.43),.25,.79,crystal)
        tube('Lightning_sigil',[(.11,-.67,1.27),(-.13,-.67,1.03),(.12,-.67,1.04),(-.12,-.67,.78)],.035,emissive)
    else:
        for i in range(5):gem('Royal_diamond',((i-2)*.30,0,3.43),.18,.53+.39*(1-abs(i-2)/2),crystal)
        for s in [-1,1]:
            tube('Royal_wing',[(s*.68,0,3.36),(s*.94,0,3.62),(s*.93,0,3.90)],.065,trim)
        tube('Diamond_sigil',[(0,-.67,.79),(-.23,-.67,1.08),(-.13,-.67,1.23),(.13,-.67,1.23),(.23,-.67,1.08),(0,-.67,.79)],.028,emissive)
        tube('Diamond_facets',[(-.23,-.67,1.08),(.23,-.67,1.08)],.018,emissive)
        for x in [-.10,.10]:tube('Diamond_facets',[(x,-.67,1.23),(0,-.67,.79)],.017,emissive)
    # Decorative incised-looking lines around plinth, both sides and back.
    for i in range(16):
        a=i*2*pi/16
        tube('Pedestal_glyph',[(.925*cos(a-.025),.925*sin(a-.025),.33),(.925*cos(a),.925*sin(a),.44),(.925*cos(a+.025),.925*sin(a+.025),.33)],.012,trim)
    # UV unwrap all real geometry. Consolidate into bounded material batches.
    for o in list(CURRENT.objects):
        bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o
        bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
        bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.uv.smart_project(island_margin=.025);bpy.ops.object.mode_set(mode='OBJECT')
    mats={o.data.materials[0] for o in CURRENT.objects}
    for mat in mats:
        objects=[o for o in CURRENT.objects if o.data.materials[0]==mat];batch=[];total=0;part=0
        def join_batch(batch,part):
            bpy.ops.object.select_all(action='DESELECT')
            for ob in batch:ob.select_set(True)
            bpy.context.view_layer.objects.active=batch[0];bpy.ops.object.join();ob=bpy.context.object
            ob.name=name+'__'+mat.name+'__'+str(part)
            scene.cursor.location=(0,0,0);bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
            return ob
        for o in objects:
            tri=sum(len(p.vertices)-2 for p in o.data.polygons)
            if batch and total+tri>18000:join_batch(batch,part);batch=[];total=0;part+=1
            batch.append(o);total+=tri
        if batch:join_batch(batch,part)
    # A separate origin-centered glTF for each prop, with actual image textures.
    bpy.ops.object.select_all(action='DESELECT')
    for o in CURRENT.objects:o.select_set(True)
    folder=ROOT/'importar'/name;folder.mkdir(exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=str(folder/(name+'.gltf')),export_format='GLTF_SEPARATE',use_selection=True,export_yup=True,export_texcoords=True,export_normals=True,export_materials='EXPORT',export_cameras=False,export_lights=False)
    for o in CURRENT.objects:o.location.x+=(idx-2)*2.55
    print('BUILT',name,flush=True)
# Studio belongs only to the master, never to exports.
CURRENT=bpy.data.collections.new('STUDIO_preview_only');scene.collection.children.link(CURRENT)
floor=material('Studio_slate',(.022,.030,.042),.1,.45)
cube('Floor',(0,0,-.14),(200,200,.20),floor,.02)
def area(name,loc,power,color,size,target):
    d=bpy.data.lights.new(name,'AREA');d.energy=power;d.color=color;d.shape='DISK';d.size=size
    o=bpy.data.objects.new(name,d);CURRENT.objects.link(o);o.location=loc;o.rotation_euler=(Vector(target)-o.location).to_track_quat('-Z','Y').to_euler()
area('Key',(-4,-7,9),2100,(1,.85,.67),7,(0,0,2))
area('Cool_fill',(6,-4,6),1700,(.55,.75,1),6,(0,0,2))
area('Rim',(0,4,8),2500,(.55,.70,1),6,(0,0,2))
camd=bpy.data.cameras.new('Camera');cam=bpy.data.objects.new('Camera',camd);CURRENT.objects.link(cam);scene.camera=cam
def camera(loc,target,scale):
    cam.location=loc;cam.rotation_euler=(Vector(target)-cam.location).to_track_quat('-Z','Y').to_euler();camd.type='ORTHO';camd.ortho_scale=scale
camera((7,-23,11),(0,0,2.1),14.8)
scene.render.resolution_x=1800;scene.render.resolution_y=850
scene.render.image_settings.file_format='PNG'
# Packed source reference for later editing.
im=bpy.data.images.load(str(ROOT/'source'/'referencia.png'));im.pack()
stats={c.name:{'objects':len(c.objects),'triangles':sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in c.objects),'max_mesh_triangles':max(sum(len(p.vertices)-2 for p in o.data.polygons) for o in c.objects)} for c in collections}
(ROOT/'geometry.json').write_text(json.dumps(stats,indent=2))
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'Invokyr_Totens.blend'))
scene.render.filepath=str(ROOT/'renders'/'colecao.png');bpy.ops.render.render(write_still=True)
for idx,c in enumerate(collections):
    x=(idx-2)*2.55
    for other in collections:other.hide_render=other!=c
    camera((x+4,-9,5.1),(x,0,2.15),5.15)
    scene.render.resolution_x=850;scene.render.resolution_y=1000
    scene.render.filepath=str(ROOT/'renders'/(c.name+'.png'));bpy.ops.render.render(write_still=True)
print('COMPLETE',flush=True)
