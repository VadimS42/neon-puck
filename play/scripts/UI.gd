## UI.gd
##
## Shared look for every screen (all built in code, like Charm Combo): a
## dark neon palette and a few builders for labels, buttons and panels.
class_name UI
extends RefCounted

const BG := Color("#0E0A18")
const BG_2 := Color("#1A1230")
const PANEL := Color("#21173B")
const PANEL_2 := Color("#2C1F4D")
const INK := Color("#F6EEFF")
const INK_SOFT := Color("#B8A8D8")
const PINK := Color("#FF4F8B")
const CYAN := Color("#3FD7FF")
const GOLD := Color("#FFC94F")
const GOOD := Color("#5BE38F")
const BAD := Color("#FF6363")
const LINE := Color("#4A3A75")


const DISPLAY_FONT := preload("res://art/fonts/Bungee-Regular.ttf")
const BODY_FONT := preload("res://art/fonts/Barlow-SemiBold.ttf")
## Labels this size or bigger use the display face (titles, scores, banners).
const DISPLAY_MIN := 30


static func label(text: String, size: int = 20, color: Color = INK, align: int = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	if size >= DISPLAY_MIN:
		l.add_theme_font_override("font", DISPLAY_FONT)
	l.text = text
	l.horizontal_alignment = align
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


static func wrap_label(text: String, size: int = 18, color: Color = INK) -> Label:
	var l := label(text, size, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


static func box(color: Color, radius: int = 14, border: Color = Color(0, 0, 0, 0), border_w: int = 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(radius)
	if border_w > 0:
		s.border_color = border
		s.set_border_width_all(border_w)
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	return s


static func panel(color: Color = PANEL, radius: int = 16, border: Color = LINE) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", box(color, radius, border, 2))
	return p


static func button(text: String, cb: Callable, size: int = 22, accent: Color = PINK, icon_name: String = "") -> Button:
	var b := Button.new()
	b.text = text
	if icon_name != "":
		b.icon = ArtAssets.icon(icon_name)
		b.add_theme_constant_override("icon_max_width", size + 6)
		b.add_theme_constant_override("h_separation", 10)
	b.focus_mode = Control.FOCUS_ALL
	if size >= DISPLAY_MIN - 2:
		b.add_theme_font_override("font", DISPLAY_FONT)
	b.add_theme_font_size_override("font_size", size)
	b.resized.connect(func(): b.pivot_offset = b.size / 2)
	b.button_down.connect(func():
		b.create_tween().tween_property(b, "scale", Vector2(0.94, 0.94), 0.05))
	b.button_up.connect(func():
		b.create_tween().tween_property(b, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT))
	b.add_theme_color_override("font_color", INK)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_disabled_color", Color(INK_SOFT, 0.5))
	b.add_theme_stylebox_override("normal", box(PANEL_2, 12, accent, 2))
	b.add_theme_stylebox_override("hover", box(accent.darkened(0.35), 12, accent, 2))
	b.add_theme_stylebox_override("pressed", box(accent.darkened(0.5), 12, accent, 2))
	b.add_theme_stylebox_override("focus", box(Color(0, 0, 0, 0), 12, Color.WHITE, 2))
	b.add_theme_stylebox_override("disabled", box(PANEL, 12, LINE, 2))
	b.pressed.connect(func():
		SFX.play("click")
		cb.call())
	return b


static func fill(c: Control) -> Control:
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	if c is TextureRect:
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


static func background(color_a: Color = BG, color_b: Color = BG_2) -> Control:
	var tex := ArtAssets.background("lounge")
	if tex:
		var tr := TextureRect.new()
		tr.texture = tex
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tr.modulate = Color(0.55, 0.55, 0.6)
		return fill(tr)
	var g := Gradient.new()
	g.set_color(0, color_a)
	g.set_color(1, color_b)
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(0.4, 1)
	var tr2 := TextureRect.new()
	tr2.texture = gt
	tr2.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	return fill(tr2)


## A small icon next to text, or an empty spacer if the file is missing.
static func icon_rect(name: String, px: int = 32) -> TextureRect:
	var r := TextureRect.new()
	r.texture = ArtAssets.icon(name)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.custom_minimum_size = Vector2(px, px)
	r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


## Pins a control to the top-right corner: it grows to the left as its
## contents need, `right` px from the screen edge, `top` px down.
static func pin_top_right(c: Control, right: float, top: float) -> Control:
	c.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	c.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	c.offset_right = -right
	c.offset_top = top
	c.offset_left = -right
	return c


static func hcolor(id: String) -> Color:
	return Color(String(GameState.heroine(id).get("color", "#FF4F8B")))


static func first_name(id: String) -> String:
	return String(GameState.heroine(id).get("name", id)).split(" ")[0]


## Your level, XP, tips, gems and lives, for the top of hub screens. The
## lives count ticks up and shows the time to the next life.
static func status_bar(pos: Vector2) -> Control:
	var p := _StatusBar.new()
	p.add_theme_stylebox_override("panel", box(PANEL, 12, GOLD, 2))
	p.position = pos
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	p.add_child(h)
	h.add_child(label("Lv %d" % GameState.level, 20, GOLD))
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(70, 12)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.show_percentage = false
	var maxed := GameState.level >= GameState.max_level()
	bar.max_value = GameState.xp_to_next()
	bar.value = bar.max_value if maxed else GameState.xp
	bar.tooltip_text = "MAX" if maxed else "%d / %d XP" % [GameState.xp, GameState.xp_to_next()]
	bar.add_theme_stylebox_override("background", box(BG, 6, LINE, 1))
	var f := box(CYAN, 6)
	f.content_margin_top = 0
	f.content_margin_bottom = 0
	bar.add_theme_stylebox_override("fill", f)
	h.add_child(bar)
	h.add_child(icon_rect("coin", 28))
	h.add_child(label("%d" % GameState.tips, 20, GOLD))
	h.add_child(icon_rect("gem", 28))
	h.add_child(label("%d" % GameState.gems, 20, CYAN))
	h.add_child(icon_rect("life", 28))
	p.lives_lbl = label("", 20, PINK)
	h.add_child(p.lives_lbl)
	p.refresh()
	return p


class _StatusBar extends PanelContainer:
	var lives_lbl: Label
	var _t := 0.0

	func _process(d: float) -> void:
		_t += d
		if _t >= 0.5:
			_t = 0.0
			refresh()

	func refresh() -> void:
		if lives_lbl == null:
			return
		GameState.tick_lives()
		if GameState.has_unlimited():
			var left := GameState.unlimited_until - GameState.now()
			lives_lbl.text = "∞ %d:%02d" % [left / 3600, (left / 60) % 60]
		elif GameState.lives >= GameState.max_lives():
			lives_lbl.text = "%d full" % GameState.lives
		else:
			var s := GameState.seconds_to_next_life()
			lives_lbl.text = "%d  +1 in %d:%02d" % [GameState.lives, s / 60, s % 60]


## A modal card over the current screen: title, body text and buttons
## ([[text, Callable, accent], ...]). Every button closes it first. Returns
## the overlay so callers can add more to it.
static func popup(parent: Node, title: String, body: String, buttons: Array, accent: Color = PINK) -> Control:
	var o := ColorRect.new()
	o.color = Color(0, 0, 0, 0.7)
	o.set_anchors_preset(Control.PRESET_FULL_RECT)
	o.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(o)
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	o.add_child(c)
	var p := panel(PANEL, 20, accent)
	p.custom_minimum_size = Vector2(620, 0)
	c.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	p.add_child(v)
	v.add_child(label(title, 34, accent))
	if body != "":
		var b := wrap_label(body, 19)
		b.custom_minimum_size = Vector2(580, 0)
		v.add_child(b)
	var first: Button
	for bt in buttons:
		var cb: Callable = bt[1]
		var btn := button(String(bt[0]), func():
			o.queue_free()
			cb.call(), 20, bt[2] if bt.size() > 2 else accent, String(bt[3]) if bt.size() > 3 else "")
		btn.disabled = bt.size() > 4 and bool(bt[4])
		v.add_child(btn)
		if first == null and not btn.disabled:
			first = btn
	if first:
		first.call_deferred("grab_focus")
	return o


## A small card that slides in at the top right and fades (achievements).
static func toast(parent: Node, title: String, body: String, accent: Color = GOLD) -> void:
	var p := panel(PANEL_2, 12, accent)
	p.custom_minimum_size = Vector2(380, 0)
	p.position = Vector2(880, -120)
	p.z_index = 100
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	p.add_child(v)
	v.add_child(label(title, 16, accent))
	var b := wrap_label(body, 18)
	b.custom_minimum_size = Vector2(350, 0)
	v.add_child(b)
	parent.add_child(p)
	var tw := p.create_tween()
	tw.tween_property(p, "position:y", 20.0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(3.2)
	tw.tween_property(p, "modulate:a", 0.0, 0.4)
	tw.tween_callback(p.queue_free)
