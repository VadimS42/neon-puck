## AIBrain.gd
##
## Drives one paddle. Written once in "her" frame (defending the right goal,
## shooting left) and mirrored for side 0, so the same brain also plays as
## the test bot in tools/sim_test.gd.
##
## Fairness rules, since "the AI returns everything" was the top complaint
## about the game this one learns from:
##   - She sees the puck `reaction` seconds late (a history buffer), so fast
##     shots and sharp banks really do beat her.
##   - Her paddle has a top speed and a size, both shown on screen, and each
##     outfit layer she loses lowers one of them.
##   - Her signature shot is announced ("Mila readies BULLET") the moment she
##     arms it, and it is always the same shot, so you can learn to block it.
## The only randomness is which spot of your goal she aims at, from a seeded
## generator; your own shots are never rolled.
class_name AIBrain
extends RefCounted

var side := 1
## Seconds of lag between the puck's real state and what she reacts to.
var reaction := 0.14
## 0..1: how much she extrapolates the lagged puck forward (anticipation).
var anticipation := 0.5
## How far (px) her aim wanders from the middle of your goal.
var aim_spread := 55.0
## 0..1 chance a planned shot is a bank shot off a side wall.
var bank_pref := 0.25
## 0..1: how far up the table she guards when the puck is away.
var aggression := 0.4
## Seconds between her picking a new aim.
var replan_every := 0.9
var rng := RandomNumberGenerator.new()

var _history: Array = []
var _aim_y := 0.0
var _bank := 0
var _replan := 0.0


func setup(seed_value: int) -> void:
	rng.seed = seed_value
	_history.clear()


func _mx(v: Vector2) -> Vector2:
	return Vector2(PuckSim.W - v.x, v.y) if side == 0 else v


func _mv(v: Vector2) -> Vector2:
	return Vector2(-v.x, v.y) if side == 0 else v


func think(sim: PuckSim, dt: float) -> void:
	_history.append([sim.time, sim.puck_pos, sim.puck_vel])
	while _history.size() > 2 and _history[1][0] <= sim.time - reaction:
		_history.pop_front()
	var seen: Array = _history[0]
	var pp: Vector2 = seen[1] + seen[2] * reaction * anticipation
	var pv: Vector2 = seen[2]
	pp = _mx(pp)
	pv = _mv(pv)
	var me: PuckSim.Paddle = sim.paddle(side)
	var my_pos := _mx(me.pos)
	var r: float = me.radius
	var W := PuckSim.W
	var H := PuckSim.H
	var R := PuckSim.PUCK_R

	_replan -= dt
	if _replan <= 0.0:
		_replan = replan_every
		_aim_y = H * 0.5 + rng.randf_range(-aim_spread, aim_spread)
		_aim_y = clampf(_aim_y, H * 0.5 - PuckSim.GOAL_W * 0.4, H * 0.5 + PuckSim.GOAL_W * 0.4)
		_bank = 0
		if rng.randf() < bank_pref:
			_bank = 1 if rng.randf() < 0.5 else -1

	var home := Vector2(W - 85, H * 0.5)
	var target := home
	if sim.paused > 0.0:
		target = home
	else:
		var in_my_half := pp.x > W * 0.5 - R
		var incoming := pv.x > 140.0
		var dangerous := incoming and pv.x > 520.0
		if dangerous or (incoming and not in_my_half):
			var x_def := W - 80.0 - aggression * 60.0
			if pp.x > x_def:
				x_def = W - 60.0
			var y_hit := _predict_y(pp, pv, x_def)
			# Lean toward the middle of the goal when unsure.
			target = Vector2(x_def, lerpf(y_hit, H * 0.5, 0.15))
		elif in_my_half:
			target = _attack(pp, pv, my_pos, r)
			# Signature shot: arm it when she is about to strike.
			if me.heat >= PuckSim.HEAT_MAX and not me.armed:
				sim.arm(side)
		else:
			var guard_x := W - 110.0 - aggression * 120.0
			target = Vector2(guard_x, lerpf(H * 0.5, pp.y, 0.45))
	me.target = _mx(target)
	var aim := _aim_point()
	if me.power_kind == "ricochet":
		# Her signature always banks off the far wall: it has room to land.
		aim = Vector2(-30.0, 2.0 * R - _aim_y if pp.y > H * 0.5 else 2.0 * (H - R) - _aim_y)
	me.power_aim = _mx(aim)


func _aim_point() -> Vector2:
	var H := PuckSim.H
	var R := PuckSim.PUCK_R
	var y := _aim_y
	if _bank == 1:
		y = 2.0 * R - y
	elif _bank == -1:
		y = 2.0 * (H - R) - y
	return Vector2(-30.0, y)


func _attack(pp: Vector2, pv: Vector2, me: Vector2, r: float) -> Vector2:
	var R := PuckSim.PUCK_R
	var lead := pp + pv * 0.08
	var dir := (_aim_point() - lead).normalized()
	var contact := r + R
	var to_me := me - lead
	var along := to_me.dot(dir)
	var lateral := to_me.cross(dir)
	if along < -contact * 0.4 and absf(lateral) < r * 0.8:
		# Lined up behind the puck: drive through it.
		return lead + dir * 70.0
	var behind := lead - dir * (contact + 14.0)
	if along > -contact * 0.2:
		# In front of the puck: go around it, not through it.
		var perp := Vector2(-dir.y, dir.x)
		var sgn := 1.0 if lateral < 0.0 else -1.0
		return behind + perp * sgn * (contact + 10.0)
	return behind


static func _predict_y(p: Vector2, v: Vector2, x_line: float) -> float:
	var H := PuckSim.H
	var R := PuckSim.PUCK_R
	if absf(v.x) < 1.0:
		return p.y
	var t := (x_line - p.x) / v.x
	if t < 0.0:
		return p.y
	var y := p.y + v.y * t
	var span := H - 2.0 * R
	var m := fposmod(y - R, 2.0 * span)
	if m > span:
		m = 2.0 * span - m
	return m + R
