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
	Extras.achievement_unlocked.connect(_on_achievement)
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
	move_child(host, 0)


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
	var m: Dictionary = GameState.heroine(id)["matches"][mi]
	if GameState.wins(id) > mi:
		prematch(id, mi, {"mode": "replay", "mods": m.get("mods", [])})
		return
	Extras.pending_mods = []
	_show(VNScreen.new(self, id, m.get("before", []), func(): prematch(id, mi, story_ctx(id, mi))))


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
	var rm: Array = c.get("round_mods", [])
	var ctx := {"mode": "cup", "cup": String(run["id"]), "round": r, "target": int(c.get("target", 5)), "boost": float(boosts[mini(r, boosts.size() - 1)]) if not boosts.is_empty() else 0.0, "mods": rm[r] if r < rm.size() else []}
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
	Extras.on_match(ctx, rules)
	var rew: Dictionary = {} if mode == "trainer" else GameState.award(ctx, rules)
	var again := ctx.duplicate()
	again["powerups"] = []
	var btns: Array = []
	match mode:
		"story":
			var m: Dictionary = GameState.heroine(id)["matches"][mi]
			var legs: Array = m.get("legs", [])
			var leg := int(ctx.get("leg", 0))
			if won and leg < legs.size():
				var nl: Dictionary = legs[leg]
				btns.append(["Next game (%d of %d)" % [leg + 2, legs.size() + 1], func():
					_show(VNScreen.new(self, id, nl.get("before", []), func(): prematch(id, mi, story_ctx(id, mi, leg + 1))))])
			elif won:
				GameState.record_win(id, mi)
				if GameState.story_done(id):
					Extras.note_won_over(id)
				var scene: Dictionary = Extras.pick_scene(id, m)
				btns.append(["Continue", func():
					_show(VNScreen.new(self, id, m.get("after", []), func():
						GameState.see_scene(String(scene.get("id", "")))
						_show(SceneViewer.new(self, id, scene, show_roster))))])
			else:
				if Extras.needs_help(id, mi):
					var help := again.duplicate()
					help["assist"] = true
					help["free_powerups"] = Extras.comeback_cfg().get("powerups", ["grip"])
					btns.append(["Coach's help: rematch with a free boost", func(): prematch(id, mi, help), UI.GOLD])
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
				var fafter: Array = Extras.finale_extra() + f.get("after", [])
				btns.append(["Continue", func():
					_show(VNScreen.new(self, "sable", fafter, func():
						GameState.see_scene(String(fs.get("id", "")))
						_show(SceneViewer.new(self, "sable", fs, show_roster))))])
			else:
				GameState.finale_round = int(ctx.get("round", 0)) + 1
				btns.append(["Next round", finale_round])
			GameState.save()
		"trainer":
			btns.append(["Again", func(): start_trainer(id, String(ctx.get("drill", "block")))])
			btns.append(["Other drill", func(): start_trainer(id, "shoot" if String(ctx.get("drill", "")) == "block" else "block"), UI.CYAN])
			btns.append(["After Hours", show_extras, UI.LINE])
		"ladder":
			if won:
				Extras.ladder_won(int(ctx.get("round", 0)))
				btns.append(["Next rung", start_ladder_round])
			else:
				Extras.ladder_lost()
				btns.append(["New climb", start_ladder_round])
			btns.append(["After Hours", show_extras, UI.LINE])
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
		"extras": show_extras()
		"choice":
			GameState.no_save = true
			var cm: Dictionary = GameState.heroine(id)["matches"][int(o.get("m", "0"))]
			var cl := []
			for L in cm.get("after", []) + cm.get("before", []):
				if L.has("choice"):
					cl = [{"who": id, "e": "teasing", "text": "(Debug: the choice in this match.)"}, L]
					break
			var vn := VNScreen.new(self, id, cl, show_menu)
			_show(vn)
			vn.call_deferred("_next")
		"achievements": show_achievements()
		"match":
			var mctx := {}
			if o.has("mods"):
				mctx["mods"] = Array(String(o["mods"]).split(","))
			if o.has("drill"):
				mctx = {"mode": "trainer", "drill": String(o["drill"])}
			var ms := MatchScreen.new(self, id, int(o.get("m", "0")), mctx)
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


# ------------------------------------------------------------- extras
# Story shapes, crossovers, the shot trainer, the ladder, dates, events.
# The state lives in the Extras autoload (autoload/Extras.gd).

## The match context for a story match: its special rules (plus any terms a
## dialogue choice just set) and which leg of a double header it is.
func story_ctx(id: String, mi: int, leg: int = 0) -> Dictionary:
	var m: Dictionary = GameState.heroine(id)["matches"][mi]
	var mods: Array = m.get("mods", []).duplicate()
	var legs: Array = m.get("legs", [])
	if leg > 0 and leg - 1 < legs.size():
		mods = legs[leg - 1].get("mods", []).duplicate()
	for x in Extras.pending_mods:
		if not mods.has(x):
			mods.append(x)
	Extras.pending_mods = []
	var c := {"mode": "story", "mods": mods, "leg": leg}
	if leg > 0 and leg - 1 < legs.size() and legs[leg - 1].has("target"):
		c["target"] = int(legs[leg - 1]["target"])
	return c


func _on_achievement(a: Dictionary) -> void:
	SFX.play("win")
	UI.toast(self, "ACHIEVEMENT", String(a.get("name", "")) + ": " + String(a.get("desc", "")))


func show_extras() -> void:
	_show(ExtrasScreen.new(self))


func show_achievements(back: Callable = Callable()) -> void:
	_show(AchievementsScreen.new(self, back if back.is_valid() else show_extras))


## Shot trainer: "block" her signature or "shoot" your own power shot.
func start_trainer(id: String, drill: String) -> void:
	var ctx := {"mode": "trainer", "drill": drill}
	play_match(id, GameState.side_match_index(id, {"mode": "pickup"}), ctx)


func play_crossover(c: Dictionary, back: Callable = Callable()) -> void:
	var ret: Callable = back if back.is_valid() else show_roster
	var sc: Dictionary = c.get("scene", {})
	_show(VNScreen.new(self, String(c["a"]), c.get("lines", []), func():
		Extras.see("crossover_" + String(c["id"]), "crossovers")
		if sc.is_empty():
			ret.call()
			return
		GameState.see_scene(String(sc.get("id", "")))
		_show(SceneViewer.new(self, String(c["a"]), sc, ret))))


func play_epilogue(id: String, back: Callable = Callable()) -> void:
	var ret: Callable = back if back.is_valid() else show_extras
	var e: Dictionary = Extras.epilogues().get(id, {})
	var sc: Dictionary = e.get("scene", {})
	_show(VNScreen.new(self, id, e.get("lines", []), func():
		Extras.see("epilogue_" + id, "epilogues")
		if sc.is_empty():
			ret.call()
			return
		GameState.see_scene(String(sc.get("id", "")))
		_show(SceneViewer.new(self, id, sc, ret))))


## Plays a story match's dialogue again from the gallery (both halves).
func replay_talk(id: String, mi: int) -> void:
	var m: Dictionary = GameState.heroine(id)["matches"][mi]
	var ls: Array = m.get("before", []).duplicate()
	ls.append({"who": "narrator", "text": "(The match.)"})
	ls.append_array(m.get("after", []))
	_show(VNScreen.new(self, id, ls, show_gallery, true))


func start_ladder_round() -> void:
	if Extras.ladder_run.is_empty():
		Extras.start_ladder()
	var r := int(Extras.ladder_run.get("round", 0))
	var rung := Extras.ladder_rung(r)
	var id := String(rung["id"])
	var ctx := {"mode": "ladder", "round": r, "target": int(rung["target"]), "boost": float(rung["boost"]), "mods": rung["mods"]}
	prematch(id, GameState.match_count(id) - 1, ctx)
