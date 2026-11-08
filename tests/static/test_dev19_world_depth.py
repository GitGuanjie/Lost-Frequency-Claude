"""DEV19 design+source contracts. Passing is NOT Godot physics validation."""
import json, hashlib, math, unittest
from pathlib import Path
from tools.preflight_dev import string_and_delimiter_check
R = Path(__file__).resolve().parents[2]

def src(name): return (R/name).read_text(encoding='utf-8')

class TestDev19WorldDepth(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.old = json.loads(src('data/dev17_cave_braids.json'))
        cls.eco = json.loads(src('data/dev19_cave_ecologies.json'))
        cls.anchor = {tuple(p) for r in cls.old['braids'] + cls.old['links'] for p in r['floor_nodes']}

    def test_01_three_branches_rejoin_existing_sdf_routes(self):
        self.assertEqual(len(self.eco['routes']), 3)
        self.assertEqual(len({r['id'] for r in self.eco['routes']}), 3)
        for r in self.eco['routes']:
            a, b = r['floor_nodes'][0], r['floor_nodes'][-1]
            self.assertIn(tuple(a), self.anchor, r['id']+' begins disconnected')
            self.assertIn(tuple(b), self.anchor, r['id']+' ends disconnected')
            self.assertNotEqual(a, b)
            self.assertGreaterEqual(len(r['floor_nodes']), 4)
            self.assertGreater(r['radius_m'], 1.9)
            self.assertTrue(0 < r['observation_index'] < len(r['floor_nodes'])-1)

    def test_02_geometric_slope_and_floor_contract(self):
        for r in self.eco['routes']:
            for a, b in zip(r['floor_nodes'], r['floor_nodes'][1:]):
                horiz = math.hypot(a[0]-b[0], a[2]-b[2])
                self.assertGreater(horiz, 1.0)
                self.assertLess(math.degrees(math.atan2(abs(a[1]-b[1]), horiz)), 40,
                                'Design slope too steep for native character floor rule')
        self.assertIn('fs.append_array(Ecologies.carve_features())', src('levels/L008/CaveBuild.gd'))
        code = src('levels/L008/CaveEcologies.gd')
        for token in ['"t": "tube"','"t": "room"','"fa": a.y, "fb": b.y','"bb"', 'observation_sites()']:
            if token == '"bb"':
                self.assertIn('f["bb"] = Cave.aabb_of(f)', src('levels/L008/CaveBuild.gd'))
            else:
                self.assertIn(token, code)

    def test_03_observation_sites_exist_in_mapped_chunks(self):
        for route in self.eco['routes']:
            p = route['floor_nodes'][route['observation_index']]
            self.assertTrue(all(math.isfinite(float(v)) for v in p))
        code = src('levels/L008/L008.gd')
        for t in ['Ecologies.observation_sites()', '"Observe the cave junction"',
                  'SaveService.record_discovery(stable_id, "ecology:"',
                  'owner.create_tween()', 'sound.play_at("wind"', ', owner)']:
            self.assertIn(t,code)

    def test_04_poolrooms_two_new_nonidentical_structures(self):
        code = src('levels/L037/L037_signature_halls.gd')
        for token in ['"arch_colonnade_over_double_basin"',
                      '"twilight_tiered_basin_two_way_descent"', 'k.arch_wall(',
                      'k.ramp(', 'g.rect(', 'g.stair(', 'k.cylinder(',
                      '"underwater_returns": 2', '"cross_pool_route": true']:
            self.assertIn(token, code)
        self.assertNotIn('teleport(', code)
        self.assertNotIn('add_exit(', code)
        self.assertNotIn('spawn_enemy(', code)

    def test_05_authored_chunks_connected_on_both_sides(self):
        code = src('levels/L037/L037.gd')
        self.assertIn('Vector2i(4, 0): "hub_colonnade"', code)
        self.assertIn('Vector2i(5, 0): "hub_twilight"', code)
        for x in (3, 4, 5):
            self.assertEqual(code.count(f'"{x},0,x": [[9, 2, 3.6]]'), 1)
        self.assertIn('Signature.paint(g, meta', code)
        self.assertIn('Signature.install(k, Vector3(ox, 0.0, oz)', code)
        self.assertIn('meta["dev19_signature"]', code)
        # The main west/east passage z~18 must avoid decorative pillars.
        self.assertIn('g.reserve(1, 8, 15, 11)',src('levels/L037/L037_signature_halls.gd'))

    def test_06_poolrooms_environment_only_with_visual_state(self):
        code = src('levels/L037/L037.gd')
        block = code.split('func _install_signature_interactions(')[1].split('\n\n\n')[0]
        self.assertIn('for i in 3:', block)
        self.assertIn('tw.tween_property(lamp, "light_energy", 1.75', block)
        self.assertIn('SaveService.record_discovery(', block)
        self.assertIn('make_interactable(', block)
        for bad in ['make_exit(', 'add_exit(', 'teleport(', 'spawn_enemy(', 'NPC.new(']:
            self.assertNotIn(bad, block)
        self.assertIn('meta["dev19_environment_interactions"] = sites.size()', code)

    def test_07_warehouse_gallery_real_two_way_state(self):
        code = src('levels/L001/L001.gd')
        self.assertIn('var _gallery_circuit_on := false',code)
        self.assertIn('for control in [Vector3(35.5, 1.2, 22.0), Vector3(58.5, TOP + 1.15, 25.3)]:',code)
        self.assertIn('_gallery_circuit_on = not _gallery_circuit_on',code)
        self.assertIn('fixture.light_energy = 1.4 if _gallery_circuit_on else 0.0',code)
        self.assertIn('node.add_child(glow)',code)
        # Not allowed to disable default stochastic system flickering.
        self.assertIn('sys.setup(self)',code)

    def test_08_old_roster_and_source_resources_intact(self):
        self.assertEqual(len(json.loads(src('data/canon/levels.json'))['levels']),100)
        self.assertEqual(sum(len(json.loads(p.read_text())['exits']) for p in (R/'levels').glob('*/level.json')),235)
        self.assertEqual(len(list((R/'assets').rglob('*.glb'))),414)
        self.assertEqual(self.eco['route_status'],'DESIGNED_SDF_NOT_ENGINE_WALKED')
        self.assertEqual(len([p for p in R.glob('levels/L037/L037_signature_halls.gd')]),1)

    def test_09_new_gd_and_qa_parse_lexically(self):
        files = ['levels/L037/L037_signature_halls.gd','levels/L037/L037.gd',
                 'levels/L008/CaveEcologies.gd','levels/L008/CaveBuild.gd','levels/L008/L008.gd',
                 'levels/L001/L001.gd','tests/qa_runner.gd']
        issues = [problem for f in files for problem in string_and_delimiter_check(src(f),f)]
        self.assertEqual(issues,[])

    def test_10_engine_test_must_fail_without_fresh_evidence(self):
        runner=src('tools/run_dev19_qa.py')
        gd=src('tests/qa_runner.gd')
        self.assertIn("'vertical_dev19'",runner)
        self.assertIn('vertical_dev19_evidence', runner)
        self.assertIn('func _vertical_dev19_suite()',gd)
        self.assertIn('if report and report.exists():report.unlink()',runner)
        self.assertIn("output['status']='PASS'",runner)
        self.assertIn('No real Godot 4.5.1 executable',src('DEV19_README_FIRST_CN.md'))

if __name__=='__main__': unittest.main()
