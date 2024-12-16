extends Panel

var selected_tower: Node3D = null  # Wieża aktualnie wybrana
@onready var main = get_node("/root/main")


# Funkcja inicjalizacji UI
func initialize_ui(tower: Node3D):
	selected_tower = tower
	if selected_tower == null:
		hide()  # Ukryj, jeśli nie ma wieży
		return
	# Ustaw teksty na podstawie statystyk wieży
	$Label.text = "Current stats:\n" + get_stats(selected_tower)
	$Label2.text = "After upgrade:\n" + get_upgraded_stats(selected_tower)
	$LabelName.text= selected_tower.turretname
	$UpgradeButton.text="$"+str(selected_tower.upgrade_cost)
	$UpgradeButton.disabled = selected_tower.level >= 3
	if selected_tower.level >= 3:
		$UpgradeButton.text=""
	show()

# Funkcja pobierająca aktualne statystyki wieży
func get_stats(_tower):
	var radius = _tower.radius
	if _tower.type==1:
		if _tower.level==1:
			return "Damage: " + "20" + "\nRange: " + str(radius) + "\nSpeed: " + "2 m/s"
		elif _tower.level==2:
			return "Damage: " + "25" + "\nRange: " + str(radius) + "\nSpeed: " + "2.5 m/s"
		elif _tower.level==3:
			return "Damage: " + "30" + "\nRange: " + str(radius) + "\nSpeed: " + "3 m/s"
	elif _tower.type==2:
		if _tower.level==1:
			return "Damage: " + "15" + "\nRange: " + str(radius) + "\nSpeed: " + "3 m/s"
		elif _tower.level==2:
			return "Damage: " + "20" + "\nRange: " + str(radius) + "\nSpeed: " + "3.5 m/s"
		elif _tower.level==3:
			return "Damage: " + "25" + "\nRange: " + str(radius) + "\nSpeed: " + "3.5 m/s"
	if _tower.type==3:
		if _tower.level==1:
			return "Damage: " + "25" + "\nRange: " + str(radius) + "\nSpeed: " + "2 m/s"
		elif _tower.level==2:
			return "Damage: " + "30" + "\nRange: " + str(radius) + "\nSpeed: " + "2 m/s"
		elif _tower.level==3:
			return "Damage: " + "35" + "\nRange: " + str(radius) + "\nSpeed: " + "2.5 m/s"
	

	
# Funkcja pobierająca statystyki po ulepszeniu
func get_upgraded_stats(_tower):
	var radius = _tower.radius
	if _tower.level==3:
		return "Max level"
	if _tower.type==1:
		if _tower.level==1:
			return "Damage: " + "25" + "\nRange: " + str(radius) + "\nSpeed: " + "2.5 m/s"
		elif _tower.level==2:
			return "Damage: " + "30" + "\nRange: " + str(radius) + "\nSpeed: " + "3 m/s"
	elif _tower.type==2:
		if _tower.level==1:
			return "Damage: " + "20" + "\nRange: " + str(radius) + "\nSpeed: " + "3.5 m/s"
		elif _tower.level==2:
			return "Damage: " + "25" + "\nRange: " + str(radius) + "\nSpeed: " + "3.5 m/s"
	elif _tower.type==3:
		if _tower.level==1:
			return "Damage: " + "30" + "\nRange: " + str(radius) + "\nSpeed: " + "2 m/s"
		elif _tower.level==2:
			return "Damage: " + "35" + "\nRange: " + str(radius) + "\nSpeed: " + "2.5 m/s"


# Funkcja obsługi przycisku ulepszania
func _on_Upgrade_pressed() -> void:
	#print("Upgrade button pressed!")
	#print("Selected tower: ", selected_tower)
	#print("Current cash: ", main.cash)
	#print("Upgrade cost: ", selected_tower.upgrade_cost)
	if selected_tower == null:
		print("No tower selected to upgrade!")
		main.remove_selection_frame()
		return
	
	if main.cash >= selected_tower.upgrade_cost:
		main.cash -= selected_tower.upgrade_cost
		main.upgrade_tower()
		hide()  # Ukryj panel po ulepszeniu
		main.selected_tower = null
	else:
		print("Not enough cash to upgrade!")