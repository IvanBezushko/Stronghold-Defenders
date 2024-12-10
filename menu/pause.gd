extends Control

var is_game_paused: bool = false  # Zmienna do kontroli stanu pauzy

func _ready():
	is_game_paused = false
	get_tree().paused = false  # Upewnij się, że pauza jest wyłączona
	self.visible = false
	print("Game started. Paused state:", is_game_paused)

func resume():
	is_game_paused = false
	get_tree().paused = false  # Wyłączenie globalnej pauzy
	self.visible = false
	print("Resuming game. Paused state:", is_game_paused)

func pause():
	is_game_paused = true
	get_tree().paused = true  # Włączenie globalnej pauzy
	self.visible = true
	print("Pausing game. Paused state:", is_game_paused)

func Esc():
	if Input.is_action_just_pressed("escape"):
		print("ESC pressed. Current paused state:", is_game_paused)
		if is_game_paused:
			print("Calling resume from Esc")
			resume()
		else:
			print("Calling pause from Esc")
			pause()

func _on_resume_bt_pressed() -> void:
	resume()

func _on_settings_bt_pressed() -> void:
	get_tree().paused = false  # Wyłączenie pauzy przed zmianą sceny
	get_tree().change_scene_to_file("res://menu/settings.tscn")

func _on_exit_bt_pressed() -> void:
	get_tree().paused = false  # Wyłączenie pauzy przed powrotem do menu głównego
	get_tree().change_scene_to_file("res://menu/menu.tscn")
	
func _unhandled_input(event):
	if event.is_action_pressed("escape"):
		Esc()


func _on_v_slider_value_changed(_value: float) -> void:
	pass # Replace with function body.
