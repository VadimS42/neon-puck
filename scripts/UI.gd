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


static func label(text: String, size: int = 20, color: Color = INK, align: int = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
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
	b.add_theme_font_size_override("font_size", size)
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


static func hcolor(id: String) -> Color:
	return Color(String(GameState.heroine(id).get("color", "#FF4F8B")))


static func first_name(id: String) -> String:
	return String(GameState.heroine(id).get("name", id)).split(" ")[0]


## Your level, XP to the next level and tips, for the top of hub screens.
static func status_bar(pos: Vector2) -> Control:
	var p := panel(PANEL, 12, GOLD)
	p.position = pos
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	p.add_child(h)
	h.add_child(label("Lv %d" % GameState.level, 22, GOLD))
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(150, 14)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.show_percentage = false
	var maxed := GameState.level >= GameState.max_level()
	bar.max_value = GameState.xp_to_next()
	bar.value = bar.max_value if maxed else GameState.xp
	bar.add_theme_stylebox_override("background", box(BG, 6, LINE, 1))
	var f := box(CYAN, 6)
	f.content_margin_top = 0
	f.content_margin_bottom = 0
	bar.add_theme_stylebox_override("fill", f)
	h.add_child(bar)
	h.add_child(label("MAX" if maxed else "%d / %d XP" % [GameState.xp, GameState.xp_to_next()], 15, INK_SOFT))
	var coin := ArtAssets.icon("Coin")
	if coin:
		var ci := TextureRect.new()
		ci.texture = coin
		ci.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ci.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ci.custom_minimum_size = Vector2(36, 36)
		h.add_child(ci)
	h.add_child(label("%d tips" % GameState.tips, 22, GOLD))
	return p
