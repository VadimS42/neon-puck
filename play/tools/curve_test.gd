## Difficulty-curve check: a bot (as you) plays each story match with no
## power-ups, then with three (Spotlight, Grip Tape, Sugar Rush), and with
## three plus one revive. The bot has the best gear for the match level. Prints win rates per match.
##   godot --headless --path . -s tools/curve_test.gd [-- games=10 bot=normal]
extends SceneTree

const SETS := {"none": [], "3 power-ups": ["spotlight", "grip", "sugar"]}


func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.split("=")
		if kv.size() == 2:
			args[kv[0]] = kv[1]
	var games := int(args.get("games", "10"))
	var bot := String(args.get("bot", "normal"))
	await process_frame
	var gs = root.get_node("GameState")
	gs.no_save = true
	gs.difficulty = "normal"
	print("match          lvl tier       none   3 pups  3 pups+revive")
	for id in gs.order():
		for mi in gs.match_count(id):
			if gs.match_level(id, mi) < int(args.get("from_level", "1")):
				continue
			var row := "%-6s m%d      %3d %-9s" % [id, mi + 1, gs.match_level(id, mi), String(gs.curve(id, mi).get("name", ""))]
			for k in ["none", "3 power-ups", "revive"]:
				var w := 0
				for g in games:
					w += int(_play(gs, id, mi, g, bot, SETS["3 power-ups"] if k != "none" else [], 1 if k == "revive" else 0))
				row += "  %4d%%" % (100 * w / games)
			print(row)
	quit()


func _play(gs, id: String, mi: int, seed_v: int, bot: String, pups: Array, revives: int) -> bool:
	# Best gear a player at this match's level could own.
	var lv: int = gs.match_level(id, mi)
	gs.equipped = {}
	for g in gs.prog.get("gear", []):
		if int(g["level"]) <= lv:
			gs.equipped[String(g["slot"])] = String(g["id"])
	var rules := MatchRules.new()
	rules.setup(id, mi, {"mode": "story", "powerups": pups})
	rules.brain.setup(seed_v * 7 + mi)
	var sim := rules.sim
	var me := AIBrain.new()
	me.side = 0
	me.setup(1000 + seed_v)
	me.reaction = 0.15 if bot != "strong" else 0.1
	me.aim_spread = 55 if bot != "strong" else 40
	me.bank_pref = 0.3
	sim.paddle(0).max_speed *= (2600.0 if bot != "strong" else 3000.0) / 2600.0
	sim.paddle(0).max_accel = 14000.0 if bot != "strong" else 20000.0
	var dt := 1.0 / 120.0
	var left := revives
	while sim.time < 900.0:
		me.think(sim, dt)
		rules.step(dt)
		rules.events.clear()
		if rules.over:
			if rules.player_won or left <= 0:
				break
			left -= 1
			rules.revive(int(gs.revive_cfg().get("her_score_back", 3)), true)
	return rules.player_won
