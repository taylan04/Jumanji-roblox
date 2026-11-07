# ============================================================ RIG DO JACARE
# Roda dentro de generate_alligator_v2.py (usa scene, G, LIMBS, tailpts, catmull).
# Convencao: criatura olha para -Y, lado esquerdo = +X (.L), direito = -X (.R).
import numpy as np
from mathutils import Quaternion

rigc = bpy.data.collections.new('AG_Rig'); scene.collection.children.link(rigc)
adata = bpy.data.armatures.new('Alligator_Rig')
arm = bpy.data.objects.new('Alligator_Armature', adata); rigc.objects.link(arm); arm.show_in_front = True
BONES = []
def B(name, h, t, parent=None): BONES.append((name, Vector(h), Vector(t), parent))

B('Root',    (0, .6, .05),   (0, -.2, .05))
B('Pelvis',  (0, 2.55, .89), (0, 1.4, .88), 'Root')
B('Spine_1', (0, 1.4, .88),  (0, .3, .89), 'Pelvis')
B('Spine_2', (0, .3, .89),   (0, -.8, .99), 'Spine_1')
B('Chest',   (0, -.8, .99), (0, -1.8, 1.02), 'Spine_2')
B('Head',    (0, -1.8, 1.08), (0, -3.95, 1.36), 'Chest')
B('Jaw',     (0, -1.78, .94), (0, -3.90, .26), 'Head')
tp, _ = catmull(tailpts, [1] * len(tailpts), 10)
idx = np.linspace(0, len(tp) - 1, 11).round().astype(int)
TAILB = []
for i in range(10):
    h = tp[idx[i]]; t = tp[idx[i + 1]]
    if i == 0: h = Vector((0, 2.55, .89))
    nm = 'Tail_%02d' % (i + 1); TAILB.append(nm)
    B(nm, h, t, 'Pelvis' if i == 0 else 'Tail_%02d' % i)
LEGB = {}
for key in ['Fore_L', 'Fore_R', 'Hind_L', 'Hind_R']:
    pts = [Vector(p) for p in LIMBS[key]]; s = '.L' if key.endswith('_L') else '.R'
    front = key.startswith('Fore'); pre = 'Arm' if front else 'Leg'
    names = [pre + '_Upper' + s, pre + '_Lower' + s, pre + ('_Hand' if front else '_Foot') + s]
    toe = pts[4] + Vector((0, -.55, -.02)); parent = 'Chest' if front else 'Pelvis'
    B(names[0], pts[0], pts[2], parent); B(names[1], pts[2], pts[3], names[0]); B(names[2], pts[3], toe, names[1])
    LEGB[key] = names

bpy.context.view_layer.objects.active = arm
bpy.ops.object.mode_set(mode='EDIT')
for name, h, t, parent in BONES:
    b = adata.edit_bones.new(name); b.head = h; b.tail = t
    if parent: b.parent = adata.edit_bones[parent]
bpy.ops.object.mode_set(mode='OBJECT')
SEG = {n: (np.array(h), np.array(t)) for n, h, t, p in BONES}

def seg_dist(P, a, b):
    ab = b - a; t = np.clip(((P - a) @ ab) / (ab @ ab), 0, 1)
    return np.linalg.norm(P - (a + t[:, None] * ab), axis=1)

def bones_for(ob):
    n = ob.name
    if n.startswith(('Heavy_torso', 'Back_')): return ['Pelvis', 'Spine_1', 'Spine_2', 'Chest', 'Head'], False
    if n.startswith(('Powerful_curled_tail', 'Tail_')): return ['Pelvis'] + TAILB, False
    for k, v in LEGB.items():
        if n.startswith(k):
            if '_toe' in n or '_claw' in n: return [v[2]], True
            return v + ['Chest' if k.startswith('Fore') else 'Pelvis'], False
    if n.startswith(('UpperJaw', 'Broad_predatory_skull')): return ['Head'], True
    if n.startswith(('LowerJaw', 'Open_lower_mandible', 'Attached_crocodilian_tongue')): return ['Jaw'], True
    if n.startswith(('Mouth_corner', 'Rear_mouth_fold', 'Throat')): return ['Head', 'Jaw'], False
    return ['Head'], True

RIGGED = 0; blended = []
for ob in list(scene.objects):
    if ob.type != 'MESH' or ob.name == 'Ground' or ob.parent: continue
    names, rigid = bones_for(ob)
    n = len(ob.data.vertices)
    if n == 0: continue
    P = np.empty(n * 3); ob.data.vertices.foreach_get('co', P); P = P.reshape(-1, 3)
    if rigid:
        vg = ob.vertex_groups.new(name=names[0]); vg.add(list(range(n)), 1.0, 'REPLACE')
    else:
        D = np.stack([seg_dist(P, *SEG[b]) for b in names], 1)
        W = (1.0 / (D + .04)) ** 4
        if len(names) > 3:  # mantem so as 3 maiores influencias por vertice
            thr = np.sort(W, axis=1)[:, -3][:, None]; W = np.where(W >= thr, W, 0)
        W /= W.sum(1, keepdims=True); Wq = np.round(W * 64) / 64
        for k, b in enumerate(names):
            col = Wq[:, k]; vg = ob.vertex_groups.new(name=b)
            for val in np.unique(col[col > 0]):
                vg.add(np.nonzero(col == val)[0].tolist(), float(val), 'REPLACE')
        blended.append(ob)
    mod = ob.modifiers.new('Armature', 'ARMATURE'); mod.object = arm
    ob.parent = arm; RIGGED += 1
for ob in blended:
    bpy.context.view_layer.objects.active = ob
    try: bpy.ops.object.vertex_group_normalize_all(group_select_mode='ALL', lock_active=False)
    except Exception as e: print('normalize skip', ob.name, e)

# ---------------------------------------------------------------- acoes de teste
for pb in arm.pose.bones: pb.rotation_mode = 'QUATERNION'
def lax(bone, axis):
    return (adata.bones[bone].matrix_local.to_3x3().inverted() @ Vector(axis)).normalized()
def R(bone, axis, ang): return Quaternion(lax(bone, axis), ang)
X, Y, Z = (1, 0, 0), (0, 1, 0), (0, 0, 1)
IDENT = Quaternion((1, 0, 0, 0))
arm.animation_data_create()
def new_action(name, frames, fn):
    act = bpy.data.actions.new(name); act.use_fake_user = True; arm.animation_data.action = act
    for f in frames:
        for pb in arm.pose.bones: pb.rotation_quaternion = IDENT
        fn(f)
        for pb in arm.pose.bones:
            if pb.rotation_quaternion != IDENT:
                pb.keyframe_insert('rotation_quaternion', frame=f, group=pb.name)
    arm.animation_data.action = None
    for pb in arm.pose.bones: pb.rotation_quaternion = IDENT
    return act
def PB(n): return arm.pose.bones[n]

# Bite: jaw aberta no rest; abre mais, trava (fecha) e volta. +ang em X = ponta da mandibula desce.
BITE = {1: (0, 0), 10: (.30, -.14), 16: (-.42, .26), 24: (-.42, .22), 40: (0, 0), 60: (0, 0)}
def bite(f):
    ks = sorted(BITE); jaw = np.interp(f, ks, [BITE[k][0] for k in ks]); head = np.interp(f, ks, [BITE[k][1] for k in ks])
    PB('Jaw').rotation_quaternion = R('Jaw', X, float(jaw)); PB('Head').rotation_quaternion = R('Head', X, float(head))
    PB('Chest').rotation_quaternion = R('Chest', X, float(head) * .35)
new_action('Bite', [1, 10, 16, 24, 40, 60], bite)

def idle(f):
    ph = 2 * pi * (f - 1) / 96
    PB('Jaw').rotation_quaternion = R('Jaw', X, .05 * sin(ph * 2))
    PB('Head').rotation_quaternion = R('Head', Z, .10 * sin(ph))
    PB('Chest').rotation_quaternion = R('Chest', Z, -.05 * sin(ph))
    for i, n in enumerate(TAILB): PB(n).rotation_quaternion = R(n, Z, .09 * sin(ph - i * .55))
new_action('Idle_Menace', list(range(1, 98, 8)), idle)

def walk(f):
    ph = 2 * pi * (f - 1) / 48
    for key, p0 in [('Fore_L', 0), ('Hind_R', 0), ('Fore_R', pi), ('Hind_L', pi)]:
        up, lo, ft = LEGB[key]; left = key.endswith('_L'); A = .38 if key.startswith('Fore') else .32
        ang = (-1 if left else 1) * A * sin(ph + p0); lift = .55 * max(0, cos(ph + p0)) * (-1 if left else 1)
        PB(up).rotation_quaternion = R(up, Z, ang) @ R(up, Y, lift * .6)
        PB(lo).rotation_quaternion = R(lo, Y, lift * .5)
    for n, a in [('Spine_1', .07), ('Spine_2', .07), ('Chest', .06)]:
        PB(n).rotation_quaternion = R(n, Z, a * sin(ph))
    PB('Head').rotation_quaternion = R('Head', Z, -.08 * sin(ph))
    for i, n in enumerate(TAILB): PB(n).rotation_quaternion = R(n, Z, .12 * sin(ph - i * .5 - 1.0))
new_action('Walk', list(range(1, 50, 4)), walk)
print('RIG_OK objetos_rigados=%d ossos=%d' % (RIGGED, len(BONES)))
