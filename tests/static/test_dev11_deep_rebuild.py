"""Dev11 regression checks: explicit SOURCE assertions, never physics substitutes."""
import json, unittest
from pathlib import Path
from tools.preflight_dev import string_and_delimiter_check
ROOT=Path(__file__).resolve().parents[2]
def src(rel):return (ROOT/rel).read_text(encoding='utf8')
class Dev11DeepRebuild(unittest.TestCase):
    def test_roster_and_manifest_exit_unchanged(self):
        roster=json.loads(src('data/canon/levels.json'))['levels']
        self.assertEqual(len(roster),100)
        for sid in ['L004','L005','L009','L011','L037']:
            man=json.loads(src('levels/'+sid+'/level.json'))
            self.assertIn('exits',man)
    def test_level4_three_real_interaction_stations(self):
        s=src('levels/L004/L004.gd');self.assertIn('func _install_archive_circuit()',s)
        self.assertEqual(s.split('func _install_archive_circuit()',1)[1].split('func _archive_count()',1)[0].count('"key":'),3)
        self.assertIn('func _inspect_archive(',s)
        self.assertIn('archive_all_inspected',s)
    def test_level4_exits_still_original(self):
        s=src('levels/L004/L004.gd');block=s.split('func _install_archive_circuit()',1)[1].split('\nfunc _audio()',1)[0]
        self.assertNotIn('add_exit(',block);self.assertNotIn('.fire(',block)
    def test_level5_housekeeping_crosses_hotel_and_boiler(self):
        s=src('levels/L005/L005.gd');self.assertIn('Vector3(5.0, -4.2, 17.4)',s)
        self.assertIn('service_all_read',s);self.assertIn('func qa_self_test() -> Array:',s)
    def test_city_bridge_has_walkable_deck_and_two_physical_stairs(self):
        s=src('levels/L011/L011.gd');block=s.split('func _elevated_walkway(',1)[1].split('\nfunc _skywalk_upper(',1)[0]
        self.assertEqual(block.count('k.stairs('),2)
        self.assertIn('k.slab(',block);self.assertIn('24.0, 1.44, 0.11',block)
        self.assertIn('Vector2i(2, 0)',s)
    def test_city_bridge_is_tested_by_actual_physics_in_engine(self):
        s=src('levels/L011/L011.gd');block=s.split('func qa_self_test()',1)[1]
        self.assertIn('PhysicsRayQueryParameters3D',block);self.assertIn('intersect_ray(',block)
        self.assertIn('float(top["position"].y)',block);self.assertIn('float(stair["position"].y)',block)
    def test_poolrooms_preserve_empty_entity_policy(self):
        s=src('levels/L037/L037.gd');b=s.split('func _depth_landmarks(',1)[1].split('\n## Altered sound:',1)[0]
        self.assertNotIn('add_exit(',b);self.assertNotIn('make_exit(',b)
        self.assertNotIn('spawn_enemy',b);self.assertIn('absf(p.y - q.y)',b)
    def test_level9_actual_arrival_is_streamed_before_interior(self):
        s=src('levels/L009/L009.gd');block=s.split('func build()',1)[1].split('\nfunc _h01',1)[0]
        self.assertLess(block.index('world.build_around(at.origin, 1)'),block.index('_interiors_near(at.origin'))
        self.assertIn('"time_ms": Time.get_ticks_msec()',s)
    def test_model_triggers_receive_player_argument(self):
        s=src('core/world/ModelDress.gd');self.assertIn('func(_p): Overlay.subtitle(description, 3.5)',s)
        self.assertNotIn('prompt, func():',s)
    def test_models_use_per_chunk_index_not_per_chunk_full_scan(self):
        s=src('core/world/ModelDress.gd');self.assertIn('static var _placements_by_chunk',s)
        block=s.split('static func _apply(',1)[1].split('\nstatic func _place(',1)[0]
        self.assertIn('_placements_by_chunk.get(',block)
        self.assertNotIn('for item_var in batch:',block)
    def test_all_edited_gd_files_pass_basic_string_lexer(self):
        rels=['levels/L004/L004.gd','levels/L005/L005.gd','levels/L009/L009.gd','levels/L011/L011.gd','levels/L037/L037.gd','core/world/ModelDress.gd']
        problems=[]
        for rel in rels:problems.extend(string_and_delimiter_check(src(rel),rel))
        self.assertEqual(problems,[])
    def test_godot_export_fails_closed(self):
        p=src('EXPORT_DEV11_WINDOWS.ps1');qa=src('tools/run_dev11_qa.py')
        self.assertIn("$summary.status -ne 'PASS'",p)
        self.assertIn('New evidence JSON was not created',qa)
        self.assertIn('if report and report.exists():report.unlink()',qa)
if __name__=='__main__':unittest.main()
