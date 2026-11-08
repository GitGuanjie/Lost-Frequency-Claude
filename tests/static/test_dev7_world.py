"""Dev7 source contracts only. No false implication of Godot or Windows runtime validation."""
import json
import re
import sys
import tempfile
import unittest
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools'))
from preflight_dev import string_and_delimiter_check
from world_audit import audit

NEW=('L994','L005_3','L007_8','L009_3','L011_2','L032','L052','L077',
     'L085','L101','L108','L160','L263','L737','L899','L998')
BUILT_DEST={'L005_3':{'L005_3>L005_3#1','L005_3>L005#2'},
            'L007_8':{'L007_8>L008#1','L007_8>L007_7#2'},
            'L011_2':{'L011_2>L011#1','L011_2>L036#6'},
            'L085':{'L085>L601#2'}, 'L101':{'L101>L000#1'},
            'L737':{'L737>L998#4'}}

class Dev7SourceContracts(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.roster={x['stable_id']:x for x in json.loads((ROOT/'data/canon/levels.json').read_text())['levels']}
        cls.edges={x['id']:x for x in json.loads((ROOT/'data/canon/transitions.json').read_text())['edges']}

    def test_all_100_roster_scenes_exist(self):
        self.assertEqual(len(self.roster),100)
        for sid in self.roster:
            self.assertTrue((ROOT/'levels'/sid/'level.json').is_file(),sid)
            self.assertTrue((ROOT/'levels'/sid/f'{sid}.tscn').is_file(),sid)
            self.assertTrue((ROOT/'levels'/sid/f'{sid}.gd').is_file(),sid)

    def test_new_scenes_are_not_falsely_accepted(self):
        for sid in NEW:
            with self.subTest(sid=sid):
                man=json.loads((ROOT/'levels'/sid/'level.json').read_text())
                self.assertEqual(man['status'],'IN_DEVELOPMENT')
                self.assertIn('NOT ENGINE VERIFIED',man['qa_status'])
                self.assertTrue(man.get('procedural'))
                self.assertGreaterEqual(len(man['mechanics']),3)

    def test_all_declared_exits_match_sourced_edges(self):
        for sid in NEW:
            with self.subTest(sid=sid):
                man=json.loads((ROOT/'levels'/sid/'level.json').read_text())
                for e in man['exits']:
                    self.assertIn(e['id'],self.edges)
                    source=self.edges[e['id']]
                    self.assertEqual(e['to'],source.get('to') or 'EXT')
                    self.assertEqual(source['from'],sid)
                    self.assertEqual(e['basis'],'SOURCE')
                    self.assertTrue(e['source_quote'])

    def test_physical_exits_are_only_sourced_and_in_builtin_targets(self):
        for sid in NEW:
            with self.subTest(sid=sid):
                text=(ROOT/'levels'/sid/f'{sid}.gd').read_text()
                physical=re.findall(r'add_exit\("([^"\n]+)"',text)
                self.assertEqual(len(physical),len(set(physical)))
                self.assertEqual(set(physical),BUILT_DEST.get(sid,set()))
                for eid in physical:
                    self.assertIn(eid,self.edges)
                    self.assertNotEqual(self.edges[eid].get('to'),None)

    def test_16_distinct_scene_authorship(self):
        markers=('EmptyEastBeach','PrometheanReadingHall','StiltVillage','WheatMazes',
                 'WinterRefuge','SkeletonForest','CavernOfMessages','ShenandoahPasture',
                 'BrilliantEvermoreSuburb','TheNearlyFamiliarHome','FertileGrounds',
                 'TheUnspecifiedPactThreshold','PrettyPinkIntervals',
                 'SevenHundredThirtySeven','IslandOfYonder','StormsAtWorldEdge')
        for sid,mark in zip(NEW,markers):
            with self.subTest(sid=sid):
                text=(ROOT/'levels'/sid/f'{sid}.gd').read_text()
                self.assertIn(mark,text)
                self.assertIn('k.commit()',text)
                self.assertIn('add_landmark(',text)
                self.assertGreaterEqual(text.count('add_shot('),2)
                self.assertIn('func qa_self_test()->Array:',text)
                self.assertGreaterEqual(text.count('add_interactable(')+text.count('add_note('),1)
                self.assertFalse(string_and_delimiter_check(text,sid))

    def test_scenes_have_real_start_and_all_arrivals_declared_in_script(self):
        for sid in NEW:
            with self.subTest(sid=sid):
                man=json.loads((ROOT/'levels'/sid/'level.json').read_text())
                source=(ROOT/'levels'/sid/f'{sid}.gd').read_text()
                self.assertIn('start',man['arrivals'])
                for tag in man['arrivals']:
                    self.assertIn(f'add_arrival("{tag}"',source)

    def test_lakes_and_upper_library_have_real_geometry_openings(self):
        isle=(ROOT/'levels/L899/L899.gd').read_text()
        self.assertNotIn('k.slab(-82,-83,82,83,0,1.2',isle)
        self.assertIn('k.slab(-82,-83,82,-13,0,1.2',isle)
        lib=(ROOT/'levels/L005_3/L005_3.gd').read_text()
        self.assertIn('k.slab(-16,-52,22,-25,5.5',lib)
        self.assertIn('k.ramp(Vector3(-19,0,-51)',lib)
        ocean=(ROOT/'levels/L007_8/L007_8.gd').read_text()
        self.assertNotIn('k.box(Vector3(-0.6,3.3,z),Vector3(6.0,3.4,7)',ocean)

    def test_manifest_world_routes_have_no_structural_issues(self):
        with tempfile.TemporaryDirectory() as temp:
            result=audit(root=ROOT,output=Path(temp),render=False)
        self.assertEqual(result['built_count'],100)
        self.assertEqual(result['issues'],[])

    def test_unsupported_exits_remain_unlinked(self):
        no_known=('L994','L009_3','L032','L052','L077','L108','L160','L263','L899','L998')
        for sid in no_known:
            text=(ROOT/'levels'/sid/f'{sid}.gd').read_text()
            self.assertNotIn('add_exit(',text,sid)

    def test_all_gd_files_lexically_balanced(self):
        files=list(ROOT.rglob('*.gd'))
        self.assertGreaterEqual(len(files),200)
        failures=[]
        for path in files:
            failures.extend(string_and_delimiter_check(path.read_text(encoding='utf-8'),str(path.relative_to(ROOT))))
        self.assertEqual(failures,[],"This is delimiter/string sanity, not Godot parsing")

    def test_level_14_shader_source_strings_are_valid_multiline_literals(self):
        source=(ROOT/'levels/L014/L014_art.gd').read_text(encoding='utf-8')
        self.assertEqual(source.count(':= """shader_type'),8)
        self.assertFalse(string_and_delimiter_check(source,'L014_art.gd'))

    def test_disallowed_misleading_status_not_present(self):
        for sid in NEW:
            text=(ROOT/'levels'/sid/'level.json').read_text()
            self.assertNotIn('ENGINE_SMOKE_PASS',text)
            self.assertNotIn('"status": "PLAYABLE"',text)

if __name__=='__main__':unittest.main()
