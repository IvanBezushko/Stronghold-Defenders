extends Node3D

var enemies_in_range: Array[Node3D] = []
var current_enemy: Node3D = null
var current_enemy_class = null
var current_enemy_targetted: bool = false
var acquire_slerp_progress: float = 0
var selection_instance: Node3D = null
var turretname: String = "Ballista Turret lvl 2"
var level: int =2
var type: int =2

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
	set_process_input(true)
	radius=(collision_shape.shape as CylinderShape3D).radius

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if is_mouse_over():  # Sprawdzamy, czy kliknięto na wieżę
				_on_tower_clicked()

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
		var current_node = collider
		while current_node != null:
			if current_node == self:
				return true
			current_node = current_node.get_parent()
	return false

func _on_tower_clicked():
	#print("Tower clicked!")
	main.show_upgrade_panel(self)

func upgrade_to_scene():
	

	var new_scene: PackedScene = preload("res://scenes/turret_2_lvl3.tscn")
	if new_scene == null:
		print("[BŁĄD] Nie udało się załadować sceny ulepszenia!")
		return null
	

	# Zapamiętaj rodzica i aktualny transform starej wieży
	var parent_node = get_parent()
	if parent_node == null:
		print("[BŁĄD] Wieża nie ma rodzica! Nie można przeprowadzić ulepszenia.")
		return null
	

	var old_transform = global_transform
	

	# Stwórz nową wieżę i ustaw w tym samym miejscu
	var new_turret = new_scene.instantiate()
	if new_turret == null:
		print("[BŁĄD] Nie udało się utworzyć nowej wieży!")
		return null
	

	new_turret.global_transform = old_transform
	

	parent_node.add_child(new_turret)
	

	# --- Zamiast usuwać starą wieżę, teleportuj ją daleko ---
	global_transform.origin = Vector3(9999, 9999, 9999)
	

	# (opcjonalnie) wyłącz logikę, żeby stara wieża nie strzelała, nie była targetowana itp.
	remove_from_group("towers")
	

	if has_node("PatrolZone"):
		$PatrolZone.monitoring = false
		print("Monitoring w PatrolZone został wyłączony.")

	set_process(false)
	

	set_physics_process(false)
	

	# Możesz też wyzerować collision_layer i collision_mask albo wyłączyć collider.
	return new_turret


func _on_patrol_zone_area_entered(area):
	# Sprawdź, czy area nie jest już celem innej wieży
	for tower in get_tree().get_nodes_in_group("towers"):
		if tower.current_enemy == area:
			print("Enemy already targeted by another tower!")
			return

	# Jeśli wieża nie ma aktualnego wroga, ustaw go jako current_enemy
	if current_enemy == null:
		current_enemy = area

	# Dodaj wroga do listy wrogów w zasięgu
	if not enemies_in_range.has(area):
		enemies_in_range.append(area)


func _on_patrol_zone_area_exited(area):
	if enemies_in_range.has(area):
		enemies_in_range.erase(area)
	if area == current_enemy:
		_remove_current_enemy()


func _on_enemy_removed(area):
	if enemies_in_range.has(area):
		enemies_in_range.erase(area)
	if area == current_enemy:
		_remove_current_enemy()

func set_patrolling(patrolling: bool):
	$PatrolZone.monitoring = patrolling

func rotate_towards_target(rtarget, delta):
	var target_vector = $Ballista.global_position.direction_to(Vector3(rtarget.global_position.x, $Ballista.global_position.y, rtarget.global_position.z))
	var target_basis: Basis = Basis.looking_at(target_vector, Vector3.UP)
	target_basis = target_basis.rotated(Vector3.UP, PI)

	if acquire_slerp_progress < 1:
		$Ballista.basis = $Ballista.basis.slerp(target_basis, acquire_slerp_progress)
		acquire_slerp_progress += delta
	else:
		$Ballista.basis = target_basis
		$StateChart.send_event("to_attacking_state")

func _find_enemy_parent(n: Node):
	if n is Enemy or n is Speed_Enemy or n is Health_Enemy or n is Sp_Hth_Enemy or n is Boss_Enemy:
		return n
	elif n.get_parent() != null:
		return _find_enemy_parent(n.get_parent())
	else:
		return null

func _on_patrolling_state_state_processing(_delta):
	for enemy in enemies_in_range:
		if enemy != null and enemy.is_inside_tree():
			current_enemy = enemy
			current_enemy_class = _find_enemy_parent(current_enemy)

			if current_enemy_class == null:
				print("ERROR: Could not find enemy class for: ", current_enemy)
				return

			_disconnect_current_enemy_signals()
			current_enemy_class.enemy_finished.connect(_remove_current_enemy)

			$StateChart.send_event("to_acquiring_state")
			return
	current_enemy = null
	current_enemy_class = null

func _disconnect_current_enemy_signals():
	if current_enemy_class != null:
		if current_enemy_class.enemy_finished.is_connected(_remove_current_enemy):
			current_enemy_class.enemy_finished.disconnect(_remove_current_enemy)

func _remove_current_enemy():
	if current_enemy != null:
		_disconnect_current_enemy_signals()
		if enemies_in_range.has(current_enemy):
			enemies_in_range.erase(current_enemy)
	current_enemy = null
	current_enemy_class = null
	acquire_slerp_progress = 0
	$StateChart.send_event("to_patrolling_state")


func _on_acquiring_state_state_entered():
	current_enemy_targetted = false
	acquire_slerp_progress = 0

func _on_acquiring_state_state_physics_processing(delta):
	if current_enemy != null and enemies_in_range.has(current_enemy):
		rotate_towards_target(current_enemy, delta)
	else:
		_remove_current_enemy()

func _on_attacking_state_state_physics_processing(_delta):
	if current_enemy != null and enemies_in_range.has(current_enemy):
		rotate_towards_target(current_enemy, _delta)
		_maybe_fire()
	else:
		_remove_current_enemy()

func _maybe_fire():
	# Sprawdź, czy current_enemy jest nadal w grze i na liście wrogów w zasięgu
	if current_enemy == null or not enemies_in_range.has(current_enemy) or not current_enemy.is_inside_tree():
		_remove_current_enemy()
		return

	# Sprawdź czas od ostatniego strzału
	var now = Time.get_ticks_msec()
	if now > (last_fire_time + fire_rate_ms):
		# Stwórz nowy pocisk i ustaw jego cel
		var projectile: Projectile_2 = projectile_type.instantiate()
		projectile.starting_position = $Ballista/projectile_spawn.global_position
		projectile.target = current_enemy
		projectile.set_tower_level(level)

		# Dodaj pocisk do sceny
		add_child(projectile)

		# Zaktualizuj czas ostatniego strzału
		last_fire_time = now


func _on_attacking_state_state_entered():
	last_fire_time = 0
