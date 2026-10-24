class_name GunArmBodyPart
extends BodyPart

@export var projectile_speed := 30.0
@export var projectile_tpl: PackedScene
@export var fire_delay := 0.1

@onready var locator: Node3D = $right_arm2/locator


func _on_attack_start(cur_dir: Vector3) -> void:
	await get_tree().create_timer(fire_delay).timeout
	var p: Projectile = projectile_tpl.instantiate()
	p.tree_entered.connect( ## Shoot the projectile once it's valid
		p.apply_impulse.bind(cur_dir * projectile_speed),
		CONNECT_ONE_SHOT
	)
	Level.add_to_scene(p, locator.global_position)
