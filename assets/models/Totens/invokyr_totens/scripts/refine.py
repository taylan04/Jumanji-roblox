import bpy,bmesh,math,pathlib,json
from mathutils import Vector,Matrix
R=pathlib.Path(__file__).resolve().parents[1]
bpy.ops.wm.open_mainfile(filepath=str(R/'Invokyr_Totens.blend'))
names=['01_Fogo','02_Gelo','03_Teleporte','04_Raio','05_Diamante_Raro']
# Restore the chiseled bridge that had rotated behind the mask shell.
raw=[Vector((.16*math.cos(i*2*math.pi/7),-.78+.16*math.sin(i*2*math.pi/7),2.52)) for i in range(7)]
raw += [Vector((.16*.68*math.cos(i*2*math.pi/7+.12),-.78+.16*.68*math.sin(i*2*math.pi/7+.12),2.52+.63*.55)) for i in range(7)]
raw += [Vector((0,-.78,3.15)),Vector((0,-.78,2.4))]
old=[Matrix.Rotation(-.12,3,'X')@v for v in raw]
for name in names:
    count=0
    for o in bpy.data.collections[name].objects:
        for v in o.data.vertices:
            for a,b in zip(old,raw):
                if (v.co-a).length<.0001:
                    v.co=b+Vector((0,-.13,0));count+=1;break
    assert count==16,(name,count)
# Replace the soft S-like stroke with a sharp lightning bolt.
c=bpy.data.collections['04_Raio'];mat=bpy.data.materials['04_Raio_Luminous']
for o in list(c.objects):
    if mat not in list(o.data.materials):continue
    bm=bmesh.new();bm.from_mesh(o.data)
    doomed=[v for v in bm.verts if v.co.z<1.4 and v.co.y<-.60]
    if doomed:bmesh.ops.delete(bm,geom=doomed,context='VERTS');bm.to_mesh(o.data)
    bm.free()
cu=bpy.data.curves.new('Lightning_angular','CURVE');cu.dimensions='3D';cu.bevel_depth=.03;cu.bevel_resolution=3;cu.use_fill_caps=True
sp=cu.splines.new('POLY');sp.points.add(3)
for b,p in zip(sp.points,[(.13,-.67,1.28),(-.13,-.67,1.03),(.12,-.67,1.03),(-.13,-.67,.77)]):b.co=(*p,1)
o=bpy.data.objects.new('04_Raio__Angular_sigil',cu);c.objects.link(o);cu.materials.append(mat);o.location.x=2.55
bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o;bpy.ops.object.convert(target='MESH')
bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.uv.smart_project(island_margin=.025);bpy.ops.object.mode_set(mode='OBJECT')
# Re-export only final revised geometry with embedded material maps.
stats={}
for i,name in enumerate(names):
    c=bpy.data.collections[name];x=(i-2)*2.55
    stats[name]={'objects':len(c.objects),'triangles':sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in c.objects),'max_mesh_triangles':max(sum(len(p.vertices)-2 for p in o.data.polygons) for o in c.objects)}
    bpy.ops.object.select_all(action='DESELECT')
    for o in c.objects:o.location.x-=x;o.select_set(True)
    bpy.ops.export_scene.gltf(filepath=str(R/'importar'/name/(name+'.gltf')),export_format='GLTF_SEPARATE',use_selection=True,export_yup=True,export_materials='EXPORT')
    for o in c.objects:o.location.x+=x
(R/'geometry.json').write_text(json.dumps(stats,indent=2))
bpy.ops.object.select_all(action='DESELECT')
bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(R/'Invokyr_Totens.blend'))
print('REFINED_OK',flush=True)
