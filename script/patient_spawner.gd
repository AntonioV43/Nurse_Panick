extends Node3D

@export var patient_scene: PackedScene
@onready var summon_pos: Node3D = $summonPos
@onready var waiting_area: Area3D = $movePos

@export var end_menu_scene: PackedScene
@export var spawn_interval: float = 5.0
@export var max_patients: int = 10

var patients_processed_count: int = 0 
var patients_failed_count: int = 0

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

func patient_successfully_processed():
	patients_processed_count += 1
	print("Patient Processed. Total Success: ", patients_processed_count)
	
	check_end_game_condition() # Ganti nama fungsi pengecekan

func patient_failed_to_process():
	patients_failed_count += 1
	print("Patient Failed (Died). Total Failed: ", patients_failed_count)
	
	check_end_game_condition() # Cek akhir game

func check_end_game_condition():
	# Kondisi 1: Pastikan semua pasien yang seharusnya sudah di-spawn
	if current_patients < max_patients:
		return # Belum selesai spawn, jadi game belum berakhir
	
	var total_handled = patients_processed_count + patients_failed_count
	
	# Kondisi Akhir Game: Jumlah pasien yang *ditangani* (sukses + gagal) 
	# sama dengan total pasien yang harus di-spawn (max_patients)
	if total_handled == max_patients:
		if patients_processed_count == max_patients:
			# SEMUA SUKSES = MENANG
			print("GAME END: WIN CONDITION MET! All patients processed.")
			end_game(true)
		else:
			# ADA YANG GAGAL = KALAH
			print("GAME END: LOSS CONDITION MET! Patients failed.")
			end_game(false)
			

func end_game(is_win: bool):
	set_process(false)
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if end_menu_scene == null:
		push_error("End Menu Scene belum di-assign!")
		return

	var end_menu = end_menu_scene.instantiate()
	get_tree().root.add_child(end_menu) # Ganti add_child ke root untuk menghindari masalah
	
	if end_menu.has_method("set_end_screen_data"):
		var total_patients_saved = patients_processed_count
		var total_patients_failed = patients_failed_count
		var total_max_patients = max_patients
		
		# Kirim data pasien yang selamat
		end_menu.set_end_screen_data(is_win, total_patients_saved, total_patients_failed, total_max_patients)
		
	# Hapus scene game lama
	get_tree().current_scene.call_deferred("queue_free")
