"""DEV20 shared data-driven topology contracts; NOT Godot navigation/physics proof."""
from __future__ import annotations
import hashlib, json, math, re, subprocess, sys, unittest
from pathlib import Path
from collections import defaultdict, deque
from tools.preflight_dev import string_and_delimiter_check
ROOT=Path(__file__).resolve().parents[2]
DATA=json.loads((ROOT/'data/dev20_atrium_blueprints.json').read_text(encoding='utf-8'))

def src(p):return (ROOT/p).read_text(encoding='utf-8')
def edge(p):return tuple(sorted((tuple(p[:2]), tuple(p[2:]))))
def connected(nodes,edges):
 graph={v:set() for v in nodes}
 for a,b in edges:
  graph[a].add(b);graph[b].add(a)
 q=[next(iter(nodes))];seen=set(q)
 for v in q:
  for w in graph[v]:
   if w not in seen:seen.add(w);q.append(w)
 return seen==nodes

class TestDev20AtriumGeneration(unittest.TestCase):
 @classmethod
 def setUpClass(cls):cls.wings=DATA['wings']
 def test_01_unique_ten_real_installed_sites(self):
  self.assertEqual(len(self.wings),10)
  self.assertEqual(len({w['id'] for w in self.wings}),10)
  for w in self.wings:
   s=src(f'levels/{w["id"]}/{w["id"]}.gd')
   self.assertIn(f'AtriumWeave.install(self, "{w["anchor"]}")',s)
   self.assertEqual(s.count('AtriumWeave.install('),1)
   self.assertIn(f'SpatialBranchworks.install(self, "{w["anchor"]}"',s)
   self.assertIn('false, 0, true)' if w['id'] not in ('L320','L808') else 'false, 1, true)',s)
 def test_02_each_floor_cell_graph_is_connected(self):
  for w in self.wings:
   self.assertEqual(len(w['floors']),3)
   self.assertIn(w['atrium_hole_column'],(1,2,3))
   for f,plan in enumerate(w['floors']):
    nodes=set(map(tuple,plan['cells']))
    edges=[edge(e) for e in plan['doors']]
    self.assertEqual(len(nodes),20 if f==0 else 18,w['id'])
    self.assertEqual(len(edges),len(set(edges)))
    self.assertTrue(connected(nodes,edges),(w['id'],f))
    self.assertTrue(all(abs(a[0]-b[0])+abs(a[1]-b[1])==1 and a in nodes and b in nodes for a,b in edges))
    self.assertEqual(len(plan['tree_edges']),len(nodes)-1)
    self.assertEqual(set(map(edge,plan['tree_edges'])) & set(map(edge,plan['extra_edges'])),set())
    self.assertEqual(plan['cycle_rank'],len(edges)-len(nodes)+1)
    self.assertGreaterEqual(plan['cycle_rank'],3)
 def test_03_global_three_storey_connectivity_and_nonessential_gate(self):
  for w in self.wings:
   nodes={(tier,*cell) for tier,f in enumerate(w['floors']) for cell in map(tuple,f['cells'])}
   edges=[]
   for tier,f in enumerate(w['floors']):
    edges += [((tier,*e[0]),(tier,*e[1])) for e in map(edge,f['doors'])]
   stairs=[]
   for tier in (0,1):
    stairs += [((tier,4,0),(tier+1,4,3)),((tier,0,3),(tier+1,0,0))]
   self.assertTrue(all(a in nodes and b in nodes for a,b in stairs))
   edges+=stairs
   self.assertEqual(len(nodes),56)
   self.assertTrue(connected(nodes,edges),w['id'])
   gate=edge(w['shutter_edge'])
   self.assertIn(gate,set(map(edge,w['floors'][1]['extra_edges'])))
   closed=[e for e in edges if e!=((1,*gate[0]),(1,*gate[1]))]
   self.assertTrue(connected(nodes,closed),w['id']+' shutter blocked only access')
 def test_04_all_tiers_have_two_independent_physical_stair_links(self):
  a=src('core/world/AtriumWeave.gd')
  self.assertIn('for tier in 2:',a)
  self.assertIn('k.stairs(Vector3(x0 + WIDTH + 2.5',a)
  self.assertIn('k.stairs(Vector3(x0 - 2.5',a)
  self.assertIn('30, mat, 0.7, false)',a)
  for w in self.wings:
   self.assertLess(math.degrees(math.atan(w['rise']/21)),12)
   self.assertGreaterEqual(w['anchor_tiers'],4)
 def test_05_source_balcony_doorway_open_at_both_rails(self):
  code=src('core/world/SpatialBranchworks.gd')
  self.assertIn('annex_east_tier2: bool = false',code)
  self.assertIn('annex_east_tier2 and f == 2 and side > 0.0',code)
  self.assertIn('not (annex_east_tier2 and f == 2)',code)
  a=src('core/world/AtriumWeave.gd')
  self.assertIn('o.x + 18.6',a)
  self.assertIn('o.y + 2.0 * rise',a)
  self.assertIn('tier == 1 and r == 1',a)
 def test_06_open_air_gap_and_indoor_wall_doors_are_two_distinct_systems(self):
  self.assertGreaterEqual(sum(w['open_air'] for w in self.wings),4)
  self.assertGreaterEqual(sum(not w['open_air'] for w in self.wings),4)
  a=src('core/world/AtriumWeave.gd')
  for phrase in ('if open_air:','k.wall(', 'k.slab(center.x - 2.57',
    'for door in plan["doors"]','_open_guard(', 'has_route',
    'if not open_air:', 'k.slab(xx, zz, xx + CELL, zz + CELL, roof_y',
    'k.slab(x0 - 4.0', 'k.slab(o.x + 18.6'):
   self.assertIn(phrase,a)
 def test_07_real_interactions_have_collision_and_state_changes(self):
  a=src('core/world/AtriumWeaveState.gd')
  for phrase in ('StaticBody3D.new()', 'CollisionShape3D.new()',
    'shutter_shape.set_deferred("disabled", shutter_open)',
    'shutter_visual.visible = not shutter_open',
    'light.light_energy = 0.14','lamp.light_energy = 1.4 if circuit_on[tier] else 0.14',
    'SaveService.record_discovery(', 'func observe(_p: Player, tier: int)',
    'func toggle_shutter(_p: Player)', 'func toggle_circuit(_p: Player, tier: int)'):
   self.assertIn(phrase,a)
  for w in self.wings:
   self.assertEqual(w['interactions'],{'light_circuits':3,'shutter':1,'observations':2})
   self.assertIn(w['shutter_edge'],w['floors'][1]['extra_edges'])
 def test_08_source_theme_compatibility(self):
  self.assertNotIn('L037',[x['id'] for x in self.wings])
  self.assertNotIn('L008',[x['id'] for x in self.wings])
  self.assertNotIn('L998',[x['id'] for x in self.wings])
  for w in self.wings:
   self.assertEqual(w['open_air'],w['style'] in ('forest','garden','desert','leisure'))
   s=src(f'levels/{w["id"]}/{w["id"]}.gd')
   self.assertIn('MatLib.define("'+w['mat']+'"',s)
   self.assertTrue('MatLib.define("'+w['accent']+'"' in s or 'MatLib.register("'+w['accent']+'"' in s)
 def test_09_old_story_world_roster_and_assets_unchanged(self):
  canon=json.loads(src('data/canon/levels.json'))
  self.assertEqual(len(canon['levels']),100)
  self.assertEqual(sum(len(json.loads(p.read_text())['exits']) for p in (ROOT/'levels').glob('*/level.json')),235)
  self.assertEqual(len(list((ROOT/'assets').rglob('*.glb'))),414)
  self.assertNotIn('add_exit(',src('core/world/AtriumWeave.gd'))
  self.assertNotIn('teleport(',src('core/world/AtriumWeave.gd'))
 def test_10_repeat_generation_is_byte_identical(self):
  path=ROOT/'data/dev20_atrium_blueprints.json'
  before=hashlib.sha256(path.read_bytes()).hexdigest()
  ret=subprocess.run([sys.executable,str(ROOT/'tools/generate_dev20_atrium.py')],cwd=ROOT,capture_output=True,text=True)
  self.assertEqual(ret.returncode,0,ret.stderr)
  self.assertEqual(before,hashlib.sha256(path.read_bytes()).hexdigest())
 def test_11_source_geometry_has_lexically_balanced_gd(self):
  rel=['core/world/SpatialBranchworks.gd','core/world/AtriumWeave.gd',
       'core/world/AtriumWeaveState.gd','tests/qa_runner.gd']+[f'levels/{w["id"]}/{w["id"]}.gd' for w in self.wings]
  failures=[f for p in rel for f in string_and_delimiter_check(src(p),p)]
  self.assertEqual(failures,[])
 def test_12_generated_stats_truthful_not_engine_certification(self):
  self.assertEqual(DATA['status'],'DESIGN_GRAPH_ONLY_NOT_GODOT_WALKED')
  self.assertEqual(sum(len(f['cells']) for w in self.wings for f in w['floors']),560)
  self.assertEqual(sum(len(f['doors']) for w in self.wings for f in w['floors']),740)
  self.assertEqual(sum(f['cycle_rank'] for w in self.wings for f in w['floors']),210)
  self.assertTrue(all(f['cycle_rank']==7 for w in self.wings for f in w['floors']))

if __name__=='__main__':unittest.main()
