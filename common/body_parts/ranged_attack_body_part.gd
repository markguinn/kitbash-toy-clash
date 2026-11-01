class_name RangedAttackBodyPart
extends BodyPart

@export var projectile_speed := 50.0
@export var projectile_tpl: PackedScene
@export var fire_delay := 0.1
@export var fire_cooldown_during_special := 0.01

@onready var locator: Node3D = $right_arm2/locator

var fire_after: float = 0.0
var in_special: bool = false


func _on_attack_start(_dir: Vector3) -> void:
	fire_after = fire_delay


func _fire_projectile(dir: Vector3) -> void:
	var p: Projectile = projectile_tpl.instantiate()
	p.tree_entered.connect( ## Shoot the projectile once it's valid
		p.apply_impulse.bind(dir * projectile_speed),
		CONNECT_ONE_SHOT
	)
	Level.add_to_scene(p, locator.global_position)


func _on_special_start(_dir: Vector3) -> void:
	fire_after = fire_cooldown_during_special
	in_special = true


func _on_special_end(_dir: Vector3) -> void:
	fire_after = 0.0
	in_special = false


func _process(delta: float) -> void:
	if fire_after > 0.0:
		fire_after -= delta
		if fire_after <= 0.0:
			# TODO: this should roll back to the player rotation I think?
			# it's awkward right now because the animation is doing the spinning
			# but this is still placeholder territory
			var dir = Coords.angle_to_vec3(get_parent().global_rotation.y)
			_fire_projectile(dir)
			fire_after = fire_cooldown_during_special if in_special else 0.0
