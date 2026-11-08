#!/usr/bin/env python3
"""Design-space diagram (never presented as a Godot screenshot)."""
from pathlib import Path
import json, matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.lines import Line2D
ROOT=Path(__file__).resolve().parents[1]
sc=json.loads((ROOT/'data/dev21_wing_scenarios.json').read_text())
bps={x['id']:x for x in json.loads((ROOT/'data/dev20_atrium_blueprints.json').read_text())['wings']}
packs=sorted({x['pack'] for w in sc['wings'] for x in w['models']})
colors=plt.cm.tab20.colors
colmap={p:colors[i%len(colors)] for i,p in enumerate(packs)}
fig,axs=plt.subplots(2,5,figsize=(16,7.8),dpi=170)
for ax,site in zip(axs.ravel(),sc['wings']):
 id=site['id'];bp=bps[id];plan=bp['floors'][1]
 cells={tuple(c) for c in plan['cells']}
 for c,r in cells:
  ax.add_patch(plt.Rectangle((c,r),1,1,facecolor='#f6f5ef',edgecolor='#b6b6b2',lw=.7))
 for c,r,c2,r2 in plan['doors']:
  ax.plot([c+.5,c2+.5],[r+.5,r2+.5],color='#8f99a1',linewidth=3.7,zorder=1)
 for obj in site['models']:
  if obj['tier']!=1:continue
  c,r=obj['cell'];ox,oz=obj['offset'];
  ax.scatter([c+.5+ox/7],[r+.5+oz/7],s=48,color=colmap[obj['pack']],edgecolor='white',lw=.4,zorder=4)
 ax.scatter([4.5],[2.5],s=72,marker='*',color='#e5730b',edgecolor='#6c3600',lw=.4,zorder=5)
 ax.plot([-.35,0.15],[1.5,1.5],lw=3,color='#1486af')
 ax.plot([2.5,2.5],[-.35,.12],lw=2.5,color='#db8b22',linestyle='--')
 ax.set_xlim(-.45,5.28);ax.set_ylim(4.22,-.43);ax.set_aspect('equal');ax.set_xticks([]);ax.set_yticks([])
 ax.set_title(f'{id}  |  {bp["style"]}',fontsize=11,weight='bold')
legend=[Line2D([0],[0],marker='o',linestyle='',markersize=6,color=colmap[p],label=p) for p in packs]
legend.append(Line2D([0],[0],marker='*',linestyle='',markersize=9,color='#e5730b',label='interactive survey marker'))
fig.legend(handles=legend,loc='lower center',ncol=5,fontsize=8,bbox_to_anchor=(.5,-.005))
fig.suptitle('DEV21 • Level-specific prop palette and actual tier-1 blueprint positions',fontsize=16,weight='bold',y=.99)
fig.text(.5,.945,'Design drawing only — GLB objects are nonblocking; portal lines and floor cells come from the real generator JSON',ha='center',fontsize=10)
fig.tight_layout(rect=[.01,.10,1,.91], h_pad=3.1, w_pad=1.5)
out=Path('/mnt/data/LostFrequency_DEV21_DiversityLayout.png')
fig.savefig(out,bbox_inches='tight')
print(out)
