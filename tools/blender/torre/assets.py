"""Lê os modelos aprovados e prepara cópias compactas sem alterar as fontes."""
import bpy, bmesh
from mathutils import Matrix, Vector
from .geometry import collection, empty, tube, box

def load_collection(path, name, scene):
    print("LOAD",str(path),name,flush=True)
    with bpy.data.libraries.load(str(path),link=False) as (src,dst):
        if name not in src.collections: raise ValueError("Coleção ausente: "+name)
        dst.collections=[name]
    print("LINK",name,flush=True)
    c=dst.collections[0];scene.collection.children.link(c)
    return c

def combine(objects,name,coll,offset=(0,0,0)):
    bpy.context.view_layer.update()
    deps=bpy.context.evaluated_depsgraph_get()
    vertices=[];faces=[];indices=[];smooth=[];uvs=[];materials=[]
    for ob in list(objects):
        if ob.type not in {"MESH","CURVE"}:continue
        ev=ob.evaluated_get(deps);me=ev.to_mesh()
        mapping=[]
        for slot in ob.material_slots:
            mat=slot.material
            if mat not in materials:materials.append(mat)
            mapping.append(materials.index(mat))
        transform=Matrix.Translation(Vector(offset)) @ ob.matrix_world
        base=len(vertices)
        vertices.extend(tuple(transform @ v.co) for v in me.vertices)
        uv=me.uv_layers.active
        for p in me.polygons:
            faces.append(tuple(base+i for i in p.vertices))
            indices.append(mapping[p.material_index] if mapping else 0)
            smooth.append(p.use_smooth)
            for li in p.loop_indices:uvs.append(tuple(uv.data[li].uv) if uv else (0,0))
        ev.to_mesh_clear()
    data=bpy.data.meshes.new(name);data.from_pydata(vertices,[],faces);data.update()
    for mat in materials:data.materials.append(mat)
    uv=data.uv_layers.new(name="UVMap")
    for i,value in enumerate(uvs):uv.data[i].uv=value
    for p,idx,sm in zip(data.polygons,indices,smooth):p.material_index=idx;p.use_smooth=sm
    ob=bpy.data.objects.new(name,data);coll.objects.link(ob)
    return ob

def portal_templates(path,scene,library):
    source=load_collection(path,"T01 | Portal ogival",scene)
    pivots=[o for o in source.all_objects if o.get("role")=="door_hinge"]
    assert len(pivots)==2
    leaves={o for p in pivots for o in p.children}
    static=combine([o for o in source.all_objects if o not in leaves and o not in pivots],
                   "Portal aprovado — cantaria",library)
    result=[]
    for p in pivots:
        ob=combine(p.children,p.name,library,offset=-p.location)
        result.append((ob.data,p.location.copy(),p["open_degrees"],"Left" if "Left" in p.name else "Right"))
    scene.collection.children.unlink(source)
    return static.data,result

def place_portals(scene,template,leaves,cfg):
    import math
    coll=collection("01 | Quatro portais aprovados",scene.collection)
    roots=[];doors=[]
    for label,angle,pos in [("North",0,(0,cfg.apothem,0)),("East",-math.pi/2,(cfg.apothem,0,0)),
                            ("South",math.pi,(0,-cfg.apothem,0)),("West",math.pi/2,(-cfg.apothem,0,0))]:
        root=empty("Portal"+label,coll,pos);root.rotation_euler.z=angle;root["role"]="portal_root";roots.append(root)
        ob=bpy.data.objects.new("Portal"+label+"_Stone",template);coll.objects.link(ob);ob.parent=root
        for data,loc,degrees,side in leaves:
            door=bpy.data.objects.new("Door"+label+"_"+side,data)
            coll.objects.link(door);door.parent=root;door.location=loc
            door["role"]="door_leaf";door["open_degrees"]=degrees;door["door_id"]=label;doors.append(door)
    bpy.context.view_layer.update()
    return roots,doors

def pillar_template(path,scene,library,cfg,mats):
    source=load_collection(path,"Jumanji | Pilar Gótico (Estudo)",scene)
    # Cópia de dados somente nos trechos retos. Nenhum capitel ou folha é esticado.
    for ob in source.all_objects:
        if ob.name.startswith(("Fuste principal","Nervura esculpida")):
            ob.data=ob.data.copy()
            original=ob.dimensions.z
            for v in ob.data.vertices:v.co.z *= (original+cfg.pillar_extension)/original
            ob.location.z += cfg.pillar_extension/2
        elif ob.location.z >= 6.90 or ob.name.startswith(("Arco ogival entalhado","Roseta central")):
            ob.location.z += cfg.pillar_extension
    details=collection("Transições do fuste",scene.collection)
    import math
    for z in (7.0,12.8,18.0):
        for dz,rad,thick in [(-.09,.91,.045),(0,.94,.07),(.11,.88,.035)]:
            tube("Anel de transição",[(rad*math.cos(i*math.tau/32),rad*math.sin(i*math.tau/32),z+dz) for i in range(32)],
                 thick,details,mats["trim"],True,sides=8)
    merged=combine(list(source.all_objects)+list(details.objects),"Pilar aprovado — fuste alto",library)
    scene.collection.children.unlink(source);scene.collection.children.unlink(details)
    return merged.data

def place_pillars(scene,data,cfg):
    coll=collection("02 | Quatro pilares principais",scene.collection)
    for i,(x,y) in enumerate([(-1,-1),(1,-1),(1,1),(-1,1)],1):
        ob=bpy.data.objects.new("Pillar_%02d"%i,data);coll.objects.link(ob)
        ob.location=(x*cfg.pillar_xy,y*cfg.pillar_xy,0)
        ob["role"]="main_pillar";ob["height"]=8.525+cfg.pillar_extension
    return coll




