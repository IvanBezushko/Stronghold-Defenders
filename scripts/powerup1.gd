extends Button

@onready var main = $"../.."
@export var powerup_button_icon:Texture2D
var health_cost = 250
var health_amount = 10

func _ready() -> void:
	icon=powerup_button_icon

func _process(delta: float) -> void:
	$Label.text="$ " + str(health_cost)
	if main.cash < health_cost:
		self.disabled=true
	else:
		self.disabled=false

func _on_pressed() -> void:
	if main.cash >= health_cost:
		main.cash -= health_cost
		main.add_castle_health(health_amount)
		print("Health purchased for", health_cost, "gold!")
		health_cost += 10
		$Label.text="$ " + str(health_cost)
		if main.cash < health_cost:
			self.disabled=true
		else:
			self.disabled=false
	else:
		print("Not enough gold to purchase health.")
