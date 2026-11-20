## ExtrasScreen.gd: "After Hours", everything off the main story path.
## Shot trainer, crossover scenes, achievements, and (where the game's
## data/extras.json has them) the Endless Ladder, dates, missions, the
## weekly event and the season pass. Shared by both games.
class_name ExtrasScreen
extends Control

var main


func _init(m) -> void:
	main = m


func _ready() -> void:
	add_child(UI.background())
	var t := UI.label("After Hours", 38, UI.CYAN)
	t.position = Vector2(40, 18)
	add_child(t)
	var sub := UI.label("Practice, side stories and challenges.", 18, UI.INK_SOFT)
	sub.position = Vector2(42, 66)
	add_child(sub)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(40, 104)
	scroll.size = Vector2(1200, 620)
	add_child(scroll)
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 20)
	scroll.add_child(cols)
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(590, 0)
	left.add_theme_constant_override("separation", 16)
	cols.add_child(left)
	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(590, 0)
	right.add_theme_constant_override("separation", 16)
	cols.add_child(right)
	var first := _trainer(left)
	_crossovers(left)
	_challenges(right)
	if not Extras.epilogues().is_empty():
		_dates(right)
	var back := UI.button("Back", main.show_roster, 20, UI.LINE, "return")
	back.position = Vector2(40, 735)
	add_child(back)
	(first if first else back).call_deferred("grab_focus")


func _card(parent: Control, title: String, body: String, col: Color) -> VBoxContainer:
	var p := UI.panel(UI.PANEL, 16, col)
	parent.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	p.add_child(v)
	v.add_child(UI.label(title, 24, col))
	if body != "":
		var b := UI.wrap_label(body, 16, UI.INK_SOFT)
		b.custom_minimum_size = Vector2(550, 0)
		v.add_child(b)
	return v


func _trainer(parent: Control) -> Button:
	var v := _card(parent, "Shot trainer", "Ten shots, no stakes. Block drill: she fires her signature every time she has the puck. Shooting drill: your power shot is always ready. Stop or score 6 of 10 to pass.", UI.CYAN)
	var first: Button
	for id in GameState.unlocked_heroines():
		var h := GameState.heroine(id)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var n := UI.label(UI.first_name(id), 18, UI.hcolor(id))
		n.custom_minimum_size = Vector2(90, 0)
		row.add_child(n)
		var hid: String = id
		var b := UI.button("Block her %s" % String(h.get("signature_name", "")), func(): main.start_trainer(hid, "block"), 16, UI.hcolor(id))
		row.add_child(b)
		row.add_child(UI.button("Shooting drill", func(): main.start_trainer(hid, "shoot"), 16, UI.LINE))
		v.add_child(row)
		if first == null:
			first = b
	v.add_child(UI.label("Drills passed: %d" % Extras.stat("trainer_passes"), 15, UI.INK_SOFT))
	return first


func _crossovers(parent: Control) -> void:
	var list := Extras.crossovers()
	if list.is_empty():
		return
	var v := _card(parent, "Crossovers", "They all know each other. Get far enough with two of them and they end up in the same room.", UI.PINK)
	var row := HFlowContainer.new()
	row.custom_minimum_size = Vector2(550, 0)
	row.add_theme_constant_override("h_separation", 8)
	row.add_theme_constant_override("v_separation", 8)
	v.add_child(row)
	for c in list:
		var ready := Extras.crossover_ready(c)
		var seen := Extras.seen.has("crossover_" + String(c["id"]))
		var cc: Dictionary = c
		var label := String(c.get("title", ""))
		if not ready:
			label = "%s + %s: %d wins with each" % [UI.first_name(String(c["a"])), UI.first_name(String(c["b"])), int(c.get("need", 3))]
		var b := UI.button(label + ("" if not ready else ("  (replay)" if seen else "  NEW")), func(): main.play_crossover(cc, main.show_extras), 16, UI.PINK if ready else UI.LINE)
		b.disabled = not ready
		row.add_child(b)


func _challenges(parent: Control) -> void:
	var v := _card(parent, "Challenges", "", UI.GOLD)
	var got := Extras.unlocked.size()
	var total := Extras.achievements().size()
	v.add_child(UI.button("Achievements (%d of %d)" % [got, total], func(): main.show_achievements(main.show_extras), 18, UI.GOLD, "trophy"))
	if not Extras.ladder_cfg().is_empty():
		var lv := VBoxContainer.new()
		v.add_child(lv)
		lv.add_child(UI.label("Endless Ladder", 20, UI.GOLD))
		var body := "Random rival, random special rules, and she gets sharper every rung. One loss ends the climb. Best: rung %d." % Extras.ladder_best
		var bl := UI.wrap_label(body, 16, UI.INK_SOFT)
		bl.custom_minimum_size = Vector2(550, 0)
		lv.add_child(bl)
		if Extras.ladder_open():
			var r := int(Extras.ladder_run.get("round", -1))
			var txt := "Start a climb" if Extras.ladder_run.is_empty() else "Continue: rung %d" % (r + 1)
			lv.add_child(UI.button(txt, main.start_ladder_round, 18, UI.GOLD))
		else:
			lv.add_child(UI.label("Opens after you win the championship.", 16, UI.LINE))
	if Extras.missions_enabled() and main.has_method("show_missions"):
		var n := Extras.missions_to_claim()
		v.add_child(UI.button("Daily missions" + (" (%d to collect)" % n if n > 0 else ""), func(): main.show_missions(main.show_extras), 18, UI.CYAN))
	if not Extras.current_event().is_empty() and main.has_method("show_event"):
		v.add_child(UI.button("Weekly event: " + String(Extras.current_event().get("name", "")), func(): main.show_event(main.show_extras), 18, UI.PINK))
	if Extras.season_enabled() and main.has_method("show_season"):
		var u := Extras.season_unclaimed()
		v.add_child(UI.button(String(Extras.season_cfg().get("name", "Season pass")) + (" (%d to claim)" % u if u > 0 else ""), func(): main.show_season(main.show_extras), 18, UI.GOLD))


func _dates(parent: Control) -> void:
	var v := _card(parent, "Date nights", "After the championship, each of them has one more night planned for you.", UI.PINK)
	for id in GameState.order():
		var e: Dictionary = Extras.epilogues().get(id, {})
		if e.is_empty():
			continue
		var ready := Extras.epilogue_ready(id)
		var hid: String = id
		var seen := Extras.seen.has("epilogue_" + id)
		var txt := String(e.get("title", "")) + ("  (replay)" if seen else "") if ready else "%s: win the championship and her story" % UI.first_name(id)
		var b := UI.button(txt, func(): main.play_epilogue(hid, main.show_extras), 16, UI.hcolor(id) if ready else UI.LINE)
		b.disabled = not ready
		v.add_child(b)


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_cancel"):
		main.show_roster()
