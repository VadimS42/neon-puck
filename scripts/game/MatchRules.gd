## MatchRules.gd
##
## One match against one heroine: the table, her brain, the score and her
## outfit. MatchScreen drives it with your input and draws it; the headless
## test drives it with a bot. Both get the same rules.
##
## Stripping: she has Composure, `composure_per_layer` points per outfit
## layer. Every goal you score knocks off 1; a power smash goal knocks off a
## whole layer at once. When it runs out a layer comes off, and that layer's
## stat (paddle speed, size or reactions) drops for the rest of the match.
## Her goals win back 1 Composure (never a layer).
class_name MatchRules
extends RefCounted

var sim := PuckSim.new()
var brain := AIBrain.new()
var heroine_id := ""
var match_index := 0
var target := 7
var layers_lost := 0
var layer_count := 3
var composure_per_layer := 2
var composure := 2
var over := false
var player_won := false
## Game-level events for the screen: strip, goal, power, signature_ready...
var events: Array = []
## Stats for the end screen.
var smash_goals := 0
var bank_goals := 0
var saves := 0
var her_signature_goals := 0
## How this match was started: {"mode": "story"|"replay"|"pickup"|"cup",
## "powerups": [ids], "cup", "round", "boost", "target"}.
var ctx: Dictionary = {}
## Cup rounds make her sharper: + this fraction of speed, faster reactions.
var boost := 0.0
var _comeback_ready := false
## Special rules for this match (MatchMods ids), from ctx "mods".
var mods: Array = []
## Rush Clock: seconds left (-1 = no clock). At 0 the leader wins; a tie
## turns the next goal into the winner.
var clock := -1.0
var golden_goal := false
## Shot trainer (ctx mode "trainer"): "block" (she fires her signature
## again and again, you stop it) or "shoot" (your power shot is always
## ready). Ten shots, then it ends. No stripping, no rewards.
var drill := ""
var drill_total := 10
var drill_shots := 0
var drill_hits := 0
## Her signature shots you stopped, and the most goals you trailed by.
var sig_blocks := 0
var revives := 0
var max_deficit := 0


## The GameState autoload, looked up at run time so the headless test can
## load this script too.
var gs: Node


func setup(id: String, mi: int, context: Dictionary = {}) -> void:
	ctx = context
	gs = (Engine.get_main_loop() as SceneTree).root.get_node("GameState")
	heroine_id = id
	match_index = mi
	var h: Dictionary = gs.heroine(id)
	var m: Dictionary = h.get("matches", [])[mi]
	target = int(ctx.get("target", m.get("target", 7)))
	boost = float(ctx.get("boost", 0.0))
	layer_count = h.get("layers", []).size()
	composure_per_layer = int(h.get("composure", 2))
	composure = composure_per_layer
	brain.side = 1
	brain.setup(hash(id) + mi * 7919)
	gs.apply_player(sim.paddle(0))
	sim.paddle(1).heat_mult = 0.6
	_apply_powerups(ctx.get("powerups", []) + ctx.get("free_powerups", []))
	apply_her(0)
	mods = ctx.get("mods", [])
	MatchMods.apply(self)
	if String(ctx.get("mode", "")) == "trainer":
		drill = String(ctx.get("drill", "block"))
		target = 999
		layer_count = 0


func has_powerup(pid: String) -> bool:
	return ctx.get("powerups", []).has(pid)


func _apply_powerups(ids: Array) -> void:
	var me: PuckSim.Paddle = sim.paddle(0)
	for pid in ids:
		match String(pid):
			"energy":
				me.heat = PuckSim.HEAT_MAX
			"grip":
				me.radius *= 1.2
			"spotlight":
				composure_per_layer = maxi(1, composure_per_layer - 1)
				composure = composure_per_layer
			"hype":
				me.heat_mult *= 1.4
			"wink":
				sim.paddle(1).heat_mult *= 0.5
			"sugar":
				me.max_speed *= 1.15
				me.power_mult *= 1.1
			"comeback":
				_comeback_ready = true


## Her paddle and brain with `layers` layers off, plus any cup boost.
func apply_her(layers: int) -> void:
	gs.apply_opponent(heroine_id, match_index, layers, brain, sim.paddle(1))
	if boost > 0.0:
		var her: PuckSim.Paddle = sim.paddle(1)
		her.max_speed *= 1.0 + boost
		her.max_accel *= 1.0 + boost
		brain.reaction = maxf(0.04, brain.reaction - boost * 0.15)


func step(dt: float) -> void:
	if over:
		return
	brain.think(sim, dt)
	_aim_player_signature()
	if drill != "":
		_drill_tick()
	sim.step(dt)
	for e in sim.events:
		_on_sim_event(e)
	sim.events.clear()
	if clock > 0.0 and sim.paused <= 0.0 and not over:
		clock = maxf(0.0, clock - dt)
		if clock <= 0.0:
			var a: int = sim.paddle(0).score
			var b: int = sim.paddle(1).score
			if a != b:
				_end(a > b)
			else:
				golden_goal = true
				events.append({"kind": "golden_goal"})


func _end(won: bool) -> void:
	over = true
	player_won = won
	events.append({"kind": "match_over", "won": player_won})


## Trainer: keeps the drill's meter full and counts the shots.
func _drill_tick() -> void:
	var me: PuckSim.Paddle = sim.paddle(0)
	var her: PuckSim.Paddle = sim.paddle(1)
	var side := 1 if drill == "block" else 0
	var p: PuckSim.Paddle = her if side == 1 else me
	if drill_shots < drill_total and not p.armed and sim.powered < 0 and sim.paused <= 0.0:
		p.heat = PuckSim.HEAT_MAX
	if side == 1:
		me.heat = minf(me.heat, PuckSim.HEAT_MAX - 1.0)
	else:
		her.heat = 0.0
	if drill_shots >= drill_total and sim.powered < 0 and not over:
		_end(drill_hits >= int(ceil(drill_total * 0.6)))


func _on_sim_event(e: Dictionary) -> void:
	events.append(e)
	if drill != "":
		_drill_event(e)
		return
	match String(e.kind):
		"power_saved":
			if e.side == 0:
				sig_blocks += 1
		"save":
			if e.side == 0:
				saves += 1
		"goal":
			if e.scorer == 0:
				if e.bank:
					bank_goals += 1
				var extra := MatchMods.bonus_points(self, e)
				if extra > 0:
					sim.paddle(0).score += extra
					events.append({"kind": "bonus_points", "n": extra})
				var dmg := 1
				if e.power:
					smash_goals += 1
					dmg = composure_per_layer
				_hit_composure(dmg)
			else:
				if e.power:
					her_signature_goals += 1
					sim.paddle(0).heat = 0.0
					events.append({"kind": "flustered"})
				if layers_lost < layer_count:
					composure = mini(composure_per_layer, composure + 1)
				if _comeback_ready and sim.paddle(1).score == target - 1:
					_comeback_ready = false
					sim.paddle(0).heat = PuckSim.HEAT_MAX
					events.append({"kind": "second_wind"})
			max_deficit = maxi(max_deficit, sim.paddle(1).score - sim.paddle(0).score)
			if sim.paddle(0).score >= target or sim.paddle(1).score >= target:
				_end(sim.paddle(0).score >= target)
			elif golden_goal:
				_end(e.scorer == 0)


func _drill_event(e: Dictionary) -> void:
	var side := 1 if drill == "block" else 0
	match String(e.kind):
		"power_shot":
			if e.side == side:
				drill_shots += 1
		"power_saved":
			if drill == "block" and e.side == 0:
				drill_hits += 1
		"goal":
			if drill == "shoot" and e.scorer == 0 and e.power:
				drill_hits += 1


func _hit_composure(dmg: int) -> void:
	if layers_lost >= layer_count:
		return
	composure -= dmg
	if composure <= 0:
		layers_lost += 1
		composure = composure_per_layer
		apply_her(layers_lost)
		gs.see_stage(heroine_id, layers_lost)
		events.append({"kind": "strip", "stage": layers_lost})


## A learned signature shot aims itself at her goal; a ricochet uses the
## far wall so it has room to bank.
func _aim_player_signature() -> void:
	var me: PuckSim.Paddle = sim.paddle(0)
	if me.power_kind == "smash":
		return
	var H := PuckSim.H
	var R := PuckSim.PUCK_R
	var aim := Vector2(PuckSim.W + 30.0, H * 0.5)
	if me.power_kind == "ricochet":
		aim.y = 2.0 * R - aim.y if sim.puck_pos.y > H * 0.5 else 2.0 * (H - R) - aim.y
	me.power_aim = aim
