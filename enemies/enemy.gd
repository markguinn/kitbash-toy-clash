class_name Enemy
extends CharacterBody3D

@export var speed := 5.0
@export var loot_parts_dc := 0.1
@export var take_damage_from_causing_it := 0.2
@export var projectile_seconds := 1.0
@export var rotate_to_move_direction := true
@export var min_animation_speed := 0.8
@export var max_animation_speed := 1.2
@export var input_source: InputSource

var last_projectile := 0

@onready var hit_box: HitBox = $HitBox
@onready var hurt_box: HurtBox = $HurtBox
@onready var life: Life = $Life
@onready var body: Node3D = $Body

func _ready() -> void:
	life.dead.connect(_on_dead)
	hit_box.caused_damage.connect(_on_caused_damage)
	if min_animation_speed != max_animation_speed:
		var anim_player: AnimationPlayer = get_node_or_null("Body/AnimationPlayer")
		if anim_player:
			anim_player.speed_scale = randf_range(min_animation_speed, max_animation_speed)
		else:
			Log.warn(self, "no animation player found")
	if not input_source:
		input_source = get_node_or_null("InputSource")
	if not input_source:
		input_source = get_node_or_null("DefaultEnemyInputSource")
	if not input_source:
		Log.error(self, "No input source found for", name)


func _physics_process(_delta: float) -> void:
	var dir := Coords.vec2_to_vec3(input_source.get_move_dir())
	if body and rotate_to_move_direction:
		body.rotation.y = Coords.vec3_to_angle(dir)
	velocity = dir * speed
	move_and_slide()

	if Time.get_ticks_msec() > last_projectile + roundi(projectile_seconds * 1000.0):
		last_projectile = Time.get_ticks_msec()


# TODO: do something fun - animation, sounds, etc
func _on_dead(from_hit_box: HitBox) -> void:
	Game.enemy_died.emit(self, from_hit_box)
	queue_free()


func _on_caused_damage(amount: float, _to: Life) -> void:
	var returned_damage := amount * take_damage_from_causing_it
	if returned_damage > 0.0:
		life.add_damage.call_deferred(returned_damage)
