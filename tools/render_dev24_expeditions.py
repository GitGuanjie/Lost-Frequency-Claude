#!/usr/bin/env python3
"""Render actual JSON design topology (NOT an in-game screenshot)."""
from PIL import Image, ImageDraw, ImageFont
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[1]
S=json.loads((ROOT/'data/dev24_expeditions.json').read_text())['sites']
W,H=1520,1700
im=Image.new('RGB',(W,H),(13,21,29));d=ImageDraw.Draw(im)
try:
 F=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',20)
 SFont=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',13)
except OSError: F=ImageFont.load_default();SFont=F
cw,ch=740,290
styles={'keep_forge':'BLUE KEEP','canopy':'BONE FOREST','highway':'HIGHWAY','red_keep':'RED FORTRESS','fog_trail':'FOG RIDGE',
'shelter':'RESIDENCE','toy_town':'MIS-SCALED TOWN','roots':'ROOTWOOD','attraction':'ABANDONED PARK','neon':'SYNTHWAVE'}
for i,rec in enumerate(S):
 col=i%2;row=i//2; sx=18+col*(cw+20);sy=75+row*(ch+20)
 d.rounded_rectangle([sx,sy,sx+cw,sy+ch],12,fill=(24,33,44),outline=(67,83,96),width=2)
 d.text((sx+14,sy+9),rec['id']+'  /  '+styles[rec['style']],font=F,fill=(230,236,241))
 nodepos=rec['nodes']; xs=[p[0] for p in nodepos.values()]; zs=[p[2] for p in nodepos.values()]
 mx,Mx=min(xs),max(xs);mz,Mz=min(zs),max(zs)
 scale=min(590/max(Mx-mx,20),198/max(Mz-mz,18),4.4)
 def xy(p):return (round(sx+70+(p[0]-mx)*scale),round(sy+60+(p[2]-mz)*scale))
 for edge in rec['links']:
  a=xy(nodepos[edge['a']]);b=xy(nodepos[edge['b']]);kind=edge['kind']
  color={'walk':(114,151,164),'stair':(245,204,111),'unlockable':(255,129,126)}[kind]
  d.line([a,b],fill=color,width=5 if kind=='stair' else 3)
  if kind=='unlockable':
   pos=((a[0]+b[0])//2,(a[1]+b[1])//2);d.ellipse([pos[0]-5,pos[1]-5,pos[0]+5,pos[1]+5],fill=color)
 for name,p in nodepos.items():
  x,y=xy(p);u=name.startswith('u');colour=(126,191,233) if u else (102,197,167)
  d.rounded_rectangle((x-12,y-12,x+12,y+12),4,fill=colour,outline=(9,20,32),width=2)
  d.text((x+15,y-7),name,font=SFont,fill=(232,235,236))
 d.text((sx+14,sy+ch-27),f"{len(nodepos)} walkable decks  •  {len(rec['links'])} links  •  30 existing GLB props",font=SFont,fill=(173,185,196))
d.text((24,17),'LOST FREQUENCY dev24  /  TEN DIFFERENT EXPEDITION GRAMMARS',font=F,fill=(234,241,248))
d.text((25,H-22),'Green: base altitude   Blue: upper altitude   Yellow: stairs   Red: optional unlockable bridge   •   SOURCE DESIGN ONLY / NOT GODOT RENDER',font=SFont,fill=(197,211,223))
out=ROOT/'docs/production/DEV24_ExpeditionMorphologies.png';out.parent.mkdir(parents=True,exist_ok=True);im.save(out)
print(out)
