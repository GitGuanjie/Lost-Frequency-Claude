"""DEV14 design-graph integrity and source constraints (NOT engine physics evidence)."""
from __future__ import annotations
import hashlib
import json
import math
import unittest
from pathlib import Path
from tools.preflight_dev import string_and_delimiter_check
ROOT = Path(__file__).resolve().parents[2]
DOC = json.loads((ROOT/'data/vertical_routes_dev14.json').read_text(encoding='utf8'))


def source(rel):
    return (ROOT/rel).read_text(encoding='utf8')


class Dev14VerticalMegastructures(unittest.TestCase):
    def test_all_four_level_designs_present_and_roster_still_fixed(self):
        self.assertEqual(set(DOC['levels']), {'L000','L001','L009','L011'})
        self.assertEqual(len(json.loads(source('data/canon/levels.json'))['levels']), 100)
        self.assertIn('NOT proof', DOC['provenance'])
        self.assertEqual(DOC['version'], '1.5.0-dev14')

    def test_graph_connected_per_level_with_genuine_rises_and_cycles(self):
        for sid, data in DOC['levels'].items():
            nodes = data['nodes']
            self.assertEqual(data['metrics']['nodes'],len(nodes),sid)
            graph = {name:set() for name in nodes}
            for a,b,kind,width in data['edges']:
                self.assertIn(a,nodes,sid)
                self.assertIn(b,nodes,sid)
                self.assertGreaterEqual(width,1.5,sid)
                self.assertIn(kind,('stair','deck','bridge'))
                pa,pb=nodes[a],nodes[b]
                self.assertTrue(all(math.isfinite(v) for v in (*pa,*pb)))
                hor=math.hypot(pa[0]-pb[0],pa[2]-pb[2]); rise=abs(pa[1]-pb[1])
                self.assertGreater(hor,.1,sid)
                if kind=='stair':
                    self.assertGreater(rise,1,sid)
                    self.assertLessEqual(rise/hor,.81,sid)
                else:
                    self.assertLess(rise,.001,sid)
                graph[a].add(b);graph[b].add(a)
            todo=[next(iter(nodes))]; seen=set(todo)
            while todo:
                for nxt in graph[todo.pop()]-seen:
                    seen.add(nxt);todo.append(nxt)
            self.assertEqual(seen,set(nodes),sid)
            cycle_rank=len(data['edges'])-len(nodes)+1
            self.assertGreaterEqual(cycle_rank,1,sid)
            self.assertEqual(data['metrics']['cycle_rank'],cycle_rank)
            self.assertGreaterEqual(data['metrics']['vertical_span_m'],6,sid)
            self.assertGreaterEqual(data['metrics']['stair_links'],2,sid)
        self.assertGreaterEqual(DOC['levels']['L000']['metrics']['vertical_span_m'],12)
        self.assertGreaterEqual(DOC['levels']['L000']['metrics']['cycle_rank'],3)

    def test_levels_have_real_collision_structures_and_access_holes(self):
        expected = {
            'L000':('_high_atrium_gallery','fifth_stratum','k.stairs(','k.slab(','bridge_lo','slot0','slot1'),
            'L001':('_maintenance_upper_deck','upper := 6.50','k.stairs(','k.slab(','upper landing','[55.0, 25.2'),
            'L009':('_night_garage_roof','y := 10.20','k.stairs(','k.slab(','roof slab over the ascent','Cantilever observation balcony'),
            'L011':('_skywalk_fourth','base_y + 3.4','k.stairs(','k.slab(','Opposite wings','two truly'),
        }
        for sid,needles in expected.items():
            src=source(f'levels/{sid}/{sid}.gd')
            block=src.split(f'func {needles[0]}(',1)[1].split('\nfunc ',1)[0]
            for n in needles[1:]:
                # Several architectural comments live in the callsite, not helper.
                self.assertIn(n,src,(sid,n))
            self.assertIn('k.stairs(',block,sid)
            self.assertIn('k.slab(',block,sid)
            self.assertNotIn('make_exit(',block,sid)
            self.assertNotIn('add_exit(',block,sid)
            self.assertNotIn('player.global_position =',block,sid)

    def test_old_canon_exit_declarations_identical(self):
        self.assertEqual(hashlib.sha256((ROOT/'data/canon/levels.json').read_bytes()).hexdigest(), DOC['canon_roster_sha256'])
        self.assertEqual(hashlib.sha256((ROOT/'data/canon/transitions.json').read_bytes()).hexdigest(), DOC['cross_level_transitions_sha256'])
        for sid,digest in DOC['level_manifest_sha256'].items():
            self.assertEqual(hashlib.sha256((ROOT/f'levels/{sid}/level.json').read_bytes()).hexdigest(),digest)

    def test_gd_lexical_integrity(self):
        problems=[]
        for rel in ('levels/L000/L000.gd','levels/L001/L001.gd','levels/L009/L009.gd',
                    'levels/L011/L011.gd','tests/qa_runner.gd','tests/model_asset_smoke_dev14.gd'):
            problems.extend(string_and_delimiter_check(source(rel),rel))
        self.assertEqual(problems,[])

    def test_engine_suite_checks_actual_physics_without_bypassing_story(self):
        qa=source('tests/qa_runner.gd')
        block=qa.split('func _vertical_dev14_suite()',1)[1].split('\nfunc ',1)[0]
        self.assertIn('direct_space_state',block)
        self.assertIn('_dev14_surface(',block)
        for sid in ('L000','L001','L009','L011'):
            self.assertIn(f'"{sid}"',block)
        self.assertNotIn('qa_prog +=',block)
        self.assertNotIn('.fire(',block)
        self.assertNotIn('progress =',block)
        runner=source('tools/run_dev14_qa.py')
        self.assertIn("'vertical_dev14'",runner)
        self.assertIn('Incomplete dev14 collision evidence',runner)
        self.assertIn('Not all 414 imported GLBs',runner)
        self.assertIn('if report and report.exists():report.unlink()',runner)
        self.assertIn('Missing QA suite',runner)
        self.assertIn("if stage['status']=='FAIL':break",runner)

    def test_dev14_export_remains_fail_closed(self):
        exporter=source('EXPORT_DEV14_WINDOWS.ps1')
        self.assertIn("$summary.status -ne 'PASS'",exporter)
        self.assertIn('--export-debug',exporter)
        self.assertIn('STILL REQUIRES launch/physics/nav/FPS/visual review on actual Windows hardware.',exporter)
        self.assertIn('v150_dev14/batch_summary.json',exporter)
        self.assertIn('tools/run_dev14_qa.py',exporter)

if __name__=='__main__': unittest.main()
