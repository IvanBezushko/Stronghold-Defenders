extends Control


func _on_play_but_pressed() -> void:
	get_tree().change_scene_to_file("res://menu/select.tscn")


func _on_settings_but_pressed() -> void:
	get_tree().change_scene_to_file("res://menu/settings.tscn")
	
	
func _ready():
	var global_music_player = get_node_or_null("/root/AudioStreamPlayer2d")
	if global_music_player and not global_music_player.playing:
		global_music_player.play()


func _on_quit_but_pressed() -> void:
	get_tree().quit()


func _on_achievements_pressed() -> void:
	get_tree().change_scene_to_file("res://menu/achiev.tscn")


func _on_tutorial_pressed() -> void:
	get_tree().change_scene_to_file("res://menu/tutorial.tscn")
