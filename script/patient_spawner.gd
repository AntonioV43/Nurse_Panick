extends Node3D

@export_group("Settings")
# Ini yang bikin bisa masukin banyak pasien
@export var patient_scenes: Array[PackedScene] 
@export var end_menu_scene: PackedScene
@export var max_failed_patients: int = 5

@onready var summon_pos: Node3D = $summonPos
@onready var waiting_area: Area3D = $movePos
@onready var spawn_timer: Timer = $SpawnTimer

var processed_count: int = 0
var failed_count: int = 0
var total_spawned: int = 0
var is_game_over: bool = false

# Variabel HUD
var stats_label: Label = null
var highscore_label: Label = null 

func _ready() -> void:
	stats_label = get_tree().get_first_node_in_group("stats_ui")
	highscore_label = get_tree().get_first_node_in_group("highscore_ui")
	update_ui()
	if highscore_label: highscore_label.text = "Best: %d" % GameData.high_score
	
	if spawn_timer:
		spawn_timer.timeout.connect(_on_spawn_timer_timeout)
		spawn_timer.start()

func _on_spawn_timer_timeout() -> void:
	if not is_game_over: spawn_patient()

func spawn_patient() -> void:
	if patient_scenes.is_empty(): return # Cek biar ga crash

	# PILIH ACAK DARI ARRAY
	var random_scene = patient_scenes.pick_random()
	var patient = random_scene.instantiate()
	
	get_tree().current_scene.add_child(patient)
	patient.global_position = summon_pos.global_position
	
	if patient.has_node("HPTimer"): patient.get_node("HPTimer").start()
	if patient.has_signal("died"): patient.died.connect(patient_failed_to_process)
	
	if patient.has_method("move_to_location"):
		patient.move_to_location(get_random_point(waiting_area))

	total_spawned += 1

func get_random_point(area: Area3D) -> Vector3:
	var shape = area.get_node_or_null("CollisionShape3D").shape as BoxShape3D
	if not shape: return area.global_position
	var ext = shape.size / 2.0
	return area.global_position + Vector3(randf_range(-ext.x, ext.x), 0, randf_range(-ext.z, ext.z))

func update_ui():
	if stats_label:
		stats_label.text = "Selamat: %d | Meninggal: %d" % [processed_count, failed_count]

func patient_successfully_processed() -> void:
	if is_game_over: return
	processed_count += 1
	GameData.update_high_score(processed_count)
	update_ui()
	if highscore_label: highscore_label.text = "Best: %d" % GameData.high_score

func patient_failed_to_process() -> void:
	if is_game_over: return
	failed_count += 1
	update_ui()
	if failed_count >= max_failed_patients:
		is_game_over = true
		end_game(false)

func end_game(is_win: bool) -> void:
	if spawn_timer: spawn_timer.stop()
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if end_menu_scene:
		var menu = end_menu_scene.instantiate()
		get_tree().root.add_child(menu)
		if menu.has_method("set_end_screen_data"):
			menu.set_end_screen_data(is_win, processed_count, failed_count, total_spawned)
