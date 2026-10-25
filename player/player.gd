class_name Player extends CharacterBody3D

var cur_dir := Vector3(0.0, 0.0, 1.0)
var cur_cam := 0
var target_rot: float

var is_attacking := false
var is_walking := false
var walk_blend_tween: Tween

@onready var hurt_box: HurtBox = $HurtBox
@onready var life: Life = $Life

# We won't leave this in the final game. I suspect we'll use
# the ortho straight or ortho 45 view, but I'm not ready to
# commit yet. Press tab to swap between them.
@onready var cams: Array[Camera3D] = [
	$CamOrthoStraight,
	$CamOrtho45,
	$CamPerspective,
	$CamFrustrum,
]

@onready var body_mesh: Node3D = $Body
@onready var body_root: BodyPartContainer = $Body/root
@onready var animation_player: AnimationPlayer = $Body/AnimationPlayer
@onready var animation_tree: AnimationTree = $AnimationTree

@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D


func _ready() -> void:
	_set_cam(0)
	animation_tree.active = true
	animation_tree["parameters/moving/blend_amount"] = 0.0


func _vec2_to_vec3(dir: Vector2) -> Vector3:
	return Vector3(dir.x, 0.0, dir.y)


func _fix_angle(angle: float) -> float:
	return -angle + PI / 2.0


func _angle_to_vec2(angle: float) -> Vector2:
	return Vector2.RIGHT.rotated(_fix_angle(angle))


func _angle_to_vec3(angle: float) -> Vector3:
	return _vec2_to_vec3(_angle_to_vec2(angle))


func _set_cam(num: int) -> void:
	cur_cam = num % cams.size()
	for c in cams:
		c.current = false
	cams[cur_cam].current = true


func _get_input_dir() -> Vector2:
	var cam: Camera3D = get_viewport().get_camera_3d()
	var dir: Vector2 = Input.get_vector("left", "right", "up", "down")
	var compensation = snappedf(cam.rotation.y, PI / 4.0)
	return dir.rotated(-compensation)


func _tween_walk_blend(val: float) -> void:
	if walk_blend_tween and walk_blend_tween.is_running():
		walk_blend_tween.stop()
	walk_blend_tween = create_tween()
	walk_blend_tween.tween_property(animation_tree, "parameters/moving/blend_amount", val, 0.2)


func _physics_process(delta: float) -> void:
	var dir := _get_input_dir()

	if dir.length() > 0.0 and body_root.can_move:
		var walk_dir := _vec2_to_vec3(dir)
		var next_rot := _fix_angle(dir.angle())
		velocity = walk_dir * body_root.stats.move_speed
		if not is_equal_approx(target_rot, next_rot):
			body_root.change_direction.emit(walk_dir)
		target_rot = next_rot
		if not is_walking:
			_tween_walk_blend(1.0)
			body_root.walk_start.emit(walk_dir)
			is_walking = true
	else:
		velocity = Vector3.ZERO
		target_rot = body_mesh.rotation.y
		if is_walking:
			_tween_walk_blend(0.0)
			body_root.walk_end.emit(cur_dir)
			is_walking = false

	if !is_equal_approx(body_mesh.rotation.y, target_rot):
		if body_root.stats.turn_speed > 0.0:
			body_mesh.rotation.y = rotate_toward(body_mesh.rotation.y, target_rot, delta * PI * 2.0 / body_root.stats.turn_speed)
		else:
			body_mesh.rotation.y = target_rot
		cur_dir = _angle_to_vec3(body_mesh.rotation.y)

	if not is_on_floor():
		velocity.y = -10.0

	move_and_slide()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("attack1") and body_root.can_attack:
		_attack.call_deferred()
	if event.is_action_pressed("switch_cam"):
		_set_cam(cur_cam + 1)


func _attack() -> void:
	is_attacking = true
	animation_tree.set("parameters/attack/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	body_root.attack_start.emit(cur_dir)
	await animation_player.animation_finished
	body_root.attack_end.emit(cur_dir)
	is_attacking = false


func _on_health_drip() -> void:
	life.add_damage(1.0)


func _on_dead(from_hit_box: HitBox) -> void:
	# TODO: remember last hit in case the timer finishes you off?
	if from_hit_box:
		Game.player_died.emit(from_hit_box.host, from_hit_box)
	else:
		Game.player_died.emit(null, null)
