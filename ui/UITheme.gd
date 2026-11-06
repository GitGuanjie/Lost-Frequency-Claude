class_name UITheme
extends RefCounted
## Code-built UI theme: warm off-white on near-black, high-contrast focus ring
## for keyboard/gamepad navigation, scalable text.

const ACCENT := Color(0.93, 0.80, 0.42)
const TEXT := Color(0.94, 0.92, 0.86)
const MUTED := Color(0.62, 0.60, 0.55)
const OK := Color(0.55, 0.85, 0.55)
const WARN := Color(0.95, 0.68, 0.30)
const LOCKED := Color(0.55, 0.53, 0.50)
const DANGER := Color(0.95, 0.42, 0.38)


static func box(bg: Color, border: Color = Color(0, 0, 0, 0), bw: int = 0, radius: int = 4, pad: int = 10) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(radius)
	s.content_margin_left = pad
	s.content_margin_right = pad
	s.content_margin_top = pad * 0.6
	s.content_margin_bottom = pad * 0.6
	return s


static func build(scale: float = 1.0) -> Theme:
	var t := Theme.new()
	var fs := int(round(18 * scale))
	t.default_font_size = fs
	t.set_color("font_color", "Label", TEXT)
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", Color(1, 1, 1))
	t.set_color("font_focus_color", "Button", Color(1, 1, 1))
	t.set_color("font_disabled_color", "Button", Color(0.45, 0.44, 0.40))
	t.set_stylebox("normal", "Button", box(Color(0.13, 0.12, 0.09, 0.95), Color(0.35, 0.32, 0.22), 1))
	t.set_stylebox("hover", "Button", box(Color(0.24, 0.21, 0.12, 0.98), ACCENT * Color(1, 1, 1, 0.7), 1))
	t.set_stylebox("pressed", "Button", box(Color(0.32, 0.27, 0.13, 1.0), ACCENT, 1))
	t.set_stylebox("focus", "Button", box(Color(0, 0, 0, 0), Color(1.0, 0.88, 0.35), 2))
	t.set_stylebox("disabled", "Button", box(Color(0.09, 0.09, 0.08, 0.9), Color(0.2, 0.2, 0.18), 1))
	t.set_stylebox("panel", "PanelContainer", box(Color(0.045, 0.043, 0.035, 0.94), Color(0.55, 0.49, 0.30, 0.6), 1, 6, 18))
	t.set_stylebox("panel", "Panel", box(Color(0.045, 0.043, 0.035, 0.94), Color(0.55, 0.49, 0.30, 0.6), 1, 6, 18))
	t.set_stylebox("normal", "LineEdit", box(Color(0.1, 0.1, 0.08), Color(0.4, 0.37, 0.26), 1))
	t.set_stylebox("focus", "LineEdit", box(Color(0, 0, 0, 0), Color(1.0, 0.88, 0.35), 2))
	t.set_color("font_color", "LineEdit", TEXT)
	t.set_stylebox("panel", "ItemList", box(Color(0.07, 0.07, 0.06, 0.95), Color(0.3, 0.28, 0.2), 1, 4, 6))
	t.set_stylebox("focus", "ItemList", box(Color(0, 0, 0, 0), Color(1.0, 0.88, 0.35), 2))
	t.set_stylebox("selected", "ItemList", box(Color(0.30, 0.26, 0.12), Color(0, 0, 0, 0), 0, 2, 2))
	t.set_stylebox("selected_focus", "ItemList", box(Color(0.38, 0.32, 0.12), Color(0, 0, 0, 0), 0, 2, 2))
	t.set_color("font_color", "ItemList", TEXT)
	t.set_color("font_color", "RichTextLabel", TEXT)
	t.set_color("default_color", "RichTextLabel", TEXT)
	t.set_stylebox("focus", "RichTextLabel", box(Color(0, 0, 0, 0), Color(1.0, 0.88, 0.35, 0.5), 1))
	t.set_color("font_color", "CheckBox", TEXT)
	t.set_color("font_color", "OptionButton", TEXT)
	t.set_stylebox("normal", "OptionButton", box(Color(0.13, 0.12, 0.09, 0.95), Color(0.35, 0.32, 0.22), 1))
	t.set_stylebox("focus", "OptionButton", box(Color(0, 0, 0, 0), Color(1.0, 0.88, 0.35), 2))
	t.set_stylebox("focus", "CheckBox", box(Color(0, 0, 0, 0), Color(1.0, 0.88, 0.35), 2))
	t.set_stylebox("focus", "HSlider", box(Color(0, 0, 0, 0), Color(1.0, 0.88, 0.35), 2))
	t.set_stylebox("panel", "TabContainer", box(Color(0.06, 0.06, 0.05, 0.95), Color(0.3, 0.28, 0.2), 1))
	t.set_stylebox("background", "ProgressBar", box(Color(0.1, 0.1, 0.08, 0.8), Color(0, 0, 0, 0), 0, 2, 0))
	t.set_stylebox("fill", "ProgressBar", box(ACCENT * Color(1, 1, 1, 0.9), Color(0, 0, 0, 0), 0, 2, 0))
	return t


static func label(text: String, size: int = 18, color: Color = TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


static func button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(320, 44)
	b.pressed.connect(cb)
	b.focus_mode = Control.FOCUS_ALL
	return b
