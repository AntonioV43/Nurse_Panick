extends CharacterBody3D

## === Movement and Navigation Properties ===
@export var speed: float = 4.0
@export var stopping_distance: float = 1.6
@export var rotation_speed: float = 6.0

var target: Node3D = null
var following: bool = false

@onready var agent: NavigationAgent3D = $NavigationAgent3D
var moving_to_location: bool = false

## === Animation Properties ===
@onready var anim_tree: AnimationTree = $AnimationTree
@onready var anim_state = anim_tree.get("parameters/playback")

## === HP System Properties ===
@export var max_health: int = 100
var current_health: int = 0
signal health_changed(new_health: int)
signal died
@export var damage_per_second: int = 1

## === Timer ===
@onready var hp_timer: Timer = $HPTimer

## === [BARU] COLOR SYSTEM ===
# Variabel untuk menyimpan tipe warna pasien
@export var patient_type: String = "" 

# Peta warna (bisa diubah di sini sesuai selera)
var color_map = {
	"merah": Color(1, 0.2, 0.2),   # Merah (Kritis)
	"biru": Color(0.2, 0.2, 1),    # Biru (Flu)
	"hijau": Color(0.2, 1, 0.2),   # Hijau (Racun)
	"kuning": Color(1, 1, 0.2)     # Kuning (Hati)
}

# Referensi Mesh untuk diubah warnanya
@onready var body_mesh = $Ireng/Armature/GeneralSkeleton/Ch28_Hoody


## ====================================================================
##                        LIFECYCLE FUNCTIONS
## ====================================================================

func _ready() -> void:
	# [BARU] Acak tipe pasien saat lahir
	randomize_patient_type()
	
	# HP Initialization
	current_health = max_health
	health_changed.emit(current_health)
	
	# Connect the Timer signal
	if not hp_timer.timeout.is_connected(_on_hp_timer_timeout):
		hp_timer.timeout.connect(_on_hp_timer_timeout)
	
	hp_timer.start()
	
	# Navigation setup
	agent.avoidance_enabled = true
	agent.radius = 0.6
	agent.avoidance_layers = 1
	agent.avoidance_mask = 1
	agent.path_max_distance = 0.5
	agent.path_postprocessing = NavigationPathQueryParameters3D.PATH_POSTPROCESSING_CORRIDORFUNNEL

# [BARU] Fungsi untuk mengacak tipe dan warna
func randomize_patient_type():
	var types = ["merah", "biru", "hijau", "kuning"]
	patient_type = types.pick_random()
	
	# Ubah visual
	apply_color(patient_type)
	
	# Ubah kesulitan berdasarkan warna (Contoh: Merah lebih cepat mati)
	if patient_type == "merah":
		damage_per_second = randi_range(3, 5) # Kritis
	else:
		damage_per_second = randi_range(1, 2) # Normal

# [BARU] Fungsi mengubah warna mesh
func apply_color(type_name: String):
	if body_mesh:
		# Buat material baru agar unik per pasien
		var new_mat = StandardMaterial3D.new()
		new_mat.albedo_color = color_map[type_name]
		
		# Override material yang ada
		body_mesh.material_override = new_mat
	else:
		print("Warning: Body Mesh tidak ditemukan untuk diwarnai.")

func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta
	else:
		velocity.y = 0.0

	# === NAVIGATION ===
	if moving_to_location:
		if agent.is_navigation_finished():
			moving_to_location = false
			velocity.x = 0
			velocity.z = 0
		else:
			var next_pos: Vector3 = agent.get_next_path_position()
			var dir = (next_pos - global_transform.origin).normalized()

			velocity.x = dir.x * speed
			velocity.z = dir.z * speed

			if dir.length_squared() > 0.001:
				var desired_rot_y = atan2(dir.x, dir.z)
				rotation.y = lerp_angle(rotation.y, desired_rot_y, rotation_speed * delta)

	# === FOLLOW TARGET ===
	elif following and target:
		var to_target: Vector3 = target.global_transform.origin - global_transform.origin
		var horizontal = Vector3(to_target.x, 0, to_target.z)
		var dist = horizontal.length()

		if dist > stopping_distance:
			var dir = horizontal.normalized()
			velocity.x = dir.x * speed
			velocity.z = dir.z * speed
		else:
			velocity.x = 0
			velocity.z = 0

		if horizontal.length_squared() > 0.001:
			var d = horizontal.normalized()
			var desired_rot = Vector3(0, atan2(d.x, d.z), 0)
			rotation.y = lerp_angle(rotation.y, desired_rot.y, clamp(rotation_speed * delta, 0, 1))

	# === IDLE ===
	else:
		velocity.x = 0
		velocity.z = 0

	move_and_slide()
	_update_animation()


## ====================================================================
##                        HP SYSTEM FUNCTIONS
## ====================================================================

func take_damage(amount: int) -> void:
	if current_health <= 0:
		return 

	current_health = max(0, current_health - amount)
	health_changed.emit(current_health)

	if current_health == 0:
		die()

func heal(amount: int) -> void:
	if current_health <= 0:
		return

	current_health = min(max_health, current_health + amount)
	health_changed.emit(current_health)

func die() -> void:
	hp_timer.stop()
	set_physics_process(false)
	set_process(false)

	moving_to_location = false
	following = false
	velocity = Vector3.ZERO

	var managers = get_tree().get_nodes_in_group("game_manager")
	var game_manager = null
	if not managers.is_empty():
		game_manager = managers[0]
	if game_manager and game_manager.has_method("patient_failed_to_process"):
		game_manager.patient_failed_to_process()
	
	died.emit()
	print("Patient died: ", patient_type) # Debug print tipe pasien
	call_deferred("queue_free")

func _on_hp_timer_timeout() -> void:
	take_damage(damage_per_second)
	if current_health > 0:
		hp_timer.start()


## ====================================================================
##                        MOVEMENT API FUNCTIONS
## ====================================================================

func move_to_location(target_position: Vector3) -> void:
	moving_to_location = true
	agent.target_position = target_position

func start_follow(new_target: Node3D) -> void:
	if new_target:
		target = new_target
		following = true

func stop_follow() -> void:
	following = false
	target = null

func toggle_follow(new_target: Node3D) -> void:
	if following:
		stop_follow()
	else:
		start_follow(new_target)


## ====================================================================
##                        ANIMATION FUNCTIONS
## ====================================================================

func _update_animation():
	var speed_now = Vector3(velocity.x, 0, velocity.z).length()
	var moving = speed_now > 0.3
	anim_tree.set("parameters/conditions/walk", moving)
	anim_tree.set("parameters/conditions/idle", not moving)

# --- SENSOR LOGIC (SESUAIKAN JIKA DIPERLUKAN) ---
func _on_sensor_ambil_body_entered(body: Node3D) -> void:
	pass

func _on_sensor_ambil_body_exited(body: Node3D) -> void:
	pass
