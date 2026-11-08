#!/usr/bin/env python3
"""Build six themed, deterministically reproducible, physically connected annex plans.

Graph nodes specify the same floor elevations used by the runtime builder. Locked
optional crossings are excluded when testing reachability. Run test_dev25_*.
"""
import json, math, hashlib, random
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
CAT=json.loads((ROOT/'assets/packs/catalog.json').read_text())['models']
# Every node is a physically supported 8x8m floor. Two 28m stair runs are
# connected with 20m ramps between 4m margins of lower and upper decks.
SITES=[
 dict(id='L041', style='tar_pier', title='Black Lake: submerging pier circuit',
      anchor=[27,0,34],rotation=0, mat='l41_plank',accent='l41_steel',
      palette=['city-kit-roads/electricity-pole','city-kit-roads/construction-light','city-kit-roads/construction-barrier','graveyard-kit/debris-wood','graveyard-kit/lantern-glass','prototype-kit/pipe-section','prototype-kit/crate','nature-kit/rock-smallb'],
      message='The tar bubbles below a pier with burned supports. A distant signal changes its rhythm.',
      cue='wind', count=24, floor='timber', lower=[(x,z) for x in (16,32,48,64) for z in (0,16)],
      upper=[(x,z) for x in (16,32,48,64) for z in (44,)]+[(48,60),(64,60)],
      optional=((48,44),(48,60)),stairs=(16,64)),
 dict(id='L048', style='seafront', title='Permanent evening: tidal observation gallery',
      anchor=[25,0,-80],rotation=-90,mat='l48_building',accent='l48_bark',
      palette=['furniture-kit/bench','furniture-kit/lampwall','furniture-kit/tablecoffee','city-kit-suburban/planter','food-kit/cup','food-kit/soda-bottle','city-kit-suburban/path-stones-messy','city-kit-roads/light-square','nature-kit/rock-smallflata'],
      message='The hotel lamps are still on. No wave seems to match the other waves.',
      cue='water_bed',count=30,floor='colonnade',lower=[(x,z) for x in (16,32,48,64,80) for z in (0,16) if not(x==80 and z==0)],
      upper=[(x,44) for x in (16,32,48,64,80)]+[(64,60),(80,60)],
      optional=((64,44),(64,60)),stairs=(16,80)),
 dict(id='L140', style='sunflower', title='Sunflower field: dusk observation loop',
      anchor=[-75,0,0],rotation=180,mat='l140_house',accent='l140_stem',
      palette=['furniture-kit/bench','furniture-kit/chair','furniture-kit/tablecoffee','food-kit/barrel','food-kit/bowl','nature-kit/rock-smallc','city-kit-suburban/planter','graveyard-kit/lantern-glass'],
      message='The flower heads face a light that does not seem to be a single sun.',
      cue='crickets',count=28,floor='pergola',lower=[(x,z) for x in (16,32,48,64,80) for z in (0,16) if not(x==80 and z==0)],
      upper=[(x,44) for x in (16,32,48,64,80)]+[(64,60),(80,60)],
      optional=((64,44),(64,60)),stairs=(16,80)),
 dict(id='L201', style='vapor_temple', title='Vaporwave world: digital ruins and signal arcade',
      anchor=[-35,0,65],rotation=180,mat='l201_city',accent='l201_neon',
      palette=['mini-dungeon/column','mini-dungeon/pot','mini-dungeon/rocks','space-kit/desk-computer','space-kit/machine-generator','space-kit/satellitedish','furniture-kit/computerscreen','city-kit-commercial/detail-overhang','prototype-kit/shape-hollow-hexagon','space-kit/desk-computerscreen'],
      message='A cursor moves over a ruined marble terminal; every window shows a different, uncertain horizon.',
      cue='pad',count=36,floor='digital',lower=[(x,z) for x in (16,32,48,64,80,96) for z in (0,16)],
      upper=[(x,44) for x in (16,32,48,64,80,96)]+[(80,60),(96,60)],
      optional=((80,44),(80,60)),stairs=(16,96)),
]

def rot(v,theta):
 rad=math.radians(theta); c,s=math.cos(rad),math.sin(rad)
 return (round(c*v[0]-s*v[1],4),round(s*v[0]+c*v[1],4))

def build_site(src):
 rng=random.Random(25000+int(src['id'][1:]))
 origin=src['anchor'];a=[float(origin[0]),float(origin[1]),float(origin[2])]
 nodes={}
 for layer,cells in [('b',src['lower']),('u',src['upper'])]:
  for x,z in cells:
   dx,dz=rot((x,z),src['rotation']);nodes[f'{layer}_{x}_{z}']=[round(a[0]+dx,4),round(a[1]+(3.5 if layer=='u' else 0),4),round(a[2]+dz,4)]
 def name(layer,p):return f'{layer}_{p[0]}_{p[1]}'
 links=[]
 for layer,cells in [('b',src['lower']),('u',src['upper'])]:
  for i,p in enumerate(cells):
   for q in cells[i+1:]:
    if abs(p[0]-q[0])+abs(p[1]-q[1])==16:
     kind='optional' if layer=='u' and {tuple(p),tuple(q)}=={tuple(x) for x in src['optional']} else 'walk'
     links.append({'a':name(layer,p),'b':name(layer,q),'kind':kind})
 for x in src['stairs']:
  p=(x,16);q=(x,44)
  assert p in src['lower'] and q in src['upper']
  links.append({'a':name('b',p),'b':name('u',q),'kind':'stair'})
 # Positions use a variation of nonblocking 3m corner placements, never centerlines.
 pack_options=[tuple(s.split('/',1)) for s in src['palette']]
 for pack,model in pack_options:
  assert f'assets/packs/{pack}/{model}.glb' in CAT,(pack,model)
 props=[]; options=[key for key in nodes if key.startswith('b') or key.startswith('u')]
 for i in range(src['count']):
  node=options[(i*7+i//len(options))%len(options)]
  pack,model=pack_options[(i*5 + rng.randrange(len(pack_options)))%len(pack_options)]
  size=CAT[f'assets/packs/{pack}/{model}.glb']['size']; span=max(size[0],size[2]);h0=size[1]
  # Off-route decoration, keeps 3m crossing zones and stairs clear.
  ht=min(1.85,1.0+0.12*(i%6))
  scale=min(8.0,ht/max(.18,h0))
  if span*scale>1.55:ht=min(ht,1.55*max(.18,h0)/span)
  props.append({'node':node,'pack':pack,'model':model,
                'dx':(-2.7 if i%2 else 2.7), 'dz':(-2.65 if i%4 in (0,1) else 2.65),
                'height':round(ht,3),'yaw':float((i*67+rng.randint(0,27))%360)})
 candidate= {'id':src['id'],'title':src['title'],'style':src['style'], 'origin':a,'entry':a,
     'mat':src['mat'],'accent':src['accent'],'cue':src['cue'],'message':src['message'],
     'nodes':nodes,'links':links,'optional_edge':list(map(lambda p:name('u',p),src['optional'])),
     'surveys':[name('b',(16,0)),name('u',(src['stairs'][0],44)),name('u',(src['stairs'][1],44))],
     'props':props,'riser':3.5,'basis_degrees':src['rotation'],'schema':'dev25-v1'}
 # Without optional edges, every node must be connected from b_16_0.
 seen={'b_16_0'}
 for _ in range(len(nodes)):
  for e in links:
   if e['kind']=='optional':continue
   if e['a'] in seen:seen.add(e['b'])
   if e['b'] in seen:seen.add(e['a'])
 assert set(nodes)==seen,(src['id'],sorted(set(nodes)-seen))
 assert sum(e['kind']=='stair' for e in links)==2
 assert sum(e['kind']=='optional' for e in links)==1
 return candidate

if __name__=='__main__':
 payload={'version':25,'sites':[build_site(x) for x in SITES],
          'note':'Non-canonical, optional physically connected exploration annexes. No source exit changes.'}
 output=ROOT/'data/dev25_immersive_networks.json';output.write_text(json.dumps(payload,sort_keys=True,indent=2,ensure_ascii=False)+'\n')
 print('sites:',len(payload['sites']),'nodes:',sum(len(x['nodes']) for x in payload['sites']),
       'links:',sum(len(x['links']) for x in payload['sites']),
       'props:',sum(len(x['props']) for x in payload['sites']),
       'sha256:',hashlib.sha256(output.read_bytes()).hexdigest())
