class_name HitBox
extends Area3D

signal caused_damage(amount: float, to_hurt_box: HurtBox)

@export var damage := 1.0
@export var host: Node3D

func _ready() -> void:
	if not host:
		host = get_parent_node_3d()
