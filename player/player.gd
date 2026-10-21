class_name Player extends CharacterBody3D

@export var speed := 10.0
@export var rotation_speed := 0.4
@export var projectile_speed := 30.0
@export var projectile_tpl: PackedScene

var cur_dir := Vector3(0.0, 0.0, 1.0)
var cur_cam := 0
var target_rot: float

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

# this is very temporary - just feeling out the body swapping
@onready var body_mesh2: Node3D = $TempSwapBody
@onready var body_root2: Node3D = $TempSwapBody/root
@onready var legs2: Node3D = $TempSwapBody/root/legs
@onready var animation_player2: AnimationPlayer = $TempSwapBody/AnimationPlayer

@onready var body_mesh: Node3D = $BodyMesh
@onready var body_root: Node3D = $BodyMesh/root
@onready var legs: Node3D = $BodyMesh/root/legs
@onready var animation_player: AnimationPlayer = $BodyMesh/AnimationPlayer

@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D

func _ready() -> void:
	_set_cam(0)


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


func _physics_process(delta: float) -> void:
	var dir := _get_input_dir()
	if dir.length() > 0.0:
		velocity = _vec2_to_vec3(dir) * speed
		target_rot = _fix_angle(dir.angle())
		if animation_player.current_animation == "idle":
			animation_player.play("walk", 0.2)
	else:
		velocity = Vector3.ZERO
		target_rot = body_mesh.rotation.y
		if animation_player.current_animation == "walk":
			animation_player.play("idle", 0.2)
	if !is_equal_approx(body_mesh.rotation.y, target_rot):
		body_mesh.rotation.y = rotate_toward(body_mesh.rotation.y, target_rot, delta * PI * 2.0 / rotation_speed)
		cur_dir = _angle_to_vec3(body_mesh.rotation.y)
	if not is_on_floor():
		velocity.y = -10.0
	move_and_slide()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("attack1") or event.is_action_pressed("attack2"):
		_attack.call_deferred()
	if event.is_action_pressed("switch_cam"):
		_set_cam(cur_cam + 1)
	if event.is_action_pressed("ui_cancel"):
		_swap_legs()


func _swap_legs() -> void:
	body_mesh2.transform = body_mesh.transform
	body_root.remove_child(legs)
	body_root2.remove_child(legs2)
	body_root2.add_child(legs)
	body_root.add_child(legs2)
	
	for anim_name in animation_player.get_animation_list():
		var a1:Animation = animation_player.get_animation(anim_name)
		var a2:Animation = animation_player2.get_animation(anim_name)

		var a1_leg_tracks: Array[int] = []
		var a2_leg_tracks: Array[int] = []
		for i in range(a1.get_track_count()):
			var np: NodePath = a1.track_get_path(i)
			if np.get_name(1) == "legs":
				a1_leg_tracks.append(i)
		for i in range(a2.get_track_count()):
			var np: NodePath = a2.track_get_path(i)
			if np.get_name(1) == "legs":
				a2_leg_tracks.append(i)
		a1_leg_tracks.reverse()
		a2_leg_tracks.reverse()
		for idx in a1_leg_tracks:
			a1.copy_track(idx, a2)
			a1.remove_track(idx)
		for idx in a2_leg_tracks:
			a2.copy_track(idx, a1)
			a2.remove_track(idx)

	animation_player.clear_caches()
	
	var t = legs2
	legs2 = legs
	legs = t
	collision_shape_3d.shape.height = 4.0 if collision_shape_3d.shape.height == 2.0 else 2.0

func _attack() -> void:
	var p: Projectile = projectile_tpl.instantiate()
	p.global_position = global_position
	p.tree_entered.connect( ## Shoot the projectile once it's valid
		p.apply_impulse.bind(cur_dir * projectile_speed),
		CONNECT_ONE_SHOT
	)
	Level.add_to_scene(p)


func _on_health_drip() -> void:
	life.add_damage(1.0)


func _on_dead(from_hit_box: HitBox) -> void:
	# TODO: remember last hit in case the timer finishes you off?
	if from_hit_box:
		Game.player_died.emit(from_hit_box.host, from_hit_box)
	else:
		Game.player_died.emit(null, null)
