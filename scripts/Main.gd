## Main.gd
##
## Root of the game. Each screen is a Control built in code; switching
## screens frees the old one and adds the new. Story flow lives here too:
##   roster -> dialogue before -> loadout -> match -> result (XP, tips)
##        -> (win) dialogue after -> scene -> roster
##        -> (loss) rematch / shop
## Side content (pickup games, cups, the Pro Shop) also starts here.
extends Control

var host: Control
var current: Control


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	host = Control.new()
	host.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(host)
	if GameState.fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	var args := OS.get_cmdline_user_args()
	# Screenshot / debug entry points: -- screen=match id=mila
	var opts := {}
	for a in args:
		var kv := a.split("=")
		if kv.size() == 2:
			opts[kv[0]] = kv[1]
	if opts.has("speed"):
		var k := float(opts["speed"])
		Engine.physics_ticks_per_second = int(120 * k)
		Engine.max_physics_steps_per_frame = int(8 * k)
		Engine.time_scale = k
	if opts.has("shot"):
		_take_shot(String(opts["shot"]), float(opts.get("delay", "1.5")))
	if opts.has("screen"):
		_debug_open(opts)
		return
	if GameState.age_ok:
		show_menu()
	else:
		_show(AgeGateScreen.new(self))


## Android back button: acts like Esc (pause, back a screen).
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		var ev := InputEventAction.new()
		ev.action = "ui_cancel"
		ev.pressed = true
		Input.parse_input_event(ev)


func _show(screen: Control) -> void:
	if screen is MatchScreen:
		Music.play("match")
	elif screen is SceneViewer:
		Music.play("scene")
	else:
		Music.play("lounge")
	if current and is_instance_valid(current):
		current.queue_free()
	current = screen
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.add_child(screen)


func show_menu() -> void:
	_show(MenuScreen.new(self))


func show_roster() -> void:
	if not GameState.prologue_seen:
		_show(VNScreen.new(self, "mila", GameState.data.get("prologue", []), func():
			GameState.prologue_seen = true
			GameState.save()
			show_roster()))
		return
	_show(RosterScreen.new(self))


func show_gallery() -> void:
	_show(GalleryScreen.new(self))


func show_settings(back: Callable = Callable()) -> void:
	_show(SettingsScreen.new(self, back if back.is_valid() else show_menu))


func show_credits() -> void:
	_show(CreditsScreen.new(self))


func show_how_to_play() -> void:
	_show(HowToPlayScreen.new(self))


## Starts match `mi` of a heroine's story: her dialogue, then your
## loadout, then the match. A match you already won is a replay.
func start_story_match(id: String, mi: int) -> void:
	if GameState.wins(id) > mi:
		prematch(id, mi, {"mode": "replay"})
		return
	var m: Dictionary = GameState.heroine(id)["matches"][mi]
	_show(VNScreen.new(self, id, m.get("before", []), func(): prematch(id, mi, {"mode": "story"})))


## Loadout screen: pick power-ups, then play.
func prematch(id: String, mi: int, ctx: Dictionary) -> void:
	if GameState.powerup_slots() <= 0:
		play_match(id, mi, ctx)
		return
	_show(PreMatchScreen.new(self, id, mi, ctx))


func start_pickup(id: String) -> void:
	var ctx := {"mode": "pickup", "target": int(GameState.prog.get("pickup", {}).get("target", 5))}
	prematch(id, GameState.side_match_index(id, ctx), ctx)


## Plays the current round of the cup in progress.
func start_cup_round() -> void:
	var run := GameState.cup_run
	if run.is_empty():
		show_cups()
		return
	var c := GameState.cup(String(run["id"]))
	var r := int(run["round"])
	var id := String(run["opponents"][r])
	var boosts: Array = c.get("round_boost", [])
	var ctx := {"mode": "cup", "cup": String(run["id"]), "round": r, "target": int(c.get("target", 5)), "boost": float(boosts[mini(r, boosts.size() - 1)]) if not boosts.is_empty() else 0.0}
	prematch(id, GameState.side_match_index(id, ctx), ctx)


## The Last Call Championship: all four, back to back. A lost round is
## replayed; rounds already won stay won.
func start_finale() -> void:
	var f := GameState.finale()
	if GameState.finale_round <= 0 or GameState.finale_done:
		GameState.finale_round = 0
		_show(VNScreen.new(self, String(f["rounds"][0]["id"]), f.get("before", []), func(): finale_round()))
	else:
		finale_round()


func finale_round() -> void:
	var f := GameState.finale()
	var r := clampi(GameState.finale_round, 0, f["rounds"].size() - 1)
	var rd: Dictionary = f["rounds"][r]
	var id := String(rd["id"])
	var boosts: Array = f.get("boost", [0.0])
	var ctx := {"mode": "finale", "round": r, "target": int(f.get("target", 7)), "boost": float(boosts[mini(r, boosts.size() - 1)])}
	_show(VNScreen.new(self, id, rd.get("before", []), func(): prematch(id, GameState.side_match_index(id, ctx), ctx)))


func play_match(id: String, mi: int, ctx: Dictionary = {}) -> void:
	_show(MatchScreen.new(self, id, mi, ctx))


func show_shop(back: Callable = Callable()) -> void:
	_show(ShopScreen.new(self, back if back.is_valid() else show_roster))


func show_cups() -> void:
	_show(CupScreen.new(self))


## Quitting a match from the pause menu. A cup run ends there.
func forfeit(ctx: Dictionary) -> void:
	if String(ctx.get("mode", "")) == "cup":
		GameState.cup_run = {}
		GameState.save()
		show_cups()
		return
	if String(ctx.get("mode", "")) in ["pickup"]:
		GameState.pickup_streak = 0
		GameState.save()
	show_roster()


func match_finished(id: String, mi: int, won: bool, rules: MatchRules, ctx: Dictionary = {}) -> void:
	var mode := String(ctx.get("mode", "story"))
	var rew := GameState.award(ctx, rules)
	var again := ctx.duplicate()
	again["powerups"] = []
	var btns: Array = []
	match mode:
		"story":
			if won:
				GameState.record_win(id, mi)
				var m: Dictionary = GameState.heroine(id)["matches"][mi]
				var scene: Dictionary = m.get("scene", {})
				btns.append(["Continue", func():
					_show(VNScreen.new(self, id, m.get("after", []), func():
						GameState.see_scene(String(scene.get("id", "")))
						_show(SceneViewer.new(self, id, scene, show_roster))))])
			else:
				btns.append(["Rematch", func(): prematch(id, mi, again)])
				if GameState.difficulty != "story":
					btns.append(["Rematch on Story difficulty", func():
						GameState.difficulty = "story"
						GameState.save()
						prematch(id, mi, again), UI.CYAN])
				btns.append(["Pro Shop", func(): show_shop(), UI.GOLD])
				btns.append(["Roster", show_roster, UI.LINE])
		"replay":
			btns.append(["Roster", show_roster])
			btns.append(["Play again", func(): prematch(id, mi, again), UI.CYAN])
		"pickup":
			btns.append(["Play again", func(): start_pickup(id)])
			btns.append(["Pro Shop", func(): show_shop(), UI.GOLD])
			btns.append(["Roster", show_roster, UI.LINE])
		"finale":
			var f := GameState.finale()
			var last_r: bool = int(ctx.get("round", 0)) >= f["rounds"].size() - 1
			if not won:
				btns.append(["Replay this round", func(): prematch(id, mi, again)])
				btns.append(["Pro Shop", func(): show_shop(), UI.GOLD])
				btns.append(["Roster", show_roster, UI.LINE])
			elif last_r:
				GameState.finale_done = true
				GameState.finale_round = 0
				var fs: Dictionary = f.get("scene", {})
				btns.append(["Continue", func():
					_show(VNScreen.new(self, "sable", f.get("after", []), func():
						GameState.see_scene(String(fs.get("id", "")))
						_show(SceneViewer.new(self, "sable", fs, show_roster))))])
			else:
				GameState.finale_round = int(ctx.get("round", 0)) + 1
				btns.append(["Next round", finale_round])
			GameState.save()
		"cup":
			var c := GameState.cup(String(ctx.get("cup", "")))
			var last := int(ctx.get("round", 0)) >= int(c.get("rounds", 3)) - 1
			if not won:
				GameState.cup_run = {}
				btns.append(["Back to cups", show_cups])
				btns.append(["Pro Shop", func(): show_shop(show_cups), UI.GOLD])
			elif last:
				GameState.cup_run = {}
				GameState.trophies[String(c["id"])] = true
				var cs: Dictionary = c.get("scene", {})
				GameState.see_scene(String(cs.get("id", "")))
				btns.append(["Continue", func(): _show(SceneViewer.new(self, id, cs, show_cups))])
			else:
				GameState.cup_run["round"] = int(ctx.get("round", 0)) + 1
				btns.append(["Next round", start_cup_round])
				btns.append(["Pro Shop", func(): show_shop(show_cups), UI.GOLD])
			GameState.save()
	_show(ResultScreen.new(self, id, mi, rules, ctx, rew, btns))


func open_scene(id: String, scene: Dictionary) -> void:
	_show(SceneViewer.new(self, id, scene, show_gallery))


func open_stage(id: String, stage: int) -> void:
	_show(SceneViewer.new(self, id, {"stage": stage, "title": "%s, stage %d" % [UI.first_name(id), stage]}, show_gallery))


func _debug_open(o: Dictionary) -> void:
	var id := String(o.get("id", "mila"))
	if o.has("all"):
		GameState.no_save = true
		GameState.unlock_all = true
		GameState.level = int(o.get("lv", "12"))
	match String(o["screen"]):
		"menu": show_menu()
		"age": _show(AgeGateScreen.new(self))
		"roster": _show(RosterScreen.new(self))
		"gallery": show_gallery()
		"settings": show_settings()
		"howto": show_how_to_play()
		"credits": show_credits()
		"vn": start_story_match(id, int(o.get("m", "0")))
		"prologue": _show(VNScreen.new(self, "mila", GameState.data.get("prologue", []), show_menu))
		"match":
			var ms := MatchScreen.new(self, id, int(o.get("m", "0")))
			ms.debug_stage = int(o.get("stage", "0"))
			ms.autoplay = o.get("autoplay", "0") == "1"
			_show(ms)
		"scene": _show(SceneViewer.new(self, id, GameState.heroine(id)["matches"][0]["scene"], show_roster))
		"result":
			GameState.no_save = true
			var r := MatchRules.new()
			r.setup(id, 0)
			r.sim.paddle(0).score = 5
			r.sim.paddle(1).score = 3
			r.layers_lost = 2
			r.smash_goals = 1
			r.player_won = o.get("won", "1") == "1"
			match_finished(id, 0, r.player_won, r, {"mode": String(o.get("mode", "story")), "cup": "bronze", "round": 2})
		"shop":
			GameState.no_save = true
			GameState.level = int(o.get("lv", "4"))
			GameState.tips = int(o.get("tips", "1200"))
			show_shop()
		"cups":
			show_cups()
		"prematch":
			GameState.no_save = true
			GameState.level = int(o.get("lv", "4"))
			GameState.powerups = {"energy": 2, "grip": 1}
			_show(PreMatchScreen.new(self, id, 0, {"mode": "story"}))
		_: show_menu()


## Debug: saves a screenshot after `delay` seconds and quits.
func _take_shot(path: String, delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
	get_tree().quit()
