"""v1.5-dev8 structural/regression tests. These cannot substitute for Godot physics.

Protects user-facing additions from being silently reverted. Godot must still
compile, navigate, trigger exits and render the levels in a separate test run.
"""
from pathlib import Path
import re
import unittest
import json
ROOT=Path(__file__).resolve().parents[2]

def src(rel):
    return (ROOT/rel).read_text(encoding='utf8')

class Dev8Rework(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.l1=src('levels/L001/L001.gd')
        cls.sys=src('levels/L001/L001_sys.gd')
        cls.l7=src('levels/L007/L007.gd')
        cls.l9=src('levels/L009/L009.gd')
        cls.qa=src('tests/qa_runner.gd')

    def test_level_1_gallery_real_collision_geometry(self):
        self.assertIn('MEZZANINE_CHUNK', self.l1)
        self.assertIn('func _maintenance_gallery(',self.l1)
        self.assertIn('k.stairs(',self.l1)
        self.assertIn('k.slab(43.8, 17.0, 61.5, 29.5',self.l1)
        self.assertIn('9.2 if gallery else HH + 0.4',self.l1)
        self.assertIn('add_landmark("Upper maintenance gallery',self.l1)

    def test_gallery_has_exploration_and_switchable_light(self):
        self.assertIn('Toggle emergency gallery lamp',self.l1)
        self.assertIn('_gallery_circuit_on = not _gallery_circuit_on',self.l1)
        self.assertIn('for fixture in circuit_lights:',self.l1)
        self.assertIn('fixture.light_energy = 1.4 if _gallery_circuit_on else 0.0',self.l1)
        self.assertIn('Inspect maintenance clipboard',self.l1)
        self.assertIn('add_shot("gallery"',self.l1)

    def test_smiler_has_occlusion_and_does_not_attack_through_walls(self):
        self.assertIn('PhysicsRayQueryParameters3D.create(smiler.global_position, cam, 1)',self.sys)
        self.assertIn('ray.exclude = [p.get_rid()]',self.sys)
        self.assertIn('if clear and to.length() < 1.5:',self.sys)
        self.assertIn('_smiler_occluded',self.sys)
        self.assertIn('if not found:',self.sys)

    def test_underwater_acoustic_interaction_is_proximal(self):
        self.assertIn('add_interactable(RING + Vector3(2.6',self.l7)
        self.assertIn('_strike_pipe(',self.l7)
        self.assertIn('func _depth_zone_tick(',self.l7)
        self.assertIn('Tiny:',self.l7)

    def test_level_9_vertical_exploration_retains_original_exit_owner(self):
        self.assertIn('func _night_garage(',self.l9)
        self.assertGreaterEqual(self.l9.count('k.stairs('),2)
        self.assertIn('if Vector2i(cx, cz) == end_owner:',self.l9)
        self.assertIn('Read the abandoned garage register',self.l9)
        self.assertIn('lights.add_anchor(',self.l9)

    def test_qa_route_requires_three_sequential_physical_waypoints(self):
        self.assertIn('if qa_fixture and qa_prog < qa_pts.size():',self.l9)
        self.assertIn('var next_idx: int = qa_prog',self.l9)
        self.assertIn('qa_prog += 1',self.l9)
        self.assertIn('Vector2(player.global_position.x - next_pt.x',self.l9)
        self.assertIn('t.condition = func(): return qa_prog >= 3',self.l9)
        self.assertIn('var i := _near(pts.slice(0, NS)',self.l9)

    def test_bot_does_not_skip_stuck_path_vertex(self):
        block=self.qa.split('func _bot_walk(',1)[1].split('func _',1)[0]
        self.assertIn('physically blocked at navigation vertex',block)
        self.assertIn('if stuck > 8:',block)
        self.assertNotRegex(block,r'if stuck\s*>[^:]+:\s*\n\s*i\s*\+=\s*1')
        self.assertIn('e.interact(p)',block)
        self.assertIn('p.global_position.distance_to(e.global_position) <= 2.2',block)
        self.assertNotIn('.fire(',block)

    def test_focused_route_uses_actual_from_l005_arrival_and_does_not_force_success(self):
        focused=self.qa.split('func _l009_route_suite()',1)[1].split('# =================================================================== story',1)[0]
        self.assertIn('load_level("L009", "from_L005"',focused)
        self.assertIn('used_arrival',focused)
        self.assertIn('after == before + 1',focused)
        self.assertIn('_bot_walk(lvl',focused)
        self.assertIn('qa_trace',focused)
        self.assertNotIn('qa_prog = 3',focused)
        self.assertNotIn('player.global_position =',focused)
        self.assertNotIn('.fire(',focused)

    def test_existing_source_exits_and_level_status_untouched(self):
        for sid in ('L001','L007','L009'):
            man=json.loads(src(f'levels/{sid}/level.json'))
            self.assertEqual(man['stable_id'],sid)
            self.assertTrue(man['exits'])
            for edge in man['exits']:
                self.assertIn(edge['basis'],('SOURCE','ADAPTATION'))

    def test_old_story_route_keeps_progress_failure_evidence(self):
        self.assertIn('qa_prog_before',self.qa)
        self.assertIn('qa_prog_after',self.qa)
        self.assertIn('waypoint_failure',self.qa)
        self.assertIn('qa_trace',self.qa)
        self.assertIn('physical condition trigger fires the canonical',self.qa)

if __name__=='__main__':unittest.main()
