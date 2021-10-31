extends Node

func play_sfx(clip: AudioStream, volume: float = 0.0, pitch: float = 1.0) -> void:
	for player in $SFX.get_children():
		if !player.playing:
			player.stream = clip
			player.volume_db = volume
			player.pitch_scale = pitch
			player.play()
			break
	pass
