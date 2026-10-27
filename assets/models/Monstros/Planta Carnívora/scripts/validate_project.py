"""Reopen and audit the saved Blender project, pack its reference, set useful viewport."""
import bpy,json,math
from pathlib import Path
from mathutils import Vector
root=Path(__file__).resolve().parents[1]
bpy.ops.wm.open_mainfile(filepath=str(root/'carnivorous_plant.blend'))
s=bpy.data.scenes['CarnivorousPlant_Presentation'];bpy.context.window.scene=s
meshes=[o for o in s.objects if o.type=='MESH' and o.name!='Ground']
invalid=[]
for ob in meshes:
 m=ob.data
 if not len(m.vertices) or not len(m.polygons):invalid.append(ob.name+': empty')
 if any(not math.isfinite(c) for v in m.vertices for c in v.co):invalid.append(ob.name+': nonfinite')
 if any(i>=len(m.vertices) for p in m.polygons for i in p.vertices):invalid.append(ob.name+': indices')
assert not invalid,invalid
im=bpy.data.images.load(str(root/'reference.png'),check_existing=True);im.name='Original_eight_view_reference';im.pack()
s.frame_set(31)
bpy.context.view_layer.objects.active=None
for ob in s.objects:ob.select_set(False)
for screen in bpy.data.screens:
 for a in screen.areas:
  if a.type=='VIEW_3D':
   space=a.spaces.active;space.shading.color_type='MATERIAL';space.region_3d.view_distance=10;space.region_3d.view_location=(0,0,1.4);space.region_3d.view_perspective='CAMERA'
report={'reopened_in_blender':bpy.app.version_string,'nonempty_finite_meshes':len(meshes),'invalid_meshes':invalid,'individual_teeth':len(bpy.data.collections['CP_Teeth'].objects),'reference_packed':bool(im.packed_file),'camera_animation':bool(s.camera.animation_data),'renders':[p.name for p in sorted((root/'renders').glob('0*.png'))]}
assert len(report['renders'])==8
(root/'validation.json').write_text(json.dumps(report,indent=2),encoding='utf8')
bpy.ops.wm.save_as_mainfile(filepath=str(root/'carnivorous_plant.blend'))
print('VALIDATION_OK',json.dumps(report))
