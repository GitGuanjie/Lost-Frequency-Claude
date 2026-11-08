#!/usr/bin/env python3
"""Plot the authored L197 high-gallery route coordinates (design, not runtime)."""
from pathlib import Path
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D  # noqa: F401
P=Path(__file__).resolve().parents[1]
G=[('Turquoise',-12.8,-46,-23,4.2),('Amethyst',12.8,13,36,4.7),('Ruby',-12.8,62,85,5.1),('Onyx',12.8,109,132,4.5)]
fig=plt.figure(figsize=(13.7,7.8),dpi=145)
ax=fig.add_subplot(111,projection='3d')
for idx,(name,x,z0,z1,h) in enumerate(G):
    c=f'C{idx}'
    ax.plot([x,x],[z0,z1],[h,h],c=c,lw=7,alpha=.7)
    ax.plot([x,x],[z0-10,z0],[0,h],c=c,lw=2.8,marker='o',markersize=4)
    ax.plot([x,x],[z1+10,z1],[0,h],c=c,lw=2.8,marker='o',markersize=4)
    ax.plot([0,x,x,0],[z0-10,z0-10,z1+10,z1+10],[0,0,0,0],c=c,lw=1.3,alpha=.6,linestyle=':')
    ax.text(x,z0+5,h+.8,f'{name}  {h:.1f}m',fontsize=9)
ax.plot([0,0],[-59,145],[0,0],color='gray',lw=3,alpha=.7,label='Original central route')
ax.set_xlabel('X (m)');ax.set_ylabel('Z (m) — zone sequence');ax.set_zlabel('Elevation (m)')
ax.set_xlim(-19,19);ax.set_ylim(-60,146);ax.set_zlim(-1,8)
ax.view_init(elev=27,azim=-66)
ax.set_title('Lost Frequency dev26 — L197: four elevated galleries and eight return ramps\nDESIGN COORDINATES • engine collision and walkability NOT verified',fontsize=12,pad=16)
ax.legend(loc='upper left');fig.tight_layout()
path=P/'docs/production/DEV26_CrystalGallery_Design.png';path.parent.mkdir(parents=True,exist_ok=True)
fig.savefig(path,dpi=145,bbox_inches='tight');plt.close(fig)
print(path)
