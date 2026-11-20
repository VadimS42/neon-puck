## PuckSim.gd
##
## The whole air hockey table as plain math: no nodes, no rendering, no
## randomness. MatchScreen steps it every physics tick and draws it;
## tools/sim_test.gd steps it headless to check balance.
##
## Side 0 (you) defends the LEFT goal and shoots right. Side 1 (her) defends
## the RIGHT goal. Paddles are kinematic: you set `target` and the paddle
## moves toward it at up to `max_speed`, so a paddle's real velocity is what
## hits the puck. Shots are pure physics: where and how hard you hit is where
## the puck goes. Nothing is rolled.
##
## Things that happen (hits, goals, power shots) are appended to `events` as
## dictionaries; the screen drains them each frame.
class_name PuckSim
extends RefCounted

const W := 960.0
const H := 540.0
const GOAL_W := 230.0
const PUCK_R := 17.0
const PUCK_MAX := 1850.0
## Fraction of the puck's speed lost per second (air table: low).
const FRICTION := 0.22
const WALL_E := 0.9
const PADDLE_E := 0.85
const HEAT_MAX := 100.0
const SUBSTEPS := 4
## Pause after a goal before the puck is live again.
const GOAL_PAUSE := 1.3
## Slingshot signature: launch speed and how fast it picks up (px/s^2).
const SLING_START := 420.0
const SLING_ACCEL := 1900.0


class Paddle:
	var side := 0
	var pos := Vector2.ZERO
	var vel := Vector2.ZERO
	var target := Vector2.ZERO
	var radius := 38.0
	var max_speed := 2600.0
	## How fast the paddle can change velocity (px/s^2). Yours is high (it
	## follows the mouse); hers is lower, which is what fakes and banks beat.
	var max_accel := 40000.0
	var heat := 0.0
	## True once the meter was spent: the NEXT hit is a power shot.
	var armed := false
	## "smash" (yours: physics aims it), "bullet", "ricochet", "hook" (hers).
	var power_kind := "smash"
	## World point a signature shot is aimed at (hers only).
	var power_aim := Vector2.ZERO
	var score := 0
	var hit_cool := 0.0
	## Multiplies every meter gain (difficulty setting for your side).
	var heat_mult := 1.0
	## Gear: multiplies the puck speed your normal hits produce.
	var power_mult := 1.0
	## Gear: multiplies the speed (and cap) of your power shot.
	var smash_mult := 1.0


var puck_pos := Vector2(W * 0.5, H * 0.5)
var puck_vel := Vector2.ZERO
var paddles: Array = []
var last_hitter := -1
## Side whose power shot is in flight, or -1.
var powered := -1
var power_kind := ""
var hook_curv := 0.0
var hook_time := 0.0
## Puck speed cap; a geared power shot may lift it until the next hit.
var puck_cap := PUCK_MAX
## Table rules a special match can change (MatchMods): goal mouth width,
## puck top speed, friction, and static round bumpers [[pos, radius], ...].
var goal_w := GOAL_W
var puck_max := PUCK_MAX
var friction := FRICTION
var bumpers: Array = []
var bounces_since_hit := 0
var paused := 0.0
var time := 0.0
var slow_time := 0.0
var events: Array = []
## The largest puck speed reached this rally (for the "fast goal" bonus).
var rally_hits := 0


func _init() -> void:
	for s in 2:
		var p := Paddle.new()
		p.side = s
		paddles.append(p)
	reset_positions(0)


func paddle(side: int) -> Paddle:
	return paddles[side]


## Puts both paddles at home and the puck in front of `serve_side`.
func reset_positions(serve_side: int) -> void:
	var a: Paddle = paddles[0]
	var b: Paddle = paddles[1]
	a.pos = Vector2(90, H * 0.5)
	b.pos = Vector2(W - 90, H * 0.5)
	a.target = a.pos
	b.target = b.pos
	a.vel = Vector2.ZERO
	b.vel = Vector2.ZERO
	place_puck(serve_side)


func place_puck(serve_side: int) -> void:
	puck_pos = Vector2(W * (0.3 if serve_side == 0 else 0.7), H * 0.5)
	puck_vel = Vector2.ZERO
	powered = -1
	power_kind = ""
	hook_time = 0.0
	puck_cap = puck_max
	last_hitter = -1
	bounces_since_hit = 0
	rally_hits = 0


## Spends a full meter: the side's next hit becomes its power shot.
func arm(side: int) -> bool:
	var p: Paddle = paddles[side]
	if p.heat < HEAT_MAX or p.armed:
		return false
	p.heat = 0.0
	p.armed = true
	events.append({"kind": "armed", "side": side, "power": p.power_kind})
	return true


func step(dt: float) -> void:
	time += dt
	var h := dt / SUBSTEPS
	for i in SUBSTEPS:
		_move_paddles(h)
		if paused > 0.0:
			continue
		if _move_puck(h):
			break
	if paused > 0.0:
		paused -= dt
	# Unstick a puck that died where nobody is pushing it.
	if paused <= 0.0 and puck_vel.length() < 25.0:
		slow_time += dt
		if slow_time > 3.5:
			slow_time = 0.0
			var c := Vector2(W * 0.5, H * 0.5)
			puck_vel = (c - puck_pos).normalized() * 160.0
	else:
		slow_time = 0.0


func _bounds(p: Paddle) -> Rect2:
	var r := p.radius
	if p.side == 0:
		return Rect2(r, r, W * 0.5 - 2.0 * r, H - 2.0 * r)
	return Rect2(W * 0.5 + r, r, W * 0.5 - 2.0 * r, H - 2.0 * r)


func _move_paddles(h: float) -> void:
	for p: Paddle in paddles:
		var b := _bounds(p)
		var want := Vector2(clampf(p.target.x, b.position.x, b.end.x), clampf(p.target.y, b.position.y, b.end.y))
		var d := want - p.pos
		var dist := d.length()
		# Arrive: fastest speed that can still stop on the target.
		var top := minf(p.max_speed, sqrt(2.0 * p.max_accel * dist) + 1.0)
		var desired := d / dist * top if dist > 0.5 else Vector2.ZERO
		if dist / h < top:
			desired = d / h
		var dv := desired - p.vel
		var max_dv: float = p.max_accel * h
		if dv.length() > max_dv:
			dv = dv.normalized() * max_dv
		p.vel += dv
		var next := p.pos + p.vel * h
		var clamped := Vector2(clampf(next.x, b.position.x, b.end.x), clampf(next.y, b.position.y, b.end.y))
		if clamped.x != next.x:
			p.vel.x = 0.0
		if clamped.y != next.y:
			p.vel.y = 0.0
		p.pos = clamped
		p.hit_cool = maxf(0.0, p.hit_cool - h)


## Returns true when a goal ended the rally.
func _move_puck(h: float) -> bool:
	if powered >= 0 and power_kind == "hook" and hook_time > 0.0:
		hook_time -= h
		puck_vel = puck_vel.rotated(hook_curv * puck_vel.length() * h)
	if powered >= 0 and power_kind == "slingshot":
		# Leaves slow and keeps accelerating: meet it early or not at all.
		var sp := puck_vel.length()
		if sp > 1.0:
			puck_vel = puck_vel / sp * minf(sp + SLING_ACCEL * h, puck_cap)
	else:
		puck_vel *= maxf(0.0, 1.0 - friction * h)
	puck_pos += puck_vel * h
	_collide_walls()
	for p: Paddle in paddles:
		_collide_paddle(p)
	if puck_vel.length() > puck_cap:
		puck_vel = puck_vel.normalized() * puck_cap
	if puck_pos.x < -PUCK_R:
		_goal(1)
		return true
	if puck_pos.x > W + PUCK_R:
		_goal(0)
		return true
	return false


func _in_mouth(y: float) -> bool:
	return absf(y - H * 0.5) < goal_w * 0.5


func _collide_walls() -> void:
	var e := 1.0 if (powered >= 0 and power_kind == "ricochet") else WALL_E
	var bounced := false
	if puck_pos.y < PUCK_R:
		puck_pos.y = PUCK_R
		puck_vel.y = absf(puck_vel.y) * e
		bounced = true
	elif puck_pos.y > H - PUCK_R:
		puck_pos.y = H - PUCK_R
		puck_vel.y = -absf(puck_vel.y) * e
		bounced = true
	if not _in_mouth(puck_pos.y):
		if puck_pos.x < PUCK_R and puck_pos.x > -PUCK_R:
			puck_pos.x = PUCK_R
			puck_vel.x = absf(puck_vel.x) * e
			bounced = true
		elif puck_pos.x > W - PUCK_R and puck_pos.x < W + PUCK_R:
			puck_pos.x = W - PUCK_R
			puck_vel.x = -absf(puck_vel.x) * e
			bounced = true
	# Goal posts: points at the mouth's edges.
	var posts: Array = [[Vector2(0, H * 0.5 - goal_w * 0.5), 0.0], [Vector2(0, H * 0.5 + goal_w * 0.5), 0.0], [Vector2(W, H * 0.5 - goal_w * 0.5), 0.0], [Vector2(W, H * 0.5 + goal_w * 0.5), 0.0]]
	posts.append_array(bumpers)
	for pb: Array in posts:
		var post: Vector2 = pb[0]
		var rad: float = PUCK_R + float(pb[1])
		var d: Vector2 = puck_pos - post
		var dist := d.length()
		if dist < rad and dist > 0.001:
			var n := d / dist
			puck_pos = post + n * rad
			var vn := puck_vel.dot(n)
			if vn < 0.0:
				puck_vel -= (1.0 + e) * vn * n
			bounced = true
	if bounced:
		bounces_since_hit += 1
		if absf(puck_vel.length()) > 250.0:
			events.append({"kind": "wall", "speed": puck_vel.length()})


func _collide_paddle(p: Paddle) -> void:
	var d := puck_pos - p.pos
	var dist := d.length()
	var min_d: float = PUCK_R + p.radius
	if dist >= min_d or dist < 0.001:
		return
	var n := d / dist
	puck_pos = p.pos + n * min_d
	_unpin(p, min_d)
	var before := puck_vel
	var rel := puck_vel - p.vel
	var vn := rel.dot(n)
	if vn < 0.0:
		puck_vel = puck_vel - (1.0 + PADDLE_E) * vn * n
		if p.power_mult != 1.0 and p.hit_cool <= 0.0:
			puck_vel *= p.power_mult
	if p.hit_cool > 0.0:
		return
	p.hit_cool = 0.1
	_on_hit(p, before)


## A paddle pressing the puck into a wall squeezes it out along the wall
## (like a real table) instead of trapping it there.
func _unpin(p: Paddle, min_d: float) -> void:
	for pass_i in 2:
		if puck_pos.y < PUCK_R or puck_pos.y > H - PUCK_R:
			var wy := PUCK_R if puck_pos.y < PUCK_R else H - PUCK_R
			puck_pos.y = wy
			var dy := wy - p.pos.y
			var need := sqrt(maxf(0.0, min_d * min_d - dy * dy))
			var sx := signf(W * 0.5 - p.pos.x) if absf(puck_pos.x - p.pos.x) < 1.0 else signf(puck_pos.x - p.pos.x)
			if (puck_pos.x < 2.0 * PUCK_R and sx < 0.0) or (puck_pos.x > W - 2.0 * PUCK_R and sx > 0.0):
				sx = -sx
			puck_pos.x = p.pos.x + sx * (need + 0.5)
			puck_vel.x = sx * maxf(absf(puck_vel.x), p.vel.length() + 300.0)
		if not _in_mouth(puck_pos.y) and (puck_pos.x < PUCK_R or puck_pos.x > W - PUCK_R):
			var wx := PUCK_R if puck_pos.x < PUCK_R else W - PUCK_R
			puck_pos.x = wx
			var dx := wx - p.pos.x
			var need2 := sqrt(maxf(0.0, min_d * min_d - dx * dx))
			var sy := signf(H * 0.5 - p.pos.y) if absf(puck_pos.y - p.pos.y) < 1.0 else signf(puck_pos.y - p.pos.y)
			if (puck_pos.y < 2.0 * PUCK_R and sy < 0.0) or (puck_pos.y > H - 2.0 * PUCK_R and sy > 0.0):
				sy = -sy
			puck_pos.y = p.pos.y + sy * (need2 + 0.5)
			puck_vel.y = sy * maxf(absf(puck_vel.y), p.vel.length() + 300.0)


func _on_hit(p: Paddle, before: Vector2) -> void:
	var opp: Paddle = paddles[1 - p.side]
	# Stopping the other side's power shot.
	if powered >= 0 and powered != p.side:
		events.append({"kind": "power_saved", "side": p.side, "power": power_kind})
		p.heat = minf(HEAT_MAX, p.heat + 15.0 * p.heat_mult)
	powered = -1
	power_kind = ""
	hook_time = 0.0
	puck_cap = puck_max
	# A save: stopping a fast puck in your own third.
	var toward_own := (before.x < -800.0 and puck_pos.x < W * 0.33) if p.side == 0 else (before.x > 800.0 and puck_pos.x > W * 0.67)
	last_hitter = p.side
	bounces_since_hit = 0
	rally_hits += 1
	if p.armed:
		p.armed = false
		_launch_power(p)
		return
	var speed := puck_vel.length()
	var gain := clampf(speed / 140.0, 1.5, 9.0)
	if toward_own:
		gain += 5.0
		events.append({"kind": "save", "side": p.side})
	var was_full := p.heat >= HEAT_MAX
	p.heat = minf(HEAT_MAX, p.heat + gain * p.heat_mult)
	events.append({"kind": "hit", "side": p.side, "speed": speed})
	if not was_full and p.heat >= HEAT_MAX:
		events.append({"kind": "heat_full", "side": p.side})
	var _unused := opp


func _launch_power(p: Paddle) -> void:
	powered = p.side
	power_kind = p.power_kind
	var speed := puck_vel.length()
	var k := p.smash_mult
	puck_cap = puck_max * maxf(1.0, k)
	match p.power_kind:
		"smash":
			# Yours: the direction is whatever your hit made it. Only faster.
			var dir := puck_vel.normalized() if speed > 1.0 else Vector2(1, 0)
			if p.side == 1 and dir.x > 0.0:
				dir.x = -dir.x
			puck_vel = dir * clampf(maxf(speed * 1.6, 1650.0) * k, 0.0, puck_cap)
		"bullet":
			puck_vel = (p.power_aim - puck_pos).normalized() * 1650.0 * k
		"ricochet":
			puck_vel = (p.power_aim - puck_pos).normalized() * 1450.0 * k
		"slingshot":
			puck_vel = (p.power_aim - puck_pos).normalized() * SLING_START * k
		"hook":
			# Leaves at an angle off the goal line and bends back into the
			# mouth on a constant-curvature arc.
			var to_goal := p.power_aim - puck_pos
			var theta := 0.5
			var sgn := 1.0 if puck_pos.y > H * 0.5 else -1.0
			if p.side == 1:
				sgn = -sgn
			var chord := to_goal.length()
			var radius := chord / (2.0 * sin(theta))
			puck_vel = to_goal.normalized().rotated(-sgn * theta) * 1150.0
			hook_curv = sgn / radius
			hook_time = radius * 2.0 * theta / 1150.0 * 1.4
		_:
			pass
	events.append({"kind": "power_shot", "side": p.side, "power": power_kind})


func _goal(scorer: int) -> void:
	var p: Paddle = paddles[scorer]
	p.score += 1
	var info := {
		"kind": "goal",
		"scorer": scorer,
		"power": powered == scorer,
		"power_kind": power_kind if powered == scorer else "",
		"bank": last_hitter == scorer and bounces_since_hit > 0,
		"own_goal": last_hitter != scorer and last_hitter >= 0,
	}
	if not info["power"]:
		p.heat = minf(HEAT_MAX, p.heat + (22.0 if info["bank"] else 12.0) * p.heat_mult)
	events.append(info)
	place_puck(1 - scorer)
	paused = GOAL_PAUSE
