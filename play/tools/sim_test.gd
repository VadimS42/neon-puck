## Headless balance check. Plays a bot (as you) against every heroine at
## every difficulty and prints win rate, match length and strips.
##   godot --headless --path . -s tools/sim_test.gd [-- games=20 bot=normal]
## bot=weak|normal|strong sets how good the stand-in player is.
extends SceneTree

func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.split("=")
		if kv.size() == 2:
			args[kv[0]] = kv[1]
	var games := int(args.get("games", "12"))
	var bot_level := String(args.get("bot", "normal"))
	await process_frame
	var gs = root.get_node("GameState")
	gs.no_save = true
	for diff in ["story", "normal", "hard"]:
		gs.difficulty = diff
		for id in gs.order():
			for mi in gs.match_count(id):
				var won := 0
				var total_t := 0.0
				var strips := 0
				var her_sig_goals := 0
				var score_sum := Vector2.ZERO
				var sm := 0
				var smg := 0
				for g in games:
					var r := _play(gs, id, mi, g, bot_level)
					won += int(r.win)
					total_t += r.t
					strips += r.strips
					her_sig_goals += r.sig
					score_sum += Vector2(r.a, r.b)
					sm += r.smash
					smg += r.smash_goals
				print("%-6s %-5s m%d  win %3d%%  avg %5.0fs  strips/match %.1f  her sig goals %.1f  avg score %.1f-%.1f  smashes %.1f (%.1f in)" % [diff, id, mi + 1, 100 * won / games, total_t / games, float(strips) / games, float(her_sig_goals) / games, score_sum.x / games, score_sum.y / games, float(sm) / games, float(smg) / games])
	quit()


func _play(gs, id: String, mi: int, seed_v: int, bot_level: String) -> Dictionary:
	var rules := MatchRules.new()
	rules.setup(id, mi)
	rules.brain.setup(seed_v * 7 + mi)
	var sim := rules.sim
	var me := AIBrain.new()
	me.side = 0
	me.setup(1000 + seed_v)
	match bot_level:
		"weak":
			me.reaction = 0.22; me.aim_spread = 70; me.bank_pref = 0.2
		"strong":
			me.reaction = 0.1; me.aim_spread = 40; me.bank_pref = 0.35
		_:
			me.reaction = 0.15; me.aim_spread = 55; me.bank_pref = 0.3
	sim.paddle(0).max_speed = 2600.0 if bot_level != "strong" else 3000.0
	sim.paddle(0).max_accel = 14000.0 if bot_level != "strong" else 20000.0
	var dt := 1.0 / 120.0
	var smashes := 0
	while sim.time < 900.0 and not rules.over:
		me.think(sim, dt)
		rules.step(dt)
		for e in rules.events:
			if e.kind == "power_shot" and e.side == 0:
				smashes += 1
		rules.events.clear()
	return {"win": rules.player_won, "t": sim.time, "strips": rules.layers_lost, "sig": rules.her_signature_goals, "a": sim.paddle(0).score, "b": sim.paddle(1).score, "smash": smashes, "smash_goals": rules.smash_goals}
