## SFX.gd (autoload "SFX")
##
## Plays res://audio/sfx/<name>.ogg (or .wav) if the file exists; otherwise a
## short synthesized blip so the prototype has feedback. Dropping real sound
## files in with these names replaces the blips with no code changes:
## hit, wall, goal, goal_against, smash, strip, warn, click, win, lose.
extends Node

const RATE := 22050.0
const TONES := {
	"hit": [520.0, 0.04], "wall": [300.0, 0.03], "goal": [880.0, 0.25],
	"goal_against": [180.0, 0.3], "smash": [1200.0, 0.12], "strip": [990.0, 0.35],
	"warn": [640.0, 0.18], "click": [700.0, 0.03], "win": [1046.0, 0.5], "lose": [140.0, 0.5],
}
var enabled := true
var _players: Array = []
var _cache := {}


func _ready() -> void:
	for i in 6:
		var p := AudioStreamPlayer.new()
		p.volume_db = -8.0
		add_child(p)
		_players.append(p)


func play(name: String, pitch: float = 1.0) -> void:
	if not enabled or DisplayServer.get_name() == "headless":
		return
	var stream: AudioStream = _cache.get(name)
	if stream == null:
		for ext: String in [".ogg", ".wav"]:
			var path := "res://audio/sfx/" + name + ext
			if ResourceLoader.exists(path):
				stream = load(path)
				break
		if stream == null:
			stream = _tone(name)
		_cache[name] = stream
	for p: AudioStreamPlayer in _players:
		if not p.playing:
			p.stream = stream
			p.pitch_scale = pitch
			p.play()
			return


func _tone(name: String) -> AudioStreamWAV:
	var spec: Array = TONES.get(name, [600.0, 0.05])
	var freq: float = spec[0]
	var dur: float = spec[1]
	var n := int(RATE * dur)
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i in n:
		var t := float(i) / RATE
		var env := 1.0 - float(i) / float(n)
		var f := freq * (1.0 + (0.5 if name == "strip" else 0.0) * t / dur)
		var v := sin(TAU * f * t) * env * 0.5
		bytes.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = int(RATE)
	w.data = bytes
	return w
