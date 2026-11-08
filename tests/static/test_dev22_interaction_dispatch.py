"""Regression audit of long-standing zero-argument Godot E interaction actions."""
import re, unittest
from pathlib import Path
from tools.preflight_dev import string_and_delimiter_check
ROOT=Path(__file__).resolve().parents[2]

class TestDev22InteractableDispatch(unittest.TestCase):
 def test_01_legacy_zero_argument_actions_are_real(self):
  # Count observed problem sites rather than assuming legacy callers were typed.
  lines=[line for p in (ROOT/'levels').rglob('*.gd') for line in p.read_text().splitlines()
         if 'add_interactable(' in line and 'func()' in line]
  self.assertGreaterEqual(len(lines),50)
 def test_02_count_and_bound_aware_dispatch(self):
  text=(ROOT/'core/interaction/Interactable.gd').read_text()
  self.assertIn('action.get_argument_count()',text)
  self.assertIn('if remaining == 0:',text)
  self.assertIn('action.call()',text)
  self.assertIn('elif remaining == 1:',text)
  self.assertIn('action.call(p)',text)
  self.assertIn('push_error(',text)
  self.assertNotIn('if action.is_valid():\n\t\taction.call(p)',text)
 def test_03_new_generated_callbacks_retain_player_argument(self):
  st=(ROOT/'core/world/NarrativeDistrictState.gd').read_text()
  for sig in ('activate_signal(_p: Player, tier: int)',
              'toggle_ambient(_p: Player, tier: int)',
              'investigate(_p: Player, index: int)',
              'toggle_gate(_p: Player)'):
   self.assertIn(sig,st)
  proc=(ROOT/'core/world/NarrativeDistrict.gd').read_text()
  self.assertIn('Callable(state,"activate_signal").bind(tier)',proc)
 def test_04_no_lexical_error(self):
  src=(ROOT/'core/interaction/Interactable.gd').read_text()
  self.assertEqual(string_and_delimiter_check(src,'Interactable.gd'),[])

if __name__=='__main__': unittest.main()
