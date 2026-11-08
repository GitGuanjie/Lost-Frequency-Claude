#!/usr/bin/env python3
"""Dev20 blueprint route overview. A design schematic, NOT a Godot capture."""
from pathlib import Path
import json, matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle
R=Path(__file__).resolve().parents[1]
d=json.loads((R/'data/dev20_atrium_blueprints.json').read_text())
fig, axes=plt.subplots(2,5,figsize=(19,8.8),dpi=160)
for ax,w in zip(axes.flat,d['wings']):
 plan=w['floors'][1]
 occ=set(map(tuple,plan['cells']))
 for r in range(4):
  for c in range(5):
   if (c,r) not in occ:
    ax.add_patch(Rectangle((c-.44, r-.44),.88,.88,facecolor='#D9DDE3',edgecolor='none',alpha=.9))
 for a,b,c,e in plan['doors']:
  ax.plot([a,c],[b,e],color=('#247E99' if not w['open_air'] else '#528554'),lw=4,solid_capstyle='round',zorder=1)
 for c,r in occ:
  ax.scatter([c],[r],s=90,c='#E4B66D' if w['open_air'] else '#B9D9EA',edgecolors='#34495e',lw=.65,zorder=2)
 gate=w['shutter_edge']
 ax.scatter([(gate[0]+gate[2])/2],[(gate[1]+gate[3])/2],s=60,c='#A93226',marker='s',edgecolors='white',lw=.6,zorder=3)
 ax.scatter([0], [1],s=115,c='#F0D24D',edgecolors='#333',marker='*',zorder=4)
 ax.set_xlim(-.7,4.7);ax.set_ylim(3.7,-.7);ax.set_aspect('equal');ax.axis('off')
 ax.set_title(w['id']+'  /  '+ ('Open-air' if w['open_air'] else 'Interior')+'  /  '+w['style'],fontsize=11,fontweight='bold',pad=10)
fig.suptitle('Lost Frequency DEV20  •  Seeded mid-tier exploration networks',fontsize=21,y=.98)
fig.text(.5,.05,'Middle floor only (each site also has lower + upper floors and 4 exterior stairs). Gold star: entrance  •  Red: optional shutter  •  Grey: open atrium void. DESIGN GRAPH ONLY',ha='center',fontsize=11)
fig.tight_layout(rect=(0,.08,1,.945),w_pad=.5,h_pad=1.6)
out=Path('/mnt/data/LostFrequency_DEV20_TopologyOverview.png')
fig.savefig(out,dpi=160,facecolor='white')
print(out,out.stat().st_size)
