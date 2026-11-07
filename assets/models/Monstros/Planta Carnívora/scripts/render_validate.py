import bpy,json,math
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
bpy.ops.wm.open_mainfile(filepath=str(ROOT/'carnivorous_plant_official.blend'))
s=bpy.data.scenes['CarnivorousPlant_Presentation'];bpy.context.window.scene=s
meshes=[o for o in s.objects if o.type=='MESH' and o.name!='Ground']
assert all(len(o.data.vertices)>0 and all(math.isfinite(c) for v in o.data.vertices for c in v.co) for o in meshes)
views=['01_front','02_front_left','03_left','04_rear_left','05_back','06_rear_right','07_right','08_front_right']
for i,name in enumerate(views):
 s.frame_set(1+i*30);s.render.filepath=str(ROOT/'renders'/name);bpy.ops.render.render(write_still=True)
s.frame_set(31)
report={'reopened':bpy.app.version_string,'finite_nonempty_meshes':len(meshes),'eight_renders':all((ROOT/'renders'/f'{name}.png').exists() for name in views),'teeth':len(bpy.data.collections['CP_Teeth'].objects),'turntable_frames':s.frame_end,'reference_packed':any(im.packed_file for im in bpy.data.images)}
(ROOT/'validation.json').write_text(json.dumps(report,indent=2),encoding='utf8')
print('VALIDATED',json.dumps(report))


# A dedicated camera render makes the oral anatomy easy to inspect.
from mathutils import Vector
s.camera.animation_data_clear()
s.camera.location=(2.4,-10,3.0)
s.camera.rotation_euler=(Vector((0,-1.75,1.48))-s.camera.location).to_track_quat('-Z','Y').to_euler()
s.camera.data.ortho_scale=3.7
s.render.resolution_x=1100;s.render.resolution_y=1100
s.render.filepath=str(ROOT/'renders/09_mouth_detail.png')
bpy.ops.render.render(write_still=True)
# Do not save: the delivered project retains its 360-degree camera animation.
