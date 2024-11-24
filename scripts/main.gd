extends Node3D

@export var tile_start: PackedScene
@export var tile_end: PackedScene
@export var tile_straight: PackedScene
@export var tile_corner: PackedScene
@export var tile_crossroads: PackedScene
@export var tile_enemy: PackedScene
@export var tile_empty: Array[PackedScene]

@export var enemy_type_1: PackedScene = preload("res://scenes/enemy_01.tscn")
@export var enemy_type_2: PackedScene = preload("res://scenes/enemy_02.tscn")
@export var enemy_type_3: PackedScene = preload("res://scenes/enemy_03.tscn")
@export var enemy_type_4: PackedScene = preload("res://scenes/enemy_04.tscn")
@export var boss_type: PackedScene = preload("res://scenes/enemy_BOSS.tscn")

@onready var cam = $Camera3D
var RAYCAST_LENGTH: float = 100

func _ready():
	PathGenInstance.reset()
	_complete_grid()
	print("Enemy Type 1: ", enemy_type_1)
	print("Enemy Type 2: ", enemy_type_2)
	print("Enemy Type 3: ", enemy_type_3)
	print("Enemy Type 4: ", enemy_type_4)
	print("Boss Type: ", boss_type)

	var time_between_enemies = 2.5  # Odstęp między przeciwnikami w sekundach
	var time_between_waves = 10.0     # Przerwa między falami w sekundach

	var waves = [
		# Fala 1: 5 x enemy_01
		{"enemy_count": 5, "enemy_types": [enemy_type_1]},
		# Fala 2: 10 x enemy_01 i enemy_02
		{"enemy_count": 10, "enemy_types": [enemy_type_1, enemy_type_2]},
		# Fala 3: 10 x enemy_01 i enemy_02
		{"enemy_count": 10, "enemy_types": [enemy_type_1, enemy_type_2]},
		# Fala 4: 15 x enemy_01, enemy_02 i enemy_03
		{"enemy_count": 15, "enemy_types": [enemy_type_1, enemy_type_2, enemy_type_3]},
		# Fala 5: 15 x enemy_01, enemy_02, enemy_03 i enemy_04
		{"enemy_count": 15, "enemy_types": [enemy_type_1, enemy_type_2, enemy_type_3, enemy_type_4]},
		# Fala 6: 25 x enemy_01, enemy_02, enemy_03 i enemy_04
		{"enemy_count": 25, "enemy_types": [enemy_type_1, enemy_type_2, enemy_type_3, enemy_type_4]},
		# Fala 7: 30 x enemy_01, enemy_02, enemy_03, enemy_04 i BOSS
		{"enemy_count": 30, "enemy_types": [enemy_type_1, enemy_type_2, enemy_type_3, enemy_type_4], "boss": boss_type},
	]

	# Generowanie fal
	for wave_index in range(len(waves)):
		var wave = waves[wave_index]
		print("Spawning wave ", wave_index + 1)
		var enemy_count = wave["enemy_count"]
		var enemy_types = wave["enemy_types"]

		# Tworzenie przeciwników w jednej fali
		for i in range(enemy_count):
			await get_tree().create_timer(time_between_enemies).timeout
			var enemy_instance: Node3D

			# Losowo wybierz przeciwnika z dostępnych typów
			if enemy_types.size() > 1:
				enemy_instance = enemy_types[randi() % enemy_types.size()].instantiate()
			else:
				enemy_instance = enemy_types[0].instantiate()

			if enemy_instance == null:
				print("ERROR: Failed to instantiate enemy!")
			else:
				add_child(enemy_instance)
				enemy_instance.add_to_group("enemies")
				print("Enemy instantiated: ", enemy_instance.name)

		# Jeśli fala zawiera BOSS-a
		if wave.has("boss"):
			print("Spawning BOSS!")
			await get_tree().create_timer(time_between_enemies).timeout
			var boss_instance = wave["boss"].instantiate()
			if boss_instance == null:
				print("ERROR: Failed to instantiate BOSS!")
			else:
				add_child(boss_instance)
				boss_instance.add_to_group("enemies")
				print("BOSS instantiated: ", boss_instance.name)

		# Przerwa między falami (nie dotyczy ostatniej fali)
		if wave_index < len(waves) - 1:
			print("Waiting ", time_between_waves, " seconds before the next wave...")
			await get_tree().create_timer(time_between_waves).timeout

	print("All waves are complete!")

func _physics_process(_delta):
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var space_state = get_world_3d().direct_space_state
		var mouse_pos: Vector2 = get_viewport().get_mouse_position()
		var origin: Vector3 = cam.project_ray_origin(mouse_pos)
		var end: Vector3 = origin + cam.project_ray_normal(mouse_pos) * RAYCAST_LENGTH
		var query = PhysicsRayQueryParameters3D.create(origin, end)
		query.collide_with_areas = true
		var rayResult: Dictionary = space_state.intersect_ray(query)
		if rayResult.size() > 0:
			#print(rayResult)
			var co: CollisionObject3D = rayResult.get("collider")
			#print(co.get_groups())

func _complete_grid():
	for x in range(PathGenInstance.path_config.map_length):
		for y in range(PathGenInstance.path_config.map_height):
			if not PathGenInstance.get_path_route().has(Vector2i(x, y)):
				var tile: Node3D = tile_empty.pick_random().instantiate()
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
			tile_rotation = Vector3(0, 0, 0)
		elif tile_score == 6:
			tile = tile_corner.instantiate()
			tile_rotation = Vector3(0, 180, 0)
		elif tile_score == 12:
			tile = tile_corner.instantiate()
			tile_rotation = Vector3(0, 90, 0)
		elif tile_score == 9:
			tile = tile_corner.instantiate()
			tile_rotation = Vector3(0, 0, 0)
		elif tile_score == 3:
			tile = tile_corner.instantiate()
			tile_rotation = Vector3(0, 270, 0)
		elif tile_score == 15:
			tile = tile_crossroads.instantiate()
			tile_rotation = Vector3(0, 0, 0)

		add_child(tile)
		tile.global_position = Vector3(PathGenInstance.get_path_tile(i).x, 0, PathGenInstance.get_path_tile(i).y)
		tile.global_rotation_degrees = tile_rotation
