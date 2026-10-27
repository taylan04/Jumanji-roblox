"""Paredes, piso e cobertura com superfícies reais e apoios definidos."""
import math, random
import bpy
from mathutils import Vector
from .geometry import *
from .assets import combine

def compact(coll,name):
    originals=list(coll.objects)
    ob=combine(originals,name,coll)
    for old in originals:
        data=old.data
        bpy.data.objects.remove(old,do_unlink=True)
        if data and data.users==0 and isinstance(data,bpy.types.Mesh):bpy.data.meshes.remove(data)
    return ob

def place_local(coll,theta,apothem):
    # Coordenadas locais: parede em Y=0; frente em -Y.
    m=__import__("mathutils").Matrix.Translation((apothem*math.sin(theta),apothem*math.cos(theta),0)) @ __import__("mathutils").Matrix.Rotation(-theta,4,"Z")
    for obj in coll.objects:obj.matrix_world=m@obj.matrix_world

def masonry(coll,mats,width,z0,z1,opening=None,seed=0):
    rng=random.Random(seed);rowh=.58
    # opening = (radius, spring, bottom): parede superior recortada.
    if opening:
        rad,spring,bottom=opening
        box("Peitoril",(0,.65,(z0+bottom)/2),(width,1.2,bottom-z0),coll,mats["dark"],0)
        for side in (-1,1):
            box("Lateral do vão",(side*(width/2+rad)/2,.65,(bottom+z1)/2),
                (width/2-rad,1.2,z1-bottom),coll,mats["dark"],0)
        pts=arch(rad,spring,32)
        for (x0,a),(x1,b) in zip(pts,pts[1:]):
            prism("Sobre o vão",[(x0,a),(x1,b),(x1,z1),(x0,z1)],.05,1.25,coll,mats["dark"])
    else:box("Núcleo de alvenaria",(0,.65,(z0+z1)/2),(width,1.2,z1-z0),coll,mats["dark"],0)
    def ex(z):
        if not opening:return 0
        rad,spring,bottom=opening
        if z<bottom or z>spring+math.sqrt(3)*rad:return 0
        if z<=spring:return rad+.08
        return max(0,math.sqrt(max(0,4*rad*rad-(z-spring)**2))-rad)+.08
    n=math.ceil((z1-z0)/rowh)
    for row in range(n):
        low=z0+row*rowh+.018;high=min(z1,z0+(row+1)*rowh-.018)
        for j in range(-5,6):
            left=j*1.3+(.65 if row%2 else 0);right=left+1.26
            left=max(-width/2,left);right=min(width/2,right)
            if right-left<.08:continue
            # Nearest silhouette conservatively avoids filling the window.
            cut=max(ex(low),ex(high),ex((low+high)/2))
            intervals=[(left,right)] if cut==0 else [(left,min(right,-cut)),(max(left,cut),right)]
            for a,b in intervals:
                if b-a>.07:
                    box("Cantaria",( (a+b)/2,rng.uniform(-.05,.01),(low+high)/2),(b-a,.22,high-low),coll,rng.choice(mats["stone"]),.023)

def windows(coll,mats,rad=1.3,spring=20.5,bottom=16):
    for radius,y,size in [(rad+.03,-.18,.11),(rad+.25,-.11,.07)]:
        tube("Moldura da janela",[(x,y,z) for x,z in arch_path(radius,spring,bottom,40)],size,coll,mats["trim"],sides=8)
    for x in (-rad,0,rad):
        tube("Montante da janela",[(x,-.05,bottom),(x,-.05,arch_z(x,rad,spring)-.05)],.065,coll,mats["trim"])
    box("Peitoril saliente",(0,-.18,bottom),(3.2,.7,.2),coll,mats["trim"])
    ring("Óculo da janela",(0,-.05,21),.48,.055,coll,mats["trim"])
    tube("Travessa", [(-rad,-.05,19.6),(rad,-.05,19.6)],.06,coll,mats["trim"])

def walls(scene,mats,cfg):
    parent=collection("03 | Oito faces da torre",scene.collection)
    for i in range(8):
        c=collection("Parede_%02d"%i,parent)
        if i%2:masonry(c,mats,12,0,13.8,seed=i+20)
        masonry(c,mats,12,13.8,cfg.wall_height,opening=(1.3,20.5,16),seed=i+30)
        windows(c,mats)
        for z,depth,h in [(13.85,.68,.3),(14.2,.5,.16),(23.4,.62,.25),(23.75,.82,.27)]:
            box("Cinta de cantaria",(0,-.16,z),(12.05,depth,h),c,mats["trim"],.035)
        compact(c,"WallBay_%02d"%i)
        place_local(c,i*math.pi/4,cfg.apothem)
    # Oito pilastras de junção, sem fingir que são pilares principais.
    c=collection("Encontros entre paredes",parent)
    rv=cfg.apothem/math.cos(math.pi/8)
    for i in range(8):
        a=math.pi/8+i*math.pi/4;x=rv*math.sin(a);y=rv*math.cos(a)
        for z0,z1,w in [(0,13.5,.65),(13.5,24.2,.5)]:
            ob=box("Pilastra de canto",(0,0,(z0+z1)/2),(w,.8,z1-z0),c,mats["stone"][2])
            ob.location=(x*.979,y*.979,0);ob.rotation_euler.z=-a
    compact(c,"WallCorners")
    return parent

def floor(scene,mats,cfg):
    c=collection("04 | Piso de lajes",scene.collection)
    rng=random.Random(cfg.seed)
    def clip(poly,n,d):
        out=[]
        for p,q in zip(poly,poly[1:]+poly[:1]):
            a=p[0]*n[0]+p[1]*n[1]-d;b=q[0]*n[0]+q[1]*n[1]-d
            if a<=0:out.append(p)
            if (a<0)!=(b<0):
                t=a/(a-b);out.append((p[0]+t*(q[0]-p[0]),p[1]+t*(q[1]-p[1])))
        return out
    for row in range(-18,19):
        for col in range(-12,13):
            x=col*1.38+(row%2)*.69;y=row*.9
            p=[(x+.025,y+.025),(x+1.355,y+.025),(x+1.355,y+.875),(x+.025,y+.875)]
            for i in range(8):p=clip(p,(math.sin(i*math.pi/4),math.cos(i*math.pi/4)),cfg.apothem+1.3) if p else []
            if len(p)<3:continue
            verts=[(x,y,z) for z in (-.25,-.018+rng.uniform(-.012,.012)) for x,y in p];n=len(p)
            faces=[tuple(range(n-1,-1,-1)),tuple(range(n,2*n))]+[(j,(j+1)%n,(j+1)%n+n,j+n) for j in range(n)]
            mesh("Laje",verts,faces,c,rng.choice(mats["stone"]),.018)
    compact(c,"FloorFlagstones")
    # Rosa dos caminhos, desenhada como incrustação de pedra/bronze no piso.
    for radius in (3.6,3.78,4.15):
        tube("Círculo do tabuleiro",[(radius*math.cos(i*math.tau/96),radius*math.sin(i*math.tau/96),.015) for i in range(96)],
             .025,c,mats["bronze"],True,sides=6)
    return c

def roof(scene,mats,cfg):
    parent=collection("05 | Cobertura e arcos estruturais",scene.collection)
    panels=collection("Painéis maciços do teto",parent)
    ribs=collection("Nervuras e tesouras",parent)
    rv=cfg.apothem/math.cos(math.pi/8)
    for i in range(8):
        a0=math.pi/8+i*math.pi/4;a1=a0+math.pi/4
        e0=Vector((rv*math.sin(a0),rv*math.cos(a0),cfg.wall_height))
        e1=Vector((rv*math.sin(a1),rv*math.cos(a1),cfg.wall_height))
        t0=Vector((1.65*math.sin(a0),1.65*math.cos(a0),cfg.roof_peak))
        t1=Vector((1.65*math.sin(a1),1.65*math.cos(a1),cfg.roof_peak))
        for strip in range(12):
            u0=strip/12;u1=(strip+1)/12
            p=[e0.lerp(e1,u0),e0.lerp(e1,u1),t0.lerp(t1,u1),t0.lerp(t1,u0)]
            verts=[tuple(v+Vector((0,0,dz))) for dz in (0,.23) for v in p]
            mesh("Painel radial",verts,[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)],
                 panels,mats["wood"][strip%4],.012)
        for u in (0,.5):
            low=e0.lerp(e1,u)-Vector((0,0,.12));high=t0.lerp(t1,u)-Vector((0,0,.12))
            tube("Viga radial",[tuple(low.lerp(high,j/12)) for j in range(13)],.18 if u==0 else .10,ribs,mats["wood"][0],sides=8)
    for radius,z in [(cfg.apothem/math.cos(math.pi/8),23.95),(1.65,cfg.roof_peak-.12)]:
        pts=[(radius*math.sin(math.pi/8+i*math.pi/4),radius*math.cos(math.pi/8+i*math.pi/4),z) for i in range(8)]
        tube("Anel vazado estrutural",pts,.24,ribs,mats["wood"][0],True,sides=8)
    # Óculo coberto: superfície real acima do aro, sem disco sobre a sala inteira.
    pts=[(1.66*math.sin(math.pi/8+i*math.pi/4),1.66*math.cos(math.pi/8+i*math.pi/4),cfg.roof_peak+.12) for i in range(8)]
    mesh("Vidro do óculo",pts,[tuple(range(8))],panels,mats["glass"])
    for i in range(4):
        a=i*math.pi/4
        tube("Travessa do óculo",[(-1.6*math.cos(a),-1.6*math.sin(a),cfg.roof_peak),(1.6*math.cos(a),1.6*math.sin(a),cfg.roof_peak)],.055,ribs,mats["iron"])
    # Quatro arcos ogivais apoiados nos capitéis; sem vigas flutuantes.
    spring=8.525+cfg.pillar_extension
    pairs=[((-6,-6),(6,-6)),((6,-6),(6,6)),((6,6),(-6,6)),((-6,6),(-6,-6))]
    for idx,(p,q) in enumerate(pairs):
        p=Vector((*p,0));q=Vector((*q,0));mid=(p+q)/2;t=(q-p).normalized()
        coords=[tuple(mid+t*x+Vector((0,0,z))) for x,z in arch(6,spring,64)]
        tube("Arcada principal %d"%idx,coords,.22,ribs,mats["trim"],sides=12)
        for offset in (-.24,.24):
            normal=Vector((-t.y,t.x,0))
            tube("Filete da arcada",[tuple(Vector(v)+normal*offset) for v in coords],.07,ribs,mats["trim"],sides=8)
    # Nervuras do ápice convergem a partir dos quatro capitéis.
    for x,y in [(-6,-6),(6,-6),(6,6),(-6,6)]:
        points=[]
        for j in range(33):
            t=j/32
            points.append((x*(1-t),y*(1-t),spring+(cfg.roof_peak-.35-spring)*math.sin(t*math.pi/2)))
        tube("Nervura central",points,.19,ribs,mats["wood"][1],sides=10)
    compact(panels,"RoofPanels");compact(ribs,"RoofRibsAndArches")
    return parent

