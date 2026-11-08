"""Dev4 nine-scene source and provenance checks. This is not Godot or Windows QA."""
from pathlib import Path
import json, re, unittest

ROOT=Path(__file__).resolve().parents[2]
NEW=('L001_1','L015','L022','L023','L027','L049','L053','L079','L320')

class Dev4Integrity(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.canon={e['id']:e for e in json.loads((ROOT/'data/canon/transitions.json').read_text())['edges']}
        cls.roster={e['stable_id'] for e in json.loads((ROOT/'data/canon/levels.json').read_text())['levels']}
        cls.manifests={p.parent.name:json.loads(p.read_text()) for p in (ROOT/'levels').glob('*/level.json')}

    def test_scene_paths_and_provenance(self):
        for sid in NEW:
            with self.subTest(sid=sid):
                self.assertIn(sid,self.roster)
                self.assertTrue((ROOT/f'docs/canon/levels/{sid}.md').exists())
                self.assertTrue((ROOT/f'sources/wiki_text/{sid}.md').exists())
                m=self.manifests[sid]
                self.assertEqual(m['status'],'IN_DEVELOPMENT')
                self.assertIn('NOT ENGINE VERIFIED',m['qa_status'])
                self.assertGreaterEqual(len(m['mechanics']),2)
                t=(ROOT/m['scene'].removeprefix('res://')).read_text()
                self.assertIn(f'res://levels/{sid}/{sid}.gd',t)
                g=(ROOT/f'levels/{sid}/{sid}.gd').read_text()
                self.assertIn('func build()',g)
                self.assertIn('qa_self_test()',g)
                self.assertIn('add_shot(',g)

    def test_exits_are_source_bound_not_invented(self):
        for sid in NEW:
            with self.subTest(sid=sid):
                m=self.manifests[sid]
                declared={e['id']:e for e in m['exits']}
                physical=set(re.findall(r'add_exit\("([^\"]+)"', (ROOT/f'levels/{sid}/{sid}.gd').read_text()))
                self.assertEqual(physical,set(declared),sid)
                for eid,edge in declared.items():
                    self.assertIn(eid,self.canon)
                    self.assertEqual(self.canon[eid]['from'],sid)
                    self.assertEqual(edge['to'],self.canon[eid]['to'] or 'EXT')
                    self.assertEqual(edge['basis'],'SOURCE')

    def test_arrival_aliases_are_explicit_not_fabricated_geometry(self):
        base=(ROOT/'core/world/LevelBase.gd').read_text()
        self.assertIn('_register_provisional_arrivals()',base)
        self.assertIn('"provisional_start_alias"',base)
        aliases=0
        for sid,m in self.manifests.items():
            tagset=set(m.get('arrivals',[]))
            codes=(ROOT/f'levels/{sid}/{sid}.gd').read_text()
            for tag in tagset:
                if tag in m.get('arrival_aliases',[]):
                    self.assertTrue(tag.startswith('from_'))
                    aliases+=1
                elif sid in NEW:
                    self.assertIn(f'add_arrival("{tag}"',codes,(sid,tag))
        self.assertGreaterEqual(aliases,30)

    def test_vertical_access_and_trench_bunkers_are_physically_opened(self):
        garage=(ROOT/'levels/L022/L022.gd').read_text()
        self.assertIn('k.slab(26,-18,35,51',garage)
        self.assertIn('k.slab(31,22,39,51',garage)
        # DEV15 adds a supported third rise to a real fourth deck.
        self.assertEqual(garage.count('k.stairs('),3)
        house=(ROOT/'levels/L053/L053.gd').read_text()
        self.assertIn('k.slab(-2,17,2,23',house)
        self.assertIn('k.stairs(',house)
        trench=(ROOT/'levels/L049/L049.gd').read_text()
        self.assertIn('var cuts:Array',trench)
        self.assertIn('k.slab(5 if s>0 else -29',trench)
        roots=(ROOT/'levels/L023/L023.gd').read_text()
        self.assertIn('k.stairs(',roots)
        self.assertIn('WaterVolume.new()',roots)

    def test_uncertain_destinations_are_not_fabricated(self):
        for sid in ('L015','L079'):
            m=self.manifests[sid]
            self.assertEqual(m['exits'],[])
        s=(ROOT/'levels/L053/L053.gd').read_text()
        self.assertIn('red.condition=func():return _breached',s)
        self.assertNotIn('_breached=true',s)

    def test_new_content_has_nontrivial_interactivity(self):
        snippets={
            'L001_1':'_dark_time', 'L015':'_terminal(', 'L022':'_diary_count',
            'L023':'_heart()', 'L027':'_bath_seconds', 'L049':'_weather_time',
            'L053':'_write_letter(', 'L079':'_machine_clock', 'L320':'_ride(',
        }
        for sid,needle in snippets.items():
            self.assertIn(needle,(ROOT/f'levels/{sid}/{sid}.gd').read_text(),sid)

if __name__=='__main__':unittest.main()
