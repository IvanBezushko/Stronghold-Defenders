extends Node3D

var enemies_in_range: Array[Node3D] = []
var current_enemy: Node3D = null
var current_enemy_class = null  # Usunięto deklarację typu
var current_enemy_targetted: bool = false
var acquire_slerp_progress: float = 0
var selection_instance: Node3D = null
var turretname: String = "Cannon Turret lvl 2"
var level: int =2
var type: int =1

# NOWE ZMIENNE
var last_fire_time: int
@export var fire_rate_ms: int = 1000
@export var projectile_type: PackedScene
#@export var upgrade_to_scene: PackedScene = null
@onready var main = get_node("/root/main")
@export var upgrade_cost: int = 100
@export var selection_frame: PackedScene
@onready var collision_shape = $PatrolZone/CollisionShape3D
var radius: float

func _ready():
	# Ustaw, aby wieża mogła odbierać wejście myszką
	set_process_input(true)
	radius=(collision_shape.shape as CylinderShape3D).radius


# Funkcja obsługująca wejścia
func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if is_mouse_over():  # Sprawdzamy, czy kliknięto na wieżę
				_on_tower_clicked()

# Sprawdzenie, czy mysz jest nad wieżą
func is_mouse_over() -> bool:
	var space_state = get_world_3d().direct_space_state
	var ray_origin = get_viewport().get_camera_3d().project_ray_origin(get_viewport().get_mouse_position())
	var ray_end = ray_origin + get_viewport().get_camera_3d().project_ray_normal(get_viewport().get_mouse_position()) * 100
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collide_with_areas = true
	query.collision_mask = 1 << 3

	var result = space_state.intersect_ray(query)
	if result.size() > 0:
		var collider = result["collider"]
		# Sprawdź, czy collider to ta wieża lub jest jej dzieckiem
		var current_node = collider
		while current_node != null:
			if current_node == self:
				return true
			current_node = current_node.get_parent()
	return false

# Obsługa kliknięcia wieży
func _on_tower_clicked():
	#print("Tower clicked!")
	main.show_upgrade_panel(self)

func upgrade_to_scene() -> PackedScene:
	# Sprawdź, jaki poziom ma aktualna wieża i zwróć odpowiednią scenę
	var new_scene: PackedScene = null
	new_scene = preload("res://scenes/turret_1_lvl3.tscn")
	# Przykładowe mechanizmy: 
	# (Możesz dostosować w zależności od specyfiki swojej gry i dostępnych scen)
	#if current_level == 1:
		#new_scene = preload("res://scenes/Tower_Level_2.tscn")  # Scena nowej wersji wieży
	#elif current_level == 2:
		#new_scene = preload("res://scenes/Tower_Level_3.tscn")
	# Dodatkowe poziomy ulepszeń, jeżeli są dostępne
	# ...

	return new_scene


func _on_patrol_zone_area_entered(area):
	if current_enemy == null:
		current_enemy = area
	if not enemies_in_range.has(area):
		enemies_in_range.append(area)

func _on_patrol_zone_area_exited(area):
	if enemies_in_range.has(area):
		enemies_in_range.erase(area)
	if area == current_enemy:
		_remove_current_enemy()

func set_patrolling(patrolling: bool):
	$PatrolZone.monitoring = patrolling

func rotate_towards_target(rtarget, delta):
	var target_vector = $Cannon.global_position.direction_to(Vector3(rtarget.global_position.x, $Cannon.global_position.y, rtarget.global_position.z))
	var target_basis: Basis = Basis.looking_at(target_vector, Vector3.UP)
	target_basis = target_basis.rotated(Vector3.UP, PI)

	if acquire_slerp_progress < 1:
		$Cannon.basis = $Cannon.basis.slerp(target_basis, acquire_slerp_progress)
		acquire_slerp_progress += delta
	else:
		$Cannon.basis = target_basis
		$StateChart.send_event("to_attacking_state")

func _find_enemy_parent(n: Node):
	if n is Enemy or n is Speed_Enemy or n is Health_Enemy or n is Sp_Hth_Enemy or n is Boss_Enemy:
		return n
	elif n.get_parent() != null:
		return _find_enemy_parent(n.get_parent())
	else:
		return null

func _on_patrolling_state_state_processing(_delta):
	if enemies_in_range.size() > 0:
		current_enemy = enemies_in_range[0]
		current_enemy_class = _find_enemy_parent(current_enemy)

		if current_enemy_class == null:
			print("ERROR: Could not find enemy class for: ", current_enemy)
			return

		_disconnect_current_enemy_signals()  # Odłącz poprzednie sygnały, jeśli istnieją

		# Podłączenie nowego sygnału
		current_enemy_class.enemy_finished.connect(_remove_current_enemy)

		$StateChart.send_event("to_acquiring_state")
	else:
		current_enemy = null
		current_enemy_class = null

func _disconnect_current_enemy_signals():
	if current_enemy_class != null:
		if current_enemy_class.enemy_finished.is_connected(_remove_current_enemy):
			current_enemy_class.enemy_finished.disconnect(_remove_current_enemy)

func _remove_current_enemy():
	if current_enemy != null:
		_disconnect_current_enemy_signals()  # Odłącz sygnały
		if enemies_in_range.has(current_enemy):
			enemies_in_range.erase(current_enemy)  # Usuń z listy
	current_enemy = null
	current_enemy_class = null
	acquire_slerp_progress = 0
	$StateChart.send_event("to_patrolling_state")

func _on_acquiring_state_state_entered():
	current_enemy_targetted = false
	acquire_slerp_progress = 0  # Resetowanie `acquire_slerp_progress`

func _on_acquiring_state_state_physics_processing(delta):
	if current_enemy != null and enemies_in_range.has(current_enemy):
		rotate_towards_target(current_enemy, delta)
	else:
		_remove_current_enemy()

func _on_attacking_state_state_physics_processing(_delta):
	if current_enemy != null and enemies_in_range.has(current_enemy):
		rotate_towards_target(current_enemy, _delta)  # Kontynuowanie obrotu wieży
		_maybe_fire()
	else:
		_remove_current_enemy()

# Funkcja kontrolująca strzelanie
func _maybe_fire():
	if current_enemy == null or not enemies_in_range.has(current_enemy):
		_remove_current_enemy()
		return
	if Time.get_ticks_msec() > (last_fire_time + fire_rate_ms):
		var projectile: Projectile = projectile_type.instantiate()
		projectile.starting_position = $Cannon/projectile_spawn.global_position
		projectile.target = current_enemy
		projectile.set_tower_level(level)
		add_child(projectile)
		last_fire_time = Time.get_ticks_msec()

func _on_attacking_state_state_entered():
	last_fire_time = 0