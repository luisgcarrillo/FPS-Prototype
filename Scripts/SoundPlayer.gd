extends Node


@onready var audio_stream_player = $AudioPlayers/AudioStreamPlayer
@onready var audio_players = $AudioPlayers

const pistolShot = preload("res://Audio/9mm Single.wav")
const shotgunShot = preload("res://Audio/sshotf1b.wav")
const arShot = preload("res://Audio/556 Single WAV.wav")
const uziShot = preload("res://Audio/22LR Single WAV.wav")
const rocketShot = preload("res://Audio/rocklf1a.wav")
const rocketTrail = preload("res://Audio/rockfly.wav")
const explosion = preload("res://Audio/rocklx1a.wav")
const outOfAmmo = preload("res://Audio/noammo.wav")
const batHit1 = preload("res://Audio/metalbaseballHit1.wav")
const batHit2 = preload("res://Audio/metalbaseballHit2.wav")


func play_sound(sound):
	for audioStreamPlayer in audio_players.get_children():
		if not audioStreamPlayer.playing:
			audioStreamPlayer.stream = sound
			audioStreamPlayer.play()
			break

