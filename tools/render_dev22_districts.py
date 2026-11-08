#!/usr/bin/env python3
"""Render source-backed DEV22 design graphs (not Godot screenshots)."""
import json
from pathlib import Path
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.patches as patch
from matplotlib.lines import Line2D
import numpy as np
ROOT=Path(__file__).resolve().parents[1]
D=json.loads((ROOT/'data/dev22_narrative_districts.json').read_text())['districts']
OUT=ROOT/'docs/production'
OUT.mkdir(parents=True,exist_ok=True)
fig,axes=plt.subplots(5,2,figsize=(13.6,23.4))
for ax,w in zip(axes.flat,D):
    plan=w['floors'][1]
    occupied={tuple(c) for c in plan['cells']}
    for x in range(4):
        for y in range(4):
            if (x,y) in occupied:
                color='#dcece6' if w['open_air'] else '#e5e8ed'
                ax.add_patch(patch.Rectangle((x-0.46,y-0.46),.92,.92,facecolor=color,edgecolor='#97a4af',lw=1.0))
            else:
                ax.add_patch(patch.Rectangle((x-0.46,y-0.46),.92,.92,facecolor='#262f43',edgecolor='#262f43'))
    extras={tuple(e) for e in plan['extra_edges']}
    gate=tuple(w['shutter_edge'])
    for e in plan['doors']:
        x,y,xx,yy=e
        color='#b44145' if tuple(e)==gate else ('#478b8e' if tuple(e) in extras else '#3c667b')
        ax.plot([x,xx],[y,yy],lw=3.1 if tuple(e)==gate else 2.4,color=color,solid_capstyle='round',zorder=3)
    ax.scatter([0,3],[0,3],marker='^',color='#226b87',s=90,zorder=8)
    ax.set(xlim=(-.7,3.7),ylim=(3.7,-.7))
    ax.set_xticks([]);ax.set_yticks([]);ax.set_aspect('equal')
    cycles=sum(f['cycle_rank'] for f in w['floors'])
    ax.set_title(f"{w['id']} · {w['style'].replace('_',' ').title()}\n{w['tiers']} elevations / {cycles} horizontal loops / {len(w['models'])+2} GLB placements",fontsize=10,loc='left',pad=8)
    for spine in ax.spines.values():spine.set_visible(False)
fig.subplots_adjust(left=.06,right=.96,bottom=.03,top=.91,hspace=.72,wspace=.23)
fig.text(.06,.975,'LOST FREQUENCY — DEV22 | 10 themed districts',fontsize=17,weight='bold',va='top')
fig.text(.06,.954,'Middle-floor graph designs · dark = void · red = gated optional route · triangles = stairs',fontsize=10,va='top')
fig.savefig(OUT/'DEV22_ThemeDistricts_Overview.png',dpi=180,bbox_inches='tight')
plt.close(fig)

w=next(w for w in D if w['id']=='L320')
fig=plt.figure(figsize=(12,9))
ax=fig.add_subplot(111,projection='3d')
levels=w['floors']; rise=w['rise']
for tier,plan in enumerate(levels):
    z=tier*rise
    for c,r in plan['cells']:
        ax.plot([c-.36,c+.36,c+.36,c-.36,c-.36],
                [r-.36,r-.36,r+.36,r+.36,r-.36],
                [z]*5,linewidth=.85,alpha=.72,color=plt.cm.viridis(tier/(len(levels)-1)))
    for c,r,d,s in plan['doors']:
        ax.plot([c,d],[r,s],[z,z],linewidth=1.35,color='#333333',alpha=.56)
for t in range(len(levels)-1):
    lo=t*rise; hi=(t+1)*rise
    ax.plot([4.15,4.15],[0,3],[lo,hi],color='#bf565d',linewidth=3)
    ax.plot([-.92,-.92],[3,0],[lo,hi],color='#bf565d',linewidth=3)
ax.plot([2,2],[3,5.0],[0,0],color='#53927d',linewidth=3)
ax.plot([1,1],[0,-1.65],[0,0],color='#53927d',linewidth=3)
ax.set_xlabel('cells E–W');ax.set_ylabel('cells N–S');ax.set_zlabel('height (m)')
ax.set_title('L320 Folding Point — DEV22: five-storey exploration structure\nStructural design; Godot body traversal not verified')
ax.set_zlim(0,5*rise+1);ax.view_init(elev=27,azim=-57)
fig.savefig(OUT/'DEV22_L320_FiveStorey_Design.png',dpi=180,bbox_inches='tight')
plt.close(fig)
print(OUT/'DEV22_ThemeDistricts_Overview.png')
print(OUT/'DEV22_L320_FiveStorey_Design.png')
