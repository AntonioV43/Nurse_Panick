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


## ====================================================================
##                        LIFECYCLE FUNCTIONS
## ====================================================================

func _ready() -> void:
	# HP Initialization
	current_health = max_health
	health_changed.emit(current_health)
	
	# Connect the Timer signal
	hp_timer.timeout.connect(_on_hp_timer_timeout)
	
	# ⭐ CRITICAL FIX: Start the timer manually to guarantee damage over time begins 
	# even when the patient is spawned/instantiated from another script.
	hp_timer.start()
	
	# Navigation setup
	agent.avoidance_enabled = true
	agent.radius = 0.6
	agent.avoidance_layers = 1
	agent.avoidance_mask = 1
	agent.path_max_distance = 0.5
	agent.path_postprocessing = NavigationPathQueryParameters3D.PATH_POSTPROCESSING_CORRIDORFUNNEL


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

## 💥 Function to inflict damage
func take_damage(amount: int) -> void:
	if current_health <= 0:
		return # Already dead

	current_health = max(0, current_health - amount)
	health_changed.emit(current_health) 

	if current_health == 0:
		die()

## 💚 Function to heal the patient
func heal(amount: int) -> void:
	if current_health <= 0:
		return 

	current_health = min(max_health, current_health + amount)
	health_changed.emit(current_health) 

## 💀 Function for when the patient dies (Disappears Safely)
func die() -> void:
	# Stop all processing and timers immediately
	hp_timer.stop()
	
	# ⭐ GODOT 4 FIX: Use set_physics_process()
	set_physics_process(false) 
	set_process(false) 

	# Stop movement and velocity instantly
	moving_to_location = false
	following = false
	velocity = Vector3.ZERO 

	# Emit signal for game management
	died.emit()
	
	print("Patient has died and is queued for removal.")

	# Use call_deferred to ensure the node is freed safely (reliably disappears)
	call_deferred("queue_free") 

## ⏱️ Timer timeout logic (Damage Over Time)
func _on_hp_timer_timeout() -> void:
	# Inflict the damage defined by damage_per_second
	take_damage(damage_per_second)
	
	# Restart the timer if the patient is still alive (since it's a One-Shot)
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

# === ANIMATION LOGIC (WALK & IDLE BOOL) ===
func _update_animation():
	var speed_now = Vector3(velocity.x, 0, velocity.z).length()
	var moving = speed_now > 0.3

	# Update both booleans
	anim_tree.set("parameters/conditions/walk", moving)
	anim_tree.set("parameters/conditions/idle", not moving)
