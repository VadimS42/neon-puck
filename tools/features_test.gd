## Headless checks for the features added on top of the core loop: special
## rules, the shot trainer, Extras (achievements, choices and conditions,
## crossovers, ladder, missions, events, season pass, comeback help) and,
## in the Rivals build, cloud save and notifications. Never touches a save.
##   godot --headless --path . -s tools/features_test.gd
## The same file runs in play/ (Rivals); sections skip what a game lacks.
extends SceneTree

var fails := 0
var passes := 0


func ok(cond: bool, what: String) -> void:
	if cond:
		passes += 1
	else:
		fails += 1
		print("FAIL: ", what)


func _init() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	var ex = root.get_node("Extras")
	gs.no_save = true
	ex.from_dict({})
	_test_mods(gs)
	_test_trainer(gs)
	_test_extras(gs, ex)
	_test_story_data(gs, ex)
	if not ex.mission_cfg().is_empty():
		_test_missions(gs, ex)
	if not ex.events().is_empty():
		_test_event(gs, ex)
	if ex.season_enabled():
		_test_season(gs, ex)
	if not ex.ladder_cfg().is_empty():
		_test_ladder(gs, ex)
	if root.has_node("CloudSave"):
		_test_cloud(gs, ex)
	if root.has_node("Notify"):
		_test_notify(gs, ex)
	print("features_test: %d passed, %d failed" % [passes, fails])
	quit(1 if fails > 0 else 0)


## Bot vs heroine under ctx; returns the finished rules.
func _bot_match(id: String, mi: int, ctx: Dictionary, max_t: float = 900.0) -> MatchRules:
	var rules := MatchRules.new()
	rules.setup(id, mi, ctx)
	var me := AIBrain.new()
	me.side = 0
	me.setup(77)
	me.reaction = 0.15
	me.aim_spread = 55
	me.bank_pref = 0.3
	rules.sim.paddle(0).max_accel = 14000.0
	var dt := 1.0 / 120.0
	while rules.sim.time < max_t and not rules.over:
		me.think(rules.sim, dt)
		rules.step(dt)
		rules.events.clear()
	return rules


func _test_mods(gs) -> void:
	for m in MatchMods.DEFS:
		var r := _bot_match("mila", 2, {"mode": "pickup", "mods": [m], "target": 3})
		ok(r.over, "match with mod %s finishes (t=%.0f)" % [m, r.sim.time])
	var r2 := MatchRules.new()
	r2.setup("juno", 0, {"mods": ["mini_goals", "turbo", "handicap", "no_heat", "rush", "bumpers"]})
	ok(r2.sim.goal_w < PuckSim.GOAL_W, "mini goals narrow the mouth")
	ok(r2.sim.friction < PuckSim.FRICTION, "turbo lowers friction")
	ok(r2.sim.bumpers.size() == 2, "trick table adds two bumpers")
	ok(r2.sim.paddle(0).heat_mult == 0.0, "by the book: no heat")
	ok(r2.clock > 0.0, "rush clock set")
	# Rush: a tie at the buzzer becomes golden goal; a lead wins.
	var r3 := MatchRules.new()
	r3.setup("mila", 0, {"mods": ["rush"]})
	r3.clock = 0.01
	r3.sim.paddle(0).score = 2
	r3.sim.paddle(1).score = 1
	r3.step(0.02)
	ok(r3.over and r3.player_won, "rush: leader at the buzzer wins")
	var r4 := MatchRules.new()
	r4.setup("mila", 0, {"mods": ["rush"]})
	r4.clock = 0.01
	r4.step(0.02)
	ok(r4.golden_goal and not r4.over, "rush: tie at the buzzer -> golden goal")
	# Bank night: a bank goal of yours counts 2.
	var r5 := MatchRules.new()
	r5.setup("juno", 1, {"mods": ["bank_double"]})
	r5._on_sim_event({"kind": "goal", "scorer": 0, "power": false, "power_kind": "", "bank": true, "own_goal": false})
	ok(r5.sim.paddle(0).score == 1, "bank night: the extra point is added on top of the sim's goal (sim adds the first)")


func _test_trainer(gs) -> void:
	for drill in ["block", "shoot"]:
		var r := _bot_match("kat", 1, {"mode": "trainer", "drill": drill}, 600.0)
		ok(r.over, "trainer %s drill ends (shots %d, hits %d, t=%.0f)" % [drill, r.drill_shots, r.drill_hits, r.sim.time])
		ok(r.drill_shots >= r.drill_total, "trainer %s fired all %d shots" % [drill, r.drill_total])
		ok(r.layers_lost == 0, "trainer never strips")


func _test_extras(gs, ex) -> void:
	ex.from_dict({})
	var rules := MatchRules.new()
	rules.setup("mila", 0, {"mode": "story"})
	rules.player_won = true
	rules.over = true
	rules.bank_goals = 2
	ex.on_match({"mode": "story"}, rules)
	ok(ex.stat("wins") == 1 and ex.stat("bank_goals") == 2, "on_match counts wins and bank goals")
	ok(ex.unlocked.has("first_win"), "first win achievement unlocks")
	# Loss streak and comeback help.
	rules.player_won = false
	for i in 3:
		ex.on_match({"mode": "story"}, rules)
	var cb_on: bool = not ex.comeback_cfg().is_empty()
	ok(ex.needs_help("mila", 0) == cb_on, "comeback help after 3 losses (enabled=%s)" % cb_on)
	rules.player_won = true
	ex.on_match({"mode": "story"}, rules)
	ok(not ex.needs_help("mila", 0), "a win clears the loss streak")
	# Conditions.
	ex.flags = {"mila_0": "tease"}
	ok(ex.cond("mila_0=tease") and not ex.cond("mila_0=sweet") and ex.cond("!mila_0=sweet"), "flag conditions")
	gs.progress = {"juno": 3}
	ok(ex.cond("wins:juno>=3") and not ex.cond("wins:juno>=4"), "wins condition")
	var lines: Array = ex.filter_lines([{"text": "a"}, {"if": "mila_0=sweet", "text": "b"}, {"if": "mila_0=tease", "text": "c"}])
	ok(lines.size() == 2 and lines[1]["text"] == "c", "filter_lines drops failed conditions")
	ex.flags = {"mila_0": "sweet", "mila_1": "sweet", "mila_2": "sweet", "terms_sable_1": "terms"}
	ok(ex.choice_count("mila", "sweet") == 3, "choice_count")
	# Crossovers and rival barks.
	gs.progress = {"mila": 3, "juno": 3}
	var waiting: Array = ex.crossovers_waiting()
	if not ex.crossovers().is_empty():
		ok(waiting.size() >= 1 and String(waiting[0]["id"]) == "mila_juno", "mila+juno crossover opens at 3 wins each")
		ok(ex.rival_bark("mila") != "", "Mila has something to say about Juno")
	gs.progress = {}
	# Finale variant.
	ex.won_order = ["kat"]
	ok(ex.finale_extra().size() > 0 or ex.data.get("finale_by_first", {}).is_empty(), "finale lines for who you won first")
	ex.from_dict({})


func _test_story_data(gs, ex) -> void:
	var shapes := {}
	for id in gs.order():
		var sig := []
		for m in gs.heroine(id).get("matches", []):
			sig.append([m.get("mods", []), m.has("legs"), m.has("attitude")])
			for L in m.get("before", []) + m.get("after", []):
				if L.has("choice"):
					for o in L["choice"]:
						for mm in o.get("mods", []):
							ok(MatchMods.DEFS.has(mm), "%s choice mod %s exists" % [id, mm])
			for mm in m.get("mods", []):
				ok(MatchMods.DEFS.has(mm), "%s mod %s exists" % [id, mm])
		shapes[str(sig)] = true
	ok(shapes.size() == gs.order().size(), "all four arcs have a different shape")
	for c in gs.prog.get("tournaments", []):
		for rm in c.get("round_mods", []):
			for mm in rm:
				ok(MatchMods.DEFS.has(mm), "cup mod %s exists" % mm)
	# Alternate scenes resolve.
	for id in gs.order():
		for m in gs.heroine(id).get("matches", []):
			if m.has("alt_scene"):
				var tag := String(m["alt_scene"]["tag"])
				ex.flags = {}
				for i in 3:
					ex.flags["%s_%d" % [id, i]] = tag
				ok(String(ex.pick_scene(id, m).get("id", "")) == String(m["alt_scene"]["id"]), "%s alt scene with 3 x %s" % [id, tag])
				ex.flags = {}
				ok(String(ex.pick_scene(id, m).get("id", "")) == String(m["scene"]["id"]), "%s normal scene without choices" % id)
	# Achievement stats are all known.
	for a in ex.achievements():
		var k := String(a.get("stat", ""))
		ok(k in ex.STAT_KEYS or k in ["won_over", "finale", "scenes", "trophies", "level", "ladder_best", "won", "alt_scenes"], "achievement %s stat %s known" % [a.get("id"), k])
	for k in ex.mission_cfg().get("pool", []):
		ok(String(k.get("stat", "")) in ex.STAT_KEYS, "mission %s stat known" % k.get("id"))


func _test_missions(gs, ex) -> void:
	ex.from_dict({})
	var ms: Array = ex.todays_missions()
	ok(ms.size() == int(ex.mission_cfg().get("per_day", 3)), "three missions today")
	var ids := {}
	for m in ms:
		ids[m["id"]] = true
	ok(ids.size() == ms.size(), "missions are distinct")
	var m0: Dictionary = ms[0]
	ok(not ex.mission_done(m0), "fresh mission not done")
	ex.bump(String(m0["stat"]), int(m0["n"]))
	ok(ex.mission_done(m0), "mission done after its stat moves")
	var gems0: int = int(gs.get("gems")) if gs.get("gems") != null else 0
	ok(ex.claim_mission(m0), "claim mission")
	ok(not ex.claim_mission(m0), "can't claim twice")
	for m in ms:
		ex.bump(String(m["stat"]), int(m["n"]))
		ex.claim_mission(m)
	ok(ex.all_missions_claimed() and ex.claim_mission_bonus(), "bonus after all three")
	ok(int(gs.get("gems")) > gems0, "missions paid gems")
	ex.from_dict({})


func _test_event(gs, ex) -> void:
	ex.from_dict({})
	var ev: Dictionary = ex.current_event()
	ok(not ev.is_empty(), "an event is running this week")
	ok(ex.seconds_left_in_event() > 0 and ex.seconds_left_in_event() <= 604800, "event ends within a week")
	var rounds := int(ev.get("rounds", 3))
	for r in rounds - 1:
		ok(not ex.event_round_won(r), "event round %d is not the final" % r)
	ok(ex.event_round_won(rounds - 1), "event final pays out the first time")
	var o := String(ev.get("outfit", ""))
	if o.contains(":"):
		var bits := o.split(":")
		ok(gs.outfit_owned(bits[0], bits[1]), "event outfit granted")
		ok(not gs.outfit_def(bits[0], bits[1]).is_empty(), "event outfit defined in heroines.json")
	ok(not ex.event_round_won(rounds - 1), "event pays out once a week")
	ok(gs.match_costs_life({"mode": "event", "round": 0}) and not gs.match_costs_life({"mode": "event", "round": 1}), "only the event's first round costs a life")
	ok(not gs.match_costs_life({"mode": "trainer"}), "trainer is free")
	ex.from_dict({})


func _test_season(gs, ex) -> void:
	ex.from_dict({})
	var cfg: Dictionary = ex.season_cfg()
	ok(not gs.product(String(cfg.get("product", ""))).is_empty(), "season pass product exists")
	ok(not ex.claim_season(0, "free"), "tier 1 locked at 0 XP")
	ex.add_season_xp(int(cfg.get("xp_per_tier", 100)) * 2)
	ok(ex.season_tier() == 2, "two tiers of XP")
	ok(ex.claim_season(0, "free") and not ex.claim_season(0, "free"), "claim free tier once")
	ok(not ex.claim_season(0, "premium"), "premium locked without the pass")
	gs.owned_products[String(cfg["product"])] = true
	ok(ex.claim_season(0, "premium"), "premium claim with the pass")
	for t in cfg.get("tiers", []):
		for track in ["free", "premium"]:
			var o := String(t.get(track, {}).get("outfit", ""))
			if o.contains(":"):
				var bits := o.split(":")
				ok(not gs.outfit_def(bits[0], bits[1]).is_empty(), "season outfit %s defined" % o)
	gs.owned_products.erase(String(cfg["product"]))
	ex.from_dict({})


func _test_ladder(gs, ex) -> void:
	ex.from_dict({})
	ex.start_ladder()
	var r0: Dictionary = ex.ladder_rung(0)
	ok(r0["mods"].is_empty(), "rung 1 has no special rules")
	var r6: Dictionary = ex.ladder_rung(6)
	ok(r6["mods"].size() >= 1 and float(r6["boost"]) > float(r0["boost"]), "later rungs add rules and boost")
	ok(String(ex.ladder_rung(3)["id"]) == String(ex.ladder_rung(3)["id"]), "rungs are deterministic per run")
	ex.ladder_won(0)
	ex.ladder_won(1)
	ok(ex.ladder_best == 2 and int(ex.ladder_run["round"]) == 2, "ladder progress")
	ex.ladder_lost()
	ok(ex.ladder_run.is_empty() and ex.ladder_best == 2, "a loss ends the climb, best stays")
	var rr := _bot_match(String(r6["id"]), gs.match_count(String(r6["id"])) - 1, {"mode": "ladder", "mods": r6["mods"], "target": 3, "boost": r6["boost"]})
	ok(rr.over, "a ladder rung plays to the end")
	ex.from_dict({})


func _test_cloud(gs, ex) -> void:
	var cs = root.get_node("CloudSave")
	var blob: Dictionary = cs.make_blob()
	ok(blob.has("game") and blob.has("extras") and blob.has("score"), "cloud blob has both saves")
	ok(cs.score_of({"progress": {"mila": 6}}) > cs.score_of({"progress": {"mila": 1}}), "more progress scores higher")


func _test_notify(gs, ex) -> void:
	var nt = root.get_node("Notify")
	ex.notify_on = true
	gs.lives = 1
	gs.life_next_at = gs.now() + 600
	gs.unlimited_until = 0
	var p: Array = nt.plan()
	var has_lives := false
	for n in p:
		if int(n[0]) == nt.ID_LIVES:
			has_lives = true
			ok(int(n[1]) > 600, "lives-full reminder after the last life refills")
	ok(has_lives, "lives reminder planned when lives are missing")
	ex.notify_on = false
	ok(nt.plan().is_empty(), "reminders off means none planned")
	ex.notify_on = true
