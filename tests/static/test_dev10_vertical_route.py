"""Dev10 offline regression assertions. Never substitute for native Godot QA."""
import json
import re
import unittest
from pathlib import Path
from tools.preflight_dev import string_and_delimiter_check

ROOT = Path(__file__).resolve().parents[2]

def source(path: str) -> str:
    return (ROOT / path).read_text(encoding='utf8')

class Dev10VerticalAndRoutes(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.zero = source('levels/L000/L000.gd')
        cls.nine = source('levels/L009/L009.gd')
        cls.qa = source('tests/qa_runner.gd')
        cls.dev = source('tools/run_dev10_qa.py')
        cls.win = source('EXPORT_DEV10_WINDOWS.ps1')

    def test_level_zero_third_floor_is_sparse_and_deterministic(self):
        self.assertIn('"upper_observation"', self.zero)
        self.assertIn('if tall:', self.zero)
        self.assertIn('meta["storeys"] = 3 if tall else 2', self.zero)
        self.assertIn('func _third_atrium_gallery(', self.zero)
        self.assertIn('var top := third + H if tall else up + H', self.zero)

    def test_third_floor_has_physical_access_and_void(self):
        block = self.zero.split('func _third_atrium_gallery(', 1)[1].split('\nfunc ', 1)[0]
        self.assertIn('k.stairs(',block)
        self.assertIn('k.slab(x0, oz + 14.9, x1, oz + 16.9',block)
        self.assertIn('ox + 2.0, z0, ox + 4.8',block)
        self.assertIn('upper - lower, 18, mat, 0.32, false',block)
        self.assertIn('side guards',self.zero)
        self.assertIn('Read the maintenance note',block)
        self.assertNotIn('add_exit(',block)

    def test_qa_verifies_actual_collision_shapes(self):
        test = self.qa.split('func _vertical_atrium_suite()', 1)[1].split('\nfunc ', 1)[0]
        self.assertIn('intersect_ray(landing_query)',test)
        self.assertIn('intersect_ray(bridge_query)',test)
        self.assertIn('intersect_ray(slot_query).is_empty()',test)
        self.assertIn('"scope": "geometry collision smoke only; not player-path proof"',test)

    def test_level9_observations_do_not_grant_route_progress(self):
        block=self.nine.split('"Examine the arrow street sign"',1)[1].split('\nfunc ',1)[0]
        self.assertIn('SaveService.set_flag(',block)
        self.assertNotIn('qa_prog +=',block)
        self.assertNotIn('last +=',block)
        self.assertNotIn('.fire(',block)
        self.assertIn('if qa_fixture and qa_prog < qa_pts.size():',self.nine)

    def test_navigation_diagnostics_do_not_skip_vertices(self):
        block=self.qa.split('func _bot_walk(',1)[1].split('\nfunc ',1)[0]
        self.assertIn('no_goal_progress_seconds',block)
        self.assertIn('nav_vertex',block)
        self.assertIn('if stuck > 8:',block)
        self.assertNotRegex(block,r'if stuck\s*>\s*\d+[^\n]*:\s*\n\s*i\s*\+=')
        self.assertNotIn('.fire(',block)
        self.assertIn('p.global_position.distance_to(e.global_position) <= 2.2',block)

    def test_level9_streams_geometry_before_navmesh_bake(self):
        block=self.qa.split('func _nav_check(',1)[1].split('\nfunc ',1)[0]
        self.assertLess(block.index('build_around(target_pos, 1)'),block.index('bake_from_source_geometry_data('))
        self.assertIn('spawn_projection_error',block)
        self.assertIn('nav_polygons',block)

    def test_l009_load_has_bounded_failure_mode(self):
        test=self.qa.split('func _l009_route_suite()',1)[1].split('\nfunc ',1)[0]
        self.assertIn('load_level("L009", "from_L005"',test)
        self.assertIn('Time.get_ticks_msec() - load_started < 30000',test)
        self.assertIn('after == before + 1',test)
        self.assertNotIn('qa_prog = 3',test)
        self.assertNotIn('player.global_position =',test)

    def test_dev10_godot_qagates_explicit(self):
        for stage in ('model_assets_smoke','vertical_atrium','l009_route','registry','lint','save','ui'):
            self.assertIn(stage,self.dev)
        self.assertIn('--full',self.dev)
        self.assertIn('if report and report.exists():report.unlink()',self.dev)
        self.assertIn('Not all 414 imported GLBs instantiated successfully',self.dev)
        self.assertIn('Real conditional L009>L011 trigger',self.dev)
        self.assertIn("output['status']='PASS' if len(stages)",self.dev)

    def test_windows_export_requires_fresh_engine_evidence(self):
        self.assertIn("$summary.status -ne 'PASS'",self.win)
        self.assertIn('Godot QA failed',self.win)
        self.assertIn('--export-debug',self.win)
        self.assertIn('Manual GPU review remains mandatory',self.win)

    def test_source_grammar_brackets_all_gd_files(self):
        problems=[]
        for path in ROOT.rglob('*.gd'):
            if '.godot' not in path.parts:
                problems.extend(string_and_delimiter_check(path.read_text(encoding='utf8'),str(path.relative_to(ROOT))))
        self.assertEqual(problems,[])

    def test_roster_unchanged_and_licensed_models_present(self):
        roster=json.loads((ROOT/'data/canon/levels.json').read_text())['levels']
        self.assertEqual(len(roster),100)
        catalog=json.loads((ROOT/'assets/packs/catalog.json').read_text())['models']
        self.assertEqual(len(catalog),414)
        self.assertTrue((ROOT/'assets/packs/LICENSE_AND_SOURCE.txt').exists())

if __name__=='__main__':
    unittest.main()
