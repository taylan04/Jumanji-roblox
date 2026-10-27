"""Desgaste concentrado nas bordas; rotas cardeais e mesa permanecem livres."""
import math,random
from mathutils import Vector
from .geometry import *
from .architecture import compact

def leaf(name,pos,size,angle,coll,mat,vertical=False):
    p=Vector(pos);u=Vector((math.cos(angle),math.sin(angle),0))*size
    v=Vector((0,0,size*1.7)) if vertical else Vector((-math.sin(angle),math.cos(angle),.08))*size*1.7
    verts=[tuple(p-u*.55),tuple(p+v),tuple(p+u*.55),tuple(p-v*.35),tuple(p+Vector((0,0,.025)))]
    return mesh(name,verts,[(0,1,4),(1,2,4),(2,3,4),(3,0,4)],coll,mat)

def build(scene,mats,cfg):
    c=collection("09 | Hera, raízes e folhas",scene.collection)
    rng=random.Random(cfg.seed+9)
    # Ramos das juntas superiores das paredes diagonais.
    for quadrant in range(4):
        a=math.pi/4+quadrant*math.pi/2;n=Vector((math.sin(a),math.cos(a),0));t=Vector((math.cos(a),-math.sin(a),0))
        for branch in range(2):
            points=[]
            for i in range(45):
                f=i/44;pos=n*(cfg.apothem-.28)+t*((branch-.5)*5+math.sin(f*7)*.45)+Vector((0,0,15-f*8))
                points.append(tuple(pos))
                if i%2==0:
                    leaf("Hera na parede",pos,.18+rng.random()*.1,a+math.pi/2,c,mats["leaf"][i%3],True)
            tube("Ramo da parede",points,.028,c,mats["bark"],sides=6)
    # Fuste alto: crescimento adicional localizado, sem esticar as folhas aprovadas.
    for x,y in [(-6,-6),(6,-6),(6,6),(-6,6)]:
        points=[]
        for i in range(55):
            t=i/54;ang=t*math.tau*1.2
            pos=(x+.92*math.cos(ang),y+.92*math.sin(ang),8+10*t)
            points.append(pos)
            if i%2==0:leaf("Hera superior",pos,.16,ang,c,mats["leaf"][i%3],True)
        tube("Hera no fuste alto",points,.025,c,mats["bark"],sides=6)
    # Raízes, gramas e folhas caídas em quatro bolsões diagonais.
    for quadrant in range(4):
        a=math.pi/4+quadrant*math.pi/2
        for branch in range(3):
            points=[]
            for i in range(20):
                t=i/19;r=14-t*(2.5+branch*.25);angle=a+branch*.04+math.sin(t*9)*.015
                points.append((r*math.cos(angle),r*math.sin(angle),.05+.03*math.sin(t*7)))
            tube("Raiz sobre lajes",points,.045-branch*.007,c,mats["bark"],sides=7)
        for tuft in range(30):
            angle=a+rng.uniform(-.20,.20);radius=rng.uniform(10,14.5)
            p=Vector((radius*math.cos(angle),radius*math.sin(angle),.01))
            for blade in range(7):
                b=rng.random()*math.tau;h=rng.uniform(.13,.48);w=.018
                q=p+Vector((rng.uniform(-.15,.15),rng.uniform(-.15,.15),0))
                u=Vector((math.cos(b),math.sin(b),0))
                verts=[tuple(q-u*w),tuple(q+u*w),tuple(q+u*.07+Vector((0,0,h*.6))),tuple(q+u*.18+Vector((0,0,h)))]
                mesh("Lâmina de grama",verts,[(0,1,2),(0,2,3)],c,mats["leaf"][blade%3])
        for j in range(45):
            angle=a+rng.uniform(-.28,.28);rad=rng.uniform(7.8,14)
            leaf("Folha caída",(rad*math.cos(angle),rad*math.sin(angle),.032),rng.uniform(.08,.19),rng.random()*math.tau,c,mats["dryleaf"][j%3])
    # Pequenas ilhas de vegetação ao redor das bases, fora do alicerce e das rotas.
    for px,py in [(-6,-6),(6,-6),(6,6),(-6,6)]:
        for tuft in range(32):
            a=rng.random()*math.tau;r=rng.uniform(1.9,2.5)
            dx=r*math.cos(a);dy=r*math.sin(a)
            if abs(dx)<1.73 and abs(dy)<1.73:continue
            p=Vector((px+dx,py+dy,.025))
            for j in range(7):
                b=rng.random()*math.tau;u=Vector((math.cos(b),math.sin(b),0));h=rng.uniform(.15,.32)
                q=p+Vector((rng.uniform(-.10,.10),rng.uniform(-.10,.10),0))
                mesh("Grama junto ao pilar",[tuple(q-u*.015),tuple(q+u*.015),tuple(q+u*.07+Vector((0,0,h*.6))),tuple(q+u*.14+Vector((0,0,h)))],
                     [(0,1,2),(0,2,3)],c,mats["leaf"][j%3])
        for j in range(30):
            a=rng.random()*math.tau;r=rng.uniform(2,2.8)
            leaf("Folha junto ao pilar",(px+r*math.cos(a),py+r*math.sin(a),.035),rng.uniform(.09,.18),a,c,mats["dryleaf"][j%3])

    compact(c,"VegetationAndLeafLitter")
    return c


