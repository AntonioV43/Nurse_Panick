extends CharacterBody3D

@export var speed: float = 4.0
@export var stopping_distance: float = 1.6
@export var rotation_speed: float = 6.0

var target: Node3D = null
var following: bool = false

@onready var agent: NavigationAgent3D = $NavigationAgent3D
var moving_to_location: bool = false

# === Animation ===
@onready var anim_tree: AnimationTree = $AnimationTree
@onready var anim_state = anim_tree.get("parameters/playback")


func _ready() -> void:
	agent.avoidance_enabled = true
	agent.radius = 0.6
	agent.avoidance_layers = 1
	agent.avoidance_mask = 1
	agent.path_max_distance = 0.5
	agent.path_postprocessing = NavigationPathQueryParameters3D.PATH_POSTPROCESSING_CORRIDORFUNNEL


func move_to_location(target_position: Vector3) -> void:
	moving_to_location = true
	agent.target_position = target_position


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


# === ANIMATION LOGIC (WALK & IDLE BOOL) ===
func _update_animation():
	var speed_now = Vector3(velocity.x, 0, velocity.z).length()
	var moving = speed_now > 0.3

	# Update both booleans
	anim_tree.set("parameters/conditions/walk", moving)
	anim_tree.set("parameters/conditions/idle", not moving)


# === API ===
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
