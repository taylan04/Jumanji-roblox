"""Geometria em metros de estudo; frente do portal = -Y; Z para cima."""
import math
import bpy
import bmesh
from mathutils import Vector

def collection(name, parent):
    c = bpy.data.collections.new(name)
    parent.children.link(c)
    return c

def mesh(name, verts, faces, coll, mat, bevel=0):
    data = bpy.data.meshes.new(name)
    data.from_pydata(verts, [], faces)
    data.update()
    bm = bmesh.new(); bm.from_mesh(data)
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    bm.to_mesh(data); bm.free()
    obj = bpy.data.objects.new(name, data); coll.objects.link(obj)
    if mat: data.materials.append(mat)
    # UV planar por face, em escala constante. Atlas final será uma etapa posterior.
    uv = data.uv_layers.new(name="UV_Meters")
    for face in data.polygons:
        normal = face.normal
        axis = max(range(3), key=lambda i: abs(normal[i]))
        axes = [i for i in range(3) if i != axis]
        for li in face.loop_indices:
            co = data.vertices[data.loops[li].vertex_index].co
            uv.data[li].uv = (co[axes[0]], co[axes[1]])
    if bevel:
        m = obj.modifiers.new("Arestas gastas", "BEVEL")
        m.width = bevel; m.segments = 1
        n = obj.modifiers.new("Normais", "WEIGHTED_NORMAL"); n.keep_sharp=True
    return obj

def prism(name, profile, front, back, coll, mat, bevel=0):
    # Perfil ordenado no plano XZ; normais recalculadas em mesh().
    n = len(profile)
    verts = [(x,y,z) for y in (front,back) for x,z in profile]
    faces = [tuple(range(n-1,-1,-1)), tuple(range(n,2*n))]
    faces += [(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
    return mesh(name,verts,faces,coll,mat,bevel)

def box(name, center, size, coll, mat, bevel=.025):
    x,y,z=center; w,d,h=size
    return prism(name,[(x-w/2,z-h/2),(x+w/2,z-h/2),(x+w/2,z+h/2),(x-w/2,z+h/2)],
                 y-d/2,y+d/2,coll,mat,bevel)

def tube(name, points, radius, coll, mat, closed=False, sides=8):
    pts=[Vector(p) for p in points]; verts=[]
    for i,p in enumerate(pts):
        prev=pts[(i-1)%len(pts)] if closed or i else pts[0]
        nex=pts[(i+1)%len(pts)] if closed or i<len(pts)-1 else pts[-1]
        tangent=(nex-prev).normalized()
        axis=Vector((0,1,0))
        if abs(tangent.dot(axis))>.95: axis=Vector((1,0,0))
        u=tangent.cross(axis).normalized(); v=tangent.cross(u).normalized()
        for j in range(sides):
            a=math.tau*j/sides
            verts.append(tuple(p+radius*(u*math.cos(a)+v*math.sin(a))))
    faces=[]
    for i in range(len(pts) if closed else len(pts)-1):
        for j in range(sides):
            faces.append((i*sides+j,i*sides+(j+1)%sides,((i+1)%len(pts))*sides+(j+1)%sides,((i+1)%len(pts))*sides+j))
    if not closed: faces += [tuple(range(sides-1,-1,-1)),tuple((len(pts)-1)*sides+j for j in range(sides))]
    obj=mesh(name,verts,faces,coll,mat)
    for f in obj.data.polygons: f.use_smooth=True
    return obj

def arch_z(x, radius, spring):
    return spring + math.sqrt(max(0,4*radius*radius-(abs(x)+radius)**2))

def arch(radius, spring, samples=40):
    return [(x,arch_z(x,radius,spring)) for x in [-radius+2*radius*i/samples for i in range(samples+1)]]

def arch_path(radius, spring, bottom=0, samples=40):
    return [(-radius,bottom)] + arch(radius,spring,samples) + [(radius,bottom)]

def ring(name, center, radius, section, coll, mat, segments=48):
    x,y,z=center
    return tube(name,[(x+radius*math.cos(i*math.tau/segments),y,z+radius*math.sin(i*math.tau/segments)) for i in range(segments)],section,coll,mat,True)

def empty(name, coll, location=(0,0,0)):
    o=bpy.data.objects.new(name,None); coll.objects.link(o); o.location=location
    return o

def parent_keep_world(obj,parent):
    obj.parent=parent
    obj.matrix_parent_inverse=parent.matrix_basis.inverted()



