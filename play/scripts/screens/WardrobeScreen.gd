## WardrobeScreen.gd: pick each heroine's outfit. Outfits are cosmetic (no
## stat changes). Her default is free, her Date outfit comes from finishing
## her story, and the rest cost gems. Art for each outfit goes in
## art/heroines/<id>/<outfit id>/ (see docs/ART_LIST.md); until it exists
## the placeholder shows the outfit's colour.
class_name WardrobeScreen
extends Control

var main
var back: Callable
var sel := ""
var body: Control
var status: Control
var tabs: HBoxContainer


func _init(m, on_back: Callable) -> void:
	main = m
	back = on_back


func _ready() -> void:
	add_child(UI.background())
	var t := UI.label("Wardrobe", 38, UI.CYAN)
	t.position = Vector2(40, 18)
	add_child(t)
	tabs = HBoxContainer.new()
	tabs.position = Vector2(260, 24)
	tabs.add_theme_constant_override("separation", 10)
	add_child(tabs)
	var bk := UI.button("Back", back, 20, UI.LINE, "return")
	bk.position = Vector2(1150, 735)
	add_child(bk)
	for id in GameState.order():
		if sel == "" and GameState.is_unlocked(id):
			sel = id
	if sel == "":
		sel = GameState.order()[0]
	_refresh()


func _refresh() -> void:
	for c in tabs.get_children():
		c.queue_free()
	for id in GameState.order():
		var hid: String = id
		var b := UI.button(UI.first_name(hid), func():
			sel = hid
			_refresh(), 18, UI.hcolor(hid))
		b.toggle_mode = true
		b.button_pressed = hid == sel
		b.disabled = not GameState.is_unlocked(hid)
		tabs.add_child(b)
	if status:
		status.queue_free()
	status = UI.pin_top_right(UI.status_bar(Vector2.ZERO), 20, 80)
	add_child(status)
	if body:
		body.queue_free()
	# Scrolls sideways once event and season outfits push past four.
	body = ScrollContainer.new()
	body.position = Vector2(40, 140)
	body.size = Vector2(1200, 590)
	body.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(body)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	body.add_child(row)
	for o in GameState.outfits_of(sel):
		row.add_child(_card(o))


func _card(o: Dictionary) -> Control:
	var oid := String(o["id"])
	var owned := GameState.outfit_owned(sel, oid)
	var on := GameState.current_outfit(sel) == oid
	var col := UI.hcolor(sel)
	var p := UI.panel(UI.PANEL_2 if on else UI.PANEL, 16, UI.GOLD if on else col)
	p.custom_minimum_size = Vector2(286, 570)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	p.add_child(v)
	var por := HeroinePortrait.new(sel, 0, "stage")
	por.outfit = oid
	por.custom_minimum_size = Vector2(256, 400)
	if not owned:
		por.modulate = Color(0.6, 0.6, 0.65)
	v.add_child(por)
	v.add_child(UI.label(String(o.get("name", oid)), 22, col))
	if on:
		v.add_child(UI.label("Wearing", 18, UI.GOLD))
	elif owned:
		v.add_child(UI.button("Wear", func():
			GameState.set_outfit(sel, oid)
			_refresh(), 18, UI.CYAN))
	else:
		match String(o.get("unlock", "")):
			"story":
				v.add_child(UI.wrap_label("Win %s over (all 6 story matches) to unlock." % UI.first_name(sel), 15, UI.INK_SOFT))
			"event":
				v.add_child(UI.wrap_label("Prize for winning the %s event (it comes back around)." % String(o.get("event", "weekly")), 15, UI.INK_SOFT))
			"pass":
				v.add_child(UI.wrap_label("Season pass reward: %s." % String(o.get("season", "premium track")), 15, UI.INK_SOFT))
			"gems":
				var cost := int(o.get("gems", 0))
				var b := UI.button("%d" % cost, func():
					if GameState.buy_outfit(sel, oid):
						SFX.play("win")
						_refresh()
					else:
						main.show_store(main.show_wardrobe), 18, UI.GOLD, "gem")
				v.add_child(b)
				if GameState.gems < cost:
					v.add_child(UI.label("Not enough gems: tap to get more", 13, UI.INK_SOFT))
	return p


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_cancel"):
		back.call()
