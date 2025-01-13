extends Node3D

@export var tile_start: PackedScene
@export var tile_end: PackedScene
@export var tile_straight: PackedScene
@export var tile_corner: PackedScene
@export var tile_crossroads: PackedScene
@export var tile_enemy: PackedScene
@export var tile_empty: Array[PackedScene]

@export var enemy: PackedScene
@export var cash: int = 1000
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
@onready var timer_label = $Control/TimerLabel


# Statystyki
var total_cash_earned: int = 0
var total_enemies_killed: int = 0
var time_elapsed: float = 0.0

func _ready():
	PathGenInstance.reset()
	_complete_grid()
	upgrade_panel.visible = false
	timer_label.visible=false

	var time_between_enemies = 2.5
	var time_between_waves = 10.0

	var waves = [
		{"enemy_count": 5, "enemy_types": [enemy_type_1]},
		{"enemy_count": 10, "enemy_types": [enemy_type_1, enemy_type_2]},
		{"enemy_count": 15, "enemy_types": [enemy_type_1, enemy_type_2, enemy_type_3]},
		{"enemy_count": 25, "enemy_types": [enemy_type_1, enemy_type_2, enemy_type_3, enemy_type_4]},
		{"enemy_count": 30, "enemy_types": [enemy_type_1, enemy_type_2, enemy_type_3, enemy_type_4], "boss": boss_type},
	]

	for wave_index in range(len(waves)):
		var wave = waves[wave_index]
		var enemy_count = wave["enemy_count"]
		var enemy_types = wave["enemy_types"]

		for i in range(enemy_count):
			await get_tree().create_timer(time_between_enemies).timeout
			var enemy_instance = enemy_types[randi() % enemy_types.size()].instantiate()
			add_child(enemy_instance)
			enemy_instance.add_to_group("enemies")
			enemy_instance.connect("tree_exited", Callable(self, "_on_enemy_killed"))

		if wave.has("boss"):
			await get_tree().create_timer(time_between_enemies).timeout
			var boss_instance = wave["boss"].instantiate()
			add_child(boss_instance)
			boss_instance.add_to_group("enemies")
			# Połączenie sygnału "tree_exited" dla bossa
			boss_instance.connect("tree_exited", Callable(self, "_on_enemy_killed"))
			# Połączenie sygnału "enemy_finished" dla bossa
			if boss_instance.has_signal("enemy_finished"):
				print("Connecting 'enemy_finished' signal to '_on_boss_killed'")
				boss_instance.connect("enemy_finished", Callable(self, "_on_boss_killed"))
				print("Connected 'enemy_finished' signal")
			else:
				print("Warning: Boss instance does not have 'enemy_finished' signal.")

		if wave_index < len(waves) - 1:
			#await get_tree().create_timer(time_between_waves).timeout
			await show_wave_timer(time_between_waves)


func _process(delta):
	time_elapsed += delta
	$Control/CashLabel.text = "Cash $%d" % cash
	$Control/HealthLabel.text="❤️ "+str(castle_health)+" "

func show_wave_timer(duration: float):
	timer_label.visible = true
	var remaining_time = duration
	timer_label.text = "Next wave in %d" % ceil(remaining_time)

	while remaining_time > 0:
		await get_tree().create_timer(1.0).timeout
		remaining_time -= 1
		timer_label.text = "Next wave in %d" % ceil(remaining_time)

	timer_label.visible = false

func _on_enemy_killed():
	var enemy_value = 100
	total_cash_earned += enemy_value
	total_enemies_killed += 1
	cash += enemy_value

	# Sprawdź, czy Boss został zabity
	if get_tree() and get_tree().root:  # Sprawdzenie, czy get_tree() nie jest null
		if get_tree().get_nodes_in_group("enemies").size() == 0:
			print("VICTORY! Boss defeated!")
			print_game_statistics()  # Wyświetl statystyki po zwycięstwie
	else:
		print("Warning: get_tree() is null. Cannot verify enemy group.")

func print_game_statistics():
	print("====\tGAME STATISTICS\t====")
	print("Total Time Played:\t%d seconds" % int(time_elapsed))
	print("Total Enemies Killed:\t%d" % total_enemies_killed)
	print("Total Cash Earned:\t$%d" % total_cash_earned)
	print("=============================")

func decrease_castle_health(amount: int):
	castle_health -= amount
	if castle_health <= 0:
		print("GAME OVER!")
		print_game_statistics()  # Wyświetl statystyki

		get_tree().paused = false
		get_tree().current_scene.queue_free()
		var game_scene = load("res://menu/lose.tscn").instantiate()
		get_tree().root.add_child(game_scene)
		get_tree().current_scene = game_scene

func add_castle_health(amount: int):
	castle_health += amount
	print("Castle health increased! Current health:", castle_health)

func slow_down_enemies(factor: float, duration: float) -> void:
	print("Slowing down enemies by factor:", factor, "for", duration, "seconds")
	
	# Apply slowdown to all enemies
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.has_method("set_speed"):
			enemy.call("set_speed", enemy.enemy_speed * factor)
	
	# Wait for the duration
	await get_tree().create_timer(duration).timeout
	
	# Restore speed to all enemies
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.has_method("set_speed"):
			enemy.call("set_speed", enemy.enemy_speed)


func _complete_grid():
	for x in range(PathGenInstance.path_config.map_length):
		for y in range(PathGenInstance.path_config.map_height):
			if not PathGenInstance.get_path_route().has(Vector2i(x, y)):
				var tile = tile_empty.pick_random().instantiate()
				add_child(tile)
				tile.global_position = Vector3(x, 0, y)
				tile.global_rotation_degrees = Vector3(0, randi_range(0, 3) * 90, 0)

	for i in range(PathGenInstance.get_path_route().size()):
		var tile_score: int = PathGenInstance.get_tile_score(i)

		var tile: Node3D = tile_empty[0].instantiate()
		var tile_rotation: Vector3 = Vector3.ZERO

		if tile_score == 2:
			tile = tile_end.instantiate()
			tile_rotation = Vector3(0, -90, 0)
		elif tile_score == 8:
			tile = tile_start.instantiate()
			tile_rotation = Vector3(0, 90, 0)
		elif tile_score == 10:
			tile = tile_straight.instantiate()
			tile_rotation = Vector3(0, 90, 0)
		elif tile_score in [1, 4, 5]:
			tile = tile_straight.instantiate()
		elif tile_score == 6:
			tile = tile_corner.instantiate()
			tile_rotation = Vector3(0, 180, 0)
		elif tile_score == 12:
			tile = tile_corner.instantiate()
			tile_rotation = Vector3(0, 90, 0)
		elif tile_score == 9:
			tile = tile_corner.instantiate()
		elif tile_score == 3:
			tile = tile_corner.instantiate()
			tile_rotation = Vector3(0, 270, 0)
		elif tile_score == 15:
			tile = tile_crossroads.instantiate()

		add_child(tile)
		tile.global_position = Vector3(PathGenInstance.get_path_tile(i).x, 0, PathGenInstance.get_path_tile(i).y)
		tile.global_rotation_degrees = tile_rotation

func show_upgrade_panel(tower: Node3D):
	# Usuń ramkę z poprzednio wybranej wieży
	if selected_tower != null and selected_tower != tower:
		remove_selection_frame()

	# Ustaw obecną wieżę jako wybraną
	selected_tower = tower
	
	# Dodaj ramkę do wieży
	if selection_instance == null:
		selection_instance = selection_frame.instantiate()
		add_child(selection_instance)
		selection_instance.global_position = tower.global_position
		selection_instance.scale = Vector3(1.3, 1.3, 1.3)  # Powiększenie ramki
	else:
		selection_instance.queue_free()
		selection_instance = null
	
	# Wyświetl panel ulepszeń
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
	
	print("selected tower ",selected_tower)
	print("selected tower get parent ",selected_tower.get_parent_node_3d())
	selected_tower as Node3D

	var new_tower_scene = selected_tower.call("upgrade_to_scene")
	if new_tower_scene == null:
		print("No upgrade scene defined for selected tower!")
		return

	var old_transform = selected_tower.global_transform
	var parent = selected_tower.get_parent()

	var new_tower = new_tower_scene.instantiate()
	parent.add_child(new_tower)
	new_tower.global_transform = old_transform
	######new_tower.visible=false

	# Jeśli chcesz, możesz usunąć dodatkowe komponenty starej wieży tutaj
	# if selected_tower.has_node("PatrolZone/CollisionShape3D"):
	#     selected_tower.get_node("PatrolZone/CollisionShape3D").queue_free()
	# if selected_tower.has_node("ClickToUpgrade/ClickCollisionShape3D"):
	#     selected_tower.get_node("ClickToUpgrade/ClickCollisionShape3D").queue_free()
	# if selected_tower.has_node("StateChart"):
	#     selected_tower.get_node("StateChart").queue_free()
	
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
			#print(ray_result)
			var collider: CollisionObject3D = ray_result.get("collider")
			#if collider != null:
			#	print("Mouse hit collider: ", collider.name)

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# Sprawdź, czy kliknięto panel ulepszeń
		if upgrade_panel.visible and upgrade_panel.get_global_rect().has_point(event.position):
			#print("Clicked inside upgrade panel")
			return  # Kliknięto w panel, nic nie rób

		if selected_tower != null:
			var space_state = get_world_3d().direct_space_state
			var ray_origin = get_viewport().get_camera_3d().project_ray_origin(get_viewport().get_mouse_position())
			var ray_end = ray_origin + get_viewport().get_camera_3d().project_ray_normal(get_viewport().get_mouse_position()) * 100
			var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
			query.collide_with_areas = true

			var result = space_state.intersect_ray(query)
			if result.size() > 0:
				var clicked_node = result["collider"]

				# Sprawdź, czy kliknięto wybraną wieżę
				while clicked_node != null:
					if clicked_node == selected_tower:
						return  # Kliknięto obecną wieżę, nic nie rób
					clicked_node = clicked_node.get_parent()

			# Jeśli kliknięto poza wieżą i panelem, usuń zaznaczenie
			#print("Clicked outside tower and panel")
			selected_tower = null
			upgrade_panel.visible = false
			remove_selection_frame()

# Nowa funkcja do obsługi śmierci bossa
func _on_boss_killed():
	print("Boss has been killed!")
	print_game_statistics()
	# Opcjonalnie możesz również wywołać inne akcje, np. przejście do sceny wygranej
	# var win_scene = load("res://menu/win.tscn").instantiate()
	# get_tree().change_scene_to(win_scene)
	var win_scene_path = "res://menu/win.tscn"
	if win_scene_path != "":
		print("Changing scene to win scene:", win_scene_path)
		var error = get_tree().change_scene_to_file(win_scene_path)
		if error != OK:
			print("ERROR: Failed to change to win scene:", win_scene_path)
	else:
		print("ERROR: win_scene_path not set.")
