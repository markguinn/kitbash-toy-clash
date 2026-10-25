class_name HitBox
extends Area3D

@warning_ignore("unused_signal")
signal caused_damage(amount: float, to: Life)

@export var damage := 1.0
@export var host: Node3D


func _ready() -> void:
	if not host:
		host = get_parent_node_3d()


func enable() -> void:
	set_deferred("monitorable", true)


func disable() -> void:
	set_deferred("monitorable", false)


func is_enabled() -> bool:
	return monitorable
