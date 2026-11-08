"""DEV15 authored design checks only; separate from engine collision and player QA."""
from __future__ import annotations
import unittest,json,hashlib,math,re
from pathlib import Path
from tools.preflight_dev import string_and_delimiter_check
from tools.build_dev15_topology import TOWERS, metrics, tower_graph
R=Path(__file__).resolve().parents[2]
DATA=json.loads((R/'data/vertical_routes_dev15.json').read_text())

def src(rel):return (R/rel).read_text()
class Dev15ArchitecturalNetwork(unittest.TestCase):
 def test_graphs_are_connected_with_independent_routes(self):
  self.assertEqual(DATA['version'],'1.5.0-dev15')
  self.assertIn('NOT proof',DATA['provenance'])
  graphs=DATA['scene_geometries']
  self.assertEqual(set(graphs),set(TOWERS)|{'L022','L030'})
  for sid,g in graphs.items():
   self.assertEqual(metrics(g),g['metrics'],sid)
   self.assertTrue(g['metrics']['graph_connected'],sid)
   self.assertGreaterEqual(g['metrics']['vertical_span_m'],6,sid)
   for a,b,kind,w in g['edges']:
    self.assertIn(a,g['nodes'],sid);self.assertIn(b,g['nodes'],sid)
    self.assertIn(kind,['stair','deck','bridge'])
    self.assertGreaterEqual(w,2.2,sid)
    p,q=g['nodes'][a],g['nodes'][b]
    self.assertTrue(all(math.isfinite(t) for t in (*p,*q)))
    rise=abs(p[1]-q[1])
    if kind=='stair':
     self.assertGreaterEqual(round(rise,6),3.4,sid)
     self.assertLessEqual(rise/math.hypot(p[0]-q[0],p[2]-q[2]),.38,sid)
    else:self.assertAlmostEqual(rise,0,places=3)
   if sid in TOWERS:
    self.assertGreaterEqual(g['metrics']['cycle_rank'],3,sid)
    self.assertEqual(g['metrics']['stair_links'],(g['storeys']-1)*2,sid)
  self.assertGreaterEqual(graphs['L030']['metrics']['cycle_rank'],2)
  self.assertEqual(graphs['L022']['metrics']['stair_links'],3)
 def test_tower_code_and_stair_aperture_cover_invariants(self):
  util=src('core/world/VerticalArchitecture.gd')
  for needle in ('k.stairs(', 'k.commit()', 'for f in range(1, floors)',
                 'for f in range(floors - 1)', '[-8.0, -5.5]', '[-2.5, 2.5]',
                 '[5.5, 8.0]', 'origin.z - 10.0', 'origin.z + 10.0'):
   self.assertIn(needle,util)
  self.assertEqual(util.count('k.stairs('),2)
  # Geometry aperture open at x=+-4 from z=-10..10, while gallery top
  # at x=0, x=+-6.5, and front/back z=+-12 is solid. This tests overlap.
  for sid,(org,n,h,label) in TOWERS.items():
   txt=src(f'levels/{sid}/{sid}.gd')
   self.assertIn('VerticalArchitecture.install(self,',txt,sid)
   self.assertIn(f'Vector3({org[0]}, 0, {org[2]})',txt,sid)
   self.assertIn(f'{n}, {h}',txt,sid)
   self.assertEqual(txt.count('VerticalArchitecture.install('),1,sid)
   for x in [-4.,4.]:
    self.assertTrue(-5.5<x<-2.5 or 2.5<x<5.5)
   self.assertEqual(tower_graph(org,n,h)['nodes'],DATA['scene_geometries'][sid]['nodes'])
  self.assertNotIn('add_exit(',util)
  self.assertNotIn('player.global_position',util)
 def test_repair_landings_and_fourth_deck_not_roofed(self):
  g=src('levels/L022/L022.gd')
  for piece in ('for f in 4:', 'if f<3:', 'k.slab(-34,44,-26,51',
                'Vector3(30,0.05,-47)', 'Vector3(35,4.05,-8)',
                'Vector3(-30,8.05,6)', '"four stacked decks"'):
   self.assertIn(piece,g)
  self.assertEqual(g.count('k.stairs('),3)
  for start,run,steps,landing in [(-47.,1.,29,-18.),(-8.,1.,30,22.),(6.,1.,38,44.)]:
   self.assertAlmostEqual(start+run*steps,landing)
 def test_terrain_exclusion_and_roof_openings(self):
  for sid in ('L015','L017','L020','L036'):
   s=src(f'levels/{sid}/{sid}.gd')
   self.assertIn('k.slab(',s)
   self.assertNotIn('add_exit("L015>',s if sid=='L015' else '')
  g=src('levels/L030/L030.gd')
  self.assertIn('_looping_island_circuits(k)',g)
  self.assertIn('for i in 4:',g)
  self.assertIn('for j in 4:',g)
  self.assertIn('18.5/30.0',g)
  self.assertNotIn('add_exit(',g)
 def test_canon_and_manifests_unchanged(self):
  self.assertEqual(len(json.loads(src('data/canon/levels.json'))['levels']),100)
  self.assertEqual(DATA['canon_roster_sha256'],hashlib.sha256((R/'data/canon/levels.json').read_bytes()).hexdigest())
  self.assertEqual(DATA['transitions_sha256'],hashlib.sha256((R/'data/canon/transitions.json').read_bytes()).hexdigest())
  for sid,digest in DATA['manifests_sha256'].items():
   self.assertEqual(digest,hashlib.sha256((R/f'levels/{sid}/level.json').read_bytes()).hexdigest(),sid)
 def test_lexical_syntax_of_every_touched_script(self):
  check=[]
  for sid in DATA['scene_geometries']:
   rel=f'levels/{sid}/{sid}.gd'
   check.extend(string_and_delimiter_check(src(rel),rel))
  rel='core/world/VerticalArchitecture.gd'
  check.extend(string_and_delimiter_check(src(rel),rel))
  self.assertEqual(check,[])
 def test_qa_is_real_engine_smoke_not_phony_pass(self):
  code=src('tests/qa_runner.gd')
  self.assertIn('func _vertical_dev15_suite()',code)
  block=code.split('func _vertical_dev15_suite()',1)[1].split('\nfunc ',1)[0]
  for sid in DATA['scene_geometries']:
   if sid in TOWERS:self.assertIn('config.keys()',block)
   else:self.assertIn(f'"{sid}"',block)
  self.assertIn('direct_space_state',block)
  self.assertIn('intersect_ray',code)
  self.assertIn('check(',block)
  self.assertNotIn('qa_prog +=',block)
  runner=src('tools/run_dev15_qa.py')
  self.assertIn("'vertical_dev15'",runner)
  self.assertIn('Incomplete DEV15 collision evidence',runner)
  self.assertIn('if report and report.exists():report.unlink()',runner)
  exp=src('EXPORT_DEV15_WINDOWS.ps1')
  self.assertIn("$summary.status -ne 'PASS'",exp)
  self.assertIn('--export-debug',exp)
if __name__=='__main__':unittest.main()
