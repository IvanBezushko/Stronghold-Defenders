extends Node3D

@export var tile_start: PackedScene
@export var tile_end: PackedScene
@export var tile_straight: PackedScene
@export var tile_corner: PackedScene
@export var tile_crossroads: PackedScene
@export var tile_enemy: PackedScene
@export var tile_empty: Array[PackedScene]

@export var enemy:PackedScene
@export var cash:int=1000

#@export var castle_settings:CastleConfig = preload("res://resources/castle_settings.tres")
var castle_health:int=20

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

func _ready():
	PathGenInstance.reset()
	_complete_grid()
	upgrade_panel.visible = false
	#print("Enemy Type 1: ", enemy_type_1)
	#print("Enemy Type 2: ", enemy_type_2)
	#print("Enemy Type 3: ", enemy_type_3)
	#print("Enemy Type 4: ", enemy_type_4)
	#print("Boss Type: ", boss_type)

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
				#print("Enemy instantiated: ", enemy_instance.name)

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
				#print("BOSS instantiated: ", boss_instance.name)

		# Przerwa między falami (nie dotyczy ostatniej fali)
		if wave_index < len(waves) - 1:
			print("Waiting ", time_between_waves, " seconds before the next wave...")
			await get_tree().create_timer(time_between_waves).timeout

	print("All waves are complete!")

func _process(_delta):
	$Control/CashLabel.text="Cash $%d" % cash

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

	#print("Przed tworzeniem nowej wieży: parent = ", parent)
	#print("Po tworzeniu nowej wieży: new_tower.parent = ", new_tower.get_parent())
	#print("Stara wieża przed przesunięciem: global_position = ", selected_tower.global_position)
	
	
	
#	if selected_tower.has_node("PatrolZone/CollisionShape3D"):
#		selected_tower.get_node("PatrolZone/CollisionShape3D").queue_free()
#	if selected_tower.has_node("ClickToUpgrade/ClickCollisionShape3D"):
#		selected_tower.get_node("ClickToUpgrade/ClickCollisionShape3D").queue_free()
#	if selected_tower.has_node("StateChart"):
#		selected_tower.get_node("StateChart").queue_free()
	selected_tower.global_translate(Vector3i(100,0,0))
	selected_tower.visible=false
	
	
	
	#print("Stara wieża po przesunięciu: global_position = ", selected_tower.global_position)
	#print("Stara wieża przed usunięciem: is_inside_tree() = ", selected_tower.is_inside_tree())

	selected_tower.connect("tree_exited", self._on_old_tower_removed.bind(new_tower))
	selected_tower.queue_free()
	selected_tower = null

	#print("Stara wieża po queue_free(): is_inside_tree() = ", selected_tower.is_inside_tree())
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
		var rayResult: Dictionary = space_state.intersect_ray(query)
		if rayResult.size() > 0:
			#print(rayResult)
			var _co: CollisionObject3D = rayResult.get("collider")
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

func decrease_castle_health(amount:int):
	castle_health-=amount
	#print("zycie zamku",castle_health)
	if(castle_health<=0):
		get_tree().paused = false
		get_tree().current_scene.queue_free()
		var game_scene = load("res://menu/lose.tscn").instantiate()
		get_tree().current_scene.queue_free() 
		get_tree().root.add_child(game_scene) 
		get_tree().current_scene = game_scene 
