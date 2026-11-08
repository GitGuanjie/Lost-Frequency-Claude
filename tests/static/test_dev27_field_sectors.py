"""DEV27 contract: blueprint, reuse, clearance and regression; NOT engine QA."""
import collections,hashlib,json,math,subprocess,sys,unittest,zipfile
from pathlib import Path
from tools.preflight_dev import string_and_delimiter_check
ROOT=Path(__file__).resolve().parents[2]
DATA=json.loads((ROOT/'data/dev27_field_sectors.json').read_text())
CAT=json.loads((ROOT/'assets/packs/catalog.json').read_text())['models']
SIDS={'L016','L024','L029','L077','L140','L737','L899','L998'}
BASE=Path('/mnt/data/LostFrequency_v1.5.0-dev26_SOURCE.zip')

class Dev27FieldSectorQA(unittest.TestCase):
 def test_01_eight_distinct_real_worlds_and_unaltered_exit_definitions(self):
  sites=DATA['sites']; self.assertEqual(len(sites),8)
  self.assertEqual({s['id'] for s in sites},SIDS)
  self.assertEqual(len({s['style'] for s in sites}),8)
  self.assertTrue(all(s['source']=='ADAPTATION' and s['canonical_exits_unchanged'] for s in sites))
  for site in sites:
   sid=site['id']
   self.assertIn(str(site['floor']), (ROOT/f'levels/{sid}/{sid}.gd').read_text())
   self.assertIn(str(site['accent']), (ROOT/f'levels/{sid}/{sid}.gd').read_text())
   self.assertTrue((ROOT/f'sources/wiki_text/{sid}.md').is_file(),sid)
   self.assertGreater(len(site['observation']),35)
   if BASE.exists():
    with zipfile.ZipFile(BASE) as z:
     for candidate in [f'3/levels/{sid}/level.json']:
      self.assertEqual((ROOT/candidate[2:]).read_bytes(),z.read(candidate),candidate)
  self.assertEqual(len(list((ROOT/'levels').rglob('level.json'))),100)

 def test_02_path_connectivity_without_optional_bridge(self):
  all_spurs=0
  diversity=[]
  for site in DATA['sites']:
   points=set(site['points'])|{s['id'] for s in site['spurs']}
   self.assertEqual(len(site['spurs']),len(set(s['id'] for s in site['spurs'])))
   self.assertGreaterEqual(len(site['spurs']),1)
   adj={p:set() for p in points}
   for a,b,kind in site['links']:
    self.assertIn(a,points);self.assertIn(b,points)
    self.assertIn(kind,{'ground','walk','stair','optional'})
    if kind!='optional': adj[a].add(b);adj[b].add(a)
   pending=['ground']; visited=set()
   while pending:
    n=pending.pop()
    if n in visited:continue
    visited.add(n);pending.extend(adj[n]-visited)
   self.assertEqual(visited,points,site['id'])
   self.assertEqual(sum(k=='stair' for _,_,k in site['links']),2)
   self.assertEqual(sum(k=='optional' for _,_,k in site['links']),1)
   # core four-corner ring remains cyclic when the optional bridge is absent
   cycle_rank=sum(k!='optional' for _,_,k in site['links'])-len(points)+1
   self.assertGreaterEqual(cycle_rank,1)
   self.assertLess(math.degrees(math.atan(3.6/(18*.48))),35.0)
   for spur in site['spurs']:
    self.assertIn(spur['from'],{'sw','nw','ne','se'})
    self.assertIn(spur['direction'],{'north','south','east','west'})
    self.assertEqual(spur['pos'][1],3.6)
    self.assertGreater(float(spur['gap']),5.)
   all_spurs+=len(site['spurs'])
   diversity.append((site['style'],len(site['spurs']),tuple(site['half'])))
  self.assertEqual(all_spurs,18)
  self.assertEqual(len(set(diversity)),8)

 def test_03_existing_models_all_real_and_off_the_middle_path(self):
  refs=set();count=0
  for site in DATA['sites']:
   self.assertEqual(len(site['props']),24+2*len(site['spurs']))
   for prop in site['props']:
    count+=1
    key=f"assets/packs/{prop['pack']}/{prop['model']}.glb"
    self.assertIn(key,CAT);self.assertTrue((ROOT/key).exists());refs.add(key)
    self.assertFalse(prop.get('solid',False))
    dims=CAT[key]['size']
    f=min(8.,float(prop['height'])/max(.18,float(dims[1])))
    self.assertLessEqual(max(float(dims[0]),float(dims[2]))*f,2.0,key)
    px,py,pz=map(float,prop['pos'])
    if py>3:
     centers=[(-site['half'][0],-site['half'][1]),(site['half'][0],-site['half'][1]),
         (site['half'][0],site['half'][1]),(-site['half'][0],site['half'][1])]
     centers += [(sp['pos'][0],sp['pos'][2]) for sp in site['spurs']]
     self.assertGreater(min(math.hypot(px-cx,pz-cz) for cx,cz in centers),2.0)
  self.assertEqual(count,228)
  self.assertGreaterEqual(len(refs),35)
  self.assertEqual(len(list((ROOT/'assets/packs').rglob('*.glb'))),414)

 def test_04_placement_inside_existing_playable_terrain(self):
  boundaries={'L016':(-62,62,-80,80),'L024':(-95,95,-110,115),
    'L029':(-83,83,-85,85),'L077':(-185,185,-180,180),
    'L140':(-250,250,-250,250),'L737':(-210,210,-210,210),
    'L899':(-82,-17,-80,80),'L998':(-150,150,-155,155)}
  for site in DATA['sites']:
   ax,az=site['anchor']; xmin,xmax,zmin,zmax=boundaries[site['id']]
   hx,hz=site['half']
   # Leave at least 2m from the edge of the source-level ground slab.
   corners=[(ax+dx,az+dz) for dx in [-hx-3.6,hx+3.6] for dz in [-hz-3.6,hz+3.6]]
   feet=[(ax-hx,az-hz-12.0),(ax+hx,az+hz+12.0)]
   spurs=[(ax+s['pos'][0]+sx,az+s['pos'][2]+sz) for s in site['spurs'] for sx in [-2.8,2.8] for sz in [-2.8,2.8]]
   for x,z in corners+feet+spurs:
    self.assertGreaterEqual(x,xmin+2,site['id']); self.assertLessEqual(x,xmax-2,site['id'])
    self.assertGreaterEqual(z,zmin+2,site['id']); self.assertLessEqual(z,zmax-2,site['id'])
  # Explicit structural-clearance exclusions within original procedural solids.
  for sid in ['L016','L029','L077','L140','L737']:
   self.assertIn('DEV27:',(ROOT/f'levels/{sid}/{sid}.gd').read_text())

 def test_05_real_geometry_and_actual_interactable_path(self):
  core=(ROOT/'core/world/FieldSectors27.gd').read_text()
  base=(ROOT/'core/world/LevelBase.gd').read_text()
  for phrase in ['GeoKit.new(self','k.stairs(','k.slab(','_build_spurs(k,','k.commit()',
   'BoxShape3D.new()','collision_layer = 1','set_deferred("disabled"',
   'Dress._place(level,level,item)','Callable(self,"survey").bind(i)',
   'Callable(self,"toggle_light").bind(i)','SaveService.record_discovery(']:
   self.assertIn(phrase,core)
  # The opened crossing must not run into a permanent inner guardrail.
  self.assertIn('var bridge_mouth: bool =',core)
  self.assertIn('if bridge_mouth and',core)
  self.assertIn('var remaining: float = (edge_length-3.30)*0.5',core)
  self.assertIn('DEV27_ClosedCrossingRail',core)
  self.assertIn('_install_dev27_field_sectors()',base)
  self.assertIn('sector.setup(self, site)',base)
  self.assertNotIn('add_exit(',core)
  self.assertNotIn('TransitionService.dev_jump(',core)
  probe=(ROOT/'tests/Dev27FieldSectorsProbe.gd').read_text()
  for t in ['TransitionService.dev_jump(sid,"start")','_floor(world,','Interactable).interact(level.player)',
    'safe spawn','bridge_open','retracted crossing removes physical collision']:
   self.assertIn(t,probe)

 def test_06_deterministic_regeneration_and_gd_preflight(self):
  output=ROOT/'data/dev27_field_sectors.json';sha=hashlib.sha256(output.read_bytes()).digest()
  cp=subprocess.run([sys.executable,'tools/build_dev27_field_sectors.py'],cwd=ROOT,capture_output=True,text=True)
  self.assertEqual(cp.returncode,0,cp.stderr)
  self.assertEqual(hashlib.sha256(output.read_bytes()).digest(),sha)
  for path in ['core/world/FieldSectors27.gd','core/world/LevelBase.gd',
       'tests/Dev27FieldSectorsProbe.gd'] + [f'levels/{sid}/{sid}.gd' for sid in SIDS]:
   self.assertEqual(string_and_delimiter_check((ROOT/path).read_text(),path),[])

if __name__=='__main__':unittest.main()
