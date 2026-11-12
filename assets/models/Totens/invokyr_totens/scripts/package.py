from pathlib import Path
import json,zipfile
from PIL import Image,ImageDraw,ImageFont
R=Path(__file__).resolve().parents[1]
v=json.loads((R/'validation.json').read_text());assert len(v['assets'])==5
names=list(v['assets'])
font=ImageFont.truetype('C:/Windows/Fonts/arialbd.ttf',28)
small=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',20)
sheet=Image.new('RGB',(1500,550),(13,17,23));d=ImageDraw.Draw(sheet)
d.text((40,22),'INVOKYR  /  RELIQUIAS ELEMENTAIS',font=font,fill=(222,226,232))
for i,name in enumerate(names):
    with Image.open(R/'renders'/(name+'.png')) as im:
        im.load();im=im.convert('RGB');im.thumbnail((300,360));sheet.paste(im,(i*300+(300-im.width)//2,80))
    label=name[3:].replace('_',' ').upper()
    d.text((i*300+20,465),label,font=small,fill=(215,224,235))
d.text((40,510),'Modelos 3D renderizados no Blender | Cinco modelos independentes',font=small,fill=(128,143,159))
sheet.save(R/'previa_totens.jpg',quality=94)
for f in (R/'renders').glob('*.png'):
    with Image.open(f) as im:im.verify()
target=R.parent/'Invokyr_Totens_entrega.zip'
with zipfile.ZipFile(target,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as z:
    for f in R.rglob('*'):
        if f.is_file() and f.suffix not in ['.blend1','.pyc']:z.write(f,f.relative_to(R.parent))
with zipfile.ZipFile(target) as z:assert z.testzip() is None
print('PACKAGE_OK',target.stat().st_size)
