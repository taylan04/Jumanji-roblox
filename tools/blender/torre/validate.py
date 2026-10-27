"""Verificações físicas básicas; não substitui desempenho/colisões no Roblox."""
import math,bpy
from mathutils import Vector

def run(scene,cfg,doors):
    bpy.context.view_layer.update();deps=bpy.context.evaluated_depsgraph_get()
    pillars=[o for o in scene.objects if o.get("role")=="main_pillar"]
    assert len(pillars)==4 and len(doors)==8
    for p in pillars:
        assert 20.4<p.dimensions.z<20.8,(p.name,p.dimensions.z)
        assert abs(p.dimensions.x-3.25)<.1
    results=[]
    for i,label in enumerate(("North","East","South","West")):
        angle=i*math.pi/2;n=Vector((math.sin(angle),math.cos(angle),0));t=Vector((math.cos(angle),-math.sin(angle),0))
        origin=n*4.8+t*.5+Vector((0,0,2.2))
        hit,loc,norm,face,obj,mat=scene.ray_cast(deps,origin,n,distance=cfg.apothem+4-4.8)
        assert hit and obj.get("role")=="door_leaf",("Porta fechada",label,obj.name if obj else None)
        pair=[d for d in doors if d["door_id"]==label]
        for d in pair:d.rotation_euler.z=math.radians(d["open_degrees"])
        bpy.context.view_layer.update()
        hit,loc,norm,face,obj,mat=scene.ray_cast(deps,origin,n,distance=cfg.apothem+4-4.8)
        assert not hit,("Vão bloqueado",label,obj.name if obj else None)
        for d in pair:d.rotation_euler.z=0
        bpy.context.view_layer.update()
        results.append({"door":label,"closed_hits_leaf":True,"open_passage_clear":True})
    roof_hits=0
    for i in range(8):
        a=i*math.pi/4+.09
        hit,loc,norm,face,obj,mat=scene.ray_cast(deps,Vector((8*math.sin(a),8*math.cos(a),40)),Vector((0,0,-1)),distance=18)
        assert hit and obj.name.startswith("Roof"),("Cobertura sem face",i,obj.name if obj else None)
        roof_hits+=1
    # Névoa volumétrica não é parede; ignorada nas verificações de raio por ser ocultada temporariamente no chamador.
    tri=0;meshes=0
    for ob in scene.objects:
        if ob.type!="MESH" or ob.get("role")=="preview_fog":continue
        ev=ob.evaluated_get(deps);me=ev.to_mesh();me.calc_loop_triangles()
        tri+=len(me.loop_triangles);meshes+=1;ev.to_mesh_clear()
    return {"pillars":4,"pillar_height":round(pillars[0].dimensions.z,3),"door_leaves":8,
            "door_tests":results,"roof_rays":roof_hits,"mesh_objects":meshes,
            "evaluated_triangles":tri,"roblox_tested":False}

