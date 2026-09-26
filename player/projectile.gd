class_name Projectile
extends RigidBody3D

@export var lifetime_ms := 1000
@export var loot_parts_dc := 0.1


var created_at: int = 0


func _ready() -> void:
	start_clock()


func _process(_delta: float) -> void:
	if created_at > 0 and Time.get_ticks_msec() > created_at + lifetime_ms:
		queue_free()


func start_clock() -> void:
	created_at = Time.get_ticks_msec()
