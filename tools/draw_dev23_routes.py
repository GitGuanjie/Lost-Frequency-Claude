#!/usr/bin/env python3
"""Schematic generated from DEV23 source coordinates, NOT a Godot screenshot."""
import json
from pathlib import Path
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d.art3d import Poly3DCollection
ROOT=Path(__file__).resolve().parents[1]
W=json.loads((ROOT/'data/dev23_landmark_spurs.json').read_text())['sites'][0]
rise=W['rise']
fig=plt.figure(figsize=(13,8.5))
ax=fig.add_subplot(111,projection='3d')

def slab(x0,x1,z0,z1,y):
    verts=[[(x0,z0,y),(x1,z0,y),(x1,z1,y),(x0,z1,y)]]
    ax.add_collection3d(Poly3DCollection(verts,alpha=.18,linewidth=.8))
def line(pts,style='-',linewidth=3,label=None):
    ax.plot([p[0] for p in pts],[p[1] for p in pts],[p[2] for p in pts],style,linewidth=linewidth,label=label)

def lbl(x,z,y,s):ax.text(x,z,y+0.4,s,fontsize=9,ha='center')
# Plot axes: physical x, z, height y (renamed vertical for readability).
slab(-5.1,5.1,-11,0,0);slab(-6,6,-27,-11,0)
slab(-20.5,-8.5,-51,-39,rise);slab(8.5,20.5,-51,-39,rise)
slab(-37.5,-25.5,-27,-15,-rise)
line([(0,-8,0),(0,-19,0)],label='Existing vista -> approach court')
line([(0,-19,0),(-4.5,-24,0),(-4.5,-45,rise),(-14.5,-45,rise)],label='Independent west ascent')
line([(0,-19,0),(4.5,-24,0),(4.5,-45,rise),(14.5,-45,rise)],label='Independent east ascent')
line([(0,-19,0),(-4.5,-21,0),(-25.5,-21,-rise),(-31.5,-21,-rise)],label='Separate lower descent')
line([(-14.5,-45,rise),(14.5,-45,rise)],'--',linewidth=3,label='Physical bridge unlocked by survey')
for x,z,y in [(0,-19,0),(-14.5,-45,rise),(14.5,-45,rise)]:
    ax.scatter([x],[z],[y],s=100,marker='o')
lbl(0,-8,0,'Existing DEV22 terrace')
lbl(0,-19,0,'Survey 1 / main court')
lbl(-14.5,-45,rise,'Survey 2 / west deck')
lbl(14.5,-45,rise,'Survey 3 / east deck')
lbl(-31.5,-21,-rise,'Lower archive')
lbl(0,-45,rise,'Unlocked cross-gallery')
ax.set_title('DEV23 | Physical 3D exploration routes\nL028 representative (six levels also have the lower branch)',fontsize=15)
ax.set_xlabel('Local X (m)');ax.set_ylabel('Local Z (m)');ax.set_zlabel('Elevation (m)')
ax.view_init(elev=23,azim=-64)
ax.set_box_aspect((1.0,1.08,.35))
ax.set_xlim(-39,25);ax.set_ylim(-54,3);ax.set_zlim(-5,7)
ax.legend(loc='lower right',fontsize=9)
fig.text(.07,.06,'Source-data topology only. Ground planes, staircase collision and unlockable bridge require Godot runtime QA.',fontsize=9)
fig.tight_layout(rect=(0,.07,1,1))
for suffix in ('png','svg'):
    name=ROOT/'docs/production'/f'DEV23_LandmarkRoutes.{suffix}'
    fig.savefig(name,dpi=190,bbox_inches='tight')
    print(name)
