"""DEV16 source and route *design* tests (never claim actual Godot execution)."""
from pathlib import Path
import hashlib, json, math, re, unittest
from tools.build_dev16_topology import graph
from tools.preflight_dev import string_and_delimiter_check
R=Path(__file__).resolve().parents[2]
D=json.loads((R/'data/vertical_routes_dev16.json').read_text())

def source(s):return (R/s).read_text()
class TestDev16Branchworks(unittest.TestCase):
 def test_route_design_connected_and_multiply_cyclic(self):
  self.assertEqual(D['version'],'1.5.0-dev16')
  self.assertTrue(D['design_only'])
  self.assertIn('no Godot runtime traversal',D['provenance'])
  graphs=graph(D)
  self.assertEqual(set(graphs),set(D['graphs']))
  self.assertEqual(len(graphs),14)
  self.assertEqual(sum(g['metrics']['site_count'] for g in graphs.values()),17)
  self.assertEqual(sum(g['metrics']['nodes'] for g in graphs.values()),905)
  self.assertEqual(sum(g['metrics']['edges'] for g in graphs.values()),1123)
  self.assertEqual(sum(g['metrics']['cycle_rank'] for g in graphs.values()),232)
  for sid,g in graphs.items():
   self.assertEqual(g,D['graphs'][sid])
   self.assertEqual(g['metrics']['components'],1,sid)
   self.assertGreaterEqual(g['metrics']['cycle_rank'],9,sid)
   self.assertGreaterEqual(g['metrics']['max_height_m']-g['metrics']['min_height_m'],10.0,sid)
   for a,b,kind,width in g['edges']:
    self.assertIn(a,g['nodes']);self.assertIn(b,g['nodes'])
    self.assertGreaterEqual(width,2.3)
    if kind=='stair':
     p,q=g['nodes'][a],g['nodes'][b]
     self.assertLess(abs(p[1]-q[1])/math.dist([p[0],p[2]],[q[0],q[2]]),0.25)
 def test_multiple_distinct_vertical_sites_and_mezzanine_bridges(self):
  bylevel={}
  for site in D['sites']:
   bylevel.setdefault(site['level'],[]).append(site)
   txt=source(f"levels/{site['level']}/{site['level']}.gd")
   needle=f'SpatialBranchworks.install(self, "{site["tag"]}", Vector3({", ".join(str(v) for v in site["origin_xyz"])})'
   self.assertIn(needle,txt)
   self.assertEqual(txt.count(f'SpatialBranchworks.install(self, "{site["tag"]}"'),1)
  self.assertEqual(sum(len(v)==2 for v in bylevel.values()),3)
  self.assertEqual([p['level'] for p in D['cross_site_bridges']],['L048','L320','L808'])
  for pair in D['cross_site_bridges']:
   s=source(f"levels/{pair['level']}/{pair['level']}.gd")
   self.assertIn('SpatialBranchworks.link_sites(',s)
   for side in (', false, 1', ', false, -1)'):self.assertIn(side,s)
   self.assertEqual(D['graphs'][pair['level']]['metrics']['cross_site_edges'],4)
 def test_underground_portal_connects_existing_floor_and_preserves_exit(self):
  site=next(s for s in D['sites'] if s['level']=='L023')
  self.assertEqual(site['origin_xyz'],[55,-6,0])
  self.assertTrue(site['descending'])
  self.assertLess(D['graphs']['L023']['metrics']['min_height_m'],-18)
  s=source('levels/L023/L023.gd')
  self.assertIn('k.slab(28.7,-1.8,46.2,1.8,-6.0,0.32',s)
  self.assertIn('k.box(Vector3(x,-1.0,-18.75)',s)
  self.assertIn('k.box(Vector3(x,-1.0,28.75)',s)
  self.assertIn('add_exit("L023>L007#1"',s)
 def test_walkable_slabs_stairs_rims_and_midspans(self):
  s=source('core/world/SpatialBranchworks.gd')
  for phrase in ('kit.slab(origin.x - 9.0','kit.slab(origin.x - 10.0',
                 'kit.stairs(Vector3(origin.x + 11.8','kit.stairs(Vector3(origin.x - 11.8',
                 'minf(ya, yb)', 'kit.commit()', 'open_side: int = 0',
                 'int(sx) == open_side','kit.slab(a.x + 10.0'):
   self.assertIn(phrase,s)
  self.assertEqual(s.count('kit.stairs('),2)
  self.assertNotIn('add_exit(',s)
  self.assertNotIn('player.global_position',s)
  self.assertEqual(32*.5,16)
  for site in D['sites']:
   self.assertGreaterEqual(site['tiers'],4)
   self.assertGreaterEqual(site['rise_m'],3.4)
 def test_no_registered_destinations_or_assets_lost(self):
  self.assertEqual(len(json.loads(source('data/canon/levels.json'))['levels']),100)
  self.assertEqual(D['canon_roster_sha256'],hashlib.sha256((R/'data/canon/levels.json').read_bytes()).hexdigest())
  self.assertEqual(D['transitions_sha256'],hashlib.sha256((R/'data/canon/transitions.json').read_bytes()).hexdigest())
  for sid,digest in D['manifests_sha256'].items():
   self.assertEqual(digest,hashlib.sha256((R/f'levels/{sid}/level.json').read_bytes()).hexdigest())
  self.assertEqual(len(list((R/'assets').rglob('*.glb'))),414)
 def test_all_changed_scripts_pass_light_lexer(self):
  rel=['core/world/SpatialBranchworks.gd','tests/qa_runner.gd','tests/model_asset_smoke_dev16.gd']
  rel.extend(f'levels/{id}/{id}.gd' for id in D['graphs'])
  failures=[]
  for path in rel:failures+=string_and_delimiter_check(source(path),path)
  self.assertEqual(failures,[])
 def test_dedicated_dev16_engine_gate_fails_closed(self):
  runner=source('tests/qa_runner.gd')
  self.assertIn('func _vertical_dev16_suite()',runner)
  block=runner.split('func _vertical_dev16_suite()',1)[1]
  for phrase in ('intersect_ray','_dev14_surface','"L023"','"vertical_dev16_evidence"', '"all_ok"'):
   self.assertIn(phrase,block)
  orchestration=source('tools/run_dev16_qa.py')
  for phrase in ("'vertical_dev14'", "'vertical_dev15'", "'vertical_dev16'", "'model_assets_smoke'", 'Incomplete new DEV16 3D collision evidence'):
   self.assertIn(phrase,orchestration)
  self.assertIn('if report and report.exists():report.unlink()',orchestration)
  self.assertIn("$summary.status -ne 'PASS'",source('EXPORT_DEV16_WINDOWS.ps1'))
  self.assertIn('--export-debug',source('EXPORT_DEV16_WINDOWS.ps1'))
 def test_terrain_avoidance_and_source_logic_kept(self):
  for sid,part in [('L032','absf(x-80.0)<20.0'),('L108','absf(x-108.0)<21.0'),('L077','absf(x-127.0)<20.0'),('L050','absf(x-67.0)<22.0'),('L140','absf(x-100.0) < 21.0')]:
   self.assertIn(part,source(f'levels/{sid}/{sid}.gd'))
  for sid in D['graphs']:
   self.assertEqual(source(f'levels/{sid}/{sid}.gd').count('SpatialBranchworks.install('),2 if sid in {'L048','L320','L808'} else 1)
if __name__=='__main__':unittest.main()
