class_name Enemy
extends CharacterBody3D


## When the enemy causes damage from its own hitbox (not a projectile)
## How much of that damage does it also take?
@export var take_damage_from_causing_it := 0.2

## Does the enemy always look in the direction its moving?
@export var rotate_to_move_direction := true

@export var min_animation_speed := 0.8
@export var max_animation_speed := 1.2

@export var input_source: InputSource

var last_projectile := 0

@onready var hit_box: HitBox = $HitBox
@onready var hurt_box: HurtBox = $HurtBox
@onready var life: Life = $Life
@onready var body: BodyPartContainer = $Body


func _ready() -> void:
	life.dead.connect(_on_dead)
	hit_box.caused_damage.connect(_on_caused_damage)
	if min_animation_speed != max_animation_speed and body and body.animation_player:
		body.animation_player.speed_scale = randf_range(min_animation_speed, max_animation_speed)
	if not input_source:
		input_source = get_node_or_null("InputSource")
	if not input_source:
		input_source = get_node_or_null("DefaultEnemyInputSource")
	if input_source:
		input_source.attack.connect(_on_attack)
		input_source.special_attack.connect(_on_special)
		input_source.dash.connect(_on_dash)
	else:
		Log.error(self, "No input source found for", name)


var last_dir: Vector3
func _physics_process(_delta: float) -> void:
	var dir := Coords.vec2_to_vec3(input_source.get_move_dir())
	if body and rotate_to_move_direction:
		body.rotation.y = Coords.vec3_to_angle(dir)
	velocity = dir * body.stats.move_speed
	last_dir = dir
	move_and_slide()


func _on_attack() -> void:
	if body and body.can_attack:
		body.attack_start.emit(last_dir)


func _on_special() -> void:
	if body and body.can_special:
		body.special_start.emit(last_dir)


func _on_dash() -> void:
	if body and body.can_dash:
		body.dash_start.emit(last_dir)


# TODO: do something fun - animation, sounds, etc
func _on_dead(from_hit_box: HitBox) -> void:
	Game.enemy_died.emit(self, from_hit_box)
	queue_free()


func _on_caused_damage(amount: float, _to: Life) -> void:
	var returned_damage := amount * take_damage_from_causing_it
	if returned_damage > 0.0:
		life.add_damage.call_deferred(returned_damage)
