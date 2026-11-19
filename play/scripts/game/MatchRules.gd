## MatchRules.gd
##
## One match against one heroine: the table, her brain, the score and her
## outfit. MatchScreen drives it with your input and draws it; the headless
## test drives it with a bot. Both get the same rules.
##
## Her Cool (PG-13 build): she has `composure_per_layer` Cool points per
## crack. Every goal you score knocks off 1; a power smash goal knocks off a
## whole crack's worth at once. When it runs out she cracks (her expression
## and pose change, never her clothes), and that crack's stat drops.
## Her goals win back 1 Cool (never a crack). Internally the cracks are
## still called layers.
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
	composure_per_layer = int(h.get("composure", 2)) + int(gs.curve(id, mi).get("cool", 0))
	composure = composure_per_layer
	brain.side = 1
	brain.setup(hash(id) + mi * 7919)
	gs.apply_player(sim.paddle(0))
	sim.paddle(1).heat_mult = 0.6
	_apply_powerups(ctx.get("powerups", []))
	apply_her(0)


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
	sim.step(dt)
	for e in sim.events:
		_on_sim_event(e)
	sim.events.clear()


func _on_sim_event(e: Dictionary) -> void:
	events.append(e)
	match String(e.kind):
		"save":
			if e.side == 0:
				saves += 1
		"goal":
			if e.scorer == 0:
				if e.bank:
					bank_goals += 1
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
			if sim.paddle(0).score >= target or sim.paddle(1).score >= target:
				over = true
				player_won = sim.paddle(0).score >= target
				events.append({"kind": "match_over", "won": player_won})


## Revive after a loss (ad or gems): the match goes on with her pulled back
## to `back` points short of winning and your Heat full.
var revives := 0


func revive(back: int, full_heat: bool) -> void:
	over = false
	player_won = false
	revives += 1
	var her: PuckSim.Paddle = sim.paddle(1)
	her.score = maxi(0, target - maxi(1, back))
	if full_heat:
		sim.paddle(0).heat = PuckSim.HEAT_MAX
	sim.paused = maxf(sim.paused, 1.0)


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
