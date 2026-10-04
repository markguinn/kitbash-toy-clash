extends CharacterBody3D


@export var speed := 10.0
@export var projectile_speed := 30.0
@export var projectile_tpl: PackedScene

var cur_dir := Vector3(1.0, 0.0, 0.0)
var cur_cam := 0
var target_rot: float

@onready var hurt_box: HurtBox = $HurtBox
@onready var life: Life = $Life
@onready var cams: Array[Camera3D] = [
	$CamOrthoStraight,
	$CamOrtho45,
	$CamPerspective,
	$CamFrustrum,
]
@onready var body_mesh: Node3D = $BodyMesh
@onready var animation_player: AnimationPlayer = $BodyMesh/AnimationPlayer

func _ready() -> void:
	_set_cam(0)


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
		cur_dir = Vector3(dir.x, 0.0, dir.y)
		velocity = cur_dir * speed
		target_rot = -dir.angle() + PI / 2.0
		if animation_player.current_animation == "idle":
			animation_player.play("walk", 0.2)
	else:
		velocity = Vector3.ZERO
		if animation_player.current_animation == "walk":
			animation_player.play("idle", 0.2)
	if !is_equal_approx(body_mesh.rotation.y, target_rot):
		body_mesh.rotation.y = rotate_toward(body_mesh.rotation.y, target_rot, delta * PI * 2.0 / 0.4)
	move_and_slide()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("attack1") or event.is_action_pressed("attack2"):
		_attack.call_deferred()
	if event.is_action_pressed("switch_cam"):
		_set_cam(cur_cam + 1)


func _attack() -> void:
	var p: Projectile = projectile_tpl.instantiate()
	get_parent().add_child(p)
	p.global_position = global_position
	await get_tree().physics_frame
	p.apply_impulse(cur_dir * projectile_speed)


func _on_health_drip() -> void:
	life.add_damage(1.0)


func _on_dead(from_hit_box: HitBox) -> void:
	# TODO: remember last hit in case the timer finishes you off?
	if from_hit_box:
		Game.player_died.emit(from_hit_box.host, from_hit_box)
	else:
		Game.player_died.emit(null, null)
