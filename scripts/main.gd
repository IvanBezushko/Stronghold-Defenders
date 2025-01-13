extends Node3D

@export var tile_start: PackedScene
@export var tile_end: PackedScene
@export var tile_straight: PackedScene
@export var tile_corner: PackedScene
@export var tile_crossroads: PackedScene
@export var tile_enemy: PackedScene
@export var tile_empty: Array[PackedScene]
@export var snow_tile: PackedScene
@export var tile_empty_easy: PackedScene
@export var tile_empty_hard: PackedScene
@export var tile_rock_snow: PackedScene
@export var tile_tree_snow: PackedScene
@export var tile_crystal_snow: PackedScene
@export var tile_start_snow: PackedScene
@export var tile_end_snow: PackedScene
@export var tile_straight_snow: PackedScene
@export var tile_corner_snow: PackedScene
@export var tile_crossroads_snow: PackedScene

@export var enemy: PackedScene
@export var cash: int = 150
var castle_health: int = 20

@export var enemy_type_1: PackedScene = preload("res://scenes/enemy_01.tscn")
@export var enemy_type_2: PackedScene = preload("res://scenes/enemy_02.tscn")
@export var enemy_type_3: PackedScene = preload("res://scenes/enemy_03.tscn")
@export var enemy_type_4: PackedScene = preload("res://scenes/enemy_04.tscn")
@export var boss_type: PackedScene = preload("res://scenes/enemy_BOSS.tscn")

@onready var cam = $Camera3D
var RAYCAST_LENGTH: float = 100
var selected_tower: Node3D = null
@onready var upgrade_panel = $Control/UIContainer/TowerUpgradePanel
var selection_instance: Node3D = null
@export var selection_frame: PackedScene

# Statystyki
var total_cash_earned: int = 0
var total_enemies_killed: int = 0
var time_elapsed: float = 0.0
var boss_killed: bool = false

# Konfiguracja fal przeciwników
var wave_config = [
	{"wave": 1, "enemy_type_1": 5, "enemy_type_2": 0, "enemy_type_3": 0, "enemy_type_4": 0, "boss_type": 0, "reward": 25},
	{"wave": 2, "enemy_type_1": 7, "enemy_type_2": 0, "enemy_type_3": 0, "enemy_type_4": 0, "boss_type": 0, "reward": 35},
	{"wave": 3, "enemy_type_1": 10, "enemy_type_2": 0, "enemy_type_3": 0, "enemy_type_4": 0, "boss_type": 0, "reward": 50},
	{"wave": 4, "enemy_type_1": 12, "enemy_type_2": 0, "enemy_type_3": 0, "enemy_type_4": 0, "boss_type": 0, "reward": 70},
	{"wave": 5, "enemy_type_1": 15, "enemy_type_2": 5, "enemy_type_3": 0, "enemy_type_4": 0, "boss_type": 0, "reward": 95},
	{"wave": 10, "enemy_type_1": 20, "enemy_type_2": 10, "enemy_type_3": 2, "enemy_type_4": 0, "boss_type": 0, "reward": 120},
	{"wave": 15, "enemy_type_1": 25, "enemy_type_2": 12, "enemy_type_3": 5, "enemy_type_4": 0, "boss_type": 0, "reward": 180},
	{"wave": 20, "enemy_type_1": 30, "enemy_type_2": 15, "enemy_type_3": 10, "enemy_type_4": 3, "boss_type": 0, "reward": 250},
	{"wave": 25, "enemy_type_1": 35, "enemy_type_2": 20, "enemy_type_3": 15, "enemy_type_4": 8, "boss_type": 0, "reward": 350},
	{"wave": 30, "enemy_type_1": 40, "enemy_type_2": 25, "enemy_type_3": 20, "enemy_type_4": 12, "boss_type": 0, "reward": 500},
	{"wave": 40, "enemy_type_1": 50, "enemy_type_2": 30, "enemy_type_3": 25, "enemy_type_4": 15, "boss_type": 0, "reward": 600},
	{"wave": 49, "enemy_type_1": 10, "enemy_type_2": 10, "enemy_type_3": 5, "enemy_type_4": 10, "boss_type": 1, "reward": 800},
	{"wave": 50, "enemy_type_1": 10, "enemy_type_2": 10, "enemy_type_3": 5, "enemy_type_4": 10, "boss_type": 1, "reward": 1000}
]

func _ready():
	PathGenInstance.reset()
	_complete_grid()
	upgrade_panel.visible = false

	var saved_stats = load_statistics_from_file("user://stat/stat.json")
	if saved_stats.size() > 0:
		print("Loaded statistics from user://:\n", format_json(saved_stats))
	else:
		print("No saved statistics found (user://).")

	for wave in wave_config:
		await _handle_wave(wave)

func _handle_wave(wave):
	for type_name in ["enemy_type_1", "enemy_type_2", "enemy_type_3", "enemy_type_4"]:
		var enemy_scene = null
		if type_name == "enemy_type_1":
			enemy_scene = enemy_type_1
		elif type_name == "enemy_type_2":
			enemy_scene = enemy_type_2
		elif type_name == "enemy_type_3":
			enemy_scene = enemy_type_3
		elif type_name == "enemy_type_4":
			enemy_scene = enemy_type_4

		if enemy_scene:
			for i in range(wave[type_name]):
				await get_tree().create_timer(2.5).timeout
				var enemy_instance = enemy_scene.instantiate()
				add_child(enemy_instance)
				enemy_instance.add_to_group("enemies")
				enemy_instance.connect("tree_exited", Callable(self, "_on_enemy_killed"))

	if wave["boss_type"] > 0:
		for i in range(wave["boss_type"]):
			await get_tree().create_timer(2.5).timeout
			var boss_instance = boss_type.instantiate()
			add_child(boss_instance)
			boss_instance.add_to_group("enemies")
			boss_instance.connect("tree_exited", Callable(self, "_on_enemy_killed"))

	await get_tree().create_timer(25.0).timeout





func _process(delta):
	time_elapsed += delta
	$Control/CashLabel.text = "Cash $%d" % cash


func _on_enemy_killed():
	if not is_inside_tree():
		print("Warning: Node is not inside the scene tree!")
		return

	var enemy_value = 0
	if get_node_or_null("../enemy_01"):
		enemy_value = 5
	elif get_node_or_null("../enemy_02"):
		enemy_value = 4
	elif get_node_or_null("../enemy_03"):
		enemy_value = 8
	elif get_node_or_null("../enemy_04"):
		enemy_value = 9
	elif get_node_or_null("../enemy_BOSS"):
		enemy_value = 500

	total_cash_earned += enemy_value
	total_enemies_killed += 1
	cash += enemy_value

	if get_tree().has_group("enemies"):
		var enemy_count = get_tree().get_nodes_in_group("enemies").size()
		if enemy_count == 0:
			print("VICTORY! Boss defeated!")
			print_game_statistics()
	else:
		print("Warning: Group 'enemies' does not exist in the tree!")


func print_game_statistics():
	print("====\tGAME STATISTICS\t====")
	print("Total Time Played:\t%d seconds" % int(time_elapsed))
	print("Total Enemies Killed:\t%d" % total_enemies_killed)
	print("Total Cash Earned:\t$%d" % total_cash_earned)
	print("Boss Defeated:\t\t%s" % ("Yes" if boss_killed else "No"))
	print("=============================")


func save_statistics_to_file():
	var folder_path = "user://stat/"
	var file_path = folder_path + "stat.json"

	var dir = DirAccess.open("user://")
	if dir == null:
		print("Error: Unable to access user directory!")
		return

	if not dir.dir_exists(folder_path):
		var result = dir.make_dir_recursive(folder_path)
		if result != OK:
			print("Error: Unable to create folder 'stat'. Error code: %d" % result)
			return

	var existing_data = load_statistics_from_file(file_path)

	var new_stats = {
		"time_played": int(time_elapsed),
		"total_cash_earned": total_cash_earned,
		"total_enemies_killed": total_enemies_killed,
		"boss_killed": 1 if boss_killed else 0
	}

	if existing_data.size() > 0:
		var last_stats = existing_data[existing_data.size() - 1]
		new_stats["time_played"] += int(last_stats.get("time_played", 0))
		new_stats["total_cash_earned"] += int(last_stats.get("total_cash_earned", 0))
		new_stats["total_enemies_killed"] += int(last_stats.get("total_enemies_killed", 0))
		new_stats["boss_killed"] += int(last_stats.get("boss_killed", 0))

	existing_data.append(new_stats)

	var json_data = JSON.stringify(existing_data, "\t")
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(json_data)
		file.close()
		print("Statistics saved successfully!")
	else:
		print("Failed to open stat.json for writing")


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

	print("Raw JSON data:\n%s" % json_data)

	var json = JSON.new()
	var parse_error: Error = json.parse(json_data)
	if parse_error != OK:
		print("Failed to parse JSON. Error: %s" % json.get_error_message())
		print("Error line: %d, position: %d" % [json.get_error_line(), json.get_error_column()])
		if json_data.strip_edges() == "":
			print("The JSON file is empty or contains only whitespace!")
		return []

	var result = json.get_data()
	if typeof(result) != TYPE_ARRAY:
		print("Unexpected JSON format. Expected an array, got: %s" % typeof(result))
		return []

	print("Successfully loaded statistics:\n%s" % JSON.stringify(result))
	return result


func format_json(data, indent: String = "\t", depth: int = 0) -> String:
	var result = ""
	if typeof(data) == TYPE_ARRAY:
		result += "[\n"
		for element in data:
			result += indent.repeat(depth + 1) + format_json(element, indent, depth + 1) + ",\n"
		result = result.strip_edges()
		result += "\n" + indent.repeat(depth) + "]"
	elif typeof(data) == TYPE_DICTIONARY:
		result += "{\n"
		for key in data.keys():
			result += indent.repeat(depth + 1) + "\"%s\": %s,\n" % [key, format_json(data[key], indent, depth + 1)]
		result = result.strip_edges()
		result += "\n" + indent.repeat(depth) + "}"
	elif typeof(data) == TYPE_STRING:
		result += "\"%s\"" % data
	else:
		result += str(data)
	return result


func get_latest_stats() -> Dictionary:
	var stats_array = load_statistics_from_file("user://stat/stat.json")
	if stats_array.size() > 0:
		return stats_array[stats_array.size() - 1]
	else:
		return {}


func show_saved_statistics():
	var stats_array = load_statistics_from_file("user://stat/stat.json")
	if stats_array.size() == 0:
		print("No saved statistics found in user://stat/stat.json")
		return

	print("====\tSTORED STATISTICS (from user://)\t====")
	for entry in stats_array:
		var time_p = entry.get("time_played", 0)
		var cash_e = entry.get("total_cash_earned", 0)
		var enemies = entry.get("total_enemies_killed", 0)
		var boss = entry.get("boss_killed", 0)

		print("Time Played:\t\t%d seconds" % time_p)
		print("Total Cash Earned:\t%d" % cash_e)
		print("Total Enemies Killed:\t%d" % enemies)
		print("Boss Killed:\t\t%d" % boss)
		print("---------------------------------------------")


func go_to_win_scene():
	save_statistics_to_file()
	var win_scene = load("res://menu/win.tscn").instantiate()
	get_tree().root.add_child(win_scene)
	get_tree().current_scene = win_scene
	win_scene.call("update_stats", int(time_elapsed), total_cash_earned, total_enemies_killed)


func go_to_lose_scene():
	save_statistics_to_file()
	var lose_scene = load("res://menu/lose.tscn").instantiate()
	get_tree().root.add_child(lose_scene)
	get_tree().current_scene = lose_scene
	lose_scene.call("update_stats", int(time_elapsed), total_cash_earned, total_enemies_killed)

func decrease_castle_health(amount: int):
	castle_health -= amount
	if castle_health <= 0:
		print("GAME OVER!")
		print_game_statistics()
		go_to_lose_scene()


func _complete_grid():
	var is_hard: bool = (Global.difficulty == "hard")

	# ------------------- PUSTE KAFELKI (poza ścieżką) -------------------
	for x in range(PathGenInstance.path_config.map_length):
		for y in range(PathGenInstance.path_config.map_height):
			if not PathGenInstance.get_path_route().has(Vector2i(x, y)):
				if tile_empty.size() > 0:
					var random_tile: PackedScene = tile_empty.pick_random()
					
					if is_hard:
						var path: String = random_tile.resource_path

						# Jeśli "tile_rock" => tile_rock_snow
						if path.ends_with("tile_rock.tscn") and tile_rock_snow:
							random_tile = tile_rock_snow
						# Jeśli "tile_tree" => tile_tree_snow
						elif path.ends_with("tile_tree.tscn") and tile_tree_snow:
							random_tile = tile_tree_snow
						# Jeśli "tile_crystal" => tile_crystal_snow
						elif path.ends_with("tile_crystal.tscn") and tile_crystal_snow:
							random_tile = tile_crystal_snow
						else:
							# Dla zwykłego tile_empty – 40% szans na snow_tile
							if randf() < 0.4 and snow_tile:
								random_tile = snow_tile

					if random_tile != null:
						var tile_instance = random_tile.instantiate()
						add_child(tile_instance)
						tile_instance.global_position = Vector3(x, 0, y)
						tile_instance.global_rotation_degrees = Vector3(
							0,
							randi_range(0, 3) * 90,
							0
						)
					else:
						print("Warning: random_tile is null!")
				else:
					print("Warning: tile_empty array is empty!")

	# ------------------- KAFELKI ŚCIEŻKI -------------------
	for i in range(PathGenInstance.get_path_route().size()):
		var tile_score: int = PathGenInstance.get_tile_score(i)
		var tile: Node3D = null
		var tile_rotation: Vector3 = Vector3.ZERO

		if tile_score == 2:
			# tile_end
			if is_hard and tile_end_snow != null:
				tile = tile_end_snow.instantiate()
				tile_rotation = Vector3(0, 90, 0)  # Przykład
			elif tile_end != null:
				tile = tile_end.instantiate()
				tile_rotation = Vector3(0, -90, 0)

		elif tile_score == 8:
			# tile_start
			if is_hard and tile_start_snow != null:
				tile = tile_start_snow.instantiate()
				tile_rotation = Vector3(0, -90, 0)
			elif tile_start != null:
				tile = tile_start.instantiate()
				tile_rotation = Vector3(0, 90, 0)

		elif tile_score == 10:
			# tile_straight
			if is_hard and tile_straight_snow != null:
				tile = tile_straight_snow.instantiate()
				tile_rotation = Vector3(0, 90, 0)
			elif tile_straight != null:
				tile = tile_straight.instantiate()
				tile_rotation = Vector3(0, 90, 0)

		elif tile_score in [1, 4, 5]:
			# też tile_straight, ale bez obrotu (lub inny)
			if is_hard and tile_straight_snow != null:
				tile = tile_straight_snow.instantiate()
				tile_rotation = Vector3(0, 0, 0)	# Przykład
			elif tile_straight != null:
				tile = tile_straight.instantiate()
				tile_rotation = Vector3(0, 0, 0)

		elif tile_score == 6:
			# tile_corner
			if is_hard and tile_corner_snow != null:
				tile = tile_corner_snow.instantiate()
				tile_rotation = Vector3(0, 180, 0)	# Przykład
			elif tile_corner != null:
				tile = tile_corner.instantiate()
				tile_rotation = Vector3(0, 180, 0)

		elif tile_score == 12:
			# tile_corner
			if is_hard and tile_corner_snow != null:
				tile = tile_corner_snow.instantiate()
				tile_rotation = Vector3(0, 90, 0)
			elif tile_corner != null:
				tile = tile_corner.instantiate()
				tile_rotation = Vector3(0, 90, 0)

		elif tile_score == 9:
			# tile_corner
			if is_hard and tile_corner_snow != null:
				tile = tile_corner_snow.instantiate()
				tile_rotation = Vector3(0, 0, 0)
			elif tile_corner != null:
				tile = tile_corner.instantiate()
				tile_rotation = Vector3(0, 0, 0)

		elif tile_score == 3:
			# tile_corner
			if is_hard and tile_corner_snow != null:
				tile = tile_corner_snow.instantiate()
				tile_rotation = Vector3(0, 270, 0)
			elif tile_corner != null:
				tile = tile_corner.instantiate()
				tile_rotation = Vector3(0, 270, 0)

		elif tile_score == 15:
			# tile_crossroads
			if is_hard and tile_crossroads_snow != null:
				tile = tile_crossroads_snow.instantiate()
				tile_rotation = Vector3(0, 0, 0)
			elif tile_crossroads != null:
				tile = tile_crossroads.instantiate()

		# Ustaw finalnie pozycję i rotację, o ile tile != null
		if tile != null:
			add_child(tile)
			tile.global_position = Vector3(
				PathGenInstance.get_path_tile(i).x,
				0,
				PathGenInstance.get_path_tile(i).y
			)
			tile.global_rotation_degrees = tile_rotation





func show_upgrade_panel(tower: Node3D):
	if selected_tower != null and selected_tower != tower:
		remove_selection_frame()

	selected_tower = tower

	if selection_instance == null:
		selection_instance = selection_frame.instantiate()
		add_child(selection_instance)
		selection_instance.global_position = tower.global_position
		selection_instance.scale = Vector3(1.3, 1.3, 1.3)
	else:
		selection_instance.queue_free()
		selection_instance = null

	upgrade_panel.visible = true
	upgrade_panel.call("initialize_ui", tower)


func remove_selection_frame():
	if selection_instance != null:
		selection_instance.queue_free()
		selection_instance = null


func upgrade_tower():
	if selected_tower == null:
		print("No tower selected for upgrade!")
		return

	var new_tower_scene = selected_tower.call("upgrade_to_scene")
	if new_tower_scene == null:
		print("No upgrade scene defined for selected tower!")
		return

	var old_transform = selected_tower.global_transform
	var parent = selected_tower.get_parent()

	var new_tower = new_tower_scene.instantiate()
	parent.add_child(new_tower)
	new_tower.global_transform = old_transform

	selected_tower.global_translate(Vector3i(100,0,0))
	selected_tower.visible = false

	selected_tower.connect("tree_exited", self._on_old_tower_removed.bind(new_tower))
	selected_tower.queue_free()
	selected_tower = null

	print("Tower upgraded successfully!")


func _on_old_tower_removed(new_tower):
	print("W _on_old_tower_removed()")
	print("new_tower = ", new_tower)
	if new_tower.has_method("_ready"):
		new_tower._ready()
	selected_tower = new_tower
	show_upgrade_panel(new_tower)


func _physics_process(_delta):
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var space_state = get_world_3d().direct_space_state
		var mouse_pos: Vector2 = get_viewport().get_mouse_position()
		var origin: Vector3 = cam.project_ray_origin(mouse_pos)
		var end: Vector3 = origin + cam.project_ray_normal(mouse_pos) * RAYCAST_LENGTH
		var query = PhysicsRayQueryParameters3D.create(origin, end)
		query.collide_with_areas = true
		var ray_result: Dictionary = space_state.intersect_ray(query)

		if ray_result.size() > 0:
			var _collider: CollisionObject3D = ray_result.get("collider")


func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# Sprawdź, czy kliknięto panel ulepszeń
		if upgrade_panel.visible and upgrade_panel.get_global_rect().has_point(event.position):
			return

		if selected_tower != null:
			var space_state = get_world_3d().direct_space_state
			var ray_origin = get_viewport().get_camera_3d().project_ray_origin(get_viewport().get_mouse_position())
			var ray_end = ray_origin + get_viewport().get_camera_3d().project_ray_normal(get_viewport().get_mouse_position()) * 100
			var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
			query.collide_with_areas = true

			var result = space_state.intersect_ray(query)
			if result.size() > 0:
				var clicked_node = result["collider"]
				while clicked_node != null:
					if clicked_node == selected_tower:
						return
					clicked_node = clicked_node.get_parent()

			selected_tower = null
			upgrade_panel.visible = false
			remove_selection_frame()


func _on_boss_killed():
	print("Removing boss...")
	boss_killed = true
	print("Boss has been defeated!")
	print_game_statistics()

	call_deferred("remove_boss_node")
	go_to_win_scene()


func remove_boss_node():
	if has_node("Boss_Enemy"):
		var boss_enemy = $Boss_Enemy
		if boss_enemy.is_inside_tree():
			boss_enemy.call_deferred("queue_free")
		else:
			print("Warning: Boss_Enemy is not inside the tree!")
	else:
		print("Boss_Enemy node not found, ignoring.")
