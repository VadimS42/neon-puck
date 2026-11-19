## Headless playthrough estimate. A bot plays the whole game on Normal and
## this prints how long it took, in match time plus reading time.
##   godot --headless --path . -s tools/playthrough_test.gd [-- bot=weak side=1]
## side=0 plays story matches only and ignores level gates (the story's own
## length). side=1 respects level gates and fills them with cups and pickup
## games, buying gear as it goes (the real playthrough).
## Reading time: READ_LINE seconds per dialogue line, READ_SCENE per scene.
extends SceneTree

const READ_LINE := 4.5
const READ_SCENE := 25.0
const SETUP := 20.0  # menus, loadout, result screen per match

var gs
var bot_level := "weak"
var t_match := 0.0
var t_read := 0.0
var n_matches := 0
var n_losses := 0
var log_lines: Array = []


func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.split("=")
		if kv.size() == 2:
			args[kv[0]] = kv[1]
	bot_level = String(args.get("bot", "weak"))
	var side := String(args.get("side", "1")) == "1"
	await process_frame
	gs = root.get_node("GameState")
	gs.no_save = true
	gs.difficulty = String(args.get("diff", "normal"))
	gs.reset_progress()
	gs.prologue_seen = true
	t_read += gs.data.get("prologue", []).size() * READ_LINE
	var guard := 0
	while guard < 400:
		guard += 1
		var next := _next_story(not side)
		if next.is_empty():
			if _all_done():
				if not side or gs.level >= int(gs.finale().get("level", 1)):
					_finale()
					break
			if not side:
				break
			_side_step()
			continue
		_story(next[0], next[1])
	print("Bot %s, %s, side content %s" % [bot_level, gs.difficulty, "on" if side else "off"])
	for l in log_lines:
		print(l)
	print("Matches %d (%d lost). Match time %.0f min, reading %.0f min, menus %.0f min. TOTAL %.0f min. Level %d, tips %d." % [n_matches, n_losses, t_match / 60.0, t_read / 60.0, n_matches * SETUP / 60.0, (t_match + t_read + n_matches * SETUP) / 60.0, gs.level, gs.tips])
	quit()


func _all_done() -> bool:
	for id in gs.order():
		if not gs.story_done(id):
			return false
	return true


## The next story match to play: [id, mi], lowest level first.
func _next_story(ignore_levels: bool) -> Array:
	var best := []
	var best_lv := 999
	for id in gs.order():
		if not gs.is_unlocked(id) or gs.story_done(id):
			continue
		var mi: int = gs.wins(id)
		var lv: int = gs.match_level(id, mi)
		if (ignore_levels or gs.level >= lv) and lv < best_lv:
			best = [id, mi]
			best_lv = lv
	return best


func _story(id: String, mi: int) -> void:
	var m: Dictionary = gs.heroine(id)["matches"][mi]
	t_read += m.get("before", []).size() * READ_LINE
	while true:
		var r := _play(id, mi, {"mode": "story"})
		if r.player_won:
			gs.record_win(id, mi)
			t_read += m.get("after", []).size() * READ_LINE + READ_SCENE
			log_lines.append("  t=%3.0f min  Lv %2d  won %s match %d" % [_now() / 60.0, gs.level, id, mi + 1])
			return


func _finale() -> void:
	var f: Dictionary = gs.finale()
	t_read += f.get("before", []).size() * READ_LINE
	for r in f["rounds"].size():
		var rd: Dictionary = f["rounds"][r]
		var id := String(rd["id"])
		t_read += rd.get("before", []).size() * READ_LINE
		var ctx := {"mode": "finale", "round": r, "target": int(f.get("target", 7)), "boost": float(f["boost"][r])}
		while not _play(id, gs.side_match_index(id, ctx), ctx).player_won:
			pass
	t_read += f.get("after", []).size() * READ_LINE + READ_SCENE
	log_lines.append("  t=%3.0f min  Lv %2d  won the championship" % [_now() / 60.0, gs.level])


func _side_step() -> void:
	_shop()
	for c in gs.prog.get("tournaments", []):
		var cid := String(c["id"])
		if not gs.trophies.has(cid) and gs.cup_block(cid) == "":
			gs.start_cup(cid)
			var ok := true
			var boosts: Array = c.get("round_boost", [])
			for r in int(c["rounds"]):
				var id := String(gs.cup_run["opponents"][r])
				var ctx := {"mode": "cup", "cup": cid, "round": r, "target": int(c["target"]), "boost": float(boosts[r])}
				var res := _play(id, gs.side_match_index(id, ctx), ctx)
				if not res.player_won:
					ok = false
					break
			gs.cup_run = {}
			if ok:
				gs.trophies[cid] = true
				t_read += READ_SCENE
				log_lines.append("  t=%3.0f min  Lv %2d  won %s" % [_now() / 60.0, gs.level, c["name"]])
			return
	# Pickup against whoever you've beaten most (the easiest XP).
	var pick := ""
	for id in gs.unlocked_heroines():
		if pick == "" or gs.wins(id) < gs.wins(pick):
			pick = id
	var ctx2 := {"mode": "pickup", "target": int(gs.prog.get("pickup", {}).get("target", 5))}
	_play(pick, gs.side_match_index(pick, ctx2), ctx2)


## Buys the cheapest gear upgrade it can afford, repeatedly.
func _shop() -> void:
	var bought := true
	while bought:
		bought = false
		var best := {}
		for g in gs.prog.get("gear", []):
			var gid := String(g["id"])
			if gs.owned_gear.has(gid) or gs.level < int(g["level"]) or gs.tips < int(g["price"]):
				continue
			var cur: Dictionary = gs.gear_item(String(gs.equipped.get(String(g["slot"]), "")))
			if int(g["tier"]) <= int(cur.get("tier", 0)):
				continue
			if best.is_empty() or int(g["price"]) < int(best["price"]):
				best = g
		if not best.is_empty():
			gs.buy_gear(String(best["id"]))
			bought = true


func _now() -> float:
	return t_match + t_read + n_matches * SETUP


func _play(id: String, mi: int, ctx: Dictionary) -> MatchRules:
	var rules := MatchRules.new()
	rules.setup(id, mi, ctx)
	rules.brain.setup(n_matches * 31 + 7)
	var sim := rules.sim
	var me := AIBrain.new()
	me.side = 0
	me.setup(1000 + n_matches)
	match bot_level:
		"weak":
			me.reaction = 0.22; me.aim_spread = 70; me.bank_pref = 0.2
		"strong":
			me.reaction = 0.1; me.aim_spread = 40; me.bank_pref = 0.35
		_:
			me.reaction = 0.15; me.aim_spread = 55; me.bank_pref = 0.3
	# The bot can't follow a mouse, so it moves with a capped acceleration.
	sim.paddle(0).max_accel = 14000.0
	var dt := 1.0 / 120.0
	while sim.time < 900.0 and not rules.over:
		me.think(sim, dt)
		rules.step(dt)
		rules.events.clear()
	n_matches += 1
	t_match += sim.time
	if not rules.player_won:
		n_losses += 1
	gs.award(ctx, rules)
	return rules
