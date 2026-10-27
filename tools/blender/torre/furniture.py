"""Mesa, tabuleiro original, livros e iluminação visível."""
import math, random
import bpy
from mathutils import Vector
from .geometry import *
from .architecture import compact,place_local

def beam(name,a,b,width,coll,mat):
    ob=box(name,(0,0,0),(width,width,(Vector(b)-Vector(a)).length),coll,mat,.035)
    ob.location=(Vector(a)+Vector(b))/2
    ob.rotation_euler=(Vector(b)-Vector(a)).to_track_quat("Z","Y").to_euler()
    return ob

def disk(name,center,radius,depth,coll,mat,segments=32):
    x,y,z=center
    v=[(x+radius*math.cos(i*math.tau/segments),y+radius*math.sin(i*math.tau/segments),z+d) for d in (-depth/2,depth/2) for i in range(segments)]
    f=[tuple(range(segments-1,-1,-1)),tuple(range(segments,2*segments))]+[(j,(j+1)%segments,(j+1)%segments+segments,j+segments) for j in range(segments)]
    return mesh(name,v,f,coll,mat,.015)

def text_flat(name,body,loc,size,coll,mat):
    data=bpy.data.curves.new(name,"FONT");data.body=body;data.size=size;data.align_x="CENTER";data.extrude=.002
    ob=bpy.data.objects.new(name,data);coll.objects.link(ob);ob.location=loc;data.materials.append(mat)
    return ob

def creature(coll,mat,cx,cy,z,kind,scale=1):
    def line(points,r=.018):
        return tube("Gravura "+kind,[(cx+x*scale,cy+y*scale,z) for x,y in points],r*scale,coll,mat,sides=6)
    if kind=="Cervo":
        line([(-.14,.12),(0,-.2),(.14,.12),(0,.21),(-.14,.12)])
        for side in (-1,1):
            line([(side*.08,.17),(side*.23,.36),(side*.21,.52)])
            line([(side*.21,.34),(side*.39,.4),(side*.42,.52)])
            line([(side*.2,.46),(side*.1,.52)])
    elif kind=="Aranha":
        line([(.12*math.cos(i*math.tau/32),.2*math.sin(i*math.tau/32)) for i in range(33)])
        for side in (-1,1):
            for j in range(4):line([(side*.1,.12-j*.08),(side*.27,.26-j*.15),(side*.42,.34-j*.23)])
    elif kind=="Serpente":
        line([((.28-.18*t/50)*math.cos(t*.23),(.28-.18*t/50)*math.sin(t*.23)) for t in range(51)])
        line([(.25,0),(.42,.12),(.51,.02),(.39,-.07),(.25,0)])
    else:
        line([(-.42,.2),(-.22,-.18),(0,-.28),(.22,-.18),(.42,.2),(.13,.08),(0,.3),(-.13,.08),(-.42,.2)])
        for side in (-1,1):
            line([(side*.06,.03),(side*.12,-.04),(side*.18,.03),(side*.06,.03)])
        line([(-.045,-.09),(0,-.17),(.045,-.09)])
        
def table(scene,mats):
    c=collection("06 | Mesa e tabuleiro",scene.collection)
    for x in (-1.35,1.35):
        for y in (-1.1,1.1):
            beam("Pé de carvalho",(x*1.05,y*1.05,.05),(x,y,1.45),.27,c,mats["wood"][0])
            box("Sapata",(x*1.05,y*1.05,.12),(.42,.42,.21),c,mats["wood"][0])
    for y in (-1.1,1.1):beam("Travessa inferior",(-1.43,y,.4),(1.43,y,.4),.2,c,mats["wood"][1])
    beam("Travessa longa",(0,-1.1,.4),(0,1.1,.4),.22,c,mats["wood"][0])
    for x in (-1.35,1.35):
        beam("Escora",(x,-1,.43),(x,.65,1.4),.14,c,mats["wood"][1])
    for i in range(6):
        x=-1.7+i*.67
        profile=[(x,1.39),(x+.65,1.38),(x+.66,1.63),(x+.42,1.67),(x+.02,1.65)]
        prism("Tábua rústica",profile,-1.7-(i%2)*.03,1.7+(i%3)*.02,c,mats["wood"][i%4],.025)
    for x in (-1.65,1.65):
        box("Cinta de ferro",(x,0,1.665),(.065,3.4,.025),c,mats["iron"],.009)
        for y in (-1.5,1.5):
            disk("Prego antigo",(x,y,1.69),.04,.025,c,mats["bronze"],8)
    # Tabuleiro original, sem símbolos ou ilustrações de outras obras.
    box("Caixa do tabuleiro",(0,0,1.78),(2.62,2.62,.18),c,mats["wood"][0],.06)
    box("Superfície entalhada",(0,0,1.88),(2.42,2.42,.06),c,mats["board"],.03)
    for rad in (1.22,1.12):
        tube("Filete do tabuleiro",[(-rad,-rad,1.93),(rad,-rad,1.93),(rad,rad,1.93),(-rad,rad,1.93)],.018,c,mats["bronze"],True,sides=6)
    for i in range(32):
        a=math.tau*i/32
        x=.88*math.cos(a);y=.88*math.sin(a)
        ob=box("Casa do caminho",(0,0,1.94),(.12,.10,.023),c,mats["trim"] if i%4 else mats["bronze"],.008)
        ob.location=(x,y,0);ob.rotation_euler.z=a
    for i,(kind,x,y) in enumerate([("Cervo",0,.5),("Aranha",.52,0),("Serpente",0,-.5),("Coruja",-.52,0)]):
        creature(c,mats["bronze"],x,y,1.956,kind,.52)
    disk("Centro do pacto",(0,0,1.955),.17,.08,c,mats["iron"],16)
    disk("Pedra verde central",(0,0,2.005),.105,.04,c,mats["jade"],12)
    for i,(x,y) in enumerate([(-1,-1),(1,-1),(1,1),(-1,1)]):
        disk("Peão cooperativo",(x,y,1.99),.055,.15,c,mats["bronze"],10)
    text_flat("Nome gravado","O PACTO DAS RAIZES",(0,-1.07,1.947),.09,c,mats["bronze"])
    for x,y,num in [(.95,-1.48,5),(.63,-1.5,3)]:
        box("Dado",(x,y,1.78),(.19,.19,.19),c,mats["trim"],.025)
        for u,v in ([(-1,-1),(1,1),(0,0)] if num==3 else [(-1,-1),(-1,1),(1,-1),(1,1),(0,0)]):
            disk("Ponto do dado",(x+u*.045,y+v*.045,1.88),.013,.007,c,mats["iron"],8)
    compact(c,"TableAndBoard")
    return c

def book(coll,mats,center,width=.18,height=.55,depth=.35,color=0):
    x,y,z=center
    box("Miolo de páginas",(x,y,z+height/2),(width-.025,depth-.025,height-.04),coll,mats["paper"],.006)
    for dx in (-width/2,width/2):
        box("Capa do livro",(x+dx,y,z+height/2),(.015,depth,height),coll,mats["book"][color%len(mats["book"])],.005)
    box("Lombada",(x,y-depth/2,z+height/2),(width,.025,height),coll,mats["book"][color%len(mats["book"])],.008)
    for dz in (.10,height-.10):
        box("Nervura dourada",(x,y-depth/2-.015,z+dz),(width,.018,.018),coll,mats["bronze"],.004)

def shelves(scene,mats,cfg):
    parent=collection("07 | Bibliotecas nas paredes",scene.collection)
    rng=random.Random(cfg.seed)
    for i in (1,3,5,7):
        c=collection("Estante_%d"%i,parent)
        radius=2.05;spring=4.6
        prof=[(-radius,.15),(radius,.15)]+list(reversed(arch(radius,spring,32)))
        prism("Fundo da estante",prof,-.5,-.28,c,mats["wood"][0],.025)
        tube("Moldura arqueada",[(x,-1.0,z) for x,z in arch_path(radius,spring,.15)],.13,c,mats["wood"][1],sides=8)
        for x in (-2.02,2.02):box("Montante",(x,-.75,2.5),(.22,.8,4.8),c,mats["wood"][0])
        for row in range(5):
            z=.4+row*.87
            box("Prateleira",(0,-.78,z),(4.2,.86,.13),c,mats["wood"][1])
            x=-1.77
            while x<1.7:
                w=rng.uniform(.12,.24);h=rng.uniform(.45,.72)
                if rng.random()>.22:book(c,mats,(x,-.76,z+.07),w,h,.48,rng.randrange(5))
                x+=w+.04
        compact(c,"Bookshelf_%d"%i)
        place_local(c,i*math.pi/4,cfg.apothem)
    # Pequenos grupos caídos nas laterais, longe do centro e dos eixos de passagem.
    c=collection("Livros caídos",parent)
    for i in range(14):
        angle=math.pi/4+(i%4)*math.pi/2;r=9.3+rng.uniform(-.5,.5)
        x=r*math.cos(angle)+rng.uniform(-.6,.6);y=r*math.sin(angle)+rng.uniform(-.6,.6)
        sub=collection("Livro_%d"%i,parent);book(sub,mats,(0,0,0),.18,.6,.42,i)
        ob=compact(sub,"Livro caído")
        ob.rotation_euler=(math.pi/2,0,rng.uniform(-math.pi,math.pi));ob.location=(x,y,.3)
    return parent

def lamp(coll,mats,center,scale=1):
    x,y,z=center
    for dz,rad in [(-.4,.25),(.38,.22)]:
        disk("Tampa da lanterna",(x,y,z+dz*scale),rad*scale,.08*scale,coll,mats["iron"],8)
    for i in range(4):
        a=i*math.pi/2+math.pi/4
        tube("Armação da lanterna",[(x+.2*math.cos(a)*scale,y+.2*math.sin(a)*scale,z-.38*scale),
                                   (x+.2*math.cos(a)*scale,y+.2*math.sin(a)*scale,z+.38*scale)],.028*scale,coll,mats["iron"],sides=6)
    disk("Vela",(x,y,z-.13*scale),.09*scale,.38*scale,coll,mats["wax"],12)
    verts=[(x,y,z+.26*scale)]+[(x+.065*math.cos(i*math.tau/8)*scale,y+.065*math.sin(i*math.tau/8)*scale,z+.09*scale) for i in range(8)]+[(x,y,z+.04*scale)]
    mesh("Chama",verts,[(0,1+i,1+(i+1)%8) for i in range(8)]+[(9,1+(i+1)%8,1+i) for i in range(8)],coll,mats["flame"])

def light(scene,name,pos,power,color,size=.3,kind="POINT",target=None):
    c=bpy.data.collections.get("T02 | Luzes")
    if c is None:c=collection("T02 | Luzes",scene.collection)
    data=bpy.data.lights.new(name,kind);data.energy=power;data.color=color
    if kind=="POINT":data.shadow_soft_size=size
    else:data.shape="DISK";data.size=size
    ob=bpy.data.objects.new(name,data);c.objects.link(ob);ob.location=pos
    if target:ob.rotation_euler=(Vector(target)-ob.location).to_track_quat("-Z","Y").to_euler()
    return ob

def lamps(scene,mats,cfg):
    c=collection("08 | Lamparinas e lustre",scene.collection)
    for i in range(8):
        a=(i//2)*math.pi/2
        n=Vector((math.sin(a),math.cos(a),0));t=Vector((math.cos(a),-math.sin(a),0))
        pos=n*(cfg.apothem-.65)+t*(4.45 if i%2 else -4.45)+Vector((0,0,5.1))
        lamp(c,mats,pos,1.35)
        light(scene,"Lamparina_%d"%i,pos,800,(1,.47,.16),.32)
        radial=Vector((math.sin(a),math.cos(a),0))
        beam("Braço de ferro",pos+radial*.1+Vector((0,0,.65)),pos+radial*1+Vector((0,0,.9)),.065,c,mats["iron"])
    z=11.7;rr=1.55
    tube("Aro do lustre",[(rr*math.cos(i*math.tau/64),rr*math.sin(i*math.tau/64),z) for i in range(64)],.065,c,mats["iron"],True)
    for i in range(8):
        a=i*math.tau/8;lamp(c,mats,(rr*math.cos(a),rr*math.sin(a),z+.45),.75)
        if i%2==0:tube("Suspensão",[(rr*math.cos(a),rr*math.sin(a),z),(0,0,z+3)],.024,c,mats["iron"],sides=6)
    tube("Corrente central",[(0,0,z+3),(0,0,cfg.roof_peak-.4)],.035,c,mats["iron"],sides=8)
    light(scene,"Luz do lustre",(0,0,z),1800,(1,.60,.27),1)
    light(scene,"Reflexo do tabuleiro",(0,0,2.12),7,(.22,1,.52),.14)
    compact(c,"LanternsAndChandelier")
    return c


