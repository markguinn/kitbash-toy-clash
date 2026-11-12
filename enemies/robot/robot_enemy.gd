class_name RobotChestBodyPart
extends BodyPart

const FLAME_DC = 1.2
const ATTACK_LEN = 1.0

@onready var flame_emitter: FlameEmitter = $FlameEmitter
@onready var chest_flame: MeshInstance3D = $ChestFlame

var has_flame: bool = true


func _ready() -> void:
	super._ready()
	var roll = randf()
	flame_emitter.intensity = 0.0
	if roll > FLAME_DC:
		chest_flame.hide()
		has_flame = false


func _on_attack_start(_dir: Vector3) -> void:
	if has_flame:
		flame_emitter.tween_to_intensity(1.0, ATTACK_LEN)
		await get_tree().create_timer(1.0).timeout
		flame_emitter.tween_to_intensity(0.0, 3.0)
