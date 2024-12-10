extends Area3D
class_name Projectile_2

@export var starting_position: Vector3
@export var target: Node3D
@export var speed: float 
@export var damage: int 

var lerp_pos: float = 0.0

func set_tower_level(tower_level: int):
	match tower_level:
		1:
			speed = 3
			damage = 15
		2:
			speed = 3.5
			damage = 20
		3:
			speed = 3.5
			damage = 25

func _ready():
	global_position = starting_position
	# Upewnij się, że pocisk patrzy w kierunku celu na początku
	if target != null:
		look_at(target.global_position, Vector3.UP)
		rotate_y(deg_to_rad(180)) # Jeśli potrzebujesz odwrócić pocisk, upewnij się, że jest to konieczne

func _process(delta):
	if target != null and lerp_pos < 1.0:
		# Inkrementuj lerp_pos przed obliczeniem nowej pozycji
		lerp_pos += delta * speed
		
		# Ogranicz lerp_pos do maksymalnej wartości 1.0
		lerp_pos = clamp(lerp_pos, 0.0, 1.0)
		
		# Oblicz nową pozycję na podstawie lerp_pos
		var new_position = starting_position.lerp(target.global_position, lerp_pos)
		
		# Oblicz kierunek ruchu
		var direction = (new_position - global_position).normalized()
		
		# Sprawdź, czy kierunek nie jest zerowy
		if direction.length() > 0.0:
			look_at(global_position + direction, Vector3.UP)
			# Jeśli konieczne, zachowaj obrót o 180 stopni
			rotate_y(deg_to_rad(180))
		
		# Ustaw nową pozycję
		global_position = new_position
	else:
		queue_free()
