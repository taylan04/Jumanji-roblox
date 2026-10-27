import bpy
import math
import random
from mathutils import Vector, Euler

# ============================================================
# JUMANJI ROBLOX - TORRE DO TABULEIRO
# ETAPA 1 REFEITA:
# - sala/torre medieval
# - pilares mais bonitos
# - portas medievais em arco
# - teto inclinado com vigas
# - materiais melhores
# ============================================================

SEED = 42
random.seed(SEED)

MAIN_COLLECTION_NAME = "Jumanji | Torre do Tabuleiro"
PREVIEW_COLLECTION_NAME = "Jumanji | Preview Torre"

# ----------------------------
# CONFIGURAÇÕES GERAIS
# ----------------------------
TOWER_RADIUS = 13.5
TOWER_WALL_HEIGHT = 18.0
TOWER_FLOOR_THICKNESS = 0.35
TOWER_WALL_THICKNESS = 0.65

ROOF_EAVE_Z = 18.4
ROOF_APEX_Z = 26.5
ROOF_INNER_RADIUS = 2.2

PILLAR_RING = 6.8
PILLAR_RADIUS = 0.56
PILLAR_HEIGHT = 17.0

DOOR_WIDTH = 4.2
DOOR_HEIGHT = 8.8
DOOR_THICKNESS = 0.26

TABLE_RADIUS = 2.0
TABLE_HEIGHT = 1.2
BOARD_SIZE = 2.2

# ============================================================
# HELPERS
# ============================================================

def get_or_create_collection(name):
    coll = bpy.data.collections.get(name)
    if coll is None:
        coll = bpy.data.collections.new(name)
        bpy.context.scene.collection.children.link(coll)
    return coll

def clear_collection(coll):
    for obj in list(coll.objects):
        bpy.data.objects.remove(obj, do_unlink=True)

def move_to_collection(obj, coll):
    for c in list(obj.users_collection):
        c.objects.unlink(obj)
    coll.objects.link(obj)
    return obj

def delete_default_scene_objects():
    for obj in list(bpy.data.objects):
        if obj.name in {"Cube", "Light", "Camera"}:
            bpy.data.objects.remove(obj, do_unlink=True)

def assign_material(obj, mat):
    if obj.type == "MESH":
        if len(obj.data.materials) == 0:
            obj.data.materials.append(mat)
        else:
            obj.data.materials[0] = mat

# ============================================================
# MATERIAIS
# ============================================================

def make_material(
    name,
    base=(0.5, 0.5, 0.5, 1.0),
    roughness=0.8,
    metallic=0.0,
    noise_scale=12.0,
    bump_strength=0.1,
    variation=0.08
):
    mat = bpy.data.materials.get(name)
    if mat is None:
        mat = bpy.data.materials.new(name=name)

    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    nodes.clear()

    out = nodes.new("ShaderNodeOutputMaterial")
    out.location = (700, 0)

    bsdf = nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.location = (350, 0)
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = metallic

    texcoord = nodes.new("ShaderNodeTexCoord")
    texcoord.location = (-800, 120)

    mapping = nodes.new("ShaderNodeMapping")
    mapping.location = (-600, 120)
    mapping.inputs["Scale"].default_value = (1.0, 1.0, 1.0)

    noise = nodes.new("ShaderNodeTexNoise")
    noise.location = (-400, 120)
    noise.inputs["Scale"].default_value = noise_scale
    noise.inputs["Detail"].default_value = 8.0
    noise.inputs["Roughness"].default_value = 0.65

    ramp = nodes.new("ShaderNodeValToRGB")
    ramp.location = (-150, 120)

    c0 = (
        max(base[0] - variation, 0.0),
        max(base[1] - variation, 0.0),
        max(base[2] - variation, 0.0),
        1.0,
    )
    c1 = (
        min(base[0] + variation, 1.0),
        min(base[1] + variation, 1.0),
        min(base[2] + variation, 1.0),
        1.0,
    )
    ramp.color_ramp.elements[0].position = 0.35
    ramp.color_ramp.elements[1].position = 0.72
    ramp.color_ramp.elements[0].color = c0
    ramp.color_ramp.elements[1].color = c1

    bump = nodes.new("ShaderNodeBump")
    bump.location = (120, -120)
    bump.inputs["Strength"].default_value = bump_strength

    links.new(texcoord.outputs["Object"], mapping.inputs["Vector"])
    links.new(mapping.outputs["Vector"], noise.inputs["Vector"])
    links.new(noise.outputs["Fac"], ramp.inputs["Fac"])
    links.new(ramp.outputs["Color"], bsdf.inputs["Base Color"])
    links.new(noise.outputs["Fac"], bump.inputs["Height"])
    links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])
    links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])

    return mat

def make_emission_material(name, color=(1.0, 0.7, 0.25, 1.0), strength=8.0):
    mat = bpy.data.materials.get(name)
    if mat is None:
        mat = bpy.data.materials.new(name=name)

    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    nodes.clear()

    out = nodes.new("ShaderNodeOutputMaterial")
    em = nodes.new("ShaderNodeEmission")
    em.inputs["Color"].default_value = color
    em.inputs["Strength"].default_value = strength

    links.new(em.outputs["Emission"], out.inputs["Surface"])
    return mat

MAT_STONE = make_material(
    "Jumanji_Stone",
    base=(0.40, 0.36, 0.32, 1.0),
    roughness=0.93,
    metallic=0.0,
    noise_scale=18.0,
    bump_strength=0.16,
    variation=0.12
)

MAT_STONE_DARK = make_material(
    "Jumanji_Stone_Dark",
    base=(0.28, 0.26, 0.24, 1.0),
    roughness=0.96,
    metallic=0.0,
    noise_scale=20.0,
    bump_strength=0.12,
    variation=0.07
)

MAT_WOOD = make_material(
    "Jumanji_Wood",
    base=(0.35, 0.23, 0.14, 1.0),
    roughness=0.84,
    metallic=0.0,
    noise_scale=16.0,
    bump_strength=0.08,
    variation=0.09
)

MAT_DARKWOOD = make_material(
    "Jumanji_DarkWood",
    base=(0.18, 0.11, 0.08, 1.0),
    roughness=0.90,
    metallic=0.0,
    noise_scale=18.0,
    bump_strength=0.07,
    variation=0.06
)

MAT_MOSS = make_material(
    "Jumanji_Moss",
    base=(0.16, 0.24, 0.10, 1.0),
    roughness=0.97,
    metallic=0.0,
    noise_scale=26.0,
    bump_strength=0.03,
    variation=0.05
)

MAT_METAL = make_material(
    "Jumanji_Metal",
    base=(0.24, 0.20, 0.16, 1.0),
    roughness=0.55,
    metallic=0.75,
    noise_scale=24.0,
    bump_strength=0.03,
    variation=0.03
)

MAT_GLOW = make_emission_material(
    "Jumanji_Glow",
    color=(1.0, 0.67, 0.28, 1.0),
    strength=8.5
)

MAT_BOARD = make_material(
    "Jumanji_Board",
    base=(0.44, 0.32, 0.15, 1.0),
    roughness=0.78,
    metallic=0.0,
    noise_scale=18.0,
    bump_strength=0.05,
    variation=0.08
)

# ============================================================
# PRIMITIVOS
# ============================================================

def create_cube(name, size=(2,2,2), location=(0,0,0), rotation=(0,0,0), collection=None, mat=None):
    bpy.ops.mesh.primitive_cube_add(location=location, rotation=rotation)
    obj = bpy.context.active_object
    obj.name = name
    obj.scale = (size[0] / 2, size[1] / 2, size[2] / 2)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if mat:
        assign_material(obj, mat)
    if collection:
        move_to_collection(obj, collection)
    return obj

def create_cylinder(name, radius=1.0, depth=2.0, vertices=24, location=(0,0,0), rotation=(0,0,0), collection=None, mat=None):
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=vertices,
        radius=radius,
        depth=depth,
        location=location,
        rotation=rotation
    )
    obj = bpy.context.active_object
    obj.name = name
    if mat:
        assign_material(obj, mat)
    if collection:
        move_to_collection(obj, collection)
    return obj

def create_plane(name, size=2.0, location=(0,0,0), rotation=(0,0,0), collection=None, mat=None):
    bpy.ops.mesh.primitive_plane_add(size=size, location=location, rotation=rotation)
    obj = bpy.context.active_object
    obj.name = name
    if mat:
        assign_material(obj, mat)
    if collection:
        move_to_collection(obj, collection)
    return obj

def create_uv_sphere(name, radius=1.0, location=(0,0,0), collection=None, mat=None):
    bpy.ops.mesh.primitive_uv_sphere_add(radius=radius, location=location)
    obj = bpy.context.active_object
    obj.name = name
    if mat:
        assign_material(obj, mat)
    if collection:
        move_to_collection(obj, collection)
    return obj

def create_bar_between_points(name, p1, p2, width=0.25, thickness=0.25, collection=None, mat=None):
    p1 = Vector(p1)
    p2 = Vector(p2)
    d = p2 - p1
    length = d.length
    mid = (p1 + p2) / 2

    yaw = math.atan2(d.y, d.x)
    horiz = math.sqrt(d.x * d.x + d.y * d.y)
    pitch = math.atan2(d.z, horiz)

    obj = create_cube(
        name,
        size=(length, width, thickness),
        location=(mid.x, mid.y, mid.z),
        rotation=(0, -pitch, yaw),
        collection=collection,
        mat=mat
    )
    return obj

# ============================================================
# PREVIEW / MUNDO
# ============================================================

def setup_scene():
    scene = bpy.context.scene
    scene.render.engine = 'BLENDER_EEVEE'
    scene.render.resolution_x = 1600
    scene.render.resolution_y = 900
    scene.render.resolution_percentage = 100

    world = scene.world
    if world is None:
        world = bpy.data.worlds.new("World")
        scene.world = world

    world.use_nodes = True
    nodes = world.node_tree.nodes
    bg = nodes.get("Background")
    if bg:
        bg.inputs[0].default_value = (0.018, 0.018, 0.025, 1.0)
        bg.inputs[1].default_value = 0.25

def create_preview_floor(collection):
    create_plane(
        "PreviewFloor",
        size=46,
        location=(0, 0, -0.03),
        collection=collection,
        mat=make_material(
            "PreviewFloorMat",
            base=(0.16, 0.16, 0.16, 1.0),
            roughness=0.96,
            metallic=0.0,
            noise_scale=28.0,
            bump_strength=0.01,
            variation=0.03
        )
    )

def create_preview_camera_and_lights(collection):
    cam_data = bpy.data.cameras.new("TowerCamera")
    cam = bpy.data.objects.new("TowerCamera", cam_data)
    cam.location = (19.5, -18.5, 11.5)
    cam.rotation_euler = Euler((math.radians(66), 0, math.radians(45)), 'XYZ')
    collection.objects.link(cam)
    bpy.context.scene.camera = cam

    key_data = bpy.data.lights.new(name="KeyLight", type='AREA')
    key_data.energy = 2600
    key_data.color = (1.0, 0.76, 0.58)
    key = bpy.data.objects.new("KeyLight", key_data)
    key.location = (8.5, -8.5, 15)
    key.rotation_euler = Euler((math.radians(60), 0, math.radians(35)), 'XYZ')
    collection.objects.link(key)

    rim_data = bpy.data.lights.new(name="RimLight", type='AREA')
    rim_data.energy = 1400
    rim_data.color = (0.45, 0.52, 0.90)
    rim = bpy.data.objects.new("RimLight", rim_data)
    rim.location = (-9.5, 10, 16)
    rim.rotation_euler = Euler((math.radians(62), 0, math.radians(-135)), 'XYZ')
    collection.objects.link(rim)

def create_fog_volume(collection):
    fog = create_cube(
        "PreviewFog",
        size=(42, 42, 24),
        location=(0, 0, 12),
        collection=collection
    )

    mat = bpy.data.materials.get("Jumanji_Fog")
    if mat is None:
        mat = bpy.data.materials.new(name="Jumanji_Fog")
        mat.use_nodes = True
        nodes = mat.node_tree.nodes
        links = mat.node_tree.links
        nodes.clear()

        out = nodes.new("ShaderNodeOutputMaterial")
        volume = nodes.new("ShaderNodeVolumePrincipled")
        volume.inputs["Color"].default_value = (0.10, 0.10, 0.10, 1.0)
        volume.inputs["Density"].default_value = 0.015
        volume.inputs["Anisotropy"].default_value = 0.18

        links.new(volume.outputs["Volume"], out.inputs["Volume"])

    assign_material(fog, mat)

# ============================================================
# SALA / TORRE
# ============================================================

def create_floor(collection):
    floor = create_cylinder(
        "TowerFloor",
        radius=TOWER_RADIUS + 1.0,
        depth=TOWER_FLOOR_THICKNESS,
        vertices=8,
        location=(0, 0, TOWER_FLOOR_THICKNESS / 2 - 0.02),
        rotation=(0, 0, math.radians(22.5)),
        collection=collection,
        mat=MAT_STONE
    )

    ring = create_cylinder(
        "CenterRing",
        radius=4.5,
        depth=0.05,
        vertices=24,
        location=(0, 0, 0.15),
        collection=collection,
        mat=MAT_DARKWOOD
    )

    return [floor, ring]

def create_wall_segment(center_angle_deg, width, z_center, height, collection, name, mat=MAT_STONE):
    angle = math.radians(center_angle_deg)
    center = Vector((math.cos(angle) * TOWER_RADIUS, math.sin(angle) * TOWER_RADIUS, z_center))
    rotation_z = angle + math.radians(90)

    return create_cube(
        name,
        size=(width, TOWER_WALL_THICKNESS, height),
        location=(center.x, center.y, center.z),
        rotation=(0, 0, rotation_z),
        collection=collection,
        mat=mat
    )

def create_tower_walls(collection):
    objs = []
    sides = 8
    wall_seg_width = (TOWER_RADIUS * math.tan(math.pi / sides) * 2) * 0.95

    for i in range(sides):
        angle_deg = i * 45
        is_cardinal = (i % 2 == 0)

        if is_cardinal:
            side_width = (wall_seg_width - DOOR_WIDTH) / 2
            angle = math.radians(angle_deg)
            tangent = Vector((-math.sin(angle), math.cos(angle), 0))
            base_center = Vector((math.cos(angle) * TOWER_RADIUS, math.sin(angle) * TOWER_RADIUS, 0))

            left_center = base_center - tangent * (DOOR_WIDTH / 2 + side_width / 2)
            right_center = base_center + tangent * (DOOR_WIDTH / 2 + side_width / 2)

            rot_z = angle + math.radians(90)

            left = create_cube(
                f"Wall_{i}_Left",
                size=(side_width, TOWER_WALL_THICKNESS, TOWER_WALL_HEIGHT),
                location=(left_center.x, left_center.y, TOWER_WALL_HEIGHT / 2),
                rotation=(0, 0, rot_z),
                collection=collection,
                mat=MAT_STONE
            )
            right = create_cube(
                f"Wall_{i}_Right",
                size=(side_width, TOWER_WALL_THICKNESS, TOWER_WALL_HEIGHT),
                location=(right_center.x, right_center.y, TOWER_WALL_HEIGHT / 2),
                rotation=(0, 0, rot_z),
                collection=collection,
                mat=MAT_STONE
            )
            top_height = TOWER_WALL_HEIGHT - DOOR_HEIGHT
            top = create_cube(
                f"Wall_{i}_Top",
                size=(DOOR_WIDTH, TOWER_WALL_THICKNESS, top_height),
                location=(base_center.x, base_center.y, DOOR_HEIGHT + top_height / 2),
                rotation=(0, 0, rot_z),
                collection=collection,
                mat=MAT_STONE
            )
            objs.extend([left, right, top])
        else:
            wall = create_wall_segment(
                angle_deg,
                wall_seg_width,
                TOWER_WALL_HEIGHT / 2,
                TOWER_WALL_HEIGHT,
                collection,
                f"Wall_{i}",
                MAT_STONE
            )
            objs.append(wall)

    # pilastras verticais entre os segmentos
    vertex_radius = TOWER_RADIUS / math.cos(math.pi / 8)
    for i in range(8):
        a = math.radians(22.5 + i * 45)
        x = math.cos(a) * vertex_radius
        y = math.sin(a) * vertex_radius
        edge_col = create_cube(
            f"WallEdge_{i}",
            size=(0.55, 0.80, TOWER_WALL_HEIGHT + 0.8),
            location=(x, y, (TOWER_WALL_HEIGHT + 0.8) / 2),
            rotation=(0, 0, a + math.radians(90)),
            collection=collection,
            mat=MAT_STONE_DARK
        )
        objs.append(edge_col)

    # anel superior
    upper_ring = create_cylinder(
        "UpperStoneRing",
        radius=TOWER_RADIUS + 0.5,
        depth=0.75,
        vertices=8,
        location=(0, 0, ROOF_EAVE_Z),
        rotation=(0, 0, math.radians(22.5)),
        collection=collection,
        mat=MAT_STONE_DARK
    )
    objs.append(upper_ring)

    return objs

# ============================================================
# PILARES
# ============================================================

def create_gothic_pillar(name, x, y, collection):
    objs = []

    base1 = create_cube(f"{name}_Base1", size=(1.95, 1.95, 0.30), location=(x, y, 0.15), collection=collection, mat=MAT_STONE)
    base2 = create_cube(f"{name}_Base2", size=(1.55, 1.55, 0.28), location=(x, y, 0.44), collection=collection, mat=MAT_STONE)
    base3 = create_cube(f"{name}_Base3", size=(1.20, 1.20, 0.24), location=(x, y, 0.70), collection=collection, mat=MAT_STONE)
    objs.extend([base1, base2, base3])

    shaft = create_cylinder(
        f"{name}_Shaft",
        radius=PILLAR_RADIUS,
        depth=PILLAR_HEIGHT,
        vertices=24,
        location=(x, y, 0.95 + PILLAR_HEIGHT / 2),
        collection=collection,
        mat=MAT_STONE
    )
    objs.append(shaft)

    # caneluras / nervuras
    rib_count = 10
    for i in range(rib_count):
        ang = (math.pi * 2 / rib_count) * i
        rx = x + math.cos(ang) * (PILLAR_RADIUS * 0.82)
        ry = y + math.sin(ang) * (PILLAR_RADIUS * 0.82)
        rib = create_cube(
            f"{name}_Rib_{i}",
            size=(0.10, 0.12, PILLAR_HEIGHT - 0.40),
            location=(rx, ry, 0.95 + (PILLAR_HEIGHT - 0.40) / 2),
            rotation=(0, 0, ang),
            collection=collection,
            mat=MAT_STONE_DARK
        )
        objs.append(rib)

    cap1 = create_cube(f"{name}_Cap1", size=(1.35, 1.35, 0.26), location=(x, y, 0.95 + PILLAR_HEIGHT + 0.15), collection=collection, mat=MAT_STONE)
    cap2 = create_cube(f"{name}_Cap2", size=(1.75, 1.75, 0.34), location=(x, y, 0.95 + PILLAR_HEIGHT + 0.48), collection=collection, mat=MAT_STONE)
    cap3 = create_cube(f"{name}_Cap3", size=(2.15, 2.15, 0.42), location=(x, y, 0.95 + PILLAR_HEIGHT + 0.86), collection=collection, mat=MAT_STONE)
    objs.extend([cap1, cap2, cap3])

    # pequenos detalhes ornamentais no topo
    for ang in [45, 135, 225, 315]:
        a = math.radians(ang)
        ox = x + math.cos(a) * 0.85
        oy = y + math.sin(a) * 0.85
        ornament = create_cube(
            f"{name}_Ornament_{ang}",
            size=(0.28, 0.22, 0.42),
            location=(ox, oy, 0.95 + PILLAR_HEIGHT + 0.25),
            rotation=(0, 0, a),
            collection=collection,
            mat=MAT_STONE_DARK
        )
        objs.append(ornament)

    # musgo / hera leve
    for i in range(12):
        ang = i * 0.52
        h = 1.6 + i * 1.10
        vx = x + math.cos(ang) * (PILLAR_RADIUS + 0.08)
        vy = y + math.sin(ang) * (PILLAR_RADIUS + 0.08)
        ivy = create_uv_sphere(
            f"{name}_Ivy_{i}",
            radius=0.10,
            location=(vx, vy, h),
            collection=collection,
            mat=MAT_MOSS
        )
        objs.append(ivy)

    return objs

def create_all_pillars(collection):
    positions = [
        (-PILLAR_RING, -PILLAR_RING),
        ( PILLAR_RING, -PILLAR_RING),
        ( PILLAR_RING,  PILLAR_RING),
        (-PILLAR_RING,  PILLAR_RING),
    ]
    for idx, (x, y) in enumerate(positions):
        create_gothic_pillar(f"Pillar_{idx+1}", x, y, collection)

# ============================================================
# PORTAS
# ============================================================

def create_medieval_door(name, angle_deg, collection):
    angle = math.radians(angle_deg)

    center = Vector((
        math.cos(angle) * (TOWER_RADIUS - TOWER_WALL_THICKNESS / 2),
        math.sin(angle) * (TOWER_RADIUS - TOWER_WALL_THICKNESS / 2),
        DOOR_HEIGHT / 2
    ))

    tangent = Vector((-math.sin(angle), math.cos(angle), 0))
    rot_z = angle + math.radians(90)

    objs = []

    # folhas da porta
    left_center = center - tangent * (DOOR_WIDTH / 4)
    right_center = center + tangent * (DOOR_WIDTH / 4)

    door_left = create_cube(
        f"{name}_Left",
        size=(DOOR_WIDTH / 2 - 0.05, DOOR_THICKNESS, DOOR_HEIGHT),
        location=(left_center.x, left_center.y, left_center.z),
        rotation=(0, 0, rot_z),
        collection=collection,
        mat=MAT_WOOD
    )
    door_right = create_cube(
        f"{name}_Right",
        size=(DOOR_WIDTH / 2 - 0.05, DOOR_THICKNESS, DOOR_HEIGHT),
        location=(right_center.x, right_center.y, right_center.z),
        rotation=(0, 0, rot_z),
        collection=collection,
        mat=MAT_WOOD
    )
    objs.extend([door_left, door_right])

    # barras metálicas
    for h in [1.8, 4.2, 6.6]:
        bar = create_cube(
            f"{name}_Bar_{int(h*10)}",
            size=(DOOR_WIDTH - 0.25, DOOR_THICKNESS + 0.04, 0.16),
            location=(center.x, center.y, h),
            rotation=(0, 0, rot_z),
            collection=collection,
            mat=MAT_METAL
        )
        objs.append(bar)

    # rebites
    rivet_positions = []
    for side in [-0.9, 0.9]:
        for h in [1.2, 2.6, 4.0, 5.4, 6.8, 8.0]:
            rivet_positions.append((side, h))

    for idx, (tx, h) in enumerate(rivet_positions):
        pos = center + tangent * tx
        rivet = create_uv_sphere(
            f"{name}_Rivet_{idx}",
            radius=0.08,
            location=(pos.x, pos.y, h),
            collection=collection,
            mat=MAT_METAL
        )
        objs.append(rivet)

    # moldura de pedra
    frame_offset = DOOR_WIDTH / 2 + 0.42
    left_frame = center - tangent * frame_offset
    right_frame = center + tangent * frame_offset

    frame_l = create_cube(
        f"{name}_FrameL",
        size=(0.55, 0.80, DOOR_HEIGHT + 1.0),
        location=(left_frame.x, left_frame.y, (DOOR_HEIGHT + 1.0) / 2),
        rotation=(0, 0, rot_z),
        collection=collection,
        mat=MAT_STONE_DARK
    )
    frame_r = create_cube(
        f"{name}_FrameR",
        size=(0.55, 0.80, DOOR_HEIGHT + 1.0),
        location=(right_frame.x, right_frame.y, (DOOR_HEIGHT + 1.0) / 2),
        rotation=(0, 0, rot_z),
        collection=collection,
        mat=MAT_STONE_DARK
    )
    objs.extend([frame_l, frame_r])

    # arco medieval (pontudo)
    left_arch_start = Vector((left_frame.x, left_frame.y, DOOR_HEIGHT + 0.55))
    right_arch_start = Vector((right_frame.x, right_frame.y, DOOR_HEIGHT + 0.55))
    apex = Vector((center.x, center.y, DOOR_HEIGHT + 2.4))

    arch_l = create_bar_between_points(
        f"{name}_ArchL",
        left_arch_start,
        apex,
        width=0.78,
        thickness=0.26,
        collection=collection,
        mat=MAT_STONE_DARK
    )
    arch_r = create_bar_between_points(
        f"{name}_ArchR",
        right_arch_start,
        apex,
        width=0.78,
        thickness=0.26,
        collection=collection,
        mat=MAT_STONE_DARK
    )
    keystone = create_cube(
        f"{name}_Keystone",
        size=(0.50, 0.75, 0.70),
        location=(apex.x, apex.y, apex.z - 0.1),
        rotation=(0, 0, rot_z),
        collection=collection,
        mat=MAT_STONE
    )
    objs.extend([arch_l, arch_r, keystone])

    # puxador / argola
    ring_center = center + Vector((0, 0, 4.6))
    ring = create_cylinder(
        f"{name}_Ring",
        radius=0.22,
        depth=0.05,
        vertices=18,
        location=(ring_center.x, ring_center.y, ring_center.z),
        rotation=(math.radians(90), 0, rot_z),
        collection=collection,
        mat=MAT_METAL
    )
    objs.append(ring)

    return objs

def create_all_doors(collection):
    create_medieval_door("Door_East", 0, collection)
    create_medieval_door("Door_North", 90, collection)
    create_medieval_door("Door_West", 180, collection)
    create_medieval_door("Door_South", 270, collection)

# ============================================================
# TETO / COBERTURA
# ============================================================

def create_roof(collection):
    objs = []

    # centros das 8 faces superiores
    outer_points = []
    inner_points = []

    for i in range(8):
        angle = math.radians(i * 45)
        ox = math.cos(angle) * (TOWER_RADIUS - 0.45)
        oy = math.sin(angle) * (TOWER_RADIUS - 0.45)
        outer_points.append(Vector((ox, oy, ROOF_EAVE_Z)))

        ix = math.cos(angle) * ROOF_INNER_RADIUS
        iy = math.sin(angle) * ROOF_INNER_RADIUS
        inner_points.append(Vector((ix, iy, ROOF_APEX_Z - 1.2)))

    # painéis inclinados do teto
    for i in range(8):
        panel = create_bar_between_points(
            f"RoofPanel_{i}",
            outer_points[i],
            inner_points[i],
            width=3.4,
            thickness=0.18,
            collection=collection,
            mat=MAT_DARKWOOD
        )
        objs.append(panel)

    # vigas principais do teto
    for i in range(8):
        beam = create_bar_between_points(
            f"RoofBeam_{i}",
            outer_points[i],
            inner_points[i],
            width=0.24,
            thickness=0.26,
            collection=collection,
            mat=MAT_WOOD
        )
        objs.append(beam)

    # aro central / claraboia simples
    top_ring = create_cylinder(
        "RoofTopRing",
        radius=ROOF_INNER_RADIUS + 0.40,
        depth=0.35,
        vertices=8,
        location=(0, 0, ROOF_APEX_Z - 1.1),
        rotation=(0, 0, math.radians(22.5)),
        collection=collection,
        mat=MAT_DARKWOOD
    )
    objs.append(top_ring)

    # vigas ligando os 4 pilares
    pillar_positions = [
        Vector((-PILLAR_RING, -PILLAR_RING, 19.0)),
        Vector(( PILLAR_RING, -PILLAR_RING, 19.0)),
        Vector(( PILLAR_RING,  PILLAR_RING, 19.0)),
        Vector((-PILLAR_RING,  PILLAR_RING, 19.0)),
    ]
    pairs = [
        (pillar_positions[0], pillar_positions[1], "InnerBeam_N"),
        (pillar_positions[1], pillar_positions[2], "InnerBeam_E"),
        (pillar_positions[2], pillar_positions[3], "InnerBeam_S"),
        (pillar_positions[3], pillar_positions[0], "InnerBeam_W"),
    ]

    for p1, p2, name in pairs:
        beam = create_bar_between_points(
            name,
            p1,
            p2,
            width=0.35,
            thickness=0.35,
            collection=collection,
            mat=MAT_DARKWOOD
        )
        objs.append(beam)

    # lustre simples
    chain = create_cube(
        "ChandelierChain",
        size=(0.10, 0.10, 4.2),
        location=(0, 0, 18.3),
        collection=collection,
        mat=MAT_METAL
    )
    ring = create_cylinder(
        "ChandelierRing",
        radius=1.10,
        depth=0.10,
        vertices=16,
        location=(0, 0, 15.9),
        collection=collection,
        mat=MAT_METAL
    )
    objs.extend([chain, ring])

    for i in range(6):
        ang = i * (math.pi * 2 / 6)
        ax = math.cos(ang) * 0.65
        ay = math.sin(ang) * 0.65
        arm = create_cube(
            f"ChandelierArm_{i}",
            size=(0.9, 0.10, 0.10),
            location=(ax, ay, 15.9),
            rotation=(0, 0, ang),
            collection=collection,
            mat=MAT_METAL
        )
        flame = create_cube(
            f"ChandelierFlame_{i}",
            size=(0.10, 0.10, 0.28),
            location=(math.cos(ang) * 1.1, math.sin(ang) * 1.1, 16.15),
            collection=collection,
            mat=MAT_GLOW
        )
        objs.extend([arm, flame])

    return objs

# ============================================================
# CENTRO (SIMPLES POR ENQUANTO)
# ============================================================

def create_center_table(collection):
    base = create_cylinder(
        "TableBase",
        radius=0.38,
        depth=TABLE_HEIGHT,
        vertices=16,
        location=(0, 0, TABLE_HEIGHT / 2),
        collection=collection,
        mat=MAT_DARKWOOD
    )

    foot = create_cube(
        "TableFoot",
        size=(2.1, 2.1, 0.18),
        location=(0, 0, 0.09),
        collection=collection,
        mat=MAT_DARKWOOD
    )

    top = create_cylinder(
        "TableTop",
        radius=TABLE_RADIUS,
        depth=0.22,
        vertices=22,
        location=(0, 0, TABLE_HEIGHT + 0.11),
        collection=collection,
        mat=MAT_WOOD
    )

    board = create_cube(
        "Board",
        size=(BOARD_SIZE, BOARD_SIZE, 0.15),
        location=(0, 0, TABLE_HEIGHT + 0.26),
        rotation=(0, 0, math.radians(45)),
        collection=collection,
        mat=MAT_BOARD
    )

    border = create_cube(
        "BoardBorder",
        size=(BOARD_SIZE + 0.14, BOARD_SIZE + 0.14, 0.05),
        location=(0, 0, TABLE_HEIGHT + 0.20),
        rotation=(0, 0, math.radians(45)),
        collection=collection,
        mat=MAT_METAL
    )

    # runas simples
    rune_positions = [(-0.55, -0.55), (0.55, -0.55), (-0.55, 0.55), (0.55, 0.55), (0, 0)]
    for idx, (x, y) in enumerate(rune_positions):
        create_cube(
            f"Rune_{idx}",
            size=(0.12, 0.12, 0.02),
            location=(x, y, TABLE_HEIGHT + 0.34),
            collection=collection,
            mat=MAT_GLOW
        )

# ============================================================
# LUZES DE PAREDE
# ============================================================

def create_wall_lantern(name, angle_deg, height, side_offset, collection):
    angle = math.radians(angle_deg)
    base = Vector((math.cos(angle) * (TOWER_RADIUS - 0.3), math.sin(angle) * (TOWER_RADIUS - 0.3), height))
    tangent = Vector((-math.sin(angle), math.cos(angle), 0))

    pos = base + tangent * side_offset
    rot_z = angle

    arm = create_cube(
        f"{name}_Arm",
        size=(0.55, 0.10, 0.10),
        location=(pos.x, pos.y, pos.z),
        rotation=(0, 0, rot_z),
        collection=collection,
        mat=MAT_METAL
    )
    glow = create_uv_sphere(
        f"{name}_Glow",
        radius=0.16,
        location=(pos.x + math.cos(rot_z) * 0.26, pos.y + math.sin(rot_z) * 0.26, pos.z - 0.12),
        collection=collection,
        mat=MAT_GLOW
    )
    return [arm, glow]

def create_wall_lights(collection):
    # duas em cada porta, uma de cada lado
    for angle_deg in [0, 90, 180, 270]:
        create_wall_lantern(f"Lantern_{angle_deg}_A", angle_deg, 6.8, -3.0, collection)
        create_wall_lantern(f"Lantern_{angle_deg}_B", angle_deg, 6.8,  3.0, collection)

# ============================================================
# BUILD
# ============================================================

def build_scene():
    delete_default_scene_objects()

    main_coll = get_or_create_collection(MAIN_COLLECTION_NAME)
    preview_coll = get_or_create_collection(PREVIEW_COLLECTION_NAME)

    clear_collection(main_coll)
    clear_collection(preview_coll)

    setup_scene()

    create_floor(main_coll)
    create_tower_walls(main_coll)
    create_all_pillars(main_coll)
    create_all_doors(main_coll)
    create_roof(main_coll)
    create_center_table(main_coll)
    create_wall_lights(main_coll)

    create_preview_floor(preview_coll)
    create_preview_camera_and_lights(preview_coll)
    create_fog_volume(preview_coll)

    # colocar viewport em material preview
    for area in bpy.context.screen.areas:
        if area.type == 'VIEW_3D':
            for space in area.spaces:
                if space.type == 'VIEW_3D':
                    space.shading.type = 'MATERIAL'
                    break

    print("Torre do tabuleiro gerada com sucesso!")

# ============================================================
# EXECUÇÃO
# ============================================================

build_scene()