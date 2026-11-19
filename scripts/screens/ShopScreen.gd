## ShopScreen.gd: the Pro Shop. Gear (paddle, glove, sneakers, lucky charm)
## is bought once and equipped for good; power-ups are one-match
## consumables you stock up on. Everything costs tips and some items need a
## level. Prices and stats live in data/progression.json.
class_name ShopScreen
extends Control

var main
var back: Callable
var tab := "gear"
var body: Control
var status: Control
var tab_btns := {}


func _init(m, on_back: Callable) -> void:
	main = m
	back = on_back


func _ready() -> void:
	add_child(UI.background())
	var t := UI.label("Pro Shop", 38, UI.GOLD)
	t.position = Vector2(40, 18)
	add_child(t)
	var tabs := HBoxContainer.new()
	tabs.position = Vector2(260, 24)
	tabs.add_theme_constant_override("separation", 10)
	add_child(tabs)
	for k in [["gear", "Gear"], ["powerups", "Power-ups"]]:
		var key: String = k[0]
		var b := UI.button(k[1], func(): _tab(key), 18, UI.CYAN)
		b.toggle_mode = true
		tabs.add_child(b)
		tab_btns[key] = b
	var bk := UI.button("Back", back, 20, UI.LINE)
	bk.position = Vector2(1150, 735)
	add_child(bk)
	_tab("gear")
	(tab_btns["gear"] as Button).call_deferred("grab_focus")


func _tab(k: String) -> void:
	tab = k
	for key in tab_btns:
		(tab_btns[key] as Button).button_pressed = key == k
	_refresh()


func _refresh() -> void:
	if status:
		status.queue_free()
	status = UI.status_bar(Vector2(760, 18))
	add_child(status)
	if body:
		body.queue_free()
	if tab == "gear":
		body = _gear()
	else:
		body = _powerups()
	body.position = Vector2(40, 90)
	add_child(body)


func _gear() -> Control:
	var wrap := VBoxContainer.new()
	wrap.add_theme_constant_override("separation", 8)
	var g := GameState.gear_stats()
	var parts := []
	for k in ["speed", "size", "power", "heat", "smash"]:
		parts.append("%s +%d%%" % [k.capitalize(), int(g[k])])
	wrap.add_child(UI.label("Your bonuses: " + "   ".join(parts), 17, UI.INK_SOFT))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	wrap.add_child(row)
	for slot in GameState.prog.get("gear_slots", []):
		var sid := String(slot["id"])
		var col := VBoxContainer.new()
		col.custom_minimum_size = Vector2(290, 0)
		col.add_theme_constant_override("separation", 6)
		row.add_child(col)
		col.add_child(UI.label(String(slot["name"]), 22, UI.CYAN))
		for item in GameState.prog.get("gear", []):
			if String(item["slot"]) != sid:
				continue
			col.add_child(_gear_card(item))
	return wrap


func _gear_card(item: Dictionary) -> Control:
	var gid := String(item["id"])
	var owned := GameState.owned_gear.has(gid)
	var on := String(GameState.equipped.get(String(item["slot"]), "")) == gid
	var locked := GameState.level < int(item.get("level", 1))
	var p := UI.panel(UI.PANEL_2 if on else UI.PANEL, 12, UI.GOLD if on else UI.LINE)
	p.custom_minimum_size = Vector2(290, 104)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	p.add_child(v)
	v.add_child(UI.label("%s  %s" % [String(item["name"]), "★".repeat(int(item.get("tier", 1)))], 17, UI.INK if not locked else UI.INK_SOFT))
	var st: Dictionary = item.get("stats", {})
	var parts := []
	for k in st:
		parts.append("%s +%d%%" % [String(k).capitalize(), int(st[k])])
	v.add_child(UI.label(", ".join(parts) if not parts.is_empty() else "No bonus", 14, UI.INK_SOFT))
	if on:
		v.add_child(UI.label("Equipped", 15, UI.GOLD))
	elif owned:
		v.add_child(UI.button("Equip", _equip.bind(gid), 14, UI.CYAN))
	elif locked:
		v.add_child(UI.label("Level %d · %d tips" % [int(item["level"]), int(item["price"])], 15, UI.INK_SOFT))
	else:
		var b := UI.button("Buy · %d tips" % int(item["price"]), _buy_gear.bind(gid), 14, UI.GOLD)
		b.disabled = GameState.tips < int(item["price"])
		v.add_child(b)
	return p


func _powerups() -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	v.add_child(UI.label("One-match boosts. You can bring %d into a match at your level (more at levels 3 and 8)." % GameState.powerup_slots(), 17, UI.INK_SOFT))
	for p in GameState.prog.get("powerups", []):
		var pid := String(p["id"])
		var locked := GameState.level < int(p.get("level", 1))
		var panel := UI.panel(UI.PANEL, 12, UI.LINE)
		panel.custom_minimum_size = Vector2(1000, 0)
		v.add_child(panel)
		var r := HBoxContainer.new()
		r.add_theme_constant_override("separation", 16)
		panel.add_child(r)
		var info := VBoxContainer.new()
		info.custom_minimum_size = Vector2(650, 0)
		info.add_child(UI.label(String(p["name"]), 19, UI.INK if not locked else UI.INK_SOFT))
		info.add_child(UI.label(String(p.get("desc", "")), 14, UI.INK_SOFT))
		r.add_child(info)
		var own := UI.label("Owned x%d" % int(GameState.powerups.get(pid, 0)), 17, UI.GOLD)
		own.custom_minimum_size = Vector2(110, 0)
		own.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		r.add_child(own)
		if locked:
			r.add_child(UI.label("Level %d" % int(p["level"]), 17, UI.INK_SOFT))
		else:
			var b := UI.button("Buy · %d tips" % int(p["price"]), _buy_powerup.bind(pid), 15, UI.GOLD)
			b.disabled = GameState.tips < int(p["price"])
			b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			r.add_child(b)
	return v


func _equip(gid: String) -> void:
	GameState.equip(gid)
	_refresh()


func _buy_gear(gid: String) -> void:
	if GameState.buy_gear(gid):
		SFX.play("win")
		_refresh()


func _buy_powerup(pid: String) -> void:
	if GameState.buy_powerup(pid):
		_refresh()


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_cancel"):
		back.call()
