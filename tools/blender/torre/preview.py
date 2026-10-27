"""Câmeras internas, luz das janelas e névoa separada da arquitetura."""
import math,bpy
from mathutils import Vector
from .geometry import collection,box
from .furniture import light

def camera(scene,coll,name,pos,target,lens,width,height):
    data=bpy.data.cameras.new(name);ob=bpy.data.objects.new(name,data);coll.objects.link(ob)
    ob.location=pos;ob.rotation_euler=(Vector(target)-ob.location).to_track_quat("-Z","Y").to_euler()
    data.lens=lens;data.sensor_width=32;data.sensor_fit="HORIZONTAL";data.clip_end=200
    ob["resolution_x"]=width;ob["resolution_y"]=height
    return ob

def setup(scene,mats,cfg):
    scene.render.engine="CYCLES";scene.cycles.samples=32;scene.cycles.use_denoising=True
    scene.cycles.max_bounces=6;scene.cycles.diffuse_bounces=3;scene.cycles.glossy_bounces=3
    scene.cycles.volume_bounces=0
    scene.view_settings.view_transform="AgX";scene.view_settings.exposure=-.5
    scene.world=bpy.data.worlds.new("T02 | Céu noturno");scene.world.use_nodes=True
    bg=scene.world.node_tree.nodes.get("Background");bg.inputs["Color"].default_value=(.15,.23,.38,1)
    bg.inputs["Strength"].default_value=.15
    for i in range(8):
        a=i*math.pi/4
        light(scene,"Luar da janela_%d"%i,((cfg.apothem+1.8)*math.sin(a),(cfg.apothem+1.8)*math.cos(a),20),
              2000,(.58,.7,1),3,"AREA",(0,0,7))
    light(scene,"Luz fria do óculo",(0,0,cfg.roof_peak-.1),1500,(.42,.68,1),2.8,"AREA",(0,0,0))
    # Luz indireta ampla para legibilidade do estudo; não representa uma luz de jogo pronta.
    light(scene,"Preenchimento indireto",(0,-5,17),800,(.73,.77,.84),9,"AREA",(0,0,4))
    c=collection("T02 | Câmeras de avaliação",scene.collection)
    cams=[
        camera(scene,c,"01_Interior",(0,-12.5,3.5),(0,1.8,12.3),16,1100,1300),
        camera(scene,c,"02_Imersiva",(4,-11,2.5),(0,2.5,6.6),17,1400,900),
        camera(scene,c,"03_Tabuleiro",(3.6,-4.6,5.2),(0,0,1.8),43,1100,950),
        camera(scene,c,"04_Cobertura",(0,-1.0,9),(0,0,31),15,1100,1100),
    ]
    scene.camera=cams[0]
    c=collection("T02 | Névoa de prévia",scene.collection)
    fog=box("Volume atmosférico",(0,0,17),(35,35,34),c,None,0);fog.display_type="WIRE";fog.hide_select=True
    mat=bpy.data.materials.new("T02 | Névoa");mat.use_nodes=True;n=mat.node_tree.nodes;n.clear()
    out=n.new("ShaderNodeOutputMaterial");vol=n.new("ShaderNodeVolumePrincipled")
    vol.inputs["Density"].default_value=cfg.fog_density;vol.inputs["Color"].default_value=(.62,.68,.75,1)
    vol.inputs["Anisotropy"].default_value=.25;mat.node_tree.links.new(vol.outputs["Volume"],out.inputs["Volume"])
    fog.data.materials.append(mat);fog["role"]="preview_fog"
    return cams

def render(scene,cam,path,draft=False):
    scene.camera=cam;scene.render.resolution_x=int(cam["resolution_x"]);scene.render.resolution_y=int(cam["resolution_y"])
    scene.render.resolution_percentage=55 if draft else 100;scene.cycles.samples=12 if draft else 28
    scene.render.image_settings.file_format="PNG";scene.render.filepath=str(path)
    bpy.ops.render.render(write_still=True,scene=scene.name)


