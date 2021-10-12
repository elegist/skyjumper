extends KinematicBody

var velocity: Vector3 = Vector3.ZERO

export var gravity: float = -40.0

export var max_speed: float = 16.0
export var acceleration: float = 70.0
export var ground_friction: float = 60.0
export var air_resistance: float = 50.0
export var jump_height: float = 18.0
export var dash_factor: int = 40

var max_jump_count: int = 2
var jump_count: int = 0

export var mouse_sensitivity: Vector2 = Vector2(0.0025, 0.0025)
export var right_stick_sensitivity: Vector2 = Vector2(0.07, 0.035)

var min_vertical_camera_rotation: float = -50.0
var max_vertical_camera_rotation: float = 50.0
var camera_x_rotation: float = 0.0

var rotation_interpolation = 10.0

var origin_basis = Basis()
var orientation = Transform()

var snap_vector: Vector3 = Vector3.ZERO

onready var mesh = $Mesh

onready var camera_root = $CameraRoot
onready var camera_pivot = $CameraRoot/CameraPivot
onready var camera = $CameraRoot/CameraPivot/CameraSpringArm/Camera
onready var animation_tree = $Mesh/AnimationTree

onready var wall_check_forward = $Mesh/WallChecks/Forward
onready var wall_check_left = $Mesh/WallChecks/Left
onready var wall_check_right = $Mesh/WallChecks/Right

onready var origin_parent = get_parent()

func _ready() -> void:
	orientation = mesh.global_transform
	origin_basis = global_transform.basis

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		camera_root.rotate_y(event.relative.x * -mouse_sensitivity.x)
		camera_root.orthonormalize()
		camera_x_rotation = clamp(camera_x_rotation + event.relative.y * mouse_sensitivity.y, deg2rad(min_vertical_camera_rotation), deg2rad(max_vertical_camera_rotation))
		camera_pivot.rotation.x = -camera_x_rotation

func _process(_delta: float) -> void:
	var camera_target: Vector2 = Vector2.ZERO
	camera_target = Vector2(
		Input.get_action_strength("camera_left") - Input.get_action_strength("camera_right"), 
		Input.get_action_strength("camera_down") - Input.get_action_strength("camera_up")
		)
	
	camera_root.rotate_y(camera_target.x * right_stick_sensitivity.x)
	camera_root.orthonormalize()
	camera_x_rotation = clamp(camera_x_rotation + camera_target.y * right_stick_sensitivity.y, deg2rad(min_vertical_camera_rotation), deg2rad(max_vertical_camera_rotation))
	camera_pivot.rotation.x = -camera_x_rotation

func _physics_process(delta: float) -> void:
	var input_vector = _get_input_vector()
	var move_direction = _get_move_direction(input_vector)
	
	_update_snap_vector()
	
	apply_gravity(delta)
	
	apply_movement(move_direction, delta)
	
	if is_on_floor():
		jump_count = max_jump_count
	
	if Input.is_action_just_pressed("jump") && jump_count > 0:
		apply_jump()
		jump_count -= 1
	elif Input.is_action_just_released("jump") && velocity.y > jump_height / 2:
		velocity.y = jump_height / 2
	
	if Input.is_action_just_pressed("dash"):
		apply_dash(move_direction, delta)
	
	if Input.is_action_pressed("dash"):
		if is_on_wall():
			apply_wallrun(move_direction)
	else:
		wall_check_forward.enabled = false
		wall_check_left.enabled = false
		wall_check_right.enabled = false
	
	velocity = move_and_slide_with_snap(velocity, snap_vector, Vector3.UP, true)
	
	apply_animations()

func _get_input_vector() -> Vector3:
	var input_vector = Vector3.ZERO
	input_vector.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_vector.z = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	return input_vector.normalized() if input_vector.length() > 1 else input_vector

func _get_move_direction(input_vector: Vector3) -> Vector3:
	var move_direction = (input_vector.x * camera_root.transform.basis.x) + (input_vector.z * camera_root.transform.basis.z)
	return move_direction

func _update_snap_vector() -> void:
	snap_vector = -get_floor_normal() if is_on_floor() else Vector3.DOWN

func apply_gravity(delta: float) -> void:
	velocity.y += gravity * delta
	velocity.y = clamp(velocity.y, gravity, jump_height)

func apply_movement(move_direction: Vector3, delta: float) -> void:
	if move_direction != Vector3.ZERO:
		velocity.x = velocity.move_toward(move_direction * max_speed, acceleration * delta).x
		velocity.z = velocity.move_toward(move_direction * max_speed, acceleration * delta).z
		mesh.rotation.y = lerp_angle(mesh.rotation.y, atan2(-move_direction.x, -move_direction.z), 10 * delta)
	else:
		if is_on_floor():
			velocity = velocity.move_toward(Vector3.ZERO, ground_friction * delta)
		else:
			velocity.x = velocity.move_toward(Vector3.ZERO, air_resistance * delta).x
			velocity.z = velocity.move_toward(Vector3.ZERO, air_resistance * delta).z

func apply_jump() -> void:
	snap_vector = Vector3.ZERO
	velocity.y = jump_height

func apply_dash(move_direction: Vector3, delta: float) -> void:
	velocity.x = velocity.move_toward(move_direction * max_speed * dash_factor, acceleration * dash_factor * delta).x
	velocity.z = velocity.move_toward(move_direction * max_speed * dash_factor, acceleration * dash_factor * delta).z
	yield(get_tree().create_timer(0.25), "timeout")
	velocity.x = velocity.move_toward(Vector3.ZERO, 50).x
	velocity.z = velocity.move_toward(Vector3.ZERO, 50).z

func apply_wallrun(move_direction: Vector3) -> void:
	wall_check_forward.enabled = true
	wall_check_left.enabled = true
	wall_check_right.enabled = true
	
	if wall_check_forward.is_colliding() && (!wall_check_left.is_colliding() || wall_check_right.is_colliding()):
		velocity.y = max_speed
	if wall_check_left.is_colliding() || wall_check_right.is_colliding():
		velocity.x = move_direction.x * max_speed
		velocity.z = move_direction.z * max_speed
		velocity.y = 0.0

func apply_animations() -> void:
	if is_on_wall():
		animation_tree.set("parameters/location/current", 0)
		animation_tree.set("parameters/ground_state/current", 1)
	else:
		if !is_on_floor():
			animation_tree.set("parameters/location/current", 1)
			if velocity.y < 0:
				animation_tree.set("parameters/air_state/current", 1)
			else:
				animation_tree.set("parameters/air_state/current", 0)
		else:
			animation_tree.set("parameters/location/current", 0)
			if velocity.x != 0 || velocity.z != 0:
				animation_tree.set("parameters/ground_state/current", 1)
				animation_tree.set("parameters/run_speed/scale", abs(velocity.length() / max_speed))
			else:
				animation_tree.set("parameters/ground_state/current", 0)
				animation_tree.set("parameters/run_speed/scale", 1.0)
