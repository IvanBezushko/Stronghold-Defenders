extends Area3D
class_name Projectile
var starting_position:Vector3
var target:Node3D
@export var speed:float  # metres per second
@export var damage:int 
var lerp_pos:float = 0

func set_tower_level(tower_level: int):
	match tower_level:
		1:
			speed = 2
			damage = 20
		2:
			speed = 2.5
			damage = 25
		3:
			speed = 3
			damage = 35

# Called when the node enters the scene tree for the first time.
func _ready():
	global_position = starting_position
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if target != null and lerp_pos < 1:
		global_position = starting_position.lerp(target.global_position, lerp_pos)
		lerp_pos += delta * speed
	else:
		queue_free()
