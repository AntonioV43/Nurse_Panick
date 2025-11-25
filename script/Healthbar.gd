extends TextureProgressBar

# Use 'owner' to reliably get the root of the local scene (the Patient)
@onready var patient: CharacterBody3D = owner 


func _ready():
	# Use a small deferred call to ensure the Patient node is fully initialized in the scene tree
	call_deferred("connect_patient")


func connect_patient():
	# Ensure patient is valid and has the required signal
	if patient and patient.has_signal("health_changed"):
		# Connect the patient's signal to our local update function
		patient.health_changed.connect(_on_patient_health_changed)
		
		# Set the HealthBar's max_value based on the patient's property
		max_value = patient.max_health
		
		# Set the initial health value
		_on_patient_health_changed(patient.current_health)
	else:
		print("ERROR: Could not find Patient or 'health_changed' signal when connecting UI.")


## Function called every time the patient's health changes
func _on_patient_health_changed(new_health: int):
	value = new_health
	
	# Optional: Change the bar's tint or color when health is low
	var progress_ratio = float(new_health) / patient.max_health
	
	if progress_ratio <= 0.25:
		tint_progress = Color.RED
	elif progress_ratio <= 0.5:
		tint_progress = Color.YELLOW
	else:
		tint_progress = Color.GREEN
