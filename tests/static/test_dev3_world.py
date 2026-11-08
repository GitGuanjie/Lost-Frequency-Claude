"""Focused dev3 source/source-ID, scene and evidence gates. No engine-pass claims."""
from pathlib import Path
import json, re, unittest

ROOT=Path(__file__).resolve().parents[2]
NEW=("L031","L048","L000_3","L006_1","L021","L808","L922","L149")

class Dev3SourceGates(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.edges={e["id"]: e for e in json.loads((ROOT/"data/canon/transitions.json").read_text())["edges"]}
        cls.roster={e["stable_id"] for e in json.loads((ROOT/"data/canon/levels.json").read_text())["levels"]}

    def test_roster_and_source_dossiers_exist(self):
        for sid in NEW:
            self.assertIn(sid,self.roster)
            self.assertTrue((ROOT/f"docs/canon/levels/{sid}.md").exists())
            self.assertTrue((ROOT/f"sources/wiki_text/{sid}.md").exists())

    def test_instantied_exit_ids_are_manifested_and_canonical(self):
        for sid in NEW:
            d=json.loads((ROOT/f"levels/{sid}/level.json").read_text())
            source=(ROOT/f"levels/{sid}/{sid}.gd").read_text()
            used=re.findall(r'add_exit\(\"([^\"]+)\"',source)
            declared={e["id"]:e for e in d["exits"]}
            self.assertEqual(set(used),set(declared),sid)
            for edge in used:
                self.assertIn(edge,self.edges,edge)
                self.assertEqual(self.edges[edge]["from"],sid)
                self.assertEqual(self.edges[edge]["to"],declared[edge]["to"])
                self.assertEqual(declared[edge]["basis"],"SOURCE")

    def test_scene_paths_and_review_state(self):
        for sid in NEW:
            d=json.loads((ROOT/f"levels/{sid}/level.json").read_text())
            self.assertEqual(d["status"],"IN_DEVELOPMENT",sid)
            self.assertIn("NOT ENGINE VERIFIED",d["qa_status"])
            scene=(ROOT/d["scene"].removeprefix("res://")).read_text()
            self.assertIn(f"res://levels/{sid}/{sid}.gd",scene)
            script=(ROOT/f"levels/{sid}/{sid}.gd").read_text()
            self.assertIn("func qa_self_test() -> Array:",script)
            self.assertIn("add_shot(",script)
            for arr in d["arrivals"]:
                if arr in d.get("arrival_aliases", []):
                    self.assertTrue(arr.startswith("from_"), (sid, arr))
                    self.assertIn("_register_provisional_arrivals", (ROOT/"core/world/LevelBase.gd").read_text())
                else:
                    self.assertIn(f'add_arrival("{arr}"',script)

    def test_distinct_world_mechanics(self):
        for sid in NEW:
            d=json.loads((ROOT/f"levels/{sid}/level.json").read_text())
            self.assertGreaterEqual(len(d["mechanics"]),2)
        stairs=(ROOT/"levels/L922/L922.gd").read_text()
        self.assertIn('k.stairs(',stairs)
        self.assertIn('player.global_position=Vector3(-8,0.25,-10)',stairs)
        isles=(ROOT/"levels/L149/L149.gd").read_text()
        self.assertIn('rules["gravity"]=1.47',isles)
        self.assertIn('rng.randf()<0.002',isles)

if __name__=="__main__": unittest.main()
