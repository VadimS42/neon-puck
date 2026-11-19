## StoreScreen.gd: real-money products (gem packs, Starter Pack, Remove
## Ads, VIP Lounge Pass), gems-for-tips swaps, and life refills. Prices come
## from Google Play when the billing plugin is in; otherwise the test store
## grants everything for free and says so. Products live in
## data/monetization.json.
class_name StoreScreen
extends Control

var main
var back: Callable
var body: Control
var status: Control
var note: Label


func _init(m, on_back: Callable) -> void:
	main = m
	back = on_back


func _ready() -> void:
	add_child(UI.background())
	var t := UI.label("Store", 38, UI.GOLD)
	t.position = Vector2(40, 18)
	add_child(t)
	note = UI.label("", 17, UI.GOOD)
	note.position = Vector2(44, 70)
	add_child(note)
	if Store.is_test():
		note.text = "Test store: purchases are free and marked TEST until Google Play Billing is in the build."
		note.add_theme_color_override("font_color", UI.GOLD)
	var bk := UI.button("Back", back, 20, UI.LINE, "return")
	bk.position = Vector2(1150, 735)
	add_child(bk)
	Store.purchase_finished.connect(_on_purchase)
	Store.prices_updated.connect(_refresh)
	_refresh()
	bk.call_deferred("grab_focus")


func _exit_tree() -> void:
	if Store.purchase_finished.is_connected(_on_purchase):
		Store.purchase_finished.disconnect(_on_purchase)
	if Store.prices_updated.is_connected(_refresh):
		Store.prices_updated.disconnect(_refresh)


func _refresh() -> void:
	if status:
		status.queue_free()
	status = UI.pin_top_right(UI.status_bar(Vector2.ZERO), 20, 18)
	add_child(status)
	if body:
		body.queue_free()
	body = VBoxContainer.new()
	body.add_theme_constant_override("separation", 12)
	body.position = Vector2(40, 104)
	add_child(body)
	# Gem packs.
	body.add_child(UI.label("Gems", 24, UI.CYAN))
	var gr := HBoxContainer.new()
	gr.add_theme_constant_override("separation", 12)
	body.add_child(gr)
	var specials := []
	for p in GameState.f2p.get("products", []):
		if String(p.get("type", "")) == "consumable":
			gr.add_child(_gem_card(p))
		else:
			specials.append(p)
	# Packs and passes.
	body.add_child(UI.label("Packs", 24, UI.PINK))
	var pr := HBoxContainer.new()
	pr.add_theme_constant_override("separation", 12)
	body.add_child(pr)
	for p in specials:
		pr.add_child(_pack_card(p))
	# Spend gems.
	body.add_child(UI.label("Spend gems", 24, UI.GOLD))
	var sr := HBoxContainer.new()
	sr.add_theme_constant_override("separation", 12)
	body.add_child(sr)
	for o in GameState.f2p.get("gem_shop", []):
		var oid := String(o["id"])
		var b := UI.button("%s: %d tips · %d gems" % [String(o["name"]), int(o["tips"]), int(o["gems"])], func():
			if GameState.buy_gem_offer(oid):
				SFX.play("win")
				_refresh(), 16, UI.GOLD, "coin")
		b.disabled = GameState.gems < int(o["gems"])
		sr.add_child(b)
	var lc := GameState.lives_cfg()
	var rf := UI.button("Refill lives · %d gems" % int(lc.get("refill_gems", 30)), func():
		if GameState.buy_life_refill():
			SFX.play("win")
		_refresh(), 16, UI.PINK, "life")
	rf.disabled = GameState.gems < int(lc.get("refill_gems", 30)) or GameState.lives >= GameState.max_lives()
	sr.add_child(rf)
	body.add_child(UI.wrap_label("No loot boxes and no random rewards for money: you always see exactly what you get. Outfits are cosmetic. Purchases need a parent's permission if you're under 18.", 15, UI.INK_SOFT))


func _gem_card(p: Dictionary) -> Control:
	var pid := String(p["id"])
	var c := UI.panel(UI.PANEL, 14, UI.CYAN)
	c.custom_minimum_size = Vector2(285, 150)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	c.add_child(v)
	var top := HBoxContainer.new()
	var art := ArtAssets.ui("store/" + pid)
	if art:
		var tr := TextureRect.new()
		tr.texture = art
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.custom_minimum_size = Vector2(64, 48)
		top.add_child(tr)
	else:
		top.add_child(UI.icon_rect("gem", 40))
	top.add_child(UI.label("%d" % int(p.get("gems", 0)), 30, UI.CYAN))
	v.add_child(top)
	v.add_child(UI.label(String(p.get("name", pid)) + ("  · " + String(p["tag"]) if p.has("tag") else ""), 16, UI.INK_SOFT))
	v.add_child(UI.button(Store.price(pid), func(): _buy(pid), 20, UI.GOLD))
	return c


func _pack_card(p: Dictionary) -> Control:
	var pid := String(p["id"])
	var owned := not Store.can_buy(pid)
	var c := UI.panel(UI.PANEL_2 if owned else UI.PANEL, 14, UI.PINK)
	c.custom_minimum_size = Vector2(385, 170)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	c.add_child(v)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	var art := ArtAssets.ui("store/" + pid)
	if art:
		var tr := TextureRect.new()
		tr.texture = art
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.custom_minimum_size = Vector2(48, 36)
		head.add_child(tr)
	head.add_child(UI.label(String(p.get("name", pid)), 22, UI.PINK))
	v.add_child(head)
	var d := UI.wrap_label(String(p.get("desc", "")), 15, UI.INK_SOFT)
	d.custom_minimum_size = Vector2(355, 60)
	v.add_child(d)
	if owned:
		v.add_child(UI.label("Owned", 18, UI.GOOD))
	else:
		v.add_child(UI.button(Store.price(pid), func(): _buy(pid), 20, UI.GOLD))
	return c


func _buy(pid: String) -> void:
	note.text = "Opening Google Play..." if not Store.is_test() else "Processing test purchase..."
	Store.buy(pid)


func _on_purchase(_pid: String, ok: bool, message: String) -> void:
	note.text = message
	note.add_theme_color_override("font_color", UI.GOOD if ok else UI.BAD)
	if ok:
		SFX.play("win")
	_refresh()


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_cancel"):
		back.call()
