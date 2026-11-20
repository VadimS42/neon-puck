## MatchMods.gd
##
## Special-rule matches. A match, cup round, ladder round or event can carry
## "mods": ["bumpers", "rush"]; MatchRules applies them at setup and asks
## here how goals and the clock behave. Everything stays deterministic: a
## mod changes the table or the scoring, never adds dice.
##
## Shared by both games (same file in play/).
class_name MatchMods
extends RefCounted

## id -> {name, desc}. Order is the order they're listed in.
const DEFS := {
	"big_goals": {"name": "Wide Goals", "desc": "Both goal mouths are a third wider. Goals come fast."},
	"mini_goals": {"name": "Mini Goals", "desc": "Both goal mouths are a quarter narrower. Aim matters."},
	"bumpers": {"name": "Trick Table", "desc": "Two round bumpers on the centre line deflect the puck."},
	"turbo": {"name": "Turbo Air", "desc": "Less friction and a higher top speed. The puck never settles."},
	"bank_double": {"name": "Bank Night", "desc": "Your bank-shot goals count double."},
	"rush": {"name": "Rush Clock", "desc": "Two minutes on the clock. Lead when it runs out, or the next goal wins."},
	"blackout": {"name": "Blackout", "desc": "The table lights die. The puck only shows near the rails and paddles."},
	"handicap": {"name": "Handicap", "desc": "Your paddle is a fifth smaller."},
	"no_heat": {"name": "By the Book", "desc": "No Heat and no power shots for either of you. Pure hockey."},
}

const RUSH_SECONDS := 120.0


static func def(id: String) -> Dictionary:
	return DEFS.get(id, {"name": id, "desc": ""})


static func names(mods: Array) -> String:
	var out := []
	for m in mods:
		out.append(String(def(String(m)).get("name", m)))
	return ", ".join(out)


static func describe(mods: Array) -> String:
	var out := []
	for m in mods:
		var d := def(String(m))
		out.append("%s: %s" % [d.get("name", m), d.get("desc", "")])
	return "\n".join(out)


## Called at the end of MatchRules.setup (after power-ups).
static func apply(rules: MatchRules) -> void:
	var sim: PuckSim = rules.sim
	for m in rules.mods:
		match String(m):
			"big_goals":
				sim.goal_w = PuckSim.GOAL_W * 1.33
			"mini_goals":
				sim.goal_w = PuckSim.GOAL_W * 0.75
			"bumpers":
				sim.bumpers = [[Vector2(PuckSim.W * 0.5, PuckSim.H * 0.24), 24.0], [Vector2(PuckSim.W * 0.5, PuckSim.H * 0.76), 24.0]]
			"turbo":
				sim.friction = PuckSim.FRICTION * 0.35
				sim.puck_max = PuckSim.PUCK_MAX * 1.15
				sim.puck_cap = sim.puck_max
			"rush":
				rules.clock = RUSH_SECONDS
			"handicap":
				sim.paddle(0).radius *= 0.8
			"no_heat":
				for side in 2:
					sim.paddle(side).heat = 0.0
					sim.paddle(side).heat_mult = 0.0


## Extra points a goal of yours is worth on top of the usual 1.
static func bonus_points(rules: MatchRules, e: Dictionary) -> int:
	if e.scorer == 0 and e.bank and rules.mods.has("bank_double"):
		return 1
	return 0
