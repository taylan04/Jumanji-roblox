from pathlib import Path
from PIL import Image, ImageOps, ImageDraw, ImageFont
root=Path(__file__).resolve().parents[1]
labels=['FRENTE','FRENTE ESQUERDA 3/4','LADO ESQUERDO','TRASEIRA ESQUERDA 3/4','COSTAS','TRASEIRA DIREITA 3/4','LADO DIREITO','FRENTE DIREITA 3/4']
files=sorted((root/'renders').glob('0*.png'))
canvas=Image.new('RGB',(1440,2040),(18,21,19));draw=ImageDraw.Draw(canvas)
try:font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',19)
except OSError:font=ImageFont.load_default()
for i,file in enumerate(files):
 im=Image.open(file).convert('RGB');im=ImageOps.contain(im,(720,480));x=(i%2)*720;y=(i//2)*510
 canvas.paste(im,(x,y));draw.text((x+24,y+483),labels[i],font=font,fill=(205,212,191))
canvas.save(root/'eight_views.jpg',quality=94)
