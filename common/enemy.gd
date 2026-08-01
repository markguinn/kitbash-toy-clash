class_name Enemy
extends CharacterBody3D

@export var speed := 5.0
@export var loot_parts_dc := 0.1
@export var take_damage_from_causing_it := 1.0
@export var projectile_seconds := 1.0

var last_projectile := 0

@onready var hit_box: HitBox = $HitBox
@onready var hurt_box: HurtBox = $HurtBox


func _ready() -> void:
	hurt_box.dead.connect(_on_dead)
	hit_box.caused_damage.connect(_on_caused_damage)


func _physics_process(_delta: float) -> void:
	var player: CharacterBody3D = get_tree().get_first_node_in_group("player")
	if not player:
		return
	var dir := global_position.direction_to(player.global_position)
	velocity = dir * speed
	move_and_slide()
	
	if Time.get_ticks_msec() > last_projectile + roundi(projectile_seconds * 1000.0):
		last_projectile = Time.get_ticks_msec()


func _on_dead(from_hit_box: HitBox) -> void:
	GameManager.enemy_died.emit(self, from_hit_box)
	queue_free()


func _on_caused_damage(amount: float, _to_hurt_box: HurtBox) -> void:
	var returned_damage := amount * take_damage_from_causing_it
	if returned_damage > 0.0:
		hurt_box.add_damage.call_deferred(returned_damage)
