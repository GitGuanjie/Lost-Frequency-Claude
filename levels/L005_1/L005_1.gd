extends LevelBase
## Level 5.1 — "GRAND OPENING OF THE TERROR HOTEL CASINO" (Backrooms Wikidot
## rev 44, accessed 2026-11-04; cite: Natedagreat563, CC BY-SA 3.0).
## Dossier: docs/canon/levels/L005_1.md.
## Content note: the page describes a man's body changed into casino parts (a
## billiard-ball eye, pool-stick limbs) and a gambling-addiction theme. Shown
## only as a stylised staff figure; nothing graphic.
##
## PLAN (v2.0 rebuild)
## SOURCE: a large Vegas-style casino inside Level 5, owned by Entity 18 (the
## Beast, "Mr. Gentleman"), entered and left only by its front doors; "TH" in
## large red letters; roulettes, cards, dice, slots; chips bartered at the front
## desk, four confirmed colours (red $1, blue $5, yellow $10, green $20; purple
## $50 only rumoured), winnings paid in chips, traded for goods when leaving
## (value table); dim lights that flash periodically, constant game noise,
## blaring music, chips clinking, air-conditioner breeze, classy new carpet;
## the bar run by The Barkeep (strong drinks, a large food menu); staff partly
## human with casino parts (Louie Sulphur the manager: pool-stick arms, a
## billiard-ball eye; Peg-Leg the welcomer; Sir Billiard the card dealer); the
## Beast challenges lucky winners to a card game: riches if you win, a staff job
## if you lose, and he has never lost; open 16 hours, closed 8. The grand
## opening (Comedian heckled off stage and put on chip duty, a free drink for
## everyone) is TESTIMONY from the audio log.
## Space: the hotel's own material language (damask, walnut, gilt, marble,
## crystal), then the casino: an entrance lobby (front desk, cashier's cage,
## the TH over the arch), a sunk gaming floor (-0.6 m) ringed by a promenade,
## slot banks to the west, roulette/card/dice tables to the east, the Beast's
## round table raised on a dais (+0.6 m), a stage with velvet curtains, and an
## east mezzanine (+4.2 m) with the bar and lounge reached by a grand stair.
## Signature mechanic (stateful): the chip economy. Barter for chips, play
## (slots 1 red, roulette and dice $5, cards $10), get paid in chips, trade them
## for the page's goods at the cage, eat and drink at the bar. A jackpot draws
## the Beast's wager; accept it and the house wins (you join the staff). The
## lights flash on a cycle; the casino closes for 8 of every 24 compressed hours.

const Hall := preload("res://levels/L005_1/L005_1_hall.gd")
const VAL := {"chip_red": 1, "chip_blue": 5, "chip_yellow": 10, "chip_green": 20}
const ORDER := ["chip_green", "chip_yellow", "chip_blue", "chip_red"]
const TRADES := [["almond_water", "a bottle of Almond Water", 2], ["deuclidators", "a box of Deuclidators", 5],
	["memory_jar", "a Memory Jar", 4], ["activated_charcoal", "a gram of Activated Charcoal", 30], ["scaraback", "a Scaraback", 6],
	["royal_rations", "a quarter pound of Royal Rations", 20], ["babel_balm", "a capsule of Babel Balm", 40], ["maidens_ink", "a bottle of Maiden's Ink", 80]]
const LOUIE_PATH := [Vector3(-6.0, -0.6, 19.0), Vector3(-6.0, -0.6, 54.0), Vector3(4.0, -0.6, 54.0), Vector3(4.0, -0.6, 19.0)]
const CYCLE := 24.0 * 60.0      # one compressed day: 1 hour = 1 minute
const OPEN_FOR := 16.0 * 60.0

var hall
var qa_fixture := false
var plays := 0
var since_jackpot := 0
var invited := false
var wager_done := false
var pocket_bartered := false
var free_drink := true
var clock := 0.0
var is_open := true
var _flash_t := 12.0
var _flash := 0.0
var _base_energy: Array = []
var _louie: Node3D
var _louie_i := 0
var _music: AudioStreamPlayer
var _crowd: AudioStreamPlayer
var _closed_said := false


func build() -> void:
	qa_fixture = SessionState.is_qa()
	rules["view_distance"] = 160.0
	rules["reverb_room"] = 0.62
	rules["reverb_wet"] = 0.22
	rules["flashlight"] = "allowed"
	indoor_env(Color(0.55, 0.34, 0.26), 0.36, Color(0.16, 0.07, 0.05), 0.006)
	environment.tonemap_exposure = 1.25
	environment.glow_intensity = 0.65
	environment.glow_hdr_threshold = 0.85
	environment.glow_bloom = 0.08
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 1.08
	Hall.materials()
	Hall.chip_materials()
	hall = Hall.new(self)
	lights.setup(14, 1)
	lights.max_distance = 40.0
	var k := kit("Casino")
	hall.shell(k)
	hall.lobby(k)
	var r := RandomNumberGenerator.new()
	r.seed = level_seed
	hall.slots(k, r)
	hall.table_games(k)
	hall.hall_dress(k)
	k.commit()
	_lights()
	_staff()
	_interactions()
	_sounds()
	clock = float(rng.randi_range(0, 9)) * 60.0
	add_arrival("start", Vector3(0.0, 0.02, 3.0), 180.0)
	add_arrival("from_L005", Vector3(0.0, 0.02, 3.0), 180.0)
	add_exit("L005_1>L005#1", "interact", Vector3(0.0, 1.4, 1.0), Vector3(3.4, 2.8, 1.6), "Leave through the front doors")
	add_landmark("Front desk and cashier's cage", Vector3(0, 0, 5))
	add_landmark("Gaming floor", Vector3(0, -0.6, 36))
	add_landmark("Mr. Gentleman's table", Vector3(-2, 0.6, 37))
	add_landmark("Mezzanine bar", Vector3(27, 4.2, 33))
	add_shot("casino_floor", Vector3(1.5, 1.62, 15.4), Vector3(-4.0, 0.6, 46.0), {"flashlight": false})
	add_shot("lobby_th", Vector3(0.6, 1.6, 1.9), Vector3(0.0, 3.6, 12.0), {"flashlight": false})
	add_shot("slot_banks", Vector3(-12.8, -0.6 + 1.62, 17.6), Vector3(-17.5, 0.4, 40.0), {"flashlight": false})
	add_shot("mezzanine_bar", Vector3(24.2, 4.2 + 1.62, 17.0), Vector3(28.2, 4.6, 38.0), {"flashlight": false})


func _lights() -> void:
	var warm := Color(1.0, 0.74, 0.46)
	for p in [Vector3(-15.0, 4.8, 25.0), Vector3(-15.0, 4.8, 49.0), Vector3(2.0, 4.8, 25.0), Vector3(12.0, 4.8, 34.0), Vector3(12.0, 4.8, 50.0)]:
		lights.add_anchor(p, warm, 1.6, 13.0)
	lights.add_anchor(Vector3(-2.0, 3.6, 37.0), Color(1.0, 0.82, 0.6), 2.6, 7.0)
	lights.add_anchor(Vector3(0.0, 4.2, 6.0), warm, 1.8, 9.0)
	lights.add_anchor(Vector3(0.0, 5.5, 57.0), Color(1.0, 0.85, 0.7), 2.4, 9.0)
	lights.add_anchor(Vector3(28.6, 6.0, 33.0), Color(1.0, 0.62, 0.3), 1.6, 8.0)
	lights.add_anchor(Vector3(26.0, 6.2, 50.0), warm, 1.2, 7.0)
	for z in [20.0, 34.0, 50.0]:
		lights.add_anchor(Vector3(29.0, 2.6, z), warm, 0.6, 4.0)
	lights.add_anchor(Vector3(0.0, 5.6, 13.2), Color(1.0, 0.1, 0.06), 1.2, 7.0)
	for a in lights.anchors:
		_base_energy.append(float(a["energy"]))


func _staff() -> void:
	hall.figure(Vector3(6.8, 0.0, 6.3), 0.0, "comedian")
	hall.figure(Vector3(-6.6, 0.0, 6.4), 0.0, "cashier")
	hall.figure(Vector3(-3.6, 0.0, 10.4), 200.0, "pegleg")
	hall.figure(Vector3(29.0, 4.2, 33.0), 90.0, "barkeep")
	hall.figure(Vector3(16.0, -0.6, 44.6), 180.0, "billy")
	_louie = hall.figure(LOUIE_PATH[0], 180.0, "louie")
	var it := make_interactable(Vector3(0, 1.1, 0), Vector3(0.9, 2.0, 0.9), "Take a drink from Louie's tray", _louie_drink, _louie)
	it.name = "LouieTray"


# ------------------------------------------------------------------ chips

func wallet() -> int:
	var v := 0
	for c in ORDER:
		v += SaveService.item_count(c) * int(VAL[c])
	return v


func _set_value(v: int) -> void:
	for c in ORDER:
		SaveService.add_item(c, -SaveService.item_count(c))
	for c in ORDER:
		var n := v / int(VAL[c])
		if n > 0:
			SaveService.add_item(c, n)
			v -= n * int(VAL[c])


func _pay(cost: int) -> bool:
	var v := wallet()
	if v < cost:
		return false
	_set_value(v - cost)
	return true


func _gain(v: int) -> void:
	_set_value(wallet() + v)


func chips_text() -> String:
	var parts: Array = []
	for c in ["chip_red", "chip_blue", "chip_yellow", "chip_green"]:
		var n := SaveService.item_count(c)
		if n > 0:
			parts.append("%d %s" % [n, c.substr(5)])
	return "no chips" if parts.is_empty() else ", ".join(parts)


func _barter() -> void:
	if not _check_open():
		return
	if SaveService.item_count("almond_water") > 0:
		SaveService.add_item("almond_water", -1)
		SaveService.add_item("chip_red", 2)
		sound.play_at("knock", {"hits": 2}, Vector3(6.6, 1.2, 4.6), -14.0, "")
		Overlay.subtitle("[the desk takes a bottle of Almond Water and slides back two red chips. Chips: %s]" % chips_text(), 4.0)
	elif not pocket_bartered:
		pocket_bartered = true
		SaveService.add_item("chip_red", 5)
		Overlay.subtitle("[you empty your pockets; the clerk weighs each thing and pushes five red chips across. Chips: %s]" % chips_text(), 4.5)
	else:
		Overlay.subtitle("[you have nothing left the desk wants]", 3.0)


func _trade(i: int) -> void:
	var t: Array = TRADES[i]
	if not _pay(int(t[2])):
		Overlay.subtitle("[the cashier taps the price list. You need more chips]", 3.0)
		return
	SaveService.add_item(str(t[0]), 1)
	Overlay.subtitle("[you trade chips for %s. Chips: %s]" % [t[1], chips_text()], 4.0)


# ------------------------------------------------------------------ games

func _check_open() -> bool:
	if is_open:
		return true
	Overlay.subtitle("[the casino is closed. The machines are dark and nobody answers]", 3.0)
	return false


func _play(kind: String) -> void:
	if not _check_open():
		return
	var cost: int = {"slots": 1, "roulette": 5, "dice": 5, "cards": 10}[kind]
	if not _pay(cost):
		Overlay.subtitle("[you need chips: %s costs %d. Barter at the front desk]" % [kind, cost], 3.0)
		return
	plays += 1
	since_jackpot += 1
	var roll := rng.randf()
	var win := 0
	var line := ""
	match kind:
		"slots":
			var jackpot_p := 0.02 + maxf(0.0, float(since_jackpot - 12)) * 0.02
			if roll < jackpot_p:
				win = 60
				since_jackpot = 0
				line = "[bells, sirens, a cascade of chips: JACKPOT]"
			elif roll < jackpot_p + 0.09:
				win = 5
				line = "[three cherries; the tray rattles with chips]"
			elif roll < jackpot_p + 0.37:
				win = 2
				line = "[the reels stop on a small win]"
			else:
				line = "[the reels whir and stop on nothing]"
		"roulette":
			if roll < 0.47:
				win = 10
				line = "[the ball drops into your colour]"
			else:
				line = "[the ball rattles past your number]"
		"dice":
			if roll < 0.49:
				win = 10
				line = "[the dice come up your way]"
			else:
				line = "[snake eyes]"
		"cards":
			if roll < 0.44:
				win = 20
				line = "[Billy turns over your winning hand without a word]"
			else:
				line = "[the dealer shows twenty-one]"
	_gain(win)
	sound.play_at("music_box" if win > 0 else "ui", {"notes": [0, 4, 7, 12], "root": 880.0} if win > 0 else {"kind": "error"}, player.global_position + Vector3(0, 1, 0), -10.0, "")
	Overlay.subtitle("%s Chips: %s" % [line, chips_text()], 3.2)
	if win >= 60 and not invited and not wager_done:
		_invite()
	elif plays % 9 == 0:
		Overlay.toast("[one more. You were so close]", 2.5)


func _invite() -> void:
	invited = true
	Overlay.subtitle("[a cultured voice at your shoulder: \"Why don't we play a fun game of two-person blackjack?\" The raised table at the centre waits]", 7.0)
	Overlay.toast("Mr. Gentleman's table: winnings tripled if you win; a staff job if you lose.", 6.0)


func _beast_table() -> void:
	if wager_done:
		Overlay.subtitle("[the chair across is empty now. The tea has gone cold]", 3.0)
		return
	if not invited:
		Overlay.subtitle("[a 'reserved' card, a cup of tea still steaming, an empty high-backed chair. The Beast plays only lucky winners]", 4.5)
		return
	Overlay.confirm("Play two-person blackjack with Mr. Gentleman?\nWin: your winnings tripled. Lose: you work for the casino.\nOnce the deal is made, there is no going back.", _wager)


## The Beast has never lost a single game (SOURCE). The first hand is yours.
func _wager() -> void:
	wager_done = true
	_gain(30)
	Overlay.subtitle("[you win the first hand. \"Good job.\" He bets again]", 4.0)
	await get_tree().create_timer(4.5).timeout
	Overlay.subtitle("[a king and an ace. Then again. Then again. Your stack melts to nothing]", 4.5)
	await get_tree().create_timer(5.0).timeout
	Overlay.subtitle("[\"The house always wins.\" Hands that are not quite hands close on your shoulders]", 5.0)
	await get_tree().create_timer(4.0).timeout
	_set_value(0)
	if player and not qa_fixture:
		player.hurt(1000.0, "you lost to the Beast; the casino staff will see that you keep your end of the deal")


func _drink() -> void:
	if not _check_open():
		return
	if free_drink:
		free_drink = false
		Overlay.subtitle("[the Barkeep, slowly: \"What can I... get for you?\" The first drink is on the house tonight]", 4.5)
	elif not _pay(1):
		Overlay.subtitle("[\"One chip... or something... to barter\"]", 3.0)
		return
	else:
		Overlay.subtitle("[an unfamiliar brand, very strong and very pleasant. Chips: %s]" % chips_text(), 3.5)
	if player:
		player.heal(8.0)
	Overlay.glitch(0.15)


func _food() -> void:
	if not _check_open():
		return
	if not _pay(3):
		Overlay.subtitle("[the menu runs from macaroni and cheese to filet mignon. You need three chips]", 3.5)
		return
	if player:
		player.heal(30.0)
	Overlay.subtitle("[a plate arrives, far better than it should be. Chips: %s]" % chips_text(), 3.5)


func _louie_drink() -> void:
	Overlay.subtitle("[the manager offers his tray with a pool-stick arm. He cannot remember anything before his first day here]", 5.0)
	if player:
		player.heal(5.0)


func _interactions() -> void:
	add_interactable(Vector3(6.6, 1.3, 4.2), Vector3(3.8, 1.0, 0.8), "Barter for chips at the front desk", _barter)
	add_interactable(Vector3(0.0, 1.0, 4.0), Vector3(1.2, 0.6, 0.6), "Count your chips", func() -> void:
		Overlay.subtitle("[chips: %s (worth $%d)]" % [chips_text(), wallet()], 3.0))
	for i in TRADES.size():
		var t: Array = TRADES[i]
		add_interactable(Vector3(-8.25 + float(i) * 0.48, 1.35, 4.35), Vector3(0.44, 0.5, 0.5), "Trade %d chips' worth for %s" % [int(t[2]), t[1]], _trade.bind(i))
	for s in hall.slot_sites:
		add_interactable(s["pos"], s["size"], "Play a slot machine (1 red chip)", _play.bind("slots"))
	for t in hall.tables:
		match str(t["kind"]):
			"roulette":
				add_interactable(t["pos"], Vector3(2.8, 0.6, 1.6), "Play roulette ($5)", _play.bind("roulette"))
			"dice":
				add_interactable(t["pos"], Vector3(1.8, 0.6, 3.8), "Roll the dice ($5)", _play.bind("dice"))
			"cards":
				add_interactable(t["pos"], Vector3(2.4, 0.6, 2.4), "Play blackjack ($10)", _play.bind("cards"))
			"beast":
				add_interactable(t["pos"] + Vector3(0, 0.8, 0), Vector3(2.2, 0.6, 2.2), "Sit at Mr. Gentleman's table", _beast_table)
	add_interactable(Vector3(27.4, 4.2 + 1.0, 27.5), Vector3(0.7, 1.0, 11.0), "Order a drink from the Barkeep", _drink)
	add_interactable(Vector3(27.4, 4.2 + 1.0, 38.5), Vector3(0.7, 1.0, 11.0), "Order food at the bar (3 chips)", _food)
	add_interactable(Vector3(0.0, 1.6, 57.0), Vector3(0.6, 1.2, 0.6), "Step up to the microphone", func() -> void:
		sound.play_at("static", {"seconds": 0.8}, Vector3(0, 2, 57), -12.0, "")
		Overlay.subtitle("[feedback whines through the speakers. Somewhere out on the floor, somebody boos]", 4.0))
	add_note("l51_meg", "A folded M.E.G. leaflet",
		"THE TERROR HOTEL CASINO (Level 5.1)\n\nA large casino inside Level 5, owned by Entity 18. Chips are bartered at the front desk: red $1, blue $5, yellow $10, green $20. A $50 purple chip is only a story.\n\nWanderers say the games are rigged to keep you playing. That is unproven. They are, by every account, extraordinarily addictive.\n\nThe M.E.G. urges people to avoid the casino and its games if possible. If you must go in, guard your supplies.\n\nThe Beast offers lucky winners a card game: riches if you win, a staff job if you lose. He has never lost.\n\n(paraphrase of the Level 5.1 entry)",
		Vector3(-7.6, 0.45, 9.0))
	add_note("l51_prices", "Chip values, chalked on the cage board",
		"Almond Water: 2 red per bottle\nDeuclidators: 1 blue per box\nMemory Jars: 4 red per jar\nActivated Charcoal: 3 yellow per gram\nScarabacks: 6 red\nRoyal Rations: 1 green per quarter pound\nBabel Balm: 4 yellow per capsule\nMaiden's Ink: 4 green per bottle\n\n(the value table from the Level 5.1 entry)",
		Vector3(-5.0, 1.2, 4.75))


# ------------------------------------------------------------------ per frame

func level_process(delta: float) -> void:
	clock = fmod(clock + delta, CYCLE)
	var open_now := clock < OPEN_FOR
	if open_now != is_open:
		is_open = open_now
		Overlay.subtitle("[the lights come up and the machines wake: the casino is open]" if is_open else "[the music cuts out, the machines go dark: the casino is closed for the night]", 4.0)
	# the lights flash periodically
	_flash_t -= delta
	if _flash_t <= 0.0 and is_open:
		_flash_t = rng.randf_range(18.0, 34.0)
		_flash = 1.4
	var mul := 1.0 if is_open else 0.35
	if _flash > 0.0:
		_flash -= delta
		mul *= 1.0 + 0.9 * sin(_flash * 22.0)
	for i in mini(_base_energy.size(), lights.anchors.size()):
		lights.anchors[i]["energy"] = _base_energy[i] * maxf(mul, 0.05)
	var t := Time.get_ticks_msec() * 0.001
	(MatLib.get_mat("l51_bulbs") as StandardMaterial3D).emission_energy_multiplier = (2.2 + 1.4 * sin(t * 6.0)) * (1.0 if is_open else 0.0)
	(MatLib.get_mat("l51_slot_screen") as StandardMaterial3D).emission_energy_multiplier = (1.3 + 0.5 * sin(t * 3.1)) * (1.0 if is_open else 0.05)
	(MatLib.get_mat("l51_slot_screen_b") as StandardMaterial3D).emission_energy_multiplier = (1.3 + 0.5 * sin(t * 2.3 + 1.0)) * (1.0 if is_open else 0.05)
	(MatLib.get_mat("l51_slot_top") as StandardMaterial3D).emission_energy_multiplier = (0.9 + 0.6 * absf(sin(t * 4.0))) * (1.0 if is_open else 0.0)
	if _music:
		_music.volume_db = lerpf(_music.volume_db, -19.0 if is_open else -80.0, 0.05)
		_crowd.volume_db = lerpf(_crowd.volume_db, -24.0 if is_open else -80.0, 0.05)
	_walk_louie(delta)


func _walk_louie(delta: float) -> void:
	if _louie == null:
		return
	_louie.visible = is_open
	if not is_open or qa_fixture:
		return
	var target: Vector3 = LOUIE_PATH[_louie_i]
	var d := target - _louie.position
	d.y = 0.0
	if d.length() < 0.2:
		_louie_i = (_louie_i + 1) % LOUIE_PATH.size()
		return
	_louie.position += d.normalized() * minf(0.9 * delta, d.length())
	_louie.rotation.y = atan2(-d.x, -d.z)


func _sounds() -> void:
	_music = sound.bed("chiptune", {"bpm": 116.0, "scale": [0, 4, 7, 9, 12, 16], "root": 196.0}, -19.0, "Music")
	_crowd = sound.bed("room_tone", {"cutoff": 1100.0, "rumble": 0.15, "seconds": 6.0}, -24.0)
	sound.bed("wind", {"seconds": 9.0}, -40.0)
	sound.oneshot("music_box", {"notes": [0, 7, 12, 16], "root": 1046.0}, 4.0, 11.0, 10.0, "[a slot machine chimes and whirs]", -20.0)
	sound.oneshot("knock", {"hits": 4}, 6.0, 14.0, 10.0, "[plastic chips clink into a machine]", -22.0)
	sound.oneshot("static", {"seconds": 1.2}, 25.0, 50.0, 14.0, "[cheering and jeering somewhere across the floor]", -24.0)


func on_player_ready() -> void:
	if not qa_fixture:
		Overlay.toast("Content note: this page describes a man's body changed into casino parts, and a gambling-addiction theme. Nothing graphic is shown.", 7.0)


# ------------------------------------------------------------------ QA

func _ray(a: Vector3, b: Vector3) -> Dictionary:
	return get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(a, b, 1))


func qa_self_test() -> Array:
	await get_tree().physics_frame
	var out: Array = []
	var floor_hit := _ray(Vector3(-6.0, 2.0, 30.0), Vector3(-6.0, -3.0, 30.0))
	out.append({"what": "sunk gaming floor at -0.6 m", "ok": not floor_hit.is_empty() and absf(floor_hit["position"].y + 0.6) < 0.05, "detail": floor_hit.get("position")})
	var mez := _ray(Vector3(25.0, 7.0, 30.0), Vector3(25.0, 2.0, 30.0))
	out.append({"what": "mezzanine floor at +4.2 m", "ok": not mez.is_empty() and absf(mez["position"].y - 4.2) < 0.05, "detail": mez.get("position")})
	var st := _ray(Vector3(18.0, 6.0, 13.6), Vector3(18.0, -1.0, 13.6))
	out.append({"what": "grand stair ramp collision", "ok": not st.is_empty() and st["position"].y > 1.5 and st["position"].y < 3.6, "detail": st.get("position")})
	var dais := _ray(Vector3(-0.5, 3.0, 38.5), Vector3(-0.5, -2.0, 38.5))
	out.append({"what": "Beast's dais at +0.6 m", "ok": not dais.is_empty() and absf(dais["position"].y - 0.6) < 0.05, "detail": dais.get("position")})
	# the chip economy: barter, pay, change-making, trade-in
	_set_value(0)
	var held := SaveService.item_count("almond_water")
	SaveService.add_item("almond_water", -held)
	is_open = true
	_barter()
	out.append({"what": "pocket barter gives five red chips", "ok": SaveService.item_count("chip_red") == 5 and wallet() == 5, "detail": chips_text()})
	SaveService.add_item("almond_water", 1)
	pocket_bartered = true
	_barter()
	out.append({"what": "a bottle of Almond Water barters for two red chips", "ok": wallet() == 7 and SaveService.item_count("almond_water") == 0})
	SaveService.add_item("almond_water", held)
	_set_value(5)
	_gain(20)
	out.append({"what": "change uses the four confirmed colours", "ok": SaveService.item_count("chip_green") == 1 and SaveService.item_count("chip_blue") == 1 and wallet() == 25, "detail": chips_text()})
	var aw := SaveService.item_count("almond_water")
	_trade(0)
	out.append({"what": "trade-in: 2 red for a bottle of Almond Water", "ok": SaveService.item_count("almond_water") == aw + 1 and wallet() == 23})
	SaveService.add_item("almond_water", -1)
	var before := wallet()
	_play("slots")
	out.append({"what": "a slot spin costs one red chip", "ok": wallet() >= before - 1 and plays == 1})
	_set_value(0)
	_play("cards")
	out.append({"what": "no chips, no game", "ok": plays == 1})
	out.append({"what": "no purple chip exists (rumour only)", "ok": not VAL.has("chip_purple")})
	out.append({"what": "only one exit: the front doors", "ok": exits.size() == 1})
	plays = 0
	return out
