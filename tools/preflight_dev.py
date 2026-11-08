#!/usr/bin/env python3
"""Very conservative source preflight; not a GDScript compiler or engine QA."""
from __future__ import annotations
import json
import re
import sys
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
LEVELS=('L036','L060','L075','L999')


def string_and_delimiter_check(source: str, name: str):
    """Basic GDScript source lexer: single, double and triple-quoted literals.

    Ignores punctuation in comments/shader strings. This does NOT compile GDScript.
    """
    stack = []
    problems = []
    i = 0
    line = 1
    n = len(source)
    while i < n:
        ch = source[i]
        if ch == '#':
            while i < n and source[i] != '\n':
                i += 1
            continue
        if ch in ('"', "'"):
            quote = ch
            triple = source.startswith(ch * 3, i)
            start = line
            i += 3 if triple else 1
            closed = False
            while i < n:
                if source[i] == '\\':
                    # Escaped character, even when the escape is a quote.
                    if i + 1 < n and source[i + 1] == '\n':
                        line += 1
                    i += 2
                    continue
                if triple and source.startswith(quote * 3, i):
                    i += 3
                    closed = True
                    break
                if not triple and source[i] == quote:
                    i += 1
                    closed = True
                    break
                if source[i] == '\n':
                    if not triple:
                        problems.append(f'{name}:{line}: a normal quoted string crosses a newline')
                        # Do not let one broken single-line string suppress the remainder.
                        break
                    line += 1
                i += 1
            if not closed:
                if i >= n:
                    problems.append(f'{name}:{start}: unclosed string')
            continue
        if ch == '\n':
            line += 1
        if ch in '([{':
            stack.append((ch, line))
        elif ch in ')]}':
            opening = {')': '(', ']': '[', '}': '{'}[ch]
            if not stack or stack[-1][0] != opening:
                problems.append(f'{name}:{line}: unmatched {ch}')
            else:
                stack.pop()
        i += 1
    for op, ln in stack:
        problems.append(f'{name}:{ln}: unclosed {op}')
    return problems


def main():
    failures=[]
    for rel in ['ui/WorldGraph.gd','ui/Overlay.gd','autoload/TransitionService.gd','autoload/SaveService.gd', 'tests/qa_runner.gd'] + [f'levels/{sid}/{sid}.gd' for sid in LEVELS]:
        path=ROOT/rel
        failures.extend(string_and_delimiter_check(path.read_text(encoding='utf-8'), rel))
    for sid in LEVELS:
        m=json.loads((ROOT/f'levels/{sid}/level.json').read_text(encoding='utf-8'))
        if m.get('status')!='IN_DEVELOPMENT':
            failures.append(f'{sid}: status must stay IN_DEVELOPMENT until engine passes')
        if not (ROOT/m['scene'].removeprefix('res://')).exists():
            failures.append(f'{sid}: scene not found')
    print(f'GDScript lexical sanity files: {5+len(LEVELS)}; candidate levels: {len(LEVELS)}')
    for f in failures: print('FAIL',f)
    print(f'Failures: {len(failures)}; ENGINE AND EXPORT NOT RUN')
    return 1 if failures else 0

if __name__=='__main__':sys.exit(main())
