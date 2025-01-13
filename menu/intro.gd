extends VideoStreamPlayer

func _ready():
	# Zatrzymaj globalny odtwarzacz muzyki
	if get_node_or_null("/root/AudioStreamPlayer2d"):
		get_node("/root/AudioStreamPlayer2d").stop()
	play()  # Rozpocznij odtwarzanie wideo





func _on_finished() -> void:
	get_tree().change_scene_to_file("res://menu/menu.tscn")
