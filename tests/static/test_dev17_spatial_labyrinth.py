"""DEV17 data/source alignment checks (not a substitute for running Godot)."""
import json,hashlib,math,unittest
from pathlib import Path
from tools.build_dev17_topology import build,metrics,cave_graph,pool_graph
from tools.preflight_dev import string_and_delimiter_check
R=Path(__file__).resolve().parents[2]
def src(name):return (R/name).read_text()
class TestDev17SpatialLabyrinth(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.cave=json.loads(src('data/dev17_cave_braids.json'))
        cls.pool=json.loads(src('data/dev17_pool_annexes.json'))
        cls.report=json.loads(src('data/dev17_spatial_graphs.json'))
    def test_cave_graph_8_nontrivial_cycles(self):
        g=cave_graph();m=metrics(g)
        self.assertEqual(m['connected_components'],1)
        self.assertEqual(m['cycle_rank'],8)
        self.assertEqual(m['height_span_m'],21)
        self.assertEqual((m['nodes'],m['edges']),(46,53))
    def test_all_cave_braids_sdf_and_slope_limited(self):
        self.assertEqual(len(self.cave['braids']),6)
        self.assertEqual(len(self.cave['links']),2)
        for route in self.cave['braids']+self.cave['links']:
            pts=route['floor_nodes']
            self.assertGreaterEqual(len(pts),4)
            for a,b in zip(pts,pts[1:]):
                self.assertLessEqual(abs(a[1]-b[1])/math.dist([a[0],a[2]],[b[0],b[2]]),.46)
        self.assertIn('fs.append_array(Braids.carve_features())',src('levels/L008/CaveBuild.gd'))
        self.assertIn('"fa": a.y, "fb": b.y',src('levels/L008/CaveBraids.gd'))
        self.assertNotIn('add_exit(',src('levels/L008/CaveBraids.gd'))
    def test_cave_graph_not_merely_new_prefab(self):
        s=src('levels/L008/CaveBraids.gd')
        for term in ['"t": "tube"','"t": "room"','carve_features','FileAccess.get_file_as_string','"sq": 0.94']:
            self.assertIn(term,s)
    def test_pool_topology_multi_tier_and_underwater_loops(self):
        m=metrics(pool_graph())
        self.assertEqual(m['connected_components'],1)
        self.assertEqual(m['cycle_rank'],22)
        self.assertEqual((m['nodes'],m['edges']),(68,89))
        self.assertAlmostEqual(m['height_span_m'],15.72)
        self.assertEqual([p['tiers'] for p in self.pool['annexes'].values()],[3,4])
        self.assertEqual([p['basin_floor_m'] for p in self.pool['annexes'].values()],[-7.25,-8.25])
    def test_pool_hub_uses_fixed_bidirectional_border_openings(self):
        s=src('levels/L037/L037.gd')
        for t in ['Vector2i(2, 0): "hub_annex_a"','Vector2i(3, 0): "hub_annex_b"',
                  '"1,0,x": [[9, 2, 3.6]]', '"2,0,x": [[9, 2, 3.6]]',
                  'Annex.install(k, Vector3(ox, 0.0, oz)', 'meta["vertical_annex"]']:
            self.assertIn(t,s)
        self.assertEqual(s.count('"2,0,x":'),1)
        self.assertEqual(s.count('"3,0,x":'),1)
    def test_pool_architecture_uses_physical_collision(self):
        s=src('levels/L037/L037_vertical_annex.gd')
        for phrase in ['k.stairs(', 'k.ramp(', 'k.slab(', '28, "l37_tile", 0.5, false',
                       '"deep_ramp_segments": 9','"res://data/dev17_pool_annexes.json"']:
            self.assertIn(phrase,s)
        for bad in ('add_exit(','player.global_position','teleport('):self.assertNotIn(bad,s)
    def test_contract_source_hashes_and_graphs_reproducible(self):
        expected=self.report['sources_sha256']
        for path,h in expected.items():
            self.assertEqual(hashlib.sha256((R/path).read_bytes()).hexdigest(),h)
        self.assertEqual(self.report['graphs']['L008'],cave_graph())
        self.assertEqual(self.report['graphs']['L037'],pool_graph())
        self.assertEqual(self.report['status'],'DESIGN_GRAPH_ONLY')
    def test_canon_roster_and_external_models_unchanged(self):
        self.assertEqual(len(json.loads(src('data/canon/levels.json'))['levels']),100)
        self.assertEqual(sum(len(json.loads(p.read_text())['exits']) for p in (R/'levels').glob('*/level.json')),235)
        self.assertEqual(len(list((R/'assets').rglob('*.glb'))),414)
    def test_gd_code_delimiter_sanity(self):
        paths=['levels/L008/CaveBraids.gd','levels/L008/CaveBuild.gd','levels/L008/L008.gd',
               'levels/L037/L037_vertical_annex.gd','levels/L037/L037_kinds.gd',
               'levels/L037/L037.gd','tests/qa_runner.gd', 'tests/model_asset_smoke_dev17.gd']
        errors=[]
        for path in paths:errors.extend(string_and_delimiter_check(src(path),path))
        self.assertEqual(errors,[])
    def test_engine_release_gate_is_fail_closed(self):
        source=src('tests/qa_runner.gd')
        self.assertIn('func _vertical_dev17_suite()',source)
        self.assertIn('world.build_around(p, 0)',source)
        self.assertIn('space.intersect_ray(q)',source)
        self.assertIn('"vertical_dev17_evidence"',source)
        runner=src('tools/run_dev17_qa.py')
        self.assertIn("'vertical_dev17'",runner)
        self.assertIn("'vertical_dev16'",runner)
        self.assertIn("ModelAssetSmokeDev17.tscn",runner)
        self.assertIn('DEV17 Godot L008+L037 physical route evidence absent or failing',runner)
        self.assertIn("if report and report.exists():report.unlink()",runner)
        self.assertIn("$summary.status -ne 'PASS'",src('EXPORT_DEV17_WINDOWS.ps1'))
        self.assertIn('--export-debug',src('EXPORT_DEV17_WINDOWS.ps1'))
if __name__=='__main__':unittest.main()
