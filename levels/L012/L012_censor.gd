extends CanvasLayer
## Level 12 "censors itself" (SOURCE, Description): attempts to record or
## photograph it give a simple white image or a mass of noise and TV static;
## footage uploaded to another device turns into a colourless SMPTE test
## screen; filenames and other data attached to the footage are censored too.
## In a found-footage game the player's view IS the recording, so this layer
## is the level's defining system:
##  - intermittent white-outs and static bursts whose rate, length and base
##    level grow with distance from the table and chair (the expedition log:
##    things break down further from them) and with memory fog;
##  - colour drains from the feed with the same breakdown;
##  - the camcorder REC overlay keeps blinking but its time and label are
##    censored (data attached to footage);
##  - the screenshot key ("upload") stores a colourless SMPTE frame under a
##    censored file name instead of the view.
## ADAPTATION: censorship is graded and intermittent; a permanent white image
## would be unplayable. Reduce-motion softens every flash.

const SHADER := """
shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float white_amt = 0.0;
uniform float noise_amt = 0.0;
uniform float band_amt = 0.0;
uniform float bars_amt = 0.0;
uniform float haze_amt = 0.0;
uniform float desat_amt = 0.0;
uniform float seed = 0.0;

float h12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float pick7(int i, vec4 a, vec3 b) {
	if (i < 4) { return a[i]; }
	return b[min(i - 4, 2)];
}

// SMPTE colour bars rendered as luminance only ("lacking any color").
float smpte(vec2 uv) {
	int i = clamp(int(floor(uv.x * 7.0)), 0, 6);
	if (uv.y < 0.67) { return pick7(i, vec4(0.75, 0.665, 0.526, 0.44), vec3(0.31, 0.224, 0.086)); }
	if (uv.y < 0.75) { return pick7(i, vec4(0.086, 0.075, 0.31, 0.075), vec3(0.526, 0.075, 0.75)); }
	float x = uv.x * 28.0;
	if (x < 5.0) { return 0.16; }
	if (x < 10.0) { return 1.0; }
	if (x < 15.0) { return 0.12; }
	if (x < 20.0) { return 0.075; }
	if (x < 21.33) { return 0.035; }
	if (x < 22.67) { return 0.075; }
	if (x < 24.0) { return 0.115; }
	return 0.075;
}

void fragment() {
	vec2 uv = SCREEN_UV;
	float rowh = h12(vec2(floor(uv.y * 72.0), floor(TIME * 18.0) + seed));
	float tear = step(1.0 - band_amt * 0.8, rowh);
	uv.x += (rowh - 0.5) * 0.06 * tear * band_amt;
	vec3 c = textureLod(screen_tex, uv, haze_amt * 2.2).rgb;
	float lum = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(c, vec3(lum), desat_amt);
	c = mix(c, vec3(0.95), haze_amt * 0.35);
	float f = floor(TIME * 30.0);
	float n = h12(floor(SCREEN_UV * vec2(400.0, 225.0)) + vec2(f * 1.7, f * 9.3));
	c = mix(c, vec3(n * 0.9 + 0.05), clamp(noise_amt + tear * band_amt * 0.85, 0.0, 1.0));
	c = mix(c, vec3(0.97), white_amt);
	c = mix(c, vec3(smpte(SCREEN_UV)), bars_amt);
	COLOR = vec4(c, 1.0);
}
"""

var mat: ShaderMaterial
var rect: ColorRect
var rng := RandomNumberGenerator.new()
var level_c := 0.0          # breakdown 0..1 at the player's position
var fog := 0.0
var white := 0.0
var static_amt := 0.0
var events := {"white": 0, "static": 0}
var capture_style: Dictionary = {}   # fixed look for evidence stills
var static_player: AudioStreamPlayer
var _ev_kind := ""
var _ev_t := 0.0
var _ev_len := 0.0
var _next := 9.0
var _bars_t := 0.0


func setup(seed_value: int) -> void:
	layer = 40
	rng.seed = seed_value
	var sh := Shader.new()
	sh.code = SHADER
	mat = ShaderMaterial.new()
	mat.shader = sh
	rect = ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.material = mat
	add_child(rect)
	static_player = AudioStreamPlayer.new()
	static_player.stream = AudioSynth.get_stream("static", {"seconds": 3.0})
	static_player.volume_db = -70.0
	static_player.bus = "Ambience"
	static_player.autoplay = true
	add_child(static_player)


## Breakdown level from distance to the table/chair and memory fog.
static func censor_level(dist: float, fog_v: float) -> float:
	return clampf(clampf((dist - 3.0) / 110.0, 0.0, 1.0) * 0.85 + fog_v * 0.25 + 0.03, 0.0, 1.0)


## Advance the scheduler. Returns a caption for a notable event (or "").
func tick(delta: float, c: float, fog_v: float) -> String:
	level_c = c
	fog = fog_v
	var soft: bool = Settings.get_value("reduce_motion")
	var caption := ""
	_bars_t = maxf(0.0, _bars_t - delta)
	if capture_style.is_empty():
		_next -= delta
		if _next <= 0.0:
			caption = trigger_event()
		if _ev_t > 0.0:
			_ev_t -= delta
		var ev := 0.0
		if _ev_t > 0.0:
			var ph := 1.0 - _ev_t / maxf(_ev_len, 0.01)
			ev = 1.0 if not soft else sin(ph * PI)
		white = ev * (1.0 if _ev_kind == "white" else 0.0) * (0.55 if soft else 1.0)
		static_amt = ev * (1.0 if _ev_kind == "static" else 0.0)
		_apply(white, c * 0.16 + static_amt * (0.35 if soft else 0.7), c * 0.28 + static_amt * 0.6, c * 0.8, fog * 0.6)
	else:
		_apply(capture_style.get("white", 0.0), capture_style.get("noise", 0.0), capture_style.get("band", 0.0),
			capture_style.get("desat", 0.0), capture_style.get("haze", 0.0))
	var lin := clampf(c * 0.25 + static_amt * 0.9, 0.0005, 1.0)
	static_player.volume_db = lerpf(static_player.volume_db, linear_to_db(lin) - 10.0, clampf(delta * 6.0, 0.0, 1.0))
	return caption


func trigger_event() -> String:
	var c := level_c
	_next = lerpf(50.0, 5.0, c) * rng.randf_range(0.6, 1.5)
	_ev_kind = "white" if rng.randf() < 0.45 + 0.35 * c else "static"
	_ev_len = (lerpf(0.06, 0.9, c) if _ev_kind == "white" else lerpf(0.25, 2.2, c)) * rng.randf_range(0.6, 1.4)
	_ev_t = _ev_len
	events[_ev_kind] += 1
	if _ev_len > 0.45:
		return "[the picture whites out]" if _ev_kind == "white" else "[static]"
	return ""


## Brief full white-out (used when a copycat door returns you).
func flash(seconds: float) -> void:
	_ev_kind = "white"
	_ev_len = seconds
	_ev_t = seconds


func _apply(w: float, noise: float, band: float, desat: float, haze: float) -> void:
	var bars := 1.0 if _bars_t > 0.0 else 0.0
	mat.set_shader_parameter("white_amt", clampf(w, 0.0, 1.0))
	mat.set_shader_parameter("noise_amt", clampf(noise, 0.0, 1.0))
	mat.set_shader_parameter("band_amt", clampf(band, 0.0, 1.0))
	mat.set_shader_parameter("desat_amt", clampf(desat, 0.0, 1.0))
	mat.set_shader_parameter("haze_amt", clampf(haze, 0.0, 1.0))
	mat.set_shader_parameter("bars_amt", bars)
	mat.set_shader_parameter("seed", float(events["white"] + events["static"]))
	rect.visible = SessionState.in_gameplay and (w + noise + band + desat + haze + bars) > 0.004


## The REC overlay's timestamp and label are data attached to the footage.
func censor_rec(t_ms: int) -> void:
	var l: Label = Overlay.rec_label
	if l == null or l.text == "":
		return
	var blink := "●" if int(t_ms / 600) % 2 == 0 else "  "
	l.text = "%s REC   ██:██:██   ████████ ██" % blink


## Luminance-only SMPTE frame, the form Level 12 footage takes once uploaded.
static func smpte_image(w: int, h: int) -> Image:
	var img := Image.create(w, h, false, Image.FORMAT_RGB8)
	var top := [0.75, 0.665, 0.526, 0.44, 0.31, 0.224, 0.086]
	var mid := [0.086, 0.075, 0.31, 0.075, 0.526, 0.075, 0.75]
	var y0 := int(h * 0.67)
	var y1 := int(h * 0.75)
	for i in 7:
		var x0 := int(w * i / 7.0)
		var x1 := int(w * (i + 1) / 7.0)
		img.fill_rect(Rect2i(x0, 0, x1 - x0, y0), Color(top[i], top[i], top[i]))
		img.fill_rect(Rect2i(x0, y0, x1 - x0, y1 - y0), Color(mid[i], mid[i], mid[i]))
	var cuts := [[0.0, 5.0, 0.16], [5.0, 10.0, 1.0], [10.0, 15.0, 0.12], [15.0, 20.0, 0.075],
		[20.0, 21.33, 0.035], [21.33, 22.67, 0.075], [22.67, 24.0, 0.115], [24.0, 28.0, 0.075]]
	for cdef in cuts:
		var a := int(w * cdef[0] / 28.0)
		var b := int(w * cdef[1] / 28.0)
		var v: float = cdef[2]
		img.fill_rect(Rect2i(a, y1, b - a, h - y1), Color(v, v, v))
	return img


## Screenshot key: show the test screen and save it under a censored name.
func censored_screenshot(dry_run := false) -> Dictionary:
	_bars_t = 1.1
	var img := smpte_image(1280, 720)
	var dir := "user://screenshots"
	var n := 8
	var path := ""
	while true:
		path = "%s/LF_%s.png" % [dir, "█".repeat(n)]
		if dry_run or not FileAccess.file_exists(path):
			break
		n += 1
	if not dry_run:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
		img.save_png(path)
		Overlay.toast("Screenshot saved: %s.png" % "█".repeat(n + 3), 3.0)
	return {"path": path, "image": img}
