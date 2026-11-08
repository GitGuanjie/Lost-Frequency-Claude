"""Source-only checks for v1.5.0-dev2. No claims about real Godot gameplay."""
from pathlib import Path
import json
import re
import unittest

ROOT = Path(__file__).resolve().parents[2]
NEW = ('L020', 'L055', 'L058', 'L083', 'L090', 'L140', 'L197', 'L201')
TRANSITIONS = {e['id']: e for e in json.loads((ROOT/'data/canon/transitions.json').read_text(encoding='utf8'))['edges']}
ROSTER = {e['stable_id'] for e in json.loads((ROOT/'data/canon/levels.json').read_text(encoding='utf8'))['levels']}


def lex_balanced(source):
    """Crude source bracket check, ignores strings, # comments, not a GDScript parser."""
    stack, quote, comment, esc = [], None, False, False
    pairs = {')': '(', ']': '[', '}': '{'}
    for i, ch in enumerate(source):
        if ch == '\n':
            comment = False
        if comment:
            continue
        if quote:
            if esc:
                esc = False
            elif ch == '\\':
                esc = True
            elif ch == quote:
                quote = None
            continue
        if ch == '#':
            comment = True
        elif ch in ('"', "'"):
            quote = ch
        elif ch in '([{':
            stack.append((ch, i))
        elif ch in ')]}':
            if not stack or stack.pop()[0] != pairs[ch]:
                return False
    return not stack and not quote


class Dev2Integrity(unittest.TestCase):
    def test_all_eight_are_real_roster_entries(self):
        self.assertEqual(len(NEW), 8)
        for sid in NEW:
            with self.subTest(sid=sid):
                self.assertIn(sid, ROSTER)
                self.assertTrue((ROOT/'docs/canon/levels'/f'{sid}.md').exists())
                self.assertTrue((ROOT/'sources/wiki_text'/f'{sid}.md').exists())

    def test_manifest_and_scripts_consistent(self):
        for sid in NEW:
            with self.subTest(sid=sid):
                base = ROOT/'levels'/sid
                manifest = json.loads((base/'level.json').read_text(encoding='utf8'))
                code = (base/f'{sid}.gd').read_text(encoding='utf8')
                scene = (base/f'{sid}.tscn').read_text(encoding='utf8')
                self.assertEqual(manifest['stable_id'],sid)
                self.assertEqual(manifest['scene'],f'res://levels/{sid}/{sid}.tscn')
                self.assertEqual(manifest['status'],'IN_DEVELOPMENT')
                self.assertIn('UNVERIFIED',manifest['qa_status'])
                self.assertIn('extends LevelBase',code)
                self.assertIn('func build() -> void:',code)
                self.assertIn('func qa_self_test() -> Array:',code)
                self.assertIn(f'stable_id = "{sid}"',scene)
                self.assertTrue(lex_balanced(code))
                for tag in manifest['arrivals']:
                    self.assertIn(f'add_arrival("{tag}"',code)

    def test_every_instantiated_exit_is_source_backed(self):
        for sid in NEW:
            with self.subTest(sid=sid):
                manifest = json.loads((ROOT/'levels'/sid/'level.json').read_text(encoding='utf8'))
                code = (ROOT/'levels'/sid/f'{sid}.gd').read_text(encoding='utf8')
                recorded = set()
                for edge in manifest['exits']:
                    eid = edge['id']
                    self.assertIn(eid,TRANSITIONS)
                    self.assertEqual(TRANSITIONS[eid]['to'],None if edge['to'] in ('EXT', '@origin') else edge['to'])
                    self.assertEqual(edge['basis'],'SOURCE')
                    self.assertNotIn(eid,recorded)
                    self.assertIn(f'add_exit("{eid}"',code)
                    recorded.add(eid)
                expressed = set(re.findall(r'add_exit\("([^"]+)"',code))
                expressed |= set(re.findall(r'"(L\d+>L\d+#\d+)"',code)) if sid == 'L201' else set()
                self.assertTrue(set(re.findall(r'add_exit\("([^"]+)"',code)).issubset(recorded))

    def test_declared_notes_disclose_adaptations(self):
        for sid in NEW:
            m = json.loads((ROOT/'levels'/sid/'level.json').read_text(encoding='utf8'))
            self.assertIn('ADAPTATION:',m['notes'])
            self.assertTrue(m['signature'])
            self.assertTrue(m['mechanics'])

    def test_original_eight_are_not_promoted_without_godot(self):
        for sid in NEW:
            m=json.loads((ROOT/'levels'/sid/'level.json').read_text(encoding='utf8'))
            self.assertNotIn(m['status'],('PLAYABLE','ACCEPTED'))

    def test_real_route_example_is_distinct_from_catalog_order(self):
        edges = [e for sid in NEW for e in json.loads((ROOT/'levels'/sid/'level.json').read_text(encoding='utf8'))['exits']]
        pairs = {(e['id'].split('>')[0],e['to']) for e in edges}
        self.assertIn(('L020','L002'),pairs)
        self.assertIn(('L083','L007'),pairs)
        self.assertIn(('L058','L001'),pairs)
        self.assertIn(('L201','L025'),pairs)


if __name__=='__main__':
    unittest.main()
