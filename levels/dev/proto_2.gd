extends Level

@onready var horse: Node3D = $Horse
@onready var human: Node3D = $Human
@onready var player: Player = $Player
@onready var body_part_container: Node3D = $Player/Body


func _on_horse_body_entered(body: Node3D) -> void:
	if body is Player:
		Log.info(self, "swapping to horse")
		var src: BodyPart = horse.get_node("root/legs")
		var dest: BodyPart = body_part_container.get_node("root/legs")
		Log.info(self, "swapping to horse", src, dest)
		if dest and src:
			dest.replace_with_body_part(src)

func _on_human_body_entered(body: Node3D) -> void:
	if body is Player:
		var src: BodyPart = human.get_node("root/legs")
		var dest: BodyPart = body_part_container.get_node("root/legs")
		Log.info(self, "swapping to human", src, dest)
		if dest and src:
			dest.replace_with_body_part(src)
