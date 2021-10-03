extends KinematicBody

var velocity: Vector3 = Vector3.ZERO

var min_vertical_camera_rotation: float = -40.0
var max_vertical_camera_rotation: float = 70.0
var camera_x_rotation: float = 0.0

export var mouse_sensitivity: Vector2 = Vector2(0.01, 0.004)
export var right_stick_sensitivity: Vector2 = Vector2(0.07, 0.035)

var move_interpolation = 15.0
var rotation_interpolation = 10.0

export var move_speed: float = 50.0
export var jump_force: float = 10.0
export var gravity: float = 9.8

var origin_basis = Basis()
var orientation = Transform()

onready var mesh = $Mesh

onready var camera_root = $CameraRoot
onready var camera_pivot = $CameraRoot/CameraPivot
onready var camera = $CameraRoot/CameraPivot/CameraOffset/Camera

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

func _process(delta: float) -> void:
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
	var move_direction: Vector2 = Vector2(
		Input.get_action_strength("move_left") - Input.get_action_strength("move_right"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)
	
	var movement: Vector2 = Vector2.ZERO
	movement = movement.linear_interpolate(move_direction * move_speed, move_interpolation * delta)
	
	var camera_z = -camera.global_transform.basis.z
	var camera_x = camera.global_transform.basis.x
	camera_z.y = 0
	camera_z = camera_z.normalized()
	camera_x.y = 0
	camera_x = camera_x.normalized()
	
	var direction = -camera_x * movement.x - camera_z * movement.y
	
	velocity.x = direction.x
	velocity.z = direction.z
	
	if move_direction.length() > 0.01:
		rotate_character(direction, delta)
	
	velocity = move_and_slide(velocity, Vector3.UP)

func rotate_character(direction: Vector3, delta: float) -> void:
	var from = Quat(orientation.basis)
	var to = Quat(Transform().looking_at(direction, Vector3.UP).basis)
	
	orientation.basis = Basis(from.slerp(to, delta * rotation_interpolation))
	
	orientation = orientation.orthonormalized()
	mesh.global_transform.basis = orientation.basis































