"""Gera uma torre nova usando o portal e o pilar aprovados. Nunca sobrescreve fontes."""
import argparse,hashlib,json,sys
from pathlib import Path
import bpy
import faulthandler; faulthandler.enable()
sys.dont_write_bytecode=True
HERE=Path(__file__).resolve().parent
if str(HERE) not in sys.path:sys.path.insert(0,str(HERE))
from torre.config import Config
from torre.materials import tower_palette
from torre import assets,architecture,furniture,vegetation,preview,validate

def main():
    p=argparse.ArgumentParser()
    p.add_argument("--portal",type=Path,default=HERE.parents[1]/"assets/models/portal_estudo_v01.blend")
    p.add_argument("--pillar",type=Path,default=HERE.parents[1]/"assets/models/pilar_gotico.blend")
    p.add_argument("--output",type=Path,default=HERE.parents[1]/"assets/models/torre_tabuleiro_v02.blend")
    p.add_argument("--render",action="store_true");p.add_argument("--draft",action="store_true")
    p.add_argument("--views",default="1,2,3,4")
    args=p.parse_args(sys.argv[sys.argv.index("--")+1:] if "--" in sys.argv else [])
    target=args.output.resolve()
    if target.exists():raise FileExistsError("Escolha uma saída nova: "+str(target))
    if "T02 | Torre do Tabuleiro" in bpy.data.scenes:raise RuntimeError("Use arquivo novo para gerar outra versão.")
    sources={str(f.resolve()):hashlib.sha256(f.read_bytes()).hexdigest() for f in (args.portal,args.pillar)}
    if str(target) in sources:raise ValueError("Saída é fonte aprovada")
    scene=bpy.data.scenes.new("T02 | Torre do Tabuleiro");bpy.context.window.scene=scene
    scene["generator"]="tower_02";scene.unit_settings.system="METRIC"
    cfg=Config();mats=tower_palette()
    library=bpy.data.collections.new("T02 | Biblioteca de malhas")
    print("T02: preparando os modelos aprovados",flush=True)
    stone,leafdata=assets.portal_templates(args.portal,scene,library)
    roots,doors=assets.place_portals(scene,stone,leafdata,cfg)
    pillar=assets.pillar_template(args.pillar,scene,library,cfg,mats);assets.place_pillars(scene,pillar,cfg)
    print("T02: arquitetura",flush=True)
    architecture.walls(scene,mats,cfg);architecture.floor(scene,mats,cfg);architecture.roof(scene,mats,cfg)
    print("T02: mesa, biblioteca e vegetação",flush=True)
    furniture.table(scene,mats);furniture.shelves(scene,mats,cfg);furniture.lamps(scene,mats,cfg)
    vegetation.build(scene,mats,cfg)
    print("T02: verificando geometria",flush=True)
    report=validate.run(scene,cfg,doors)
    cams=preview.setup(scene,mats,cfg)
    for f,h in sources.items():assert hashlib.sha256(Path(f).read_bytes()).hexdigest()==h
    report.update({"blender":bpy.app.version_string,"source_sha256":sources,
                   "height":cfg.roof_peak,"width_inside":round(cfg.apothem*2,3),
                   "materials":"Procedurais de estudo; ainda sem baking PBR/atlas.",
                   "status":"Cena Blender; importação e desempenho Roblox pendentes."})
    scene.camera=cams[0];scene.render.resolution_x=cams[0]["resolution_x"];scene.render.resolution_y=cams[0]["resolution_y"]
    scene.render.resolution_percentage=100
    for screen in bpy.data.screens:
        for area in screen.areas:
            if area.type=="VIEW_3D":
                area.spaces.active.region_3d.view_perspective="CAMERA"
                area.spaces.active.shading.type="MATERIAL"
                area.spaces.active.overlay.show_overlays=False
    target.parent.mkdir(parents=True,exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(target),compress=True)
    target.with_suffix(".json").write_text(json.dumps(report,indent=2,ensure_ascii=False),encoding="utf-8")
    print("T02_VALIDATED "+json.dumps(report,ensure_ascii=False),flush=True)
    if args.render:
        for index in [int(i)-1 for i in args.views.split(",")]:
            cam=cams[index];preview.render(scene,cam,target.with_name(target.stem+"_"+cam.name+".png"),args.draft)
    print("T02: concluído",flush=True)
if __name__=="__main__":main()


