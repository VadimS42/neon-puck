## PreMatchScreen.gd: your loadout before a match. Pick power-ups from your
## bag (or buy one on the spot) up to your slot count; they're used up when
## the match starts. Also shows your gear bonuses and who you're facing.
class_name PreMatchScreen
extends Control

var main
var heroine_id := ""
var match_index := 0
var ctx: Dictionary
var chosen: Array = []
var list_box: VBoxContainer
var slots_lbl: Label
var status: Control


func _init(m, id: String, mi: int, context: Dictionary) -> void:
	main = m
	heroine_id = id
	match_index = mi
	ctx = context


func _ready() -> void:
	add_child(UI.background())
	var h := GameState.heroine(heroine_id)
	var col := UI.hcolor(heroine_id)
	var por := HeroinePortrait.new(heroine_id, 0, "stage")
	por.position = Vector2(40, 90)
	por.size = Vector2(380, 560)
	add_child(por)
	var t := UI.label("Loadout", 38, UI.PINK)
	t.position = Vector2(40, 18)
	add_child(t)
	var vs := UI.label("vs %s · %s" % [String(h.get("name", heroine_id)), _mode_text()], 20, col)
	vs.position = Vector2(44, 662)
	add_child(vs)
	var tip := UI.wrap_label(String(h.get("signature_tip", "")), 15, UI.INK_SOFT)
	tip.position = Vector2(44, 692)
	tip.size = Vector2(400, 40)
	add_child(tip)
	_status()
	var right := VBoxContainer.new()
	right.position = Vector2(460, 90)
	right.custom_minimum_size = Vector2(780, 0)
	right.add_theme_constant_override("separation", 10)
	add_child(right)
	slots_lbl = UI.label("", 22, UI.GOLD)
	right.add_child(slots_lbl)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(780, 470)
	right.add_child(scroll)
	list_box = VBoxContainer.new()
	list_box.add_theme_constant_override("separation", 8)
	scroll.add_child(list_box)
	right.add_child(UI.label(_gear_text(), 16, UI.INK_SOFT))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	right.add_child(row)
	var go := UI.button("Start match", _start, 26)
	row.add_child(go)
	row.add_child(UI.button("Pro Shop", func(): main.show_shop(func(): main.prematch(heroine_id, match_index, ctx)), 20, UI.GOLD))
	row.add_child(UI.button("Back", _back, 20, UI.LINE))
	_rebuild()
	go.call_deferred("grab_focus")


func _status() -> void:
	if status:
		status.queue_free()
	status = UI.status_bar(Vector2(760, 18))
	add_child(status)


func _mode_text() -> String:
	match String(ctx.get("mode", "story")):
		"pickup": return "pickup game, first to %d" % int(ctx.get("target", 5))
		"cup":
			var c := GameState.cup(String(ctx.get("cup", "")))
			return "%s round %d" % [String(c.get("name", "")), int(ctx.get("round", 0)) + 1]
		"replay": return "replay of match %d" % (match_index + 1)
		"finale": return "championship round %d" % (int(ctx.get("round", 0)) + 1)
	return "story match %d" % (match_index + 1)


func _gear_text() -> String:
	var g := GameState.gear_stats()
	var parts := []
	for k in ["speed", "size", "power", "heat", "smash"]:
		if float(g[k]) > 0.0:
			parts.append("%s +%d%%" % [k.capitalize(), int(g[k])])
	return "Gear: " + (", ".join(parts) if not parts.is_empty() else "starter gear (visit the Pro Shop)")


func _rebuild() -> void:
	for c in list_box.get_children():
		c.queue_free()
	var slots := GameState.powerup_slots()
	slots_lbl.text = "Power-ups: %d / %d slots used" % [chosen.size(), slots]
	for p in GameState.prog.get("powerups", []):
		var pid := String(p["id"])
		var locked := GameState.level < int(p.get("level", 1))
		var have := int(GameState.powerups.get(pid, 0))
		var on := chosen.has(pid)
		var panel := UI.panel(UI.PANEL_2 if on else UI.PANEL, 12, UI.GOLD if on else UI.LINE)
		list_box.add_child(panel)
		var r := HBoxContainer.new()
		r.add_theme_constant_override("separation", 12)
		panel.add_child(r)
		var info := VBoxContainer.new()
		info.custom_minimum_size = Vector2(470, 0)
		info.add_child(UI.label(String(p["name"]), 19, UI.INK if not locked else UI.INK_SOFT))
		info.add_child(UI.wrap_label(("Level %d. " % int(p["level"]) if locked else "") + String(p.get("desc", "")), 14, UI.INK_SOFT))
		r.add_child(info)
		var own := UI.label("x%d" % have, 18, UI.GOLD if have > 0 else UI.INK_SOFT)
		own.custom_minimum_size = Vector2(40, 0)
		own.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		r.add_child(own)
		var buy := UI.button("Buy %d" % int(p["price"]), func(): _buy(pid), 15, UI.GOLD)
		buy.disabled = locked or GameState.tips < int(p["price"])
		buy.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		r.add_child(buy)
		var use := UI.button("Remove" if on else "Use", func(): _toggle(pid), 15, UI.CYAN)
		use.disabled = locked or (not on and (have <= 0 or chosen.size() >= slots))
		use.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		r.add_child(use)


func _buy(pid: String) -> void:
	if GameState.buy_powerup(pid):
		if not chosen.has(pid) and chosen.size() < GameState.powerup_slots():
			chosen.append(pid)
		_status()
		_rebuild()


func _toggle(pid: String) -> void:
	if chosen.has(pid):
		chosen.erase(pid)
	elif chosen.size() < GameState.powerup_slots() and int(GameState.powerups.get(pid, 0)) > 0:
		chosen.append(pid)
	_rebuild()


func _start() -> void:
	var c := ctx.duplicate()
	c["powerups"] = GameState.use_powerups(chosen)
	main.play_match(heroine_id, match_index, c)


func _back() -> void:
	if String(ctx.get("mode", "")) == "cup":
		main.show_cups()
	else:
		main.show_roster()


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_cancel"):
		_back()
