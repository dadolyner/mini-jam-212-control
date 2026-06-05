extends Node

##  `SoundManager.play("name")`

const _POOL_SIZE := 8
const _SOUND_DIR := "res://assets/Pixel Adventure/Sounds/"

const _FILES := {
	"convert_bad": "power_up.wav",   
	"convert_good": "coin.wav",     
}

var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0


func _ready() -> void:
	for key in _FILES:
		var stream = load(_SOUND_DIR + _FILES[key])
		if stream:
			_streams[key] = stream
		else:
			push_warning("SoundManager: could not load '%s'" % _FILES[key])

	for i in _POOL_SIZE:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)


func play(sound_name: String) -> void:
	if not _streams.has(sound_name):
		push_warning("SoundManager: unknown sound '%s'" % sound_name)
		return
	var player := _players[_next]
	_next = (_next + 1) % _POOL_SIZE
	player.stream = _streams[sound_name]
	player.play()
