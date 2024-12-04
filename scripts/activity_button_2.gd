extends Button

@export var activity_button_icon:Texture2D
@export var activity_draggable:PackedScene
@onready var main = $"../.."
@export var activity_cost:int=70

var _is_dragging:bool = false
var _draggable:Node
var _is_valid_location:bool = false
var _last_valid_location:Vector3
var _cam:Camera3D
var RAYCAST_LENGTH:float = 100
var occupied_positions: Array = []


# Called when the node enters the scene tree for the first time.
func _ready():
	icon = activity_button_icon
	_draggable = activity_draggable.instantiate()
	_draggable.set_patrolling(false)
	add_child(_draggable)
	_draggable.visible = false
	_cam = get_viewport().get_camera_3d()

func _process(delta):
	disabled=activity_cost>main.cash

func _physics_process(_delta):
	if _is_dragging:
		var space_state = _draggable.get_world_3d().direct_space_state
		var mouse_pos:Vector2 = get_viewport().get_mouse_position()
		var origin:Vector3 = _cam.project_ray_origin(mouse_pos)
		var end:Vector3 = origin + _cam.project_ray_normal(mouse_pos) * RAYCAST_LENGTH
		var query = PhysicsRayQueryParameters3D.create(origin, end)
		query.collide_with_areas = true
		var rayResult:Dictionary = space_state.intersect_ray(query)
		if rayResult.size() > 0:
			var co:CollisionObject3D = rayResult.get("collider")
			if "grid_empty" in str(co.get_groups()):
				_last_valid_location = Vector3(co.global_position.x, 0.2, co.global_position.z)
				if not _is_position_occupied(_last_valid_location):
					_draggable.visible = true
					_is_valid_location = true
					_draggable.global_position = _last_valid_location
				else:
					_draggable.visible = false
					_is_valid_location = false
		else:
			_draggable.visible = false

func _on_button_down():
	#print("Button Down")
	_is_dragging = true


func _on_button_up():
	#print("Button Up")
	_is_dragging = false
	_draggable.visible = false
	
	if _is_valid_location:
		var activity = activity_draggable.instantiate()
		add_child(activity)
		activity.global_position = _last_valid_location
		main.cash-=activity_cost
		occupied_positions.append(_last_valid_location)

func _is_position_occupied(position: Vector3) -> bool:
	for occupied in occupied_positions:
		if position.distance_to(occupied) < 0.5: 
			return true
	return false
