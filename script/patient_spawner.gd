extends Node3D

@export var patient_scene: PackedScene
@onready var summon_pos: Node3D = $summonPos
@onready var waiting_area: Area3D = $movePos

@export var spawn_interval: float = 5.0
@export var max_patients: int = 10

var spawn_timer: float = 0.0
var current_patients: int = 0	

func _process(delta):
	spawn_timer += delta
	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		if current_patients < max_patients:
			spawn_patient()

func spawn_patient():
	var patient = patient_scene.instantiate()
	get_tree().current_scene.add_child(patient)
	patient.global_transform.origin = summon_pos.global_transform.origin
	current_patients += 1
	if patient.has_node("HPTimer"):
		var hp_timer = patient.get_node("HPTimer")
		hp_timer.start()
		print("DEBUG: HPTimer started for new patient.")
	var random_pos = get_random_point_in_area(waiting_area)
	if patient.has_method("move_to_location"):
		patient.move_to_location(random_pos)

	print("Spawned patient #", current_patients, "→ Moving to:", random_pos)

# 🔹 Helper: pick a random point inside Area3D bounds
func get_random_point_in_area(area: Area3D) -> Vector3:
	var shape = area.get_node("CollisionShape3D").shape
	if shape is BoxShape3D:
		var extents = shape.size / 2.0
		var local_point = Vector3(
			randf_range(-extents.x, extents.x),
			0,
			randf_range(-extents.z, extents.z)
		)
		return area.global_transform.origin + local_point
	else:
		push_warning("WaitingArea must use a BoxShape3D for random point selection.")
		return area.global_transform.origin
