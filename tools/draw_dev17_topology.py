#!/usr/bin/env python3
"""Render transparent source-derived route plan, never label it a game capture."""
import json
from pathlib import Path
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.lines import Line2D
R=Path(__file__).resolve().parents[1]
G=json.loads((R/'data/dev17_spatial_graphs.json').read_text())['graphs']
COLORS={'road':'#A5AFC0','road_ladder':'#C5CED9','braid':'#18B5A5','crosslink':'#F0A846',
        'hub_rim_step':'#C0C6CF','hub_doorway':'#C0C6CF',
        'ground_perimeter':'#8A929E','base_water_approach':'#8A929E',
        'stair':'#EE8A40','landing':'#7CB3EB','bridge':'#67CAEB','island':'#67CAEB','underwater_ramp':'#8E78DC'}
fig=plt.figure(figsize=(16,6),facecolor='#0A1620')
for idx,sid in enumerate(['L008','L037'],1):
    ax=fig.add_subplot(1,2,idx,projection='3d')
    ax.set_facecolor('#0A1620')
    graph=G[sid]
    for aa,bb,k in graph['edges']:
        a=graph['nodes'][aa];b=graph['nodes'][bb]
        ax.plot([a[0],b[0]],[a[2],b[2]],[a[1],b[1]],color=COLORS[k],alpha=.88,lw=2.4 if k in ('braid','stair','underwater_ramp') else 1.5)
    if sid=='L008':
        ax.set_title('LEVEL 8  /  BRAIDED CAVE ROUTES',color='white',fontsize=15,pad=18)
        ax.view_init(elev=32,azim=-70)
        ax.set_box_aspect([4.2,1.8,1.2]);ax.set_xlim(-1,360);ax.set_ylim(-55,75);ax.set_zlim(-12,14)
        kinds=['road','braid','crosslink']
    else:
        ax.set_title('LEVEL 37  /  STACKED POOLROOMS',color='white',fontsize=15,pad=18)
        ax.view_init(elev=29,azim=-63)
        ax.set_box_aspect([2.2,1.4,1.45]);ax.set_xlim(58,132);ax.set_ylim(-3,32);ax.set_zlim(-10,10)
        kinds=['ground_perimeter','stair','bridge','underwater_ramp']
    ax.set_xlabel('East-West (m)',labelpad=5,color='#B6C3D0')
    ax.set_ylabel('North-South (m)',labelpad=5,color='#B6C3D0')
    ax.set_zlabel('Height (m)',labelpad=3,color='#B6C3D0')
    ax.tick_params(colors='#B6C3D0',labelsize=8)
    ax.xaxis.pane.fill=False;ax.yaxis.pane.fill=False;ax.zaxis.pane.fill=False
    ax.xaxis.line.set_color('#53606C');ax.yaxis.line.set_color('#53606C');ax.zaxis.line.set_color('#53606C')
    legend=[Line2D([0],[0],color=COLORS[k],lw=3,label={'road':'9th Road','braid':'Cave bypass','crosslink':'Inter-branch link','ground_perimeter':'Ground perimeter','stair':'Real stairs','bridge':'Upper bridge','underwater_ramp':'Deep ramps'}[k]) for k in kinds]
    ax.legend(handles=legend,facecolor='#0E2230',labelcolor='white',edgecolor='#436477',loc='upper left',fontsize=9)
    m=json.loads((R/'data/dev17_spatial_graphs.json').read_text())['metrics'][sid]
    ax.text2D(.02,-.02,f"{m['nodes']} graph nodes  |  {m['cycle_rank']} cycles  |  {m['height_span_m']:.1f}m vertical extent",transform=ax.transAxes,color='#D2DFEA',size=10)
fig.text(.5,.016,'SOURCE-DERIVED DESIGN ROUTES  •  NOT AN IN-GAME SCREENSHOT OR VERIFIED PLAYER NAVIGATION',color='#E6BB8D',ha='center',fontsize=10)
fig.subplots_adjust(left=.03,right=.98,top=.9,bottom=.1,wspace=.10)
out=R/'docs/production/DEV17_SpatialRoutes.png'
fig.savefig(out,dpi=180,facecolor=fig.get_facecolor(),bbox_inches='tight')
print(out,out.stat().st_size)
