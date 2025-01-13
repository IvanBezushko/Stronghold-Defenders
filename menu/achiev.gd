extends Control

@onready var enemy_death_icon = $ColorRect/enemy_death
@onready var boss_death_icon  = $ColorRect/boss_death
@onready var money_icon       = $ColorRect/money
@onready var time_icon        = $ColorRect/time

# Nasze "okienko" (ColorRect/Panel) na informację:
@onready var info_popup = $ColorRect/Info
# Label wewnątrz popupu
@onready var info_label = $ColorRect/Info/info_label

# -------------------------------------------------------------
#  Ładowanie statystyk z user://stat/stat.json
# -------------------------------------------------------------
func load_statistics_from_file(file_path: String) -> Array:
	if not FileAccess.file_exists(file_path):
		print("File does not exist: %s" % file_path)
		return []

	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		print("Failed to open file: %s" % file_path)
		return []

	var json_data = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_error: Error = json.parse(json_data)
	if parse_error != OK:
		print("Failed to parse JSON. Error: %s" % json.get_error_message())
		print("Error line: %d, position: %d" % [json.get_error_line(), json.get_error_column()])
		return []

	var result = json.get_data()
	if typeof(result) != TYPE_ARRAY:
		print("Unexpected JSON format. Expected an array, got: %s" % typeof(result))
		return []

	return result

func get_latest_stats() -> Dictionary:
	var stats_array = load_statistics_from_file("user://stat/stat.json")
	if stats_array.size() > 0:
		return stats_array[stats_array.size() - 1]  # Ostatni (najnowszy) zapis
	else:
		return {}

# -------------------------------------------------------------
#  Główne funkcje
# -------------------------------------------------------------
func _ready():
	# Aktualizujemy ikony osiągnięć na starcie
	update_achievement_icons()
	# Ukrywamy popup informacyjny
	info_popup.visible = false

	# Podłączamy sygnały (Godot 4):
	enemy_death_icon.connect("gui_input", Callable(self, "_on_enemy_icon_clicked"))
	boss_death_icon.connect("gui_input",  Callable(self, "_on_boss_icon_clicked"))
	money_icon.connect("gui_input",       Callable(self, "_on_money_icon_clicked"))
	time_icon.connect("gui_input",        Callable(self, "_on_time_icon_clicked"))

func update_achievement_icons():
	var stats = get_latest_stats()
	if stats.size() == 0:
		print("No stats found, skipping achievements update.")
		return

	var total_kills  = stats.get("total_enemies_killed", 0)
	var boss_count   = stats.get("boss_killed", 0)
	var total_money  = stats.get("total_cash_earned", 0)
	var time_played  = stats.get("time_played", 0)

	var kills_icon_path = get_enemy_kills_icon_path(total_kills)
	var boss_icon_path  = get_boss_icon_path(boss_count)
	var money_icon_path = get_money_icon_path(total_money)
	var time_icon_path  = get_time_icon_path(time_played)

	enemy_death_icon.texture = load(kills_icon_path)
	boss_death_icon.texture  = load(boss_icon_path)
	money_icon.texture       = load(money_icon_path)
	time_icon.texture        = load(time_icon_path)

	print("=== ACHIEVEMENTS UPDATED ===")
	print("enemy_kills_icon = %s (dla %d zabitych wrogów)" % [kills_icon_path, total_kills])
	print("boss_death_icon  = %s (dla %d pokonanych bossów)" % [boss_icon_path, boss_count])
	print("money_icon       = %s (dla %d zebranej kasy)" % [money_icon_path, total_money])
	print("time_icon        = %s (dla %d sekund gry)" % [time_icon_path, time_played])
	print("============================")

# -------------------------------------------------------------
#  Ikony / progi
# -------------------------------------------------------------
func get_enemy_kills_icon_path(kills: int) -> String:
	if kills < 10:
		return "res://icon/100px_dead1.png"
	elif kills < 50:
		return "res://icon/100px_dead2.png"
	else:
		return "res://icon/100px_dead3.png"

func get_boss_icon_path(boss_count: int) -> String:
	if boss_count == 0:
		return "res://icon/100px_crown1.png"
	elif boss_count <= 2:
		return "res://icon/100px_crown2.png"
	else:
		return "res://icon/100px_crown3.png"

func get_money_icon_path(money: int) -> String:
	if money < 500:
		return "res://icon/100px_money1.png"
	elif money < 2000:
		return "res://icon/100px_money2.png"
	else:
		return "res://icon/100px_money3.png"

func get_time_icon_path(play_time: int) -> String:
	if play_time < 30:
		return "res://icon/100px_time1.png"
	elif play_time < 120:
		return "res://icon/100px_time2.png"
	else:
		return "res://icon/100px_time3.png"

# -------------------------------------------------------------
#  Kliknięcia w ikony: pobieramy staty i wyświetlamy w panelu
# -------------------------------------------------------------
func _on_enemy_icon_clicked(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		info_popup.visible = true
		info_popup.position = Vector2(128, 476)  # Ustawienie stałej pozycji popupu

		var stats = get_latest_stats()
		var total_kills = stats.get("total_enemies_killed", 0)
		info_label.text = "Enemy killed: %d" % total_kills

func _on_boss_icon_clicked(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		info_popup.visible = true

		var stats = get_latest_stats()
		var boss_count = stats.get("boss_killed", 0)
		info_label.text = "Killed BOSS: %d " % boss_count

func _on_money_icon_clicked(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		info_popup.visible = true

		var stats = get_latest_stats()
		var total_money = stats.get("total_cash_earned", 0)
		info_label.text = "Cash: %d$" % total_money

func _on_time_icon_clicked(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		info_popup.visible = true

		var stats = get_latest_stats()
		var time_played = stats.get("time_played", 0)  # w sekundach

		# Zamiana sekund na godziny (z dwoma miejscami po przecinku):
		var hours = float(time_played) / 3600.0
		info_label.text = "Time: %.2f godzin" % hours

# -------------------------------------------------------------
#  Inne
# -------------------------------------------------------------
func _on_achiv_exit_pressed() -> void:
	get_tree().change_scene_to_file("res://menu/menu.tscn")

func _process(delta: float) -> void:
	pass
