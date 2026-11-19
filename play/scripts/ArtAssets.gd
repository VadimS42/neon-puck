## ArtAssets.gd
##
## The one place that knows where real art lives. Every lookup returns the
## texture if a file exists at that exact path, or null so the caller draws
## its placeholder. Dropping a correctly named PNG into res://art/... is the
## whole integration step. docs/ART_LIST.md lists every path and size.
class_name ArtAssets
extends RefCounted

const EXPRESSIONS := ["neutral", "happy", "shy", "surprised", "teasing", "sad", "angry"]


static func _try(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var r = load(path)
		if r is Texture2D:
			return r
	return null


## UI icon: res://art/ui/icons/<name>.png (Kenney CC0 icons from Charm Combo
## plus our own from tools/make_icons.py; see data/credits.txt).
static func icon(name: String) -> Texture2D:
	return _try("res://art/ui/icons/%s.png" % name)


## Her art in the outfit she's wearing: res://art/heroines/<id>/<outfit>/<file>
## for any outfit but "default", falling back to res://art/heroines/<id>/<file>.
## Pass outfit "" to use the one picked in the Wardrobe.
static func heroine_file(id: String, file: String, outfit: String = "") -> Texture2D:
	var o := outfit if outfit != "" else GameState.current_outfit(id)
	if o != "default":
		var t := _try("res://art/heroines/%s/%s/%s" % [id, o, file])
		if t:
			return t
	return _try("res://art/heroines/%s/%s" % [id, file])


## Match portrait at crack stage 0..3 (0 = cool and composed, 3 = she's
## completely lost her cool). Same outfit at every stage: only her
## expression and pose change. stage_<n>.png, falling back to lower stages.
static func stage(id: String, n: int, outfit: String = "") -> Texture2D:
	# Stay in her outfit if any stage of it exists, then the default outfit.
	var o := outfit if outfit != "" else GameState.current_outfit(id)
	if o != "default":
		for i in range(n, -1, -1):
			var t := _try("res://art/heroines/%s/%s/stage_%d.png" % [id, o, i])
			if t:
				return t
	for i in range(n, -1, -1):
		var t := _try("res://art/heroines/%s/stage_%d.png" % [id, i])
		if t:
			return t
	return null


## Dialogue sprite. vn_<expression>.png, then vn_neutral.png, then her
## stage_0 portrait.
static func vn(id: String, expression: String) -> Texture2D:
	var t := heroine_file(id, "vn_%s.png" % expression)
	if t:
		return t
	t = heroine_file(id, "vn_neutral.png")
	if t:
		return t
	return stage(id, 0)


## Roster card / Wardrobe preview. card.png, falling back to stage_0.
static func card(id: String, outfit: String = "") -> Texture2D:
	var t := heroine_file(id, "card.png", outfit)
	return t if t else stage(id, 0, outfit)


## Reward scene CG. res://art/scenes/<scene_id>.png
static func scene(scene_id: String) -> Texture2D:
	return _try("res://art/scenes/%s.png" % scene_id)


## res://art/bg/<name>.png (lounge, menu, street, bar, office)
static func background(name: String) -> Texture2D:
	return _try("res://art/bg/%s.png" % name)


## Table pieces: res://art/table/table.png (960x540 playfield), puck.png,
## paddle_player.png, paddle_<heroine id>.png
static func table(name: String) -> Texture2D:
	return _try("res://art/table/%s.png" % name)


static func ui(name: String) -> Texture2D:
	return _try("res://art/ui/%s.png" % name)
