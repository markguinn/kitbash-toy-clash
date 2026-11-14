class_name RobotChestBodyPart
extends BodyPart

@onready var flame_emitter: FlameEmitter = $FlameEmitter
@onready var chest_flame: MeshInstance3D = $ChestFlame

var has_flame: bool = true


func _ready() -> void:
	super._ready()
	var roll = randf()
	flame_emitter.intensity = 0.0
	if roll < Game.config.get_value("robot", "flame_dc", 0.8):
		chest_flame.hide()
		has_flame = false


func _on_attack_start(_dir: Vector3) -> void:
	if has_flame:
		var attack_len = Game.config.get_value("robot", "attack_length", 4.0)
		flame_emitter.tween_to_intensity(1.0, attack_len * 0.25)
		await get_tree().create_timer(attack_len * 0.25).timeout
		flame_emitter.tween_to_intensity(0.0, attack_len * 0.5)
