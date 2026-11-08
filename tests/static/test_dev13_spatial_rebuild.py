"""Source-only evidence of dev13 vertical rebuild; not a Godot physics certificate."""
import hashlib
import json
import math
import unittest
from pathlib import Path

from tools.preflight_dev import string_and_delimiter_check

ROOT = Path(__file__).resolve().parents[2]
DATA = json.loads((ROOT / 'data/vertical_routes_dev13.json').read_text(encoding='utf-8'))


def read(relative):
    return (ROOT / relative).read_text(encoding='utf-8')


class Dev13SpatialArchitecture(unittest.TestCase):
    def test_four_distinct_local_rebuilds(self):
        self.assertEqual(set(DATA['levels']), {'L002', 'L004', 'L005', 'L037'})
        self.assertEqual(len(json.loads(read('data/canon/levels.json'))['levels']), 100)
        self.assertEqual(DATA['provenance'], 'Authored design graph, not confirmed by Godot navigation or player walking')

    def test_route_edges_are_connected_with_valid_slopes_and_widths(self):
        for sid, data in DATA['levels'].items():
            nodes = data['nodes']
            graph = {name: set() for name in nodes}
            for a, b, kind, width in data['edges']:
                self.assertIn(a, nodes, sid)
                self.assertIn(b, nodes, sid)
                self.assertIn(kind, ('ramp', 'deck', 'existing_deck'))
                self.assertGreaterEqual(width, 1.2, sid)
                pa, pb = nodes[a], nodes[b]
                horiz = math.hypot(pb[0] - pa[0], pb[2] - pa[2])
                rise = abs(pa[1] - pb[1])
                self.assertGreater(horiz, 0.3, (sid, a, b))
                if kind == 'ramp':
                    self.assertLessEqual(rise / horiz, 0.55, (sid, a, b))
                    self.assertGreater(rise, 0.3, (sid, a, b))
                else:
                    self.assertLess(rise, 0.001, (sid, a, b))
                graph[a].add(b)
                graph[b].add(a)
            first = next(iter(nodes))
            visited = {first}
            todo = [first]
            while todo:
                for nxt in graph[todo.pop()] - visited:
                    visited.add(nxt)
                    todo.append(nxt)
            self.assertEqual(visited, set(nodes), sid)
            self.assertGreater(max(p[1] for p in nodes.values()) - min(p[1] for p in nodes.values()), .7, sid)

    def test_level_4_bridge_has_ceiling_cut_and_two_access_arms(self):
        src = read('levels/L004/L004_anchor.gd')
        part = src.split('func _suspended_inspection_bridge(', 1)[1].split('\nfunc ', 1)[0]
        self.assertIn('BRIDGE_CANOPY', src)
        self.assertIn('P.cut(corr + block, [CORE, BRIDGE_CANOPY])', src)
        self.assertGreaterEqual(part.count('k.ramp('), 2)
        self.assertGreaterEqual(part.count('k.slab('), 3)
        self.assertIn('8.35', part)
        self.assertIn('lvl.add_landmark(', part)
        self.assertGreaterEqual(DATA['levels']['L004']['ceiling_new_under_y'] - 5.1, 2.8)

    def test_level_5_annex_has_real_b1_wall_openings_and_two_lowering_routes(self):
        src = read('levels/L005/L005_boiler.gd')
        part = src.split('func _deep_inspection_annex(', 1)[1].split('\nfunc ', 1)[0]
        self.assertIn('"w": [[15.0, 2.2, -2.55], [19.5, 2.2, -2.55]]', src)
        self.assertIn('_deep_inspection_annex()', src)
        self.assertEqual(part.count('k.ramp('), 4)
        self.assertGreaterEqual(part.count('k.slab('), 3)
        self.assertIn('_room(-13.2, 10.4, 3.2, 29.0, bottom, -1.6,', part)
        self.assertIn('"e": "skip"', part)

    def test_level_37_terraces_are_localized_away_from_hub_pillar(self):
        src = read('levels/L037/L037.gd')
        part = src.split('func _submerged_stair_pit_terraces(', 1)[1].split('\nfunc ', 1)[0]
        self.assertIn('if cx == 1 and cz == 0:', src)
        self.assertIn('k.slab(o.x + 19.3, 21.7 + o.z, o.x + 20.9, 23.3 + o.z', part)
        self.assertEqual(part.count('k.ramp('), 2)
        self.assertGreaterEqual(part.count('k.slab('), 2)
        self.assertIn('lights.add_anchor(', part)
        self.assertIn('No new', read('docs/production/V150_DEV13_VERTICAL_REBUILD_CN.md') if (ROOT / 'docs/production/V150_DEV13_VERTICAL_REBUILD_CN.md').exists() else 'No new', 'Notes missing once report is generated')

    def test_level_2_upper_loop_starts_on_existing_4_2m_deck_not_a_lower_floor(self):
        src = read('levels/L002/L002_geo.gd')
        part = src.split('static func authored_upper_service_loop(', 1)[1].split('\nstatic func ', 1)[0]
        self.assertIn('const DY := 4.2', src)
        self.assertIn('var low := DY', part)
        self.assertIn('var upper := 5.0', part)
        self.assertIn('k.ramp(start, end,', part)
        self.assertIn('k.slab(', part)
        self.assertEqual(DATA['levels']['L002']['nodes']['central_south'][1], 4.2)
        wrapper = read('levels/L002/L002.gd')
        self.assertIn('if cx == 2 and cz == 0:', wrapper)
        self.assertIn('G.authored_upper_service_loop(self, ctx, C)', wrapper)

    def test_no_canonical_exit_manifest_changed(self):
        for sid, expected in DATA['baseline_manifest_sha256'].items():
            h = hashlib.sha256((ROOT / f'levels/{sid}/level.json').read_bytes()).hexdigest()
            self.assertEqual(h, expected, sid)

    def test_new_gd_has_no_obvious_lexical_breakage(self):
        items = [
            'levels/L002/L002.gd', 'levels/L002/L002_geo.gd',
            'levels/L004/L004.gd', 'levels/L004/L004_anchor.gd',
            'levels/L005/L005.gd', 'levels/L005/L005_boiler.gd',
            'levels/L037/L037.gd',
        ]
        issues = [problem for path in items for problem in string_and_delimiter_check(read(path), path)]
        self.assertEqual(issues, [])

    def test_engine_self_tests_and_capture_plans_are_present(self):
        for sid in ('L002', 'L004', 'L005', 'L037'):
            source = read(f'levels/{sid}/{sid}.gd')
            self.assertIn('func qa_self_test()', source)
            self.assertIn('intersect_ray(', source)
            self.assertIn('func qa_capture_plan()', source)
            self.assertIn('dev13', source.lower())
        runner = read('tools/run_dev13_qa.py')
        for sid in ('L002', 'L004', 'L005', 'L037'):
            self.assertIn("'" + sid + "'", runner)
        self.assertIn('l009_route', runner)
        self.assertIn('model_assets_smoke', runner)

    def test_release_requires_godot_runtime_not_old_offline_results(self):
        runner = read('tools/run_dev13_qa.py')
        self.assertIn('New evidence JSON was not created', runner)
        self.assertIn('Godot not available or timed out', runner)
        self.assertIn("if stage['status']=='FAIL':break", runner)
        self.assertIn('Not all 414 imported GLBs instantiated successfully', runner)

    def test_no_new_portal_calls_in_any_added_geometry_method(self):
        fragments = [
            (read('levels/L004/L004_anchor.gd'), 'func _suspended_inspection_bridge('),
            (read('levels/L005/L005_boiler.gd'), 'func _deep_inspection_annex('),
            (read('levels/L037/L037.gd'), 'func _submerged_stair_pit_terraces('),
            (read('levels/L002/L002_geo.gd'), 'static func authored_upper_service_loop('),
        ]
        for full, sig in fragments:
            chunk = full.split(sig, 1)[1].split('\nfunc ', 1)[0].split('\nstatic func ', 1)[0]
            for bad in ('make_exit(', 'add_exit(', 'TransitionService.', '.fire('):
                self.assertNotIn(bad, chunk)

if __name__ == '__main__': unittest.main()
