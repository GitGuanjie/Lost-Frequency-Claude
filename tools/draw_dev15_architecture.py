#!/usr/bin/env python3
"""Draw a source-derived schematic, NOT a screenshot or traversal proof."""
from pathlib import Path
import json,html
R=Path(__file__).resolve().parents[1]
D=json.loads((R/'data/vertical_routes_dev15.json').read_text())
W,H=1440,1100
parts=[f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">',
       '<rect width="100%" height="100%" fill="#101b2b"/>',
       '<style>text{font-family:Arial,sans-serif} .t{fill:#e7f4fc}.sub{fill:#a5b6c7}.cap{fill:#a9f0dc}.note{fill:#bbcbd6}</style>',
       '<text x="42" y="55" class="t" font-size="32" font-weight="bold">LOST FREQUENCY / DEV15</text>',
       '<text x="42" y="86" class="sub" font-size="18">9 structural rebuilds | authored route DESIGN (not a Godot gameplay screenshot)</text>']
col=455;row=271
names=['L015','L016','L017','L020','L024','L029','L036']
titles={'L015':'MACHINE INSPECTION','L016':'CANOPY LABYRINTH','L017':'CARRIER SERVICE','L020':'ELECTRIC GALLERY',
        'L024':'PLASTICWORKS','L029':'HYPERIA OVERLOOK','L036':'AIRPORT OVERLOOK'}
for ii,sid in enumerate(names):
 x=42+(ii%3)*col;y=122+(ii//3)*row
 g=D['scene_geometries'][sid];n=g['storeys'];height=g['metrics']['vertical_span_m']
 parts.append(f'<rect x="{x}" y="{y}" width="429" height="245" rx="10" fill="#182b3d" stroke="#3b5568"/>')
 parts.append(f'<text x="{x+16}" y="{y+34}" class="t" font-weight="bold" font-size="19">{sid} — {titles[sid]}</text>')
 parts.append(f'<text x="{x+16}" y="{y+58}" class="sub" font-size="14">{n} levels / {g["metrics"]["stair_links"]} stair runs / {height:g} m rise</text>')
 cx=x+215;fy=y+195
 for f in range(n):
  yy=fy-f*32
  color='#4ab5ce' if f==n-1 else '#456a83'
  parts.append(f'<rect x="{cx-105}" y="{yy-2}" width="210" height="6" rx="2" fill="{color}"/>')
  # The two apertures are shown as open strips (background rectangles).
  for gap in [-43,43]: parts.append(f'<rect x="{cx+gap-10}" y="{yy-3}" width="20" height="8" fill="#182b3d"/>')
  parts.append(f'<text x="{cx+121}" y="{yy+4}" class="note" font-size="12">F{f}</text>')
  if f<n-1:
   parts.append(f'<path d="M{cx-43} {yy} L{cx-43} {yy-9} L{cx+30} {yy-32}" stroke="#f9c376" stroke-width="3.5" fill="none"/>')
   parts.append(f'<path d="M{cx+43} {yy} L{cx+43} {yy-9} L{cx-30} {yy-32}" stroke="#80d3a4" stroke-width="3.5" fill="none"/>')
 parts.append(f'<text x="{x+16}" y="{y+230}" class="cap" font-size="13">Twin opposed climbs / apertured decks / loops</text>')
# bottom right: 4-deck garage
x,y=42+2*col,122+2*row
g=D['scene_geometries']['L022']
parts.append(f'<rect x="{x}" y="{y}" width="429" height="245" rx="10" fill="#182b3d" stroke="#3b5568"/>')
parts.append(f'<text x="{x+16}" y="{y+34}" class="t" font-size="19" font-weight="bold">L022 — FOUR-DECK GARAGE</text>')
parts.append(f'<text x="{x+16}" y="{y+58}" class="sub" font-size="14">Existing stair landings repaired / new fourth deck</text>')
for i in range(4):
 yy=y+192-i*38
 parts.append(f'<path d="M{x+42} {yy} H{x+348}" stroke="#5f7c91" stroke-width="6"/>')
 parts.append(f'<text x="{x+364}" y="{yy+4}" class="note" font-size="13">F{i}</text>')
 if i<3:
  c=x+(73 if i==2 else 270+i*15)
  parts.append(f'<path d="M{c} {yy} L{c+35} {yy-38}" stroke="#f9c376" stroke-width="4"/>')
parts.append(f'<text x="{x+16}" y="{y+230}" class="cap" font-size="13">Four plates / three climb segments / 12 m vertical</text>')
# L030 full bottom row
x,y=42,122+3*row
parts.append(f'<rect x="{x}" y="{y}" width="1339" height="123" rx="10" fill="#182b3d" stroke="#3b5568"/>')
parts.append(f'<text x="{x+14}" y="{y+25}" class="t" font-size="19" font-weight="bold">L030 — SHIFTED VOID / TWO PHYSICAL CLIMBS + HIGH SHELF LOOP</text>')
# diagram top-view: row low/far x positions, upper half shifted
x0=x+280;scale=95; yl=y+92;yu=y+54
for i in range(5):
 px=x0+i*scale
 if i<4:
  parts.append(f'<path d="M{px} {yl} H{px+scale}" stroke="#7b98b0" stroke-width="7"/>')
 for yrow in [yl,yu]:
  if yrow==yu and i>=4:continue
  color='#a5d6b9' if yrow==yu else '#547e9e'
  parts.append(f'<circle cx="{px}" cy="{yrow}" r="8" fill="{color}"/>')
 if i in [1,4]:
  parts.append(f'<path d="M{px} {yl} V{yu}" stroke="#f9c376" stroke-width="4" stroke-dasharray="4 3"/>')
for i in range(3):
 px=x0+scale+i*scale
 parts.append(f'<path d="M{px} {yu} H{px+scale}" stroke="#a5d6b9" stroke-width="6"/>')
for i in range(4):
 px=x0+i*scale
 if i<4: parts.append(f'<path d="M{px} {yl} H{px+scale}" stroke="#547e9e" stroke-width="4"/>')
parts.append(f'<text x="{x+15}" y="{y+60}" class="sub" font-size="13">Island rows: y=12 m</text>')
parts.append(f'<text x="{x+15}" y="{y+80}" class="sub" font-size="13">Upper shelf: y=18 m</text>')
parts.append(f'<text x="{x+1140}" y="{y+72}" class="cap" font-size="15">2 cycles</text>')
parts.append(f'<text x="{x+1120}" y="{y+95}" class="sub" font-size="12">No new exits</text>')
parts.append(f'<text x="42" y="1084" class="sub" font-size="14">Blue: floor/bridge   Gold and green: distinct physical climb directions   Not to scale; collision/character traversal not certified.</text>')
parts.append('</svg>')
p=R/'docs/production/DEV15_SPATIAL_NETWORK.svg';p.write_text('\n'.join(parts),encoding='utf8');print(p)
