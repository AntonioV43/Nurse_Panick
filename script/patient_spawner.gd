extends Node3D

# --- KONFIGURASI ---
@export_group("Settings")
@export var patient_scene: PackedScene
@export var end_menu_scene: PackedScene

# --- REFERENSI NODE ---
@onready var summon_pos: Node3D = $summonPos
@onready var waiting_area: Area3D = $movePos
@onready var spawn_timer: Timer = $SpawnTimer

# --- DATA STATISTIK ---
var processed_count: int = 0 
var failed_count: int = 0
var total_spawned: int = 0

func _ready() -> void:
	if spawn_timer:
		spawn_timer.timeout.connect(_on_spawn_timer_timeout)
		spawn_timer.start()
		print("Spawner Stabil Dimulai. Waktu per spawn: ", spawn_timer.wait_time)

func _on_spawn_timer_timeout() -> void:
	spawn_patient()
	
	# CATATAN: Logika pengurangan waktu SUDAH DIHAPUS.
	# Waktu spawn akan tetap stabil sesuai settingan Timer awal (5 detik).
	print("Next spawn in: ", spawn_timer.wait_time)

func spawn_patient() -> void:
	if not patient_scene: return

	var patient = patient_scene.instantiate()
	get_tree().current_scene.add_child(patient)
	
	# Setup Posisi & HP
	patient.global_position = summon_pos.global_position
	if patient.has_node("HPTimer"): patient.get_node("HPTimer").start()
	
	# Setup Gerakan ke Waiting Area
	var random_pos = get_random_point(waiting_area)
	if patient.has_method("move_to_location"): patient.move_to_location(random_pos)

	total_spawned += 1

# Fungsi Helper: Ambil titik acak dalam kotak Area3D
func get_random_point(area: Area3D) -> Vector3:
	var shape = area.get_node_or_null("CollisionShape3D").shape as BoxShape3D
	if not shape: return area.global_position
	
	var extents = shape.size / 2.0
	return area.global_position + Vector3(
		randf_range(-extents.x, extents.x), 0, randf_range(-extents.z, extents.z)
	)

# --- LOGIKA GAME ---
func patient_successfully_processed() -> void:
	processed_count += 1
	print("Sukses: %d" % processed_count)

func patient_failed_to_process() -> void:
	failed_count += 1
	print("Gagal: %d" % failed_count)
	
	# Kondisi Kalah (Misal: 5 Pasien Mati)
	if failed_count >= 5: end_game(false)

func end_game(is_win: bool) -> void:
	if spawn_timer: spawn_timer.stop()
	
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if end_menu_scene:
		var menu = end_menu_scene.instantiate()
		get_tree().root.add_child(menu)
		if menu.has_method("set_end_screen_data"):
			menu.set_end_screen_data(is_win, processed_count, failed_count, total_spawned)
