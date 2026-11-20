## MissionsScreen.gd: today's three missions. Progress counts from the
## moment they were rolled (first look of the day); finish all three and
## collect the bonus. New set every day at midnight, same set for everyone.
class_name MissionsScreen
extends Control

var main
var back: Callable


func _init(m, on_back: Callable) -> void:
	main = m
	back = on_back


func _ready() -> void:
	add_child(UI.background())
	var t := UI.label("Daily missions", 38, UI.CYAN)
	t.position = Vector2(40, 18)
	add_child(t)
	var tm := Time.get_time_dict_from_system()
	var secs := 86400 - (int(tm.hour) * 3600 + int(tm.minute) * 60 + int(tm.second))
	var sub := UI.label("New missions in %dh %02dm. Every mission also gives season pass XP." % [secs / 3600, (secs % 3600) / 60], 18, UI.INK_SOFT)
	sub.position = Vector2(42, 66)
	add_child(sub)
	add_child(UI.pin_top_right(UI.status_bar(Vector2.ZERO), 20, 14))
	var v := VBoxContainer.new()
	v.position = Vector2(40, 120)
	v.custom_minimum_size = Vector2(1200, 0)
	v.add_theme_constant_override("separation", 14)
	add_child(v)
	var first: Button
	for m in Extras.todays_missions():
		var p := UI.panel(UI.PANEL, 14, UI.CYAN)
		v.add_child(p)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 16)
		p.add_child(h)
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(col)
		col.add_child(UI.label(String(m.get("text", "")), 24, UI.INK))
		var n := int(m.get("n", 1))
		var bar := ProgressBar.new()
		bar.max_value = n
		bar.value = Extras.mission_progress(m)
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(700, 16)
		bar.add_theme_stylebox_override("background", UI.box(UI.BG, 6, UI.LINE, 1))
		var f := UI.box(UI.CYAN, 6)
		f.content_margin_top = 0
		f.content_margin_bottom = 0
		bar.add_theme_stylebox_override("fill", f)
		col.add_child(bar)
		col.add_child(UI.label("%d / %d    Reward: %s" % [Extras.mission_progress(m), n, GameState.describe(m.get("reward", {}))], 16, UI.INK_SOFT))
		var mm: Dictionary = m
		var b: Button
		if Extras.mission_claimed(m):
			b = UI.button("Collected", func(): pass, 20, UI.LINE)
			b.disabled = true
		else:
			b = UI.button("Collect", func():
				Extras.claim_mission(mm)
				SFX.play("win")
				main.show_missions(back), 20, UI.GOLD, "coin")
			b.disabled = not Extras.mission_done(m)
		b.custom_minimum_size = Vector2(200, 60)
		h.add_child(b)
		if first == null and not b.disabled:
			first = b
	var bonus: Dictionary = Extras.mission_cfg().get("bonus", {})
	if not bonus.is_empty():
		var done := bool(Extras.missions.get("bonus", false))
		var bb := UI.button("Bonus collected" if done else "All three done: collect %s" % GameState.describe(bonus), func():
			Extras.claim_mission_bonus()
			SFX.play("win")
			main.show_missions(back), 22, UI.GOLD, "trophy")
		bb.disabled = done or not Extras.all_missions_claimed()
		v.add_child(bb)
		if first == null and not bb.disabled:
			first = bb
	var bk := UI.button("Back", back, 20, UI.LINE, "return")
	bk.position = Vector2(40, 735)
	add_child(bk)
	(first if first else bk).call_deferred("grab_focus")


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_cancel"):
		back.call()
