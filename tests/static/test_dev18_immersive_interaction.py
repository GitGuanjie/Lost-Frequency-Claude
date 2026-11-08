"""Dev18 atmosphere and interaction contracts; NOT physics/engine verification."""
import json, math, unittest
from pathlib import Path
from tools.preflight_dev import string_and_delimiter_check
ROOT = Path(__file__).resolve().parents[2]
def src(name): return (ROOT/name).read_text(encoding='utf-8')
class TestDev18ImmersiveInteraction(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.amb = json.loads(src('data/dev18_ambient_discoveries.json'))
    def test_01_event_schemas(self):
        self.assertEqual(self.amb['schema'],'dev18_proximity_story_v1')
        self.assertEqual(set(self.amb['levels']),{'L000','L001','L008','L009','L037'})
        self.assertEqual(sum(map(len,self.amb['levels'].values())),17)
    def test_02_cues_are_unique_and_reachable_scale(self):
        ids=[]
        for level,events in self.amb['levels'].items():
            for event in events:
                ids.append((level,event['id']))
                self.assertEqual(event['source'] in {'CANON_MOTIF','ADAPTATION'}, True)
                self.assertEqual(len(event['pos']),3)
                self.assertTrue(all(math.isfinite(float(x)) for x in event['pos']))
                self.assertGreaterEqual(event['radius'],2.0)
                self.assertLessEqual(event['radius'],6.0)
                self.assertGreaterEqual(event.get('height',2.75),1.0)
                self.assertLessEqual(event.get('height',2.75),3.5)
                self.assertGreater(len(event['caption']),20)
        self.assertEqual(len(set(ids)),len(ids))
    def test_03_sound_library_recipes_exist(self):
        code=src('autoload/AudioSynth.gd')
        sounds={ev['sound'] for events in self.amb['levels'].values() for ev in events}
        for sound in sounds: self.assertIn('"%s":'%sound,code)
    def test_04_chunk_owned_colliders(self):
        base=src('core/world/LevelBase.gd')
        self.assertIn('owner.add_child(it)',base)
        self.assertIn('return make_interactable(center, size, prompt, cb, self)',base)
        for level in ['L000','L001','L008','L037']:
            code=src('levels/%s/%s.gd'%(level,level))
            self.assertIn('make_interactable(',code)
            self.assertIn(', owner)',code)
    def test_05_stateful_wall_markers_shift_with_room(self):
        code=src('levels/L000/L000.gd')
        for token in ['_wall_marks[key] = version','_on_marked_chunk_shifted','_wall_marks.erase(key)', 'make_interactable(']:
            self.assertIn(token,code)
    def test_06_valves_optional_not_required_for_exits(self):
        code=src('levels/L001/L001.gd')
        self.assertIn('"dev18_valve"',code)
        self.assertIn('_valve_states[id] = now',code)
        self.assertIn('lamp.light_energy = 1.0 if now else 0.0',code)
    def test_07_cave_landmarks_at_existing_braid_nodes(self):
        code=src('levels/L008/L008.gd')
        for xyz in ['56.0, 7.0, -20.0','74.0, -8.0, 28.0','128.0, 2.0, -28.0']:
            self.assertIn(xyz,code)
        self.assertIn('Inspect 9th Road marker',code)
        self.assertIn('path_length += (Lay.ROAD',code)
        self.assertIn('Study the cave formation (do not touch)',code)
    def test_08_pool_environment_only(self):
        code=src('levels/L037/L037.gd')
        for text in ['Listen to the water','Touch the perfectly smooth tile','Feel the air above the stair pit','Watch light bend through the pool']:
            self.assertIn(text,code)
        block=code.split('func _install_environment_touches(')[1].split('\n\n\n')[0]
        for forbidden in ['make_exit(', 'add_exit(', 'spawn_enemy(', 'teleport(', 'add_note(']:
            self.assertNotIn(forbidden,block)
    def test_09_vertical_gating_and_once_trigger(self):
        code=src('core/world/AmbientDiscovery.gd')
        for text in ['heard.has(key)','absf(p.y - at.y)', 'cooldown = 12.0','SessionState.is_qa()', 'Overlay.subtitle(', 'level.sound.play_at(']:
            self.assertIn(text,code)
    def test_10_no_modification_to_registry_or_resources(self):
        self.assertEqual(len(json.loads(src('data/canon/levels.json'))['levels']),100)
        self.assertEqual(sum(len(json.loads(p.read_text())['exits']) for p in (ROOT/'levels').glob('*/level.json')),235)
        self.assertEqual(len(list((ROOT/'assets').rglob('*.glb'))),414)
    def test_11_lexical_sanity(self):
        files=['core/world/AmbientDiscovery.gd','core/world/LevelBase.gd','levels/L000/L000.gd', 'levels/L001/L001.gd','levels/L008/L008.gd','levels/L037/L037.gd','tests/qa_runner.gd']
        issues=[]
        for f in files: issues.extend(string_and_delimiter_check(src(f),f))
        self.assertEqual(issues,[])
    def test_12_field_journal_survives_old_saves(self):
        save=src('autoload/SaveService.gd')
        ui=src('ui/Overlay.gd')
        self.assertIn('func record_discovery(',save)
        self.assertIn('if not j.has("discoveries"):',save)
        self.assertIn('j.get("discoveries", [])',ui)
        self.assertIn('Environmental observations:',ui)
        for f in ['core/world/AmbientDiscovery.gd','levels/L000/L000.gd','levels/L001/L001.gd','levels/L008/L008.gd','levels/L037/L037.gd']:
            self.assertIn('SaveService.record_discovery(',src(f))
    def test_13_engine_gate_exists(self):
        s=src('tools/run_dev18_qa.py')
        self.assertIn('interactions_dev18',s)
        self.assertIn('Godot not available or timed out',s)
        self.assertIn('if report and report.exists():report.unlink()',s)
        self.assertIn('interactions_dev18_evidence',src('tests/qa_runner.gd'))
if __name__=='__main__': unittest.main()
