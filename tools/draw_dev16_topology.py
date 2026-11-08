#!/usr/bin/env python3
"""Compact source-derived architecture schematic; NOT gameplay imagery."""
import json, math, html
from pathlib import Path
R=Path(__file__).resolve().parents[1]
D=json.loads((R/'data/vertical_routes_dev16.json').read_text())
G=D['graphs'];names=list(G)
site_by_level={}
for s in D['sites']:site_by_level.setdefault(s['level'],[]).append(s)
# 3-column overview, visually distinct descent/paired architecture
W,H=1500,1770
p=['<svg xmlns="http://www.w3.org/2000/svg" width="1500" height="1770" viewBox="0 0 1500 1770">',
'<rect width="100%" height="100%" fill="#10151e"/>',
'<style>text{font-family:Arial,Helvetica,sans-serif} .title{fill:#ecf5ff} .small{fill:#b7c7d8} .muted{fill:#8499b0} .chip{fill:#52c3ae}</style>',
'<text x="35" y="55" font-size="34" font-weight="bold" class="title">LOST FREQUENCY // DEV16</text>',
'<text x="35" y="87" font-size="17" class="small">14 maps · 17 multi-tier sites · 3 paired skybridge systems · 905 nodes / 1123 edges / 232 cycles</text>',
'<text x="35" y="111" font-size="14" class="muted">Topology design reconstruction only. Not a Godot screenshot or certified player route.</text>']
cardw=465;cardh=312
palette=['#80d6cd','#72bcd6','#edbd7b','#b4a1e3']
for index,sid in enumerate(names):
 ix=index%3;iy=index//3
 xx=34+ix*488; yy=134+iy*321
 sites=site_by_level[sid];m=G[sid]['metrics']
 p += [f'<rect x="{xx}" y="{yy}" width="{cardw}" height="{cardh}" rx="12" fill="#1a2634" stroke="#34516a"/>',
 f'<text x="{xx+18}" y="{yy+32}" font-size="21" font-weight="bold" class="title">{html.escape(sid)}</text>',
 f'<text x="{xx+18}" y="{yy+54}" font-size="13" class="small">{len(sites)} site(s)   {m["nodes"]} nodes   {m["cycle_rank"]} cycles</text>']
 if sid=='L023':
  p.append(f'<text x="{xx+18}" y="{yy+73}" font-size="12" fill="#f9cc87">Descending underground — top -6.0 m</text>')
 elif len(sites)>1:
  p.append(f'<text x="{xx+18}" y="{yy+73}" font-size="12" fill="#f9cc87">Two towers, dual-height bridges</text>')
 else:
  p.append(f'<text x="{xx+18}" y="{yy+73}" font-size="12" fill="#8fd2c7">Four branch corridors per tier</text>')
 def tower(s, cx, left=False):
  n=s['tiers'];h=s['rise_m'];is_down=s['descending']
  base_y=yy+262 if not is_down else yy+125
  spacing=min(31,142/max(1,n-1))
  levelpos=[]
  for f in range(n):
   ypos=base_y-(f*spacing if not is_down else -f*spacing)
   levelpos.append(ypos)
   c=palette[index%len(palette)]
   p.append(f'<rect x="{cx-56}" y="{ypos-3}" width="112" height="6" rx="2" fill="{c}"/>')
   # show cross-run north/south pocket loops, edges not a solid floor
   for side in [-1,1]:
    sx=cx+side*74
    p.append(f'<path d="M {cx+side*56} {ypos} H {sx}" stroke="#7a9bb2" stroke-width="2.5"/>')
    p.append(f'<rect x="{sx-3}" y="{ypos-4}" width="7" height="8" fill="#b4cde0"/>')
   p.append(f'<text x="{cx-9}" y="{ypos-8}" font-size="11" class="small">{f}</text>')
  for f in range(n-1):
   lo,hi=levelpos[f],levelpos[f+1]
   p.append(f'<path d="M {cx+48} {lo} L {cx+73} {(lo+hi)/2} L {cx+48} {hi}" fill="none" stroke="#f2bf71" stroke-width="3.4"/>')
   p.append(f'<path d="M {cx-48} {lo} L {cx-73} {(lo+hi)/2} L {cx-48} {hi}" fill="none" stroke="#86bded" stroke-width="3.4"/>')
  return levelpos
 if len(sites)==1:
  tower(sites[0],xx+232)
 else:
  levels1=tower(sites[0],xx+129)
  levels2=tower(sites[1],xx+335)
  n=sites[0]['tiers']
  for f in (1,n-1):
   y=levels1[f]
   p.append(f'<path d="M{xx+129+74} {y} H{xx+335-74}" stroke="#f6d78d" stroke-width="4" stroke-dasharray="9 4"/>')
 p.append(f'<text x="{xx+18}" y="{yy+293}" font-size="13" class="muted">Vertical span {m["max_height_m"]-m["min_height_m"]:.1f} m · {"subsurface" if sid=="L023" else "above grade"}</text>')
# Footer
p += ['<text x="35" y="1754" font-size="13" fill="#9fadc0">Teal: walkable deck designs. Gold/blue: two physical stairs. Dashed: paired elevated link. Detailed collision and traversal require Godot.</text>','</svg>']
out=R/'docs/production/DEV16_SPATIAL_OVERVIEW.svg';out.write_text('\n'.join(p));print(out)
