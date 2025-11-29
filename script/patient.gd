extends CharacterBody3D

## === CONFIGURATION ===
@export_group("Movement")
@export var speed: float = 4.0
@export var stopping_distance: float = 1.6
@export var rotation_speed: float = 6.0

@export_group("Stats")
@export var max_health: int = 100
var current_health: int = 0
@export var damage_per_second: int = 1

# [PENTING] SLOT MODEL BAJU
@export var body_mesh: MeshInstance3D 

# --- SYSTEM VARIABLES ---
var target: Node3D = null
var following: bool = false
var moving_to_location: bool = false
@export var patient_type: String = "" 

# --- REFERENCES ---
@onready var agent: NavigationAgent3D = $NavigationAgent3D
@onready var hp_timer: Timer = $HPTimer
@onready var anim_tree: AnimationTree = $AnimationTree

# --- SIGNALS ---
signal health_changed(new_health: int)
signal died

# --- COLOR MAP ---
var color_map = {
	"merah": Color(1, 0.2, 0.2),
	"biru": Color(0.2, 0.2, 1),
	"hijau": Color(0.2, 1, 0.2),
	"kuning": Color(1, 1, 0.2)
}

func _ready() -> void:
	randomize_patient_type()
	
	current_health = max_health
	health_changed.emit(current_health)
	
	if not hp_timer.timeout.is_connected(_on_hp_timer_timeout):
		hp_timer.timeout.connect(_on_hp_timer_timeout)
	hp_timer.start()
	
	agent.path_postprocessing = NavigationPathQueryParameters3D.PATH_POSTPROCESSING_CORRIDORFUNNEL
	agent.avoidance_enabled = true

# --- LOGIKA WARNA ---
func randomize_patient_type():
	var types = ["merah", "biru", "hijau", "kuning"]
	patient_type = types.pick_random()
	apply_color(patient_type)
	
	if patient_type == "merah":
		damage_per_second = randi_range(3, 5) 
	else:
		damage_per_second = randi_range(1, 2) 

func apply_color(type_name: String):
	if body_mesh:
		var new_mat = StandardMaterial3D.new()
		new_mat.albedo_color = color_map[type_name]
		body_mesh.material_override = new_mat
	else:
		print("PERINGATAN: Body Mesh belum diisi di Inspector!")

# --- LOGIKA GERAK ---
func _physics_process(delta: float) -> void:
	if not is_on_floor(): velocity.y -= 9.8 * delta

	if moving_to_location:
		if agent.is_navigation_finished():
			moving_to_location = false
			velocity = Vector3.ZERO
		else:
			var next_pos = agent.get_next_path_position()
			var dir = (next_pos - global_position).normalized()
			velocity.x = dir.x * speed
			velocity.z = dir.z * speed
			look_at_smooth(dir, delta)

	elif following and target:
		var dir = (target.global_position - global_position)
		dir.y = 0
		if dir.length() > stopping_distance:
			dir = dir.normalized()
			velocity.x = dir.x * speed
			velocity.z = dir.z * speed
			look_at_smooth(dir, delta)
		else:
			velocity = Vector3.ZERO
	else:
		velocity.x = 0
		velocity.z = 0

	move_and_slide()
	_update_animation()

func look_at_smooth(dir: Vector3, delta: float):
	if dir.length_squared() > 0.001:
		var target_rot = atan2(dir.x, dir.z)
		rotation.y = lerp_angle(rotation.y, target_rot, rotation_speed * delta)

# --- HP SYSTEM ---
func take_damage(amount: int):
	if current_health <= 0: return
	current_health = max(0, current_health - amount)
	health_changed.emit(current_health)
	if current_health == 0: die()

func die() -> void:
	hp_timer.stop()
	set_physics_process(false)
	moving_to_location = false
	following = false
	
	# 1. Cari Hospital (Game Manager) untuk mematikan UI
	var hospital_controller = get_tree().get_first_node_in_group("game_manager")
	if hospital_controller and hospital_controller.has_method("sembunyikan_ui"):
		hospital_controller.sembunyikan_ui()
	
	# 2. Cari Spawner untuk lapor kematian (Update Skor)
	# Kita coba cari di grup 'spawner' dulu, kalau tidak ada coba 'game_manager'
	var spawner = get_tree().get_first_node_in_group("spawner")
	if not spawner: 
		spawner = get_tree().get_first_node_in_group("game_manager")
		
	if spawner and spawner.has_method("patient_failed_to_process"):
		spawner.patient_failed_to_process()
	
	died.emit()
	print("Patient died: ", patient_type)
	call_deferred("queue_free")
	
	died.emit()
	call_deferred("queue_free")

func _on_hp_timer_timeout():
	take_damage(damage_per_second)
	if current_health > 0: hp_timer.start()

# --- MOVEMENT API (INTERAKSI) ---
func move_to_location(pos: Vector3):
	moving_to_location = true
	agent.target_position = pos

func start_follow(new_target: Node3D):
	moving_to_location = false # Stop AI navigation
	target = new_target
	following = true
	print("Pasien mulai mengikuti.")

func stop_follow():
	following = false
	target = null
	print("Pasien berhenti mengikuti.")

# Dipanggil oleh Player.gd saat tombol E ditekan
func toggle_follow(new_target: Node3D):
	if following:
		stop_follow()
	else:
		start_follow(new_target)

# --- SENSOR LOGIC (UNTUK MEMUNCULKAN UI) ---
# Pastikan Sensor_Ambil di scene Pasien tersambung ke sini!
# --- SENSOR LOGIC (UNTUK MEMUNCULKAN UI) ---
func _on_sensor_ambil_body_entered(body: Node3D) -> void:
	# Cek jika yang masuk adalah Player (pastikan nama node player kamu 'player')
	if body.name == "player" or body.is_in_group("player_node"):
		var manager = get_tree().get_first_node_in_group("game_manager")
		if manager:
			# Panggil fungsi UI di Hospital
			manager.tampilkan_ui("[E] Bawa / Lepas Pasien")

func _on_sensor_ambil_body_exited(body: Node3D) -> void:
	if body.name == "player" or body.is_in_group("player_node"):
		var manager = get_tree().get_first_node_in_group("game_manager")
		if manager:
			# Matikan UI
			manager.sembunyikan_ui()

# --- ANIMATION ---
func _update_animation():
	var is_moving = Vector3(velocity.x, 0, velocity.z).length() > 0.1
	if anim_tree:
		anim_tree.set("parameters/conditions/walk", is_moving)
		anim_tree.set("parameters/conditions/idle", not is_moving)
