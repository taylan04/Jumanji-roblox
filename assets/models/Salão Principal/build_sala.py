"""Torre do Tabuleiro V3 - melhora a sala do ChatGPT (torre_tabuleiro_v02.blend).
Mantem a arquitetura (paredes, portais, pilares, teto, estantes, luzes) e troca/adiciona:
hera, grama, musgo, raizes, vasos tombados, livros, mesa + tabuleiro novos, cadeiras, estandartes, teias, entulho.
"""
import bpy, math, random, sys, json
import numpy as np
from math import sin, cos, pi
from mathutils import Vector
random.seed(11); np.random.seed(11)
SRC = open('/tmp/work/build_v3.py').read()
def cut(a, b): return SRC[SRC.index(a):SRC.index(b)]
helpers = cut('def nrm(v)', '# ---------------------------------------------------------------- primitives')
exec(helpers, globals()); exec(cut('def tube(', 'def leaf('), globals()); exec(cut('def make(name)', 'def m_skin('), globals())
exec(cut('def m_bark(', 'def m_leaf('), globals())

bpy.ops.wm.open_mainfile(filepath='/tmp/sala/orig.blend')
scene = bpy.data.scenes['T02 | Torre do Tabuleiro']; bpy.context.window.scene = scene
class CM(dict):
    def __missing__(s, k): return s[k.split('#')[0]]
COLL = CM()
for k in ['Veg', 'Mesa', 'Props', 'Livros', 'Tecidos', 'Pedras']:
    c = bpy.data.collections.new('N3 | ' + {'Veg': 'Hera, grama e raizes', 'Mesa': 'Mesa e tabuleiro', 'Props': 'Cadeiras e vasos', 'Livros': 'Livros e paginas', 'Tecidos': 'Estandartes e teias', 'Pedras': 'Entulho e rachaduras'}[k])
    scene.collection.children.link(c); COLL[k] = c
_u = [0]
def U(base): _u[0] += 1; return '%s#%d' % (base, _u[0])

# --------------------------------------------------------------- limpar o que sera refeito
for n in ['VegetationAndLeafLitter', 'TableAndBoard']:
    if n in bpy.data.objects: bpy.data.objects.remove(bpy.data.objects[n], do_unlink=True)
for o in [o for o in scene.objects if o.name.startswith('Livro caído')]: bpy.data.objects.remove(o, do_unlink=True)

gm = lambda n: bpy.data.materials[n]
WOOD, WOOD2, BRONZE, IRON = gm('T02 | Carvalho 00'), gm('T02 | Carvalho 01'), gm('T02 | Bronze envelhecido'), gm('T02 | Ferro forjado')
FELT, WAX, FLAME, PAGES, CRYST = gm('T02 | Tabuleiro verde escuro'), gm('T02 | Cera'), gm('T02 | Chama âmbar'), gm('T02 | Páginas antigas'), gm('T02 | Pedra viva')
LEATH = [gm('T02 | Couro %d' % i) for i in range(5)]
STONE = [gm('T02 | Cantaria 0%d' % i) for i in range(5)]

# --------------------------------------------------------------- materiais novos
def m_ivy():
    m, nt = make('N3 | Hera'); p = base(nt)
    uvn = node(nt, 'ShaderNodeUVMap', uv_map='uv'); sep = node(nt, 'ShaderNodeSeparateXYZ'); link(nt, uvn.outputs[0], sep.inputs[0])
    ab = mth(nt, 'ABSOLUTE', mth(nt, 'SUBTRACT', sep.outputs['X'], .5))
    ph = mth(nt, 'SUBTRACT', mth(nt, 'MULTIPLY', ab, 2.2), mth(nt, 'MULTIPLY', sep.outputs['Y'], 6.))
    wave = mth(nt, 'POWER', mth(nt, 'ABSOLUTE', mth(nt, 'SINE', mth(nt, 'MULTIPLY', ph, 6.2832))), .4)
    rib = mth(nt, 'SUBTRACT', 1., mth(nt, 'MULTIPLY', ab, 9.), True)
    h = mth(nt, 'ADD', mth(nt, 'MULTIPLY', wave, .5), rib)
    col = cramp(nt, [(0, (.006, .022, .004, 1)), (.45, (.03, .10, .012, 1)), (.8, (.12, .20, .02, 1)), (.93, (.28, .20, .04, 1)), (1, (.12, .07, .02, 1))], attr(nt, 'tint'))
    vc = cramp(nt, [(0, (.8, .85, .6, 1)), (1, (1.1, 1.12, 1, 1))], wave)
    link(nt, mix(nt, 1., col, vc, 'MULTIPLY'), p.inputs['Base Color'])
    setp(p, Roughness=.38, Coat_Weight=.12, Coat_Roughness=.3, Subsurface_Weight=.1); bump(nt, h, .6, .02, p); return m
def m_dry():
    m, nt = make('N3 | Folha seca'); p = base(nt)
    col = cramp(nt, [(0, (.07, .03, .008, 1)), (.5, (.2, .10, .028, 1)), (1, (.32, .21, .06, 1))], attr(nt, 'tint'))
    link(nt, col, p.inputs['Base Color']); setp(p, Roughness=.7); return m
def m_grass():
    m, nt = make('N3 | Grama'); p = base(nt); o = tex(nt)
    n = node(nt, 'ShaderNodeTexNoise'); n.inputs['Scale'].default_value = .9; n.inputs['Detail'].default_value = 3; link(nt, o, n.inputs['Vector'])
    f = mth(nt, 'ADD', mth(nt, 'MULTIPLY', attr(nt, 'tint'), .75), mth(nt, 'MULTIPLY', n.outputs['Fac'], .35))
    col = cramp(nt, [(0, (.004, .014, .003, 1)), (.4, (.04, .11, .012, 1)), (.75, (.14, .2, .025, 1)), (1, (.30, .26, .06, 1))], f)
    link(nt, col, p.inputs['Base Color']); setp(p, Roughness=.55, Subsurface_Weight=.15); return m
def m_moss():
    m, nt = make('N3 | Musgo'); p = base(nt); o = tex(nt)
    n1 = node(nt, 'ShaderNodeTexNoise'); n1.inputs['Scale'].default_value = 5; n1.inputs['Detail'].default_value = 8; link(nt, o, n1.inputs['Vector'])
    n2 = node(nt, 'ShaderNodeTexNoise'); n2.inputs['Scale'].default_value = 70; n2.inputs['Detail'].default_value = 3; link(nt, o, n2.inputs['Vector'])
    link(nt, cramp(nt, [(.25, (.015, .04, .008, 1)), (.75, (.09, .17, .025, 1))], n1.outputs['Fac']), p.inputs['Base Color'])
    setp(p, Roughness=1., Sheen_Weight=.6, Sheen_Roughness=.4); bump(nt, n2.outputs['Fac'], 1.3, .03, p); return m
def m_simple(name, col, rough=.8, noise=True, **kw):
    m, nt = make(name); p = base(nt); o = tex(nt)
    if noise:
        n = node(nt, 'ShaderNodeTexNoise'); n.inputs['Scale'].default_value = 14; n.inputs['Detail'].default_value = 6; link(nt, o, n.inputs['Vector'])
        c2 = tuple(min(1, x * 1.7) for x in col[:3]) + (1,)
        link(nt, cramp(nt, [(.3, col), (.75, c2)], n.outputs['Fac']), p.inputs['Base Color']); bump(nt, n.outputs['Fac'], .5, .03, p)
    else: setp(p, Base_Color=col)
    setp(p, Roughness=rough, **kw); return m
def m_web():
    m, nt = make('N3 | Teia'); p = base(nt); setp(p, Base_Color=(.8, .8, .78, 1), Roughness=.6, Alpha=.28); return m
def m_glow(name, col, e=.9):
    m, nt = make(name); p = base(nt); setp(p, Base_Color=col, Roughness=.15, Coat_Weight=.6, Emission_Strength=e); p.inputs['Emission Color'].default_value = col; return m
def m_lacquer(name, col):
    m, nt = make(name); p = base(nt); setp(p, Base_Color=col, Roughness=.22, Coat_Weight=.7, Coat_Roughness=.08); return m

M_IVY, M_DRY, M_GRASS, M_MOSS = m_ivy(), m_dry(), m_grass(), m_moss()
M_STEM = m_bark('N3 | Caule', (.03, .02, .008, 1), (.2, .14, .06, 1), moss=(.05, .1, .015, 1))
M_ROOT = m_bark('N3 | Raiz', (.05, .032, .015, 1), (.28, .2, .09, 1), moss=(.05, .1, .015, 1))
M_SOIL = m_simple('N3 | Terra', (.02, .012, .006, 1), 1.)
M_CLAY = m_simple('N3 | Barro', (.28, .10, .045, 1), .7)
M_CLOTH = m_simple('N3 | Pano', (.13, .016, .016, 1), 1., Sheen_Weight=.5)
M_CRACK = m_simple('N3 | Rachadura', (.004, .003, .002, 1), 1., noise=False)
M_WEB = m_web()
PIECE = [m_lacquer('N3 | Peça vermelha', (.45, .02, .02, 1)), m_lacquer('N3 | Peça azul', (.03, .08, .5, 1)),
         m_lacquer('N3 | Peça verde', (.03, .3, .06, 1)), m_lacquer('N3 | Peça dourada', (.7, .45, .06, 1))]
GEM = [m_glow('N3 | Gema vermelha', (.9, .03, .03, 1)), m_glow('N3 | Gema azul', (.05, .2, 1., 1)),
       m_glow('N3 | Gema verde', (.05, .9, .15, 1)), m_glow('N3 | Gema dourada', (1., .6, .08, 1))]
M_CRYST = m_glow('N3 | Cristal', (.2, 1., .45, 1), 1.3)
IVORY = m_lacquer('N3 | Marfim', (.7, .62, .42, 1))

# envelhecimento da pedra: musgo e sujeira subindo do chao (coordenadas de mundo)
def grime(mat):
    nt = mat.node_tree; p = [n for n in nt.nodes if n.bl_idname == 'ShaderNodeBsdfPrincipled'][0]; inp = p.inputs['Base Color']
    if inp.links: src = inp.links[0].from_socket
    else:
        r = node(nt, 'ShaderNodeRGB'); r.outputs[0].default_value = inp.default_value; src = r.outputs[0]
    pos = node(nt, 'ShaderNodeNewGeometry').outputs['Position']
    sep = node(nt, 'ShaderNodeSeparateXYZ'); link(nt, pos, sep.inputs[0])
    n1 = node(nt, 'ShaderNodeTexNoise'); n1.inputs['Scale'].default_value = .38; n1.inputs['Detail'].default_value = 5; link(nt, pos, n1.inputs['Vector'])
    n2 = node(nt, 'ShaderNodeTexNoise'); n2.inputs['Scale'].default_value = 3.; n2.inputs['Detail'].default_value = 7; link(nt, pos, n2.inputs['Vector'])
    zc = mth(nt, 'MULTIPLY', sep.outputs['Z'], .22)
    h = mth(nt, 'SUBTRACT', 1., zc, True)
    m = mth(nt, 'SUBTRACT', mth(nt, 'ADD', mth(nt, 'MULTIPLY', n1.outputs['Fac'], 1.6), mth(nt, 'MULTIPLY', h, .62)), .88)
    m = mth(nt, 'MULTIPLY', mth(nt, 'MULTIPLY', m, 3.), mth(nt, 'ADD', n2.outputs['Fac'], .4), True)
    dirt = cramp(nt, [(0, (.42, .40, .36, 1)), (1, (1, 1, 1, 1))], mth(nt, 'MULTIPLY', sep.outputs['Z'], .2, True))
    c = mix(nt, 1., src, dirt, 'MULTIPLY')
    moss = cramp(nt, [(.3, (.012, .03, .006, 1)), (.8, (.07, .14, .02, 1))], n2.outputs['Fac'])
    link(nt, mix(nt, m, c, moss), p.inputs['Base Color'])
for mt in list(bpy.data.materials):
    if mt.node_tree and mt.name.startswith(('T02 | Cantaria', 'T01 | Cantaria', 'T02 | Calcário', 'T01 | Calcário', 'JUM • Pedra', 'T02 | Juntas', 'T01 | Juntas')):
        grime(mt)

# --------------------------------------------------------------- geometria auxiliar
def Rz(a): c, s = cos(a), sin(a); return np.array([[c, -s, 0], [s, c, 0], [0, 0, 1.]])
def Rx(a): c, s = cos(a), sin(a); return np.array([[1, 0, 0], [0, c, -s], [0, s, c]])
def Ry(a): c, s = cos(a), sin(a); return np.array([[c, 0, s], [0, 1, 0], [-s, 0, c]])
def bev(key, mat, w=.012):
    MODS[(key, mat.name)] = [('split', 'EDGE_SPLIT', {'split_angle': .7}), ('bev', 'BEVEL', {'width': w, 'segments': 2, 'limit_method': 'ANGLE'})]
def box(key, mat, c, s, R=None):
    x, y, z = [v / 2 for v in s]
    V = np.array([[-x, -y, -z], [x, -y, -z], [x, y, -z], [-x, y, -z], [-x, -y, z], [x, -y, z], [x, y, z], [-x, y, z]])
    if R is not None: V = V @ R.T
    V = V + np.asarray(c, float)
    add(batch(key, mat), V, [[0, 3, 2, 1], [4, 5, 6, 7], [0, 1, 5, 4], [1, 2, 6, 5], [2, 3, 7, 6], [3, 0, 4, 7]])
def lathe_geo(profile, seg=48):
    pr = np.array(profile, float); ang = np.linspace(0, 2 * pi, seg, endpoint=False)
    return np.stack([pr[:, 0:1] * np.cos(ang)[None, :], pr[:, 0:1] * np.sin(ang)[None, :], np.repeat(pr[:, 1:2], seg, 1)], -1)
def lathe(key, mat, profile, seg=48, R=None, t=(0, 0, 0)):
    P = lathe_geo(profile, seg)
    if R is not None: P = P @ R.T
    grid(key, mat, P + np.asarray(t, float), closed_u=True)
def place(key, R=None, t=(0, 0, 0), settle=False):
    arrs = [b for (cn, mn), (b, m, c) in BATCH.items() if cn == key]
    for b in arrs:
        for i, v in enumerate(b.v):
            if R is not None: v = v @ R.T
            b.v[i] = v + np.asarray(t, float)
    if settle:
        mn = min(v[:, 2].min() for b in arrs for v in b.v)
        for b in arrs:
            for i, v in enumerate(b.v): b.v[i] = v + np.array([0, 0, .015 - mn])
def jag(n, a=.2): return 1 + np.random.uniform(-a, a, n)
def rock(key, mat, c, size, flat=.6):
    nu, nv = 9, 6; th = np.linspace(.05, pi - .05, nv)[:, None]; ph = np.linspace(0, 2 * pi, nu, endpoint=False)[None, :]
    j = np.random.uniform(.72, 1.28, (nv, nu))
    P = np.stack([np.sin(th) * np.cos(ph), np.sin(th) * np.sin(ph), np.cos(th) * flat + 0 * ph], -1) * j[..., None] * np.asarray(size) + np.asarray(c)
    grid(key, mat, P, closed_u=True)

# folha de hera (3 lobos)
RS = np.array([(0, 0), (.22, -.04), (.46, .03), (.62, .17), (.46, .27), (.56, .44), (.36, .52), (.2, .72), (0, 1.)])
OUT2D = np.vstack([RS, RS[-2:0:-1] * [-1, 1]]); N_O = len(OUT2D)
IN2D = (OUT2D - [0, .45]) * .5 + [0, .45]
def ivy_leaf(key, mat, o, d, n, size, tint):
    d = nrm(d); n = nrm(n - d * np.dot(n, d)); lat = np.cross(d, n)
    def mk(P2, z0): return np.asarray(o) + size * (P2[:, 0:1] * lat + P2[:, 1:2] * d + (z0 - .22 * P2[:, 1] ** 2)[:, None] * n)
    V = np.vstack([mk(OUT2D, np.zeros(N_O)), mk(IN2D, np.full(N_O, .09)), mk(np.array([[0, .45]]), np.array([.12]))])
    UVp = np.vstack([OUT2D, IN2D, [[0, .45]]]); uv = np.stack([np.clip(UVp[:, 0] / .62 * .5 + .5, 0, 1), UVp[:, 1]], 1)
    Q = [[i, (i + 1) % N_O, N_O + (i + 1) % N_O, N_O + i] for i in range(N_O)]; T = [[N_O + i, N_O + (i + 1) % N_O, 2 * N_O] for i in range(N_O)]
    add(batch(key, mat), V, Q, T, uv, tint)
def rtint(): return random.uniform(.93, 1.) if random.random() < .07 else random.uniform(0, .78)

def vine(pts, radii, normal_fn, size=(.38, .62), step=.42, hang=False):
    tube('Veg', M_STEM, pts, radii, 6, 3, .15)
    C, Rr = catmull(pts, 5, radii); acc = 0
    for i in range(1, len(C) - 1):
        acc += np.linalg.norm(C[i] - C[i - 1])
        if acc < step: continue
        acc = 0; T = nrm(C[i + 1] - C[i - 1]); n = normal_fn(C[i]); lat = nrm(np.cross(T, n))
        for _ in range(random.choice([1, 2, 2])):
            if hang: d = nrm(A(0, 0, -1) * .7 + lat * rnd(-.6, .6) + n * rnd(.0, .3))
            else: d = nrm(T * .5 + lat * rnd(-1, 1) + A(0, 0, .3))
            n2 = nrm(n + lat * rnd(-.3, .3) + T * rnd(-.2, .4))
            ivy_leaf('Veg', M_IVY, C[i] + n * (Rr[i] + .01), d, n2, rnd(*size), rtint())

def blade(base, d, height, width, curl):
    d = np.asarray(d); side = np.array([-d[1], d[0], 0.]); V = []; tint = []
    for i, t in enumerate([0, .34, .68, 1.]):
        c = base + np.array([0, 0, height * t * (1 - .35 * t * t)]) + np.array([d[0], d[1], 0]) * curl * height * t * t
        if i < 3: w = width * (1 - t) ** .8; V += [c - side * w, c + side * w]; tint += [t, t]
        else: V.append(c); tint.append(1.)
    add(batch('Veg', M_GRASS), V, [[0, 1, 3, 2], [2, 3, 5, 4]], [[4, 5, 6]], None, tint)
def clump(c, scale=1.):
    for _ in range(random.randint(9, 17)):
        a = rnd(0, 2 * pi); r = rnd(0, .28) * scale; b = A(c[0] + r * cos(a), c[1] + r * sin(a), 0.)
        d = A(cos(a + rnd(-.8, .8)), sin(a + rnd(-.8, .8)), 0)
        blade(b, d, rnd(.5, 1.5) * scale, rnd(.035, .08), rnd(.2, .8))
def frond(base, dh, L, droop):
    dh = nrm(dh); side = nrm(np.cross(dh, A(0, 0, 1))); sp = lambda t: base + dh * L * t * .95 + A(0, 0, L * (.9 * t - (.5 + droop) * t * t))
    n = 15
    for i in range(1, n):
        t = i / n; p = sp(t); T = nrm(sp(t + .02) - sp(t - .02)); ll = L * (.26 * sin(pi * t) ** .7 + .03)
        for sg in (-1, 1):
            tip = p + sg * side * ll * .85 + T * ll * .5 - A(0, 0, ll * .18)
            mid = (p + tip) / 2; up = A(0, 0, ll * .12)
            add(batch('Veg', M_IVY), [p, mid + up, tip, mid - up], [[0, 1, 2, 3]], None, [[0, 0], [.5, .5], [.5, 1], [.5, .5]], random.uniform(.2, .6))
def fern(c, nf=9, s=1.):
    for k in range(nf):
        a = 2 * pi * k / nf + rnd(-.3, .3); frond(A(c[0], c[1], .05), A(cos(a), sin(a), 0), rnd(1.6, 2.8) * s, rnd(0, .5))

APO = 14.04
PILLARS = [(-6, -6), (6, -6), (6, 6), (-6, 6)]
PZ = [0, 1.5, 3, 17, 18, 19.5]; PR = [2.15, 1.7, 1.0, 1.0, 1.55, 2.1]
def wall_pt(c, s, inward, z):
    n = A(cos(c), sin(c)); t = A(-sin(c), cos(c)); p = n * (APO - inward) + t * s; return A(p[0], p[1], z)

# --------------------------------------------------------------- HERA nos pilares
for (px, py) in PILLARS:
    for k in range(8):
        a0 = rnd(0, 2 * pi); turns = rnd(.16, .34) * (1 if k % 2 else -1); z0 = rnd(.2, 1.2); z1 = rnd(9, 18.5); N = int((z1 - z0) / .8) + 3; pts = []; rad = []
        for i in range(N):
            z = z0 + (z1 - z0) * i / (N - 1); a = a0 + turns * (z - z0) + .25 * sin(z * 1.3 + k); r = np.interp(z, PZ, PR) + .05
            pts.append((px + r * cos(a), py + r * sin(a), z)); rad.append(.085 * (1 - .6 * i / N) + .02)
        vine(pts, rad, lambda p, px=px, py=py: nrm(A(p[0] - px, p[1] - py, 0)))
    # trepadeiras caindo do capitel
    for k in range(6):
        a = rnd(0, 2 * pi); z1 = 19.2; pts = []; rad = []; L = rnd(5, 10)
        for i in range(7):
            t = i / 6; r = 2.0 + .3 * sin(t * 3 + k); aa = a + .25 * sin(t * 4 + k)
            pts.append((px + r * cos(aa), py + r * sin(aa), z1 - L * t)); rad.append(.05 * (1 - .6 * t) + .015)
        vine(pts, rad, lambda p: nrm(A(rnd(-1, 1), rnd(-1, 1), .1)), (.35, .55), .4, hang=True)
# --------------------------------------------------------------- HERA nas paredes
for w in range(8):
    c = w * pi / 4; card = (w % 2 == 0); ninward = A(-cos(c), -sin(c), 0)
    for k in range(5):
        for _ in range(20):
            s0 = rnd(-5.4, 5.4)
            if abs(s0) > (3.6 if card else 2.9): break
        H = rnd(6, 16); N = int(H / .8) + 3; ph = rnd(0, 6); pts = []; rad = []
        for i in range(N):
            z = H * i / (N - 1); s = s0 + 1.1 * sin(z * .5 + ph) + .3 * sin(z * 1.3)
            pts.append(wall_pt(c, s, .06, z)); rad.append(.09 * (1 - .6 * i / N) + .02)
        vine(pts, rad, lambda p, nn=ninward: nn)
# --------------------------------------------------------------- RACHADURAS + GRAMA + MUSGO
def floor_ok(x, y): return math.hypot(x, y) > 3.7 and math.hypot(x, y) < 13.6
cracks = []
for k in range(22):
    for _ in range(30):
        r = rnd(4.5, 12.5); a = rnd(0, 2 * pi); x, y = r * cos(a), r * sin(a)
        if floor_ok(x, y): break
    h = rnd(0, 2 * pi); pts = []
    for i in range(8):
        pts.append((x, y, .012)); h += rnd(-.5, .5); st = rnd(.7, 1.1); x += st * cos(h); y += st * sin(h)
        if not floor_ok(x, y): break
    if len(pts) >= 3:
        tube('Pedras', M_CRACK, pts, [.05 + .04 * sin(i) ** 2 for i in range(len(pts))], 4, 2, 0, flat=.12); cracks.append(pts)
spots = []
for pts in cracks:
    for p in pts[::1]:
        if random.random() < .6: spots.append((p[0] + rnd(-.3, .3), p[1] + rnd(-.3, .3)))
for (px, py) in PILLARS:
    for _ in range(40):
        a = rnd(0, 2 * pi); r = rnd(2.4, 3.8); spots.append((px + r * cos(a), py + r * sin(a)))
for _ in range(220):
    a = rnd(0, 2 * pi); r = rnd(12.3, 13.8); spots.append((r * cos(a), r * sin(a)))
for _ in range(170):
    a = rnd(0, 2 * pi); r = rnd(4.4, 12.5); spots.append((r * cos(a), r * sin(a)))
ng = 0
for (x, y) in spots:
    if math.hypot(x, y) < 3.7: continue
    clump((x, y), rnd(.7, 1.3)); ng += 1
    if random.random() < .5:
        for _ in range(random.randint(2, 4)): rock('Veg', M_MOSS, (x + rnd(-.5, .5), y + rnd(-.5, .5), 0), (rnd(.3, .9), rnd(.3, .9), rnd(.12, .25)), 1.)
for (px, py) in PILLARS:
    for k in range(3):
        a = rnd(0, 2 * pi); fern((px + 3.0 * cos(a), py + 3.0 * sin(a)), random.randint(8, 11), rnd(.8, 1.2))
for _ in range(7):
    a = rnd(0, 2 * pi); r = rnd(11.5, 13.3); fern((r * cos(a), r * sin(a)), 9, rnd(.8, 1.3))
# folhas secas
for _ in range(650):
    a = rnd(0, 2 * pi); r = rnd(3.6, 13.6); sz = rnd(.22, .45)
    ivy_leaf('Veg', M_DRY, A(r * cos(a), r * sin(a), .02 + rnd(0, .03)), A(cos(rnd(0, 6.28)), sin(rnd(0, 6.28)), 0), A(rnd(-.1, .1), rnd(-.1, .1), 1), sz, random.random())
# --------------------------------------------------------------- RAIZES
for k in range(7):
    c = rnd(0, 2 * pi); s = rnd(-5, 5)
    p0 = wall_pt(c, s, -.1, rnd(2, 5)); pts = [p0]
    for i in range(1, 7):
        q = p0 + (A(-cos(c), -sin(c), 0) * i * rnd(.7, 1.1) + A(rnd(-.4, .4), rnd(-.4, .4), 0)); q[2] = max(.12, p0[2] * (1 - i / 3.2)) if i < 4 else .1 + .04 * sin(i); pts.append(q)
    rd = [.42, .38, .32, .26, .2, .12, .04]
    tube('Veg', M_ROOT, pts, rd, 9, 4, .22, twist=.15)
    for br in range(2):
        q = pts[3 + br]; d = A(rnd(-1, 1), rnd(-1, 1), 0); d = nrm(d)
        tube('Veg', M_ROOT, [q, q + d * .6 + A(0, 0, .02), q + d * 1.3, q + d * 2.0], [rd[3 + br] * .6, rd[3 + br] * .4, .08, .02], 7, 3, .2)
# --------------------------------------------------------------- MESA + TABULEIRO
ZT = 2.7
k = U('Mesa')
lathe(k, WOOD, [(0, ZT), (3.0, ZT), (3.18, ZT - .02), (3.3, ZT - .08), (3.34, ZT - .2), (3.3, ZT - .3), (3.0, ZT - .36), (2.6, ZT - .4), (0, ZT - .4)], 72)
lathe(U('Mesa'), WOOD2, [(2.45, ZT - .4), (2.58, ZT - .5), (2.6, ZT - .8), (2.45, ZT - .9)], 48)
lathe(U('Mesa'), WOOD, [(0, ZT - .4), (.95, ZT - .4), (.7, ZT - .5), (.56, ZT - .7), (.56, 1.7), (.82, 1.55), (.56, 1.4), (.5, 1.1), (.72, .9), (.5, .7), (.64, .45), (1.2, .35), (1.6, .22), (1.75, .1), (1.75, 0), (0, 0)], 48)
for i in range(4):
    a = i * pi / 2 + pi / 4; d = A(cos(a), sin(a), 0)
    tube(U('Mesa'), WOOD, [d * .9 + A(0, 0, .75), d * 1.7 + A(0, 0, .52), d * 2.4 + A(0, 0, .22), d * 2.75 + A(0, 0, .12)], [.28, .24, .21, .2], 12, 4, .08)
    kk = U('Mesa'); ellipsoid(kk, WOOD, d * 2.8 + A(0, 0, .22), (.3, .3, .25), 16, 10)
    for j in (-1, 0, 1):
        dd = nrm(d + A(-d[1], d[0], 0) * j * .5); tube(U('Mesa'), WOOD2, [d * 2.8 + A(0, 0, .15), d * 2.8 + dd * .25 + A(0, 0, .08), d * 2.8 + dd * .5 + A(0, 0, .02)], [.1, .08, .03], 8, 3)
for i in range(16):
    a = i * 2 * pi / 16; ellipsoid(U('Mesa'), BRONZE, A(3.3 * cos(a), 3.3 * sin(a), ZT - .2), (.1, .1, .1), 10, 7)
ring = [(3.05 * cos(a), 3.05 * sin(a), ZT + .012) for a in np.linspace(0, 2 * pi, 73)]
tube(U('Mesa'), BRONZE, ring, [.035] * 73, 6, 1)
lathe(U('Mesa'), FELT, [(0, ZT + .055), (2.5, ZT + .055), (2.62, ZT + .045), (2.62, ZT), (0, ZT)], 72)
lathe(U('Mesa'), WOOD2, [(2.5, ZT + .06), (2.62, ZT + .08), (2.82, ZT + .07), (2.9, ZT + .035), (2.9, ZT), (2.5, ZT)], 72)
for r_ in (1.05, 1.75, 2.45):
    tube(U('Mesa'), BRONZE, [(r_ * cos(a), r_ * sin(a), ZT + .062) for a in np.linspace(0, 2 * pi, 73)], [.018] * 73, 6, 1)
kl, kd = U('Mesa'), U('Mesa')
for i in range(48):
    a = i * 2 * pi / 48; box(kl if i % 2 else kd, STONE[0] if i % 2 else IRON, A(2.1 * cos(a), 2.1 * sin(a), ZT + .085), (.34, .22, .05), Rz(a))
for i in range(4):
    a = i * pi / 2 + pi / 4; c = A(1.5 * cos(a), 1.5 * sin(a), ZT + .055)
    lathe(U('Mesa'), BRONZE, [(0, .16), (.16, .12), (.2, .04), (.28, 0), (0, 0)], 20, None, c)
    kg = U('Mesa'); ellipsoid(kg, GEM[i], c + A(0, 0, .26), (.17, .17, .2), 8, 6); MODS[(kg, GEM[i].name)] = [('split', 'EDGE_SPLIT', {'split_angle': .35})]
    for j in range(3):
        b = a + (j - 1) * .09 + rnd(-.02, .02); pr = [(0, .5), (.09, .46), (.11, .38), (.06, .3), (.1, .22), (.19, .05), (.2, 0), (0, 0)]
        pc = A(2.1 * cos(b), 2.1 * sin(b), ZT + .11) if j == 1 else A(1.0 * cos(b + j * .25), 1.0 * sin(b + j * .25), ZT + .06)
        lathe(U('Mesa'), PIECE[i], [(r * .85, z * .85) for r, z in pr], 18, None, pc)
        ellipsoid(U('Mesa'), PIECE[i], pc + A(0, 0, .5 * .85 + .06), (.1, .1, .1), 12, 8)
lathe(U('Mesa'), BRONZE, [(0, ZT + .06), (.6, ZT + .06), (.5, ZT + .12), (.32, ZT + .3), (.26, ZT + .46), (.4, ZT + .5), (0, ZT + .5)], 32)
kcr = U('Mesa'); ellipsoid(kcr, M_CRYST, A(0, 0, ZT + .9), (.24, .24, .46), 6, 5); MODS[(kcr, M_CRYST.name)] = [('split', 'EDGE_SPLIT', {'split_angle': .35})]
# adereços da mesa
def at_table(r, ang): return A(r * cos(ang), r * sin(ang), ZT)
kc = U('Mesa'); pc = at_table(3.0, radians := math.radians(250))
lathe(kc, BRONZE, [(0, 0), (.3, 0), (.34, .03), (.26, .06), (.1, .07), (.1, .1), (0, .1)], 24, None, pc)
lathe(U('Mesa'), WAX, [(0, .1), (.1, .1), (.09, .55), (.07, .6), (0, .6)], 18, None, pc)
ellipsoid(U('Mesa'), FLAME, pc + A(0, 0, .72), (.055, .055, .13), 10, 8)
for j in range(4): ellipsoid(U('Mesa'), WAX, pc + A(.1 * cos(j * 1.6), .1 * sin(j * 1.6), .18 + .08 * j), (.03, .03, .08), 8, 6)
CANDLE = pc + A(0, 0, .72)
lathe(U('Mesa'), BRONZE, [(0, 0), (.16, 0), (.18, .03), (.05, .1), (.05, .3), (.2, .36), (.22, .62), (.19, .64), (.0, .55)], 28, None, at_table(3.0, math.radians(160)))
kb = U('Livros')
for i in range(3):
    w, l = rnd(.45, .55), rnd(.65, .8); t = rnd(.1, .17); cv = LEATH[(i * 2) % 5]; z = ZT + sum([.13] * i)
    a = math.radians(20) + rnd(-.2, .2); c = at_table(2.95, math.radians(20)); k2 = U('Livros')
    box(k2, cv, (0, 0, .015), (w, l, .03)); box(k2, cv, (0, 0, t - .015), (w, l, .03)); box(k2, cv, (-w / 2 + .02, 0, t / 2), (.04, l, t)); box(k2, PAGES, (.02, 0, t / 2), (w - .06, l - .04, t - .06))
    for mm in (cv, PAGES): bev(k2, mm)
    place(k2, Rz(a), c + A(0, 0, z - ZT))
for i in range(5):
    a = math.radians(105) + (i - 2) * .17; k2 = U('Livros'); box(k2, PAGES, (0, 0, 0), (.38, .6, .01)); bev(k2, PAGES, .004)
    place(k2, Rz(a + pi / 2), at_table(2.95, a) + A(0, 0, .012))
for i in range(2):
    k2 = U('Livros'); box(k2, IVORY, (0, 0, 0), (.24, .24, .24)); bev(k2, IVORY, .03); place(k2, Rz(rnd(0, 6)) @ Rx(rnd(0, 1)), at_table(2.4 + i * .5, math.radians(-30) + i * .4) + A(0, 0, .12 + .06))
# --------------------------------------------------------------- CADEIRAS
def chair(theta, toppled):
    k2 = U('Props'); h = 1.5
    for sx in (-1, 1):
        for sy in (-1, 1):
            tube(k2, WOOD, [(sx * .65, sy * .65, 0), (sx * .65, sy * .65, h)], [.1, .085], 8, 1)
    box(k2, WOOD2, (0, 0, h + .07), (1.5, 1.5, .14))
    for sx in (-1, 1): tube(k2, WOOD, [(sx * .65, -.65, h), (sx * .65, -.65, 2.9), (sx * .62, -.68, 3.45)], [.09, .08, .1], 8, 3)
    box(k2, WOOD2, (0, -.66, 3.3), (1.4, .1, .22))
    for j in (-1, 0, 1): box(k2, WOOD, (j * .36, -.66, 2.35), (.16, .07, 1.5))
    box(k2, WOOD2, (0, -.65, 1.0), (1.3, .06, .08)); box(k2, WOOD2, (0, .65, 1.0), (1.3, .06, .08))
    bev(k2, WOOD, .02); bev(k2, WOOD2, .02)
    yaw = theta + pi / 2; c = A(4.9 * cos(theta), 4.9 * sin(theta), 0)
    if toppled: place(k2, Rz(yaw + rnd(-.4, .4)) @ Rx(-1.45), c, settle=True)
    else: place(k2, Rz(yaw + rnd(-.1, .1)), c)
for i, th in enumerate([30, 120, 210, 300]): chair(math.radians(th), i in (1, 3))
# --------------------------------------------------------------- VASOS TOMBADOS + SAMAMBAIAS
for (px, py, ang) in [(-4.0, -4.3, 1.0), (4.1, 4.9, 3.6), (7.6, -4.6, 5.2)]:
    s = rnd(.9, 1.15); yaw = ang
    prof = [(0, 0), (.6, 0), (.72, .12), (.92, .65), (1., 1.05), (1.04, 1.2), (1.02, 1.3), (.92, 1.3), (.88, 1.22), (.82, 1.1), (.7, .3), (0, .25)]
    P = lathe_geo([(r * s, z * s) for r, z in prof], 36); R = Rz(yaw) @ Rx(pi / 2 - .12)
    sh = P.shape; Pw = P.reshape(-1, 3) @ R.T; dz = -Pw[:, 2].min() + .01; t = A(px, py, dz)
    grid(U('Props'), M_CLAY, (Pw + t).reshape(sh), closed_u=True)
    mouth = R @ A(0, 0, 1.25 * s) + t; out = nrm(R @ A(0, 0, 1) * A(1, 1, 0))
    for j in range(5): rock('Veg', M_SOIL, mouth + out * (.3 + .35 * j) + A(rnd(-.4, .4), rnd(-.4, .4), -mouth[2]), (rnd(.5, .8), rnd(.4, .7), .12), 1.)
    for j in range(10):
        a = math.atan2(out[1], out[0]) + rnd(-1.2, 1.2); frond(A(mouth[0] + out[0] * .5, mouth[1] + out[1] * .5, .1), A(cos(a), sin(a), 0), rnd(1.4, 2.4), rnd(0, .5))
    clump((mouth[0] + out[0] * 1.2, mouth[1] + out[1] * 1.2), 1.2)
# --------------------------------------------------------------- LIVROS pelo chao
def book(pos, yaw, tilt=0.):
    w, l, t = rnd(.38, .55), rnd(.55, .8), rnd(.09, .2); cv = random.choice(LEATH); k2 = U('Livros')
    box(k2, cv, (0, 0, .015), (w, l, .03)); box(k2, cv, (0, 0, t - .015), (w, l, .03)); box(k2, cv, (-w / 2 + .02, 0, t / 2), (.04, l, t)); box(k2, PAGES, (.02, 0, t / 2), (w - .06, l - .04, t - .06))
    for mm in (cv, PAGES): bev(k2, mm)
    place(k2, Rz(yaw) @ Rx(tilt), pos); return t
def open_book(pos, yaw):
    k2 = U('Livros'); cv = random.choice(LEATH); w, l = rnd(.4, .5), rnd(.6, .75)
    for sg in (-1, 1):
        box(k2, cv, (sg * w / 2 * .98, 0, .04), (w, l, .03), Ry(-sg * .16)); box(k2, PAGES, (sg * w / 2 * .98, 0, .075), (w - .05, l - .05, .05), Ry(-sg * .16))
    bev(k2, cv); bev(k2, PAGES); place(k2, Rz(yaw), pos)
for ci in range(4):
    ca = pi / 4 + ci * pi / 2
    for pile in range(3):
        lat = rnd(-2.4, 2.4); r = rnd(11.7, 12.9); base = A(r * cos(ca) - lat * sin(ca), r * sin(ca) + lat * cos(ca), 0); z = 0
        for b in range(random.randint(3, 6)): z += book(base + A(rnd(-.06, .06), rnd(-.06, .06), z), rnd(0, 3.14)) * .95
    for _ in range(9):
        lat = rnd(-3.2, 3.2); r = rnd(8.5, 12.4); book(A(r * cos(ca) - lat * sin(ca), r * sin(ca) + lat * cos(ca), 0), rnd(0, 6.28))
    for _ in range(2): open_book(A((rnd(9, 12)) * cos(ca) - rnd(-2, 2) * sin(ca), rnd(9, 12) * sin(ca) + rnd(-2, 2) * cos(ca), 0), rnd(0, 6.28))
for _ in range(22):
    a = rnd(0, 2 * pi); r = rnd(4.4, 11.5); book(A(r * cos(a), r * sin(a), 0), rnd(0, 6.28))
for _ in range(5):
    a = rnd(0, 2 * pi); r = rnd(4.6, 9); open_book(A(r * cos(a), r * sin(a), 0), rnd(0, 6.28))
for _ in range(45):
    a = rnd(0, 2 * pi); r = rnd(4.2, 12.6); k2 = U('Livros'); ph = rnd(0, 6)
    xs = np.linspace(-.25, .25, 6); ys = np.linspace(-.35, .35, 6); X, Y = np.meshgrid(xs, ys)
    Z = .035 * np.sin(X * 8 + ph) + .05 * np.abs(Y) ** 2 * 3 + .02
    grid(k2, PAGES, np.stack([X, Y, Z], -1)); place(k2, Rz(rnd(0, 6.28)), A(r * cos(a), r * sin(a), 0))
# --------------------------------------------------------------- ENTULHO (pedras caidas)
for _ in range(110):
    for _ in range(20):
        a = rnd(0, 2 * pi); r = rnd(3.9, 13.4)
        if math.hypot(r * cos(a) - 0, r * sin(a)) > 3.8: break
    rock('Pedras', random.choice(STONE), (r * cos(a), r * sin(a), 0), (rnd(.12, .5), rnd(.12, .5), rnd(.1, .3)))
for _ in range(9):
    a = rnd(0, 2 * pi); r = rnd(5, 12); k2 = U('Pedras'); box(k2, random.choice(STONE), (0, 0, 0), (rnd(1., 1.8), rnd(.7, 1.3), .22)); bev(k2, STONE[0], .03)
    place(k2, Rz(rnd(0, 6.28)) @ Rx(rnd(-.18, .18)) @ Ry(rnd(-.18, .18)), A(r * cos(a), r * sin(a), .14))
# --------------------------------------------------------------- ESTANDARTES RASGADOS + TEIAS
for w in range(8):
    if w % 2 == 0: continue
    c = w * pi / 4
    for s in (-4.6, 4.6):
        W, L = 2.4, rnd(5.5, 7.5); top = 15.5; nu, nv = 12, 26; u = np.linspace(-.5, .5, nu)[None, :]; v = np.linspace(0, 1, nv)[:, None]
        wob = .12 * np.sin(v * 9 + u * 4 + rnd(0, 6)) * (v + .2)
        pts = np.zeros((nv, nu, 3)); n = A(-cos(c), -sin(c), 0); t = A(-sin(c), cos(c), 0); basep = A(cos(c), sin(c), 0) * (APO - .22)
        for i in range(nv):
            for j in range(nu): pts[i, j] = basep + t * (s + u[0, j] * W) + n * wob[i, j] + A(0, 0, top - L * v[i, 0])
        Q = []
        for i in range(nv - 1):
            for j in range(nu - 1):
                if i / nv > .72 and random.random() < (i / nv - .6) * 1.5: continue
                Q.append([i * nu + j, i * nu + j + 1, (i + 1) * nu + j + 1, (i + 1) * nu + j])
        add(batch('Tecidos', M_CLOTH), pts.reshape(-1, 3), Q)
        tube(U('Tecidos'), BRONZE, [basep + t * (s - W / 2 - .25) + A(0, 0, top + .1), basep + t * (s + W / 2 + .25) + A(0, 0, top + .1)], [.06, .06], 8, 1)
for (px, py) in PILLARS:
    for kk in range(3):
        ang = math.atan2(py, px) + rnd(-.6, .6); cx, cy, cz = 1.22 * abs(px) * np.sign(px) * (1 + .03 * kk), 1.22 * abs(py) * np.sign(py), 17.4 + kk * .3
        axis = A(-sin(ang), cos(ang), 0); R = rnd(1.2, 2.2)
        for i in range(9):
            th = pi * i / 8; tip = A(cx, cy, cz) + axis * R * cos(th) - A(0, 0, 1) * R * sin(th) * 1.0
            tube('Tecidos', M_WEB, [A(cx, cy, cz), (A(cx, cy, cz) + tip) / 2 + A(0, 0, -.05), tip], [.006, .006, .004], 3, 1)
        for ri in range(1, 6):
            rr = R * ri / 6; ps = [A(cx, cy, cz) + axis * rr * cos(th) - A(0, 0, 1) * rr * sin(th) - A(0, 0, .08 * sin(pi * th / pi * 3)) for th in np.linspace(0, pi, 15)]
            tube('Tecidos', M_WEB, ps, [.005] * 15, 3, 1)
# --------------------------------------------------------------- criar objetos
objs = flush()
for ob in scene.objects: pass
# luz da vela + ajuste do reflexo do tabuleiro
ld = bpy.data.lights.new('Vela da mesa', 'POINT'); ld.energy = 90; ld.color = (1, .55, .2); ld.shadow_soft_size = .06
lo = bpy.data.objects.new('Vela da mesa', ld); lo.location = tuple(CANDLE + A(0, 0, .1)); COLL['Mesa'].objects.link(lo)
if 'Reflexo do tabuleiro' in bpy.data.objects: bpy.data.objects['Reflexo do tabuleiro'].location.z = ZT + .9
# cameras novas
def newcam(name, loc, target, lens):
    cd = bpy.data.cameras.new(name); cd.lens = lens; co = bpy.data.objects.new(name, cd); co.location = loc
    co.rotation_euler = (Vector(target) - Vector(loc)).to_track_quat('-Z', 'Y').to_euler(); scene.collection.objects.link(co)
dg = bpy.context.evaluated_depsgraph_get()
def clear_at(p, target, stop):
    p = Vector(p)
    for d in [(1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1), (.7, .7, 0), (-.7, -.7, 0), (.7, -.7, 0), (-.7, .7, 0)]:
        if scene.ray_cast(dg, p, Vector(d).normalized(), distance=1.0)[0]: return False
    dv = Vector(target) - p; L = dv.length - stop
    return not scene.ray_cast(dg, p, dv.normalized(), distance=max(L, 1))[0]
def find_cam(cands, target, stop, ideal):
    cands = sorted(cands, key=lambda p: (Vector(p) - Vector(ideal)).length)
    for p in cands:
        if clear_at(p, target, stop): return p
    return cands[0]
hero = find_cam([(x, y, z) for x in np.linspace(-3, 3, 7) for y in (-12.3, -11.4, -10.5) for z in (4., 4.6, 5.2)], (0, .4, 3.2), 3.8, (0, -11.4, 4.6))
chao = find_cam([(x, y, z) for x in np.linspace(-1, 4, 6) for y in np.linspace(-5.5, -9, 6) for z in (2.2, 2.8, 3.4)], (10.5, -10.3, 1.2), 3.0, (2, -8, 2.6))
print('CAMS', hero, chao)
newcam('05_Heroi', tuple(float(v) for v in hero), (0, .4, 3.2), 28); newcam('06_Chao', tuple(float(v) for v in chao), (10.5, -10.3, 1.0), 24)
nv_ = sum(len(o.data.vertices) for o in objs.values())
print('SALA_OK novos_objetos=%d vertices_novos=%d grama=%d' % (len(objs), nv_, ng))
bpy.ops.wm.save_as_mainfile(filepath='/tmp/sala/torre_tabuleiro_v03.blend')
