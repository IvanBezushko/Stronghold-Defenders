extends Control





# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass



func _on_exit_bt_pressed() -> void:
	get_tree().change_scene_to_file("res://menu/menu.tscn")


func _on_quit_bt_pressed() -> void:
	get_tree().quit()




func _on_VSlider_value_changed(value):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), value)
	print("Głośność ustawiona na:", value, "dB")

	
	
