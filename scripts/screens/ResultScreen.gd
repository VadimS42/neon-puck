## ResultScreen.gd: after any match. Shows the score, what you earned (XP,
## tips, level-ups and what they opened) and the buttons Main hands it:
## continue to her story beat, rematch, next cup round, and so on.
class_name ResultScreen
extends Control

var main
var heroine_id := ""
var match_index := 0
var rules: MatchRules
var ctx: Dictionary
var reward: Dictionary
## [[text, Callable, accent Color], ...]; the first one gets focus.
var buttons: Array


func _init(m, id: String, mi: int, r: MatchRules, context: Dictionary, rew: Dictionary, btns: Array) -> void:
	main = m
	heroine_id = id
	match_index = mi
	rules = r
	ctx = context
	reward = rew
	buttons = btns


func _ready() -> void:
	var won := rules.player_won
	var mode := String(ctx.get("mode", "story"))
	var h := GameState.heroine(heroine_id)
	add_child(UI.background())
	var por := HeroinePortrait.new(heroine_id, rules.layers_lost, "stage")
	por.position = Vector2(820, 60)
	por.size = Vector2(420, 660)
	add_child(por)
	add_child(UI.status_bar(Vector2(820, 14)))
	var v := VBoxContainer.new()
	v.position = Vector2(70, 40)
	v.custom_minimum_size = Vector2(700, 0)
	v.add_theme_constant_override("separation", 10)
	add_child(v)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 24)
	head.add_child(UI.label("You win!" if won else "%s wins" % UI.first_name(heroine_id), 50, UI.GOLD if won else UI.BAD))
	var sc := UI.label("%d : %d" % [rules.sim.paddle(0).score, rules.sim.paddle(1).score], 40, UI.INK)
	sc.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(sc)
	v.add_child(head)
	var stats := "Layers taken: %d / %d    Smash goals: %d    Bank goals: %d    Saves: %d    Her %s goals: %d" % [rules.layers_lost, rules.layer_count, rules.smash_goals, rules.bank_goals, rules.saves, String(h.get("signature_name", "")), rules.her_signature_goals]
	v.add_child(UI.wrap_label(stats, 17, UI.INK_SOFT))
	_reward_panel(v)
	if won and mode == "story":
		var scene: Dictionary = h["matches"][match_index].get("scene", {})
		v.add_child(UI.label("Scene unlocked: " + String(scene.get("title", "")), 22, UI.PINK))
		v.add_child(UI.label("%s now: %s" % [UI.first_name(heroine_id), GameState.attitude(heroine_id)], 20, UI.hcolor(heroine_id)))
		if GameState.story_done(heroine_id) and match_index == GameState.match_count(heroine_id) - 1:
			v.add_child(UI.label("You learned her %s! Pick it on the roster." % String(h.get("signature_name", "")), 19, UI.GOLD))
		else:
			var nl := GameState.match_level(heroine_id, match_index + 1)
			if nl > GameState.level:
				v.add_child(UI.label("Her next match needs level %d. Pickup games and cups get you there." % nl, 17, UI.INK_SOFT))
	elif mode == "finale":
		var f := GameState.finale()
		var rr := int(ctx.get("round", 0))
		if not won:
			v.add_child(UI.label("The rounds you've already won stay won. Go again.", 18, UI.INK_SOFT))
		elif rr >= f["rounds"].size() - 1:
			v.add_child(UI.label("LAST CALL CHAMPION!", 30, UI.PINK))
		else:
			v.add_child(UI.label("Round %d of %d cleared. Next up: %s." % [rr + 1, f["rounds"].size(), UI.first_name(String(f["rounds"][rr + 1]["id"]))], 20, UI.CYAN))
	elif mode == "cup":
		var c := GameState.cup(String(ctx.get("cup", "")))
		if not won:
			v.add_child(UI.label("Knocked out of the %s. Your round rewards are yours to keep." % String(c.get("name", "")), 18, UI.INK_SOFT))
		elif int(ctx.get("round", 0)) >= int(c.get("rounds", 3)) - 1:
			v.add_child(UI.label("%s champion! Scene unlocked: %s" % [String(c.get("name", "")), String(c.get("scene", {}).get("title", ""))], 22, UI.PINK))
		else:
			var opp: Array = GameState.cup_run.get("opponents", [])
			var nr := int(GameState.cup_run.get("round", 0))
			var nxt := UI.first_name(String(opp[nr])) if nr < opp.size() else "the final"
			v.add_child(UI.label("Round %d cleared. Next up: %s." % [int(ctx.get("round", 0)) + 1, nxt], 20, UI.CYAN))
	if not won:
		v.add_child(UI.wrap_label("Tip: " + String(h.get("signature_tip", "")), 17, UI.CYAN))
		v.add_child(UI.wrap_label("Every layer you take makes her slower or smaller. Gear from the Pro Shop and power-ups help too.", 16, UI.INK_SOFT))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	v.add_child(row)
	var first: Button
	for b in buttons:
		var btn := UI.button(String(b[0]), b[1], 22 if first == null else 18, b[2] if b.size() > 2 else UI.PINK)
		row.add_child(btn)
		if first == null:
			first = btn
	if first:
		first.call_deferred("grab_focus")


func _reward_panel(v: VBoxContainer) -> void:
	if reward.is_empty():
		return
	var p := UI.panel(UI.PANEL, 14, UI.GOLD)
	v.add_child(p)
	var g := GridContainer.new()
	g.columns = 3
	g.add_theme_constant_override("h_separation", 30)
	g.add_theme_constant_override("v_separation", 2)
	p.add_child(g)
	for l in reward.get("lines", []):
		g.add_child(UI.label(String(l[0]), 17, UI.INK_SOFT))
		g.add_child(UI.label("+%d XP" % int(l[1]), 17, UI.CYAN))
		g.add_child(UI.label("+%d tips" % int(l[2]), 17, UI.GOLD))
	g.add_child(UI.label("Total", 20, UI.INK))
	g.add_child(_count_up(UI.label("+0 XP", 20, UI.CYAN), int(reward.get("xp", 0)), "+%d XP"))
	g.add_child(_count_up(UI.label("+0 tips", 20, UI.GOLD), int(reward.get("tips", 0)), "+%d tips"))
	if int(reward.get("level_to", 1)) > int(reward.get("level_from", 1)):
		v.add_child(UI.label("Level %d" % int(reward["level_to"]), 30, UI.GOLD))
		var un: Array = reward.get("unlocks", [])
		if not un.is_empty():
			v.add_child(_unlock_cards(un))


## Ticks a reward label up from zero so the payout feels earned.
func _count_up(l: Label, to: int, fmt: String) -> Label:
	var tw := l.create_tween()
	tw.tween_interval(0.25)
	tw.tween_method(func(x: float): l.text = fmt % int(x), 0.0, float(to), 0.7).set_ease(Tween.EASE_OUT)
	return l


## Each unlock as its own small card, popping in one after another.
func _unlock_cards(un: Array) -> Control:
	var flow := HFlowContainer.new()
	flow.custom_minimum_size = Vector2(700, 0)
	flow.add_theme_constant_override("h_separation", 8)
	flow.add_theme_constant_override("v_separation", 8)
	var i := 0
	for u in un:
		var s := String(u)
		var kind := "New"
		var nm := s
		if s.contains(": "):
			kind = s.get_slice(": ", 0)
			nm = s.get_slice(": ", 1)
		elif s.contains(" match "):
			kind = "Match"
		elif s.ends_with("Cup"):
			kind = "Cup"
		elif s.contains("slot"):
			kind = "Upgrade"
		var col := UI.GOOD
		match kind:
			"Gear": col = UI.GOLD
			"Power-up": col = UI.CYAN
			"Match": col = UI.PINK
		var card := UI.panel(UI.PANEL_2, 10, col)
		var cv := VBoxContainer.new()
		cv.add_theme_constant_override("separation", 0)
		card.add_child(cv)
		cv.add_child(UI.label(kind.to_upper(), 12, col))
		cv.add_child(UI.label(nm, 17, UI.INK))
		card.modulate.a = 0.0
		card.scale = Vector2(0.8, 0.8)
		flow.add_child(card)
		var tw := card.create_tween()
		tw.tween_interval(0.9 + 0.12 * i)
		tw.tween_callback(func():
			card.pivot_offset = card.size / 2
			SFX.play("click"))
		tw.parallel().tween_property(card, "modulate:a", 1.0, 0.15)
		tw.parallel().tween_property(card, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		i += 1
	return flow
