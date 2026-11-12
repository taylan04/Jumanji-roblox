import bpy,pathlib,numpy as np
R=pathlib.Path(__file__).resolve().parents[1]
bpy.ops.wm.open_mainfile(filepath=str(R/'Invokyr_Totens.blend'))
s=bpy.context.scene
names=['01_Fogo','02_Gelo','03_Teleporte','04_Raio','05_Diamante_Raro']
for mat in bpy.data.materials:
    if not mat.node_tree:continue
    p=next((n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED'),None)
    if not p:continue
    for channel in ['Metallic','Roughness','Emission Color']:
        if p.inputs[channel].is_linked:continue
        value=p.inputs[channel].default_value
        if channel=='Emission Color':
            if p.inputs['Emission Strength'].default_value==0:continue
            rgba=tuple(value)
        else:rgba=(value,value,value,1)
        im=bpy.data.images.new(mat.name+'_'+channel.replace(' ','_'),width=16,height=16)
        im.colorspace_settings.name='Non-Color'
        im.pixels.foreach_set(np.tile(np.array(rgba,dtype=np.float32),256));im.pack()
        n=mat.node_tree.nodes.new('ShaderNodeTexImage');n.image=im
        mat.node_tree.links.new(n.outputs['Color'],p.inputs[channel])
for i,name in enumerate(names):
    c=bpy.data.collections[name];x=(i-2)*2.55
    bpy.ops.object.select_all(action='DESELECT')
    for o in c.objects:o.location.x-=x;o.select_set(True)
    bpy.ops.export_scene.gltf(filepath=str(R/'importar'/name/(name+'.gltf')),export_format='GLTF_SEPARATE',use_selection=True,export_yup=True,export_materials='EXPORT')
    for o in c.objects:o.location.x+=x
for screen in bpy.data.screens:
    for a in screen.areas:
        if a.type=='VIEW_3D':
            a.spaces.active.region_3d.view_perspective='CAMERA'
            a.spaces.active.shading.type='MATERIAL'
bpy.ops.object.select_all(action='DESELECT')
bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(R/'Invokyr_Totens.blend'))
print('MAPS_OK',flush=True)
