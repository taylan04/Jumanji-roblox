"""Materiais de estudo do Blender; sem alegação de exportação PBR pronta."""
import bpy

def material(name, color, rough=.8, metallic=0, wood=False, weather=False):
    mat=bpy.data.materials.new("T02 | "+name); mat.diffuse_color=(*color,1); mat.use_nodes=True
    n=mat.node_tree.nodes; n.clear(); l=mat.node_tree.links
    out=n.new("ShaderNodeOutputMaterial"); bs=n.new("ShaderNodeBsdfPrincipled")
    bs.inputs["Roughness"].default_value=rough; bs.inputs["Metallic"].default_value=metallic
    l.new(bs.outputs["BSDF"],out.inputs["Surface"])
    tex=n.new("ShaderNodeTexCoord"); mapping=n.new("ShaderNodeVectorMath");mapping.operation="MULTIPLY"
    mapping.inputs[1].default_value=(9,9,.32) if wood else (1,1,1)
    l.new(tex.outputs["Object"],mapping.inputs[0])
    noise=n.new("ShaderNodeTexNoise"); noise.inputs["Scale"].default_value=3 if wood else 1.4
    noise.inputs["Detail"].default_value=4;noise.inputs["Roughness"].default_value=.75
    l.new(mapping.outputs["Vector"],noise.inputs["Vector"])
    ramp=n.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].position=.18; ramp.color_ramp.elements[1].position=.85
    ramp.color_ramp.elements[0].color=(*[v*.42 for v in color],1)
    ramp.color_ramp.elements[1].color=(*[v*1.15 for v in color],1)
    l.new(noise.outputs["Fac"],ramp.inputs["Fac"]);l.new(ramp.outputs["Color"],bs.inputs["Base Color"])
    fine=n.new("ShaderNodeTexNoise");fine.inputs["Scale"].default_value=55 if not wood else 12
    fine.inputs["Detail"].default_value=3
    l.new(mapping.outputs["Vector"],fine.inputs["Vector"])
    bump=n.new("ShaderNodeBump");bump.inputs["Strength"].default_value=.28
    bump.inputs["Distance"].default_value=.025 if not wood else .016
    l.new(fine.outputs["Fac"],bump.inputs["Height"]);l.new(bump.outputs["Normal"],bs.inputs["Normal"])
    if weather:
        # Umidade mais forte na base, quebrada por ruído; evita manchas aleatórias uniformes.
        sep=n.new("ShaderNodeSeparateXYZ"); l.new(tex.outputs["Object"],sep.inputs["Vector"])
        fade=n.new("ShaderNodeMapRange")
        fade.inputs["From Min"].default_value=0;fade.inputs["From Max"].default_value=3.2
        fade.inputs["To Min"].default_value=.85;fade.inputs["To Max"].default_value=0
        l.new(sep.outputs["Z"],fade.inputs["Value"])
        mult=n.new("ShaderNodeMath");mult.operation="MULTIPLY"
        l.new(fade.outputs["Result"],mult.inputs[0]);l.new(noise.outputs["Fac"],mult.inputs[1])
        mix=n.new("ShaderNodeMixRGB");mix.blend_type="MIX"
        l.new(mult.outputs[0],mix.inputs[0]);l.new(ramp.outputs["Color"],mix.inputs[1])
        mix.inputs[2].default_value=(.07,.10,.052,1)
        l.new(mix.outputs[0],bs.inputs["Base Color"])
    return mat

def palette():
    return {
        "stone":[material("Cantaria %02d"%i,(.27+i*.018,.285+i*.017,.26+i*.015),weather=True) for i in range(5)],
        "trim":material("Calcário esculpido",(.46,.43,.34),weather=True),
        "dark":material("Juntas e pedra úmida",(.12,.145,.13)),
        "wood":[material("Carvalho %02d"%i,(.105+i*.011,.054+i*.005,.025+i*.003),wood=True) for i in range(4)],
        "iron":material("Ferro forjado",(.048,.055,.05),.48,.8),
        "bronze":material("Bronze envelhecido",(.28,.18,.065),.46,.7),
        "moss":material("Musgo nas juntas",(.075,.12,.038)),
    }




def emission(name,color,strength):
    mat=bpy.data.materials.new("T02 | "+name);mat.use_nodes=True
    bs=mat.node_tree.nodes.get("Principled BSDF")
    bs.inputs["Base Color"].default_value=(*color,1)
    bs.inputs["Emission Color"].default_value=(*color,1);bs.inputs["Emission Strength"].default_value=strength
    return mat

def tower_palette():
    m=palette()
    m["board"]=material("Tabuleiro verde escuro",(.035,.064,.045),.55)
    m["jade"]=emission("Pedra viva",(.05,.6,.26),1.7)
    m["flame"]=emission("Chama âmbar",(1,.34,.045),8)
    m["glass"]=emission("Óculo azul",(.11,.23,.4),.65)
    m["paper"]=material("Páginas antigas",(.41,.34,.21))
    m["wax"]=material("Cera",(.55,.38,.15))
    m["book"]=[material("Couro %d"%i,col) for i,col in enumerate([(.11,.025,.018),(.035,.07,.055),(.11,.075,.023),(.035,.045,.07),(.07,.025,.055)])]
    m["leaf"]=[material("Folha %d"%i,col) for i,col in enumerate([(.035,.095,.028),(.075,.15,.035),(.12,.18,.045)])]
    m["dryleaf"]=[material("Folha seca %d"%i,col) for i,col in enumerate([(.19,.095,.028),(.12,.065,.02),(.24,.16,.045)])]
    m["bark"]=material("Raiz antiga",(.068,.043,.018))
    return m

