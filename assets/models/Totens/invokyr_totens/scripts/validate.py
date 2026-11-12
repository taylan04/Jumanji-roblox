import bpy,json,pathlib,math
R=pathlib.Path(__file__).resolve().parents[1]
bpy.ops.wm.open_mainfile(filepath=str(R/'Invokyr_Totens.blend'))
expected=json.loads((R/'geometry.json').read_text())
report={'blend_reopened':True,'studio_import_tested':False,'assets':{}}
for name,stats in expected.items():
    c=bpy.data.collections[name]
    for o in c.objects:
        assert o.type=='MESH'
        assert o.data.uv_layers
        assert all(math.isfinite(x) for v in o.data.vertices for x in v.co)
        assert sum(len(p.vertices)-2 for p in o.data.polygons)<=20000
    f=R/'importar'/name/(name+'.gltf');data=json.loads(f.read_text())
    for x in data.get('buffers',[])+data.get('images',[]):
        if 'uri' in x:assert (f.parent/x['uri']).is_file(),x
    bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
    bpy.ops.import_scene.gltf(filepath=str(f))
    objects=[o for o in bpy.context.scene.objects if o.type=='MESH']
    tris=sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in objects)
    assert tris==stats['triangles'],(name,tris,stats)
    assert all(o.data.uv_layers for o in objects)
    assert all(sum(len(p.vertices)-2 for p in o.data.polygons)<=20000 for o in objects)
    report['assets'][name]={'gltf_reimported':True,'triangles':tris,'mesh_parts':len(objects),'all_textures_present':True,'uvs_present':True}
    # Reload master before inspecting next original collection.
    bpy.ops.wm.open_mainfile(filepath=str(R/'Invokyr_Totens.blend'))
(R/'validation.json').write_text(json.dumps(report,indent=2))
print('VALIDATION_OK',flush=True)
