def material(name, dark, light, rough=0.5, scale=8, bump=0.15, wet=0, stretch=(1, 1, 1)):
    m = bpy.data.materials.new('AG_' + name)
    m.use_nodes = True
    n = m.node_tree.nodes
    n.clear()
    l = m.node_tree.links
    p = n.get('Principled BSDF') or n.new('ShaderNodeBsdfPrincipled')
    out = n.get('Material Output') or n.new('ShaderNodeOutputMaterial')
    l.new(p.outputs['BSDF'], out.inputs['Surface'])
    p.inputs['Roughness'].default_value = rough
    p.inputs['Coat Weight'].default_value = wet
    p.inputs['Coat Roughness'].default_value = 0.21
    tc = n.new('ShaderNodeTexCoord')
    mp = n.new('ShaderNodeVectorMath')
    mp.operation = 'MULTIPLY'
    mp.inputs[1].default_value = stretch
    l.new(tc.outputs['Generated'], mp.inputs[0])
    noise = n.new('ShaderNodeTexNoise')
    noise.inputs['Scale'].default_value = scale
    noise.inputs['Detail'].default_value = 5
    noise.inputs['Roughness'].default_value = 0.73
    l.new(mp.outputs[0], noise.inputs['Vector'])
    ramp = n.new('ShaderNodeValToRGB')
    ramp.color_ramp.elements[0].position = 0.22
    ramp.color_ramp.elements[0].color = (*dark, 1)
    ramp.color_ramp.elements[1].position = 0.8
    ramp.color_ramp.elements[1].color = (*light, 1)
    l.new(noise.outputs['Fac'], ramp.inputs[0])
    l.new(ramp.outputs[0], p.inputs['Base Color'])
    fine = n.new('ShaderNodeTexNoise')
    fine.inputs['Scale'].default_value = scale * 8
    fine.inputs['Detail'].default_value = 3
    l.new(mp.outputs[0], fine.inputs['Vector'])
    b = n.new('ShaderNodeBump')
    b.inputs['Strength'].default_value = bump
    b.inputs['Distance'].default_value = 0.07
    l.new(fine.outputs['Fac'], b.inputs['Height'])
    l.new(b.outputs[0], p.inputs['Normal'])
    m.diffuse_color = (*light, 1)
    return m

def mesh(name, v, f, mat, g):
    assert v and all((0 <= idx < len(v) for face in f for idx in face)), name
    me = bpy.data.meshes.new(name)
    me.from_pydata(v, [], f)
    me.update()
    ob = bpy.data.objects.new(name, me)
    G[g].objects.link(ob)
    me.materials.append(mat)
    for p in me.polygons:
        p.use_smooth = True
    return ob

def catmull(points, radii, steps):
    pts = [Vector(p) for p in points]
    out = []
    rs = []
    for k in range(len(pts) - 1):
        a = pts[max(0, k - 1)]
        b = pts[k]
        c = pts[k + 1]
        d = pts[min(len(pts) - 1, k + 2)]
        for j in range(steps):
            t = j / steps
            out.append(0.5 * (2 * b + (-a + c) * t + (2 * a - 5 * b + 4 * c - d) * t * t + (-a + 3 * b - 3 * c + d) * t * t * t))
            rs.append(radii[k] * (1 - t) + radii[k + 1] * t)
    out.append(pts[-1])
    rs.append(radii[-1])
    return (out, rs)

def tube(name, points, radii, mat, g, steps=7, sides=12, lobes=0, flat=1):
    pts, rs = catmull(points, radii, steps)
    v = []
    f = []
    last = None
    for i, (p, r) in enumerate(zip(pts, rs)):
        t = (pts[min(i + 1, len(pts) - 1)] - pts[max(i - 1, 0)]).normalized()
        up = Vector((0, 0, 1)) if abs(t.z) < 0.95 else Vector((0, 1, 0))
        u = t.cross(up).normalized() if last is None else (last - t * last.dot(t)).normalized()
        w = t.cross(u).normalized()
        last = u
        for j in range(sides):
            a = j * 2 * pi / sides
            rj = r * (1 + lobes * (0.65 * sin(5 * a + i * 0.09) + 0.35 * sin(9 * a - i * 0.1)))
            if lobes:
                rj *= 1 + 0.1 * organic_noise.noise_vector(p * 7 + Vector((cos(a), sin(a), 0)))[0]
            v.append(p + rj * (u * cos(a) + w * sin(a) * flat))
        if i:
            for j in range(sides):
                a = (i - 1) * sides + j
                b = (i - 1) * sides + (j + 1) % sides
                f.append((a, b, b + sides, a + sides))
    f.extend([tuple(reversed(range(sides))), tuple(((len(pts) - 1) * sides + j for j in range(sides)))])
    return mesh(name, v, f, mat, g)

def ellipsoid(name, center, size, mat, g, ribs=0, nu=64, nv=32):
    v = []
    f = []
    for i in range(nv + 1):
        t = pi * i / nv
        for j in range(nu):
            a = 2 * pi * j / nu
            fac = 1 + ribs * cos(10 * a) * sin(t) ** 2 + 0.012 * sin(23 * a + 7 * t)
            v.append((center[0] + size[0] * sin(t) * cos(a) * fac, center[1] + size[1] * sin(t) * sin(a) * fac, center[2] + size[2] * cos(t) * fac))
            if i:
                q = (i - 1) * nu + j
                b = (i - 1) * nu + (j + 1) % nu
                f.append((q, b, b + nu, q + nu))
    return mesh(name, v, f, mat, g)