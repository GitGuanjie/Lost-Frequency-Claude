#!/usr/bin/env python3
"""Build-only non-game schematic from deterministic DEV27 blueprint JSON."""
import json,matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
DATA=json.loads((ROOT/'data/dev27_field_sectors.json').read_text())['sites']
fig,axes=plt.subplots(2,4,figsize=(17,9),constrained_layout=True)
for ax,site in zip(axes.flat,DATA):
    hx,hz=site['half'];anchor=site['anchor']
    nodes={'ground':(0,0),'sw_foot':(-hx,-hz-12),'ne_foot':(hx,hz+12),
        'sw':(-hx,-hz),'se':(hx,-hz),'ne':(hx,hz),'nw':(-hx,hz),
        'south_mid':(0,-hz),'north_mid':(0,hz)}
    nodes.update({s['id']:(s['pos'][0],s['pos'][2]) for s in site['spurs']})
    for a,b,kind in site['links']:
        p,q=nodes[a],nodes[b]
        if kind=='ground':
            ax.plot([p[0],q[0]],[p[1],q[1]],color='#7c8c8c',linestyle=':',lw=1.4)
        elif kind=='stair':
            ax.plot([p[0],q[0]],[p[1],q[1]],color='#e89e49',lw=3,linestyle='--')
        elif kind=='optional':
            ax.plot([p[0],q[0]],[p[1],q[1]],color='#a05065',lw=3,linestyle=(0,(4,3)))
        else:
            ax.plot([p[0],q[0]],[p[1],q[1]],color='#538ca2',lw=5,solid_capstyle='round',alpha=.8)
    for name,(x,z) in nodes.items():
        if name in ('ground','sw_foot','ne_foot'):
            ax.scatter([x],[z],s=35,color='#d9ae5d',zorder=5)
        elif name.startswith('spur'):
            ax.add_patch(Rectangle((x-2.75,z-2.75),5.5,5.5,facecolor='#b6ced5',edgecolor='#57707d',lw=1.2,zorder=2))
        elif name.endswith('mid'):pass
        else:
            ax.add_patch(Rectangle((x-3.55,z-3.55),7.1,7.1,facecolor='#b6ced5',edgecolor='#57707d',lw=1.2,zorder=2))
    ax.scatter([nodes['ground'][0]],[nodes['ground'][1]],color='#e7b254',s=90,marker='*',zorder=6)
    a,b=site['anchor']
    ax.set_title(f"{site['id']}  {site['style'].upper()}\n{len(site['spurs'])} side spurs  |  {len(site['props'])} GLBs",fontsize=11,weight='bold')
    ax.set_aspect('equal');ax.set_xlim(-39,39);ax.set_ylim(-44,44)
    ax.grid(alpha=.12);ax.set_xticks([]);ax.set_yticks([])
    ax.set_facecolor('#eff2f2')
fig.suptitle('Lost Frequency  /  dev27: eight distinct exploration sectors',fontsize=18,weight='bold')
fig.text(.5,.016,'Layout blueprint, NOT an in-engine screenshot. Blue: upper physical walks  •  Yellow: two independent stairs  •  Red: optional unlocked bridge',ha='center',fontsize=10)
output=ROOT/'docs/production/DEV27_FieldSectors_Design.png'
output.parent.mkdir(parents=True,exist_ok=True)
fig.savefig(output,dpi=145,bbox_inches='tight')
print(output)
