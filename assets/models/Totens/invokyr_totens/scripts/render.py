import bpy,pathlib,math
from mathutils import Vector
R=pathlib.Path(__file__).resolve().parents[1]
bpy.ops.wm.open_mainfile(filepath=str(R/'Invokyr_Totens.blend'))
s=bpy.context.scene;s.render.engine='CYCLES';s.cycles.samples=20;s.cycles.use_denoising=True
s.render.threads_mode='FIXED';s.render.threads=8
s.render.resolution_percentage=100
cam=s.camera
cols=[bpy.data.collections[n] for n in ['01_Fogo','02_Gelo','03_Teleporte','04_Raio','05_Diamante_Raro']]
def render(name,loc,target,scale,w,h):
    cam.location=loc;cam.rotation_euler=(Vector(target)-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=scale
    s.render.resolution_x=w;s.render.resolution_y=h;s.render.filepath=str(R/'renders'/name)
    bpy.ops.render.render(write_still=True)
render('colecao.png',(5,-24,10),(0,0,2.1),14.4,1600,800)
for i,c in enumerate(cols):
    for other in cols:other.hide_render=other!=c
    x=(i-2)*2.55
    render(c.name+'.png',(x+3.3,-9,4.9),(x,0,2.15),5.1,750,900)
    if i==2:render('03_Teleporte_costas.png',(x+4,8,5),(x,0,2.15),5.1,750,900)
print('RENDERS_OK',flush=True)
