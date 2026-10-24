class_name SwordArmBodyPart
extends BodyPart

@onready var hit_box: HitBox = $left_arm2/mesh/HitBox

func _ready() -> void:
	super._ready()
	hit_box.disable()
	
	var n = get_parent()
	while n:
		if n is CharacterBody3D:
			hit_box.host = n
			break
		n = n.get_parent()


func _on_attack_start(_dir: Vector3) -> void:
	hit_box.enable()
	pass


func _on_attack_end(_dir: Vector3) -> void:
	hit_box.disable()
	pass
