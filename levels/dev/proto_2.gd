extends Level

@onready var player: Player = $Player
@onready var body_part_container: Node3D = $Player/Body


func _on_horse_body_entered(body: Node3D) -> void:
	if body is Player:
		Log.info(self, "swapping to horse")
		var src: BodyPart = $Horse.get_node("root/legs")
		var dest: BodyPart = body_part_container.get_node("root/legs")
		Log.info(self, "swapping to horse", src, dest)
		if dest and src:
			dest.replace_with_body_part(src)

func _on_human_body_entered(body: Node3D) -> void:
	if body is Player:
		var src: BodyPart = $Human.get_node("root/legs")
		var dest: BodyPart = body_part_container.get_node("root/legs")
		Log.info(self, "swapping to human", src, dest)
		if dest and src:
			dest.replace_with_body_part(src)


var has_sword := true
func _on_sword_arm_body_entered(body: Node3D) -> void:
	if body is Player:
		var src_node = $GunArm if has_sword else $SwordArm
		has_sword = !has_sword
		var src: BodyPart = src_node.get_node("root/torso/left_arm")
		var dest: BodyPart = body_part_container.get_node("root/torso/left_arm")
		Log.info(self, "swapping to sword arm", src, dest)
		if dest and src:
			dest.replace_with_body_part(src)


var has_gun := false
func _on_gun_arm_body_entered(body: Node3D) -> void:
	if body is Player:
		var src_node = $SwordArm if has_gun else $GunArm
		has_gun = !has_gun
		var src: BodyPart = src_node.get_node("root/torso/right_arm")
		var dest: BodyPart = body_part_container.get_node("root/torso/right_arm")
		Log.info(self, "swapping to gun arm", src, dest)
		if dest and src:
			dest.replace_with_body_part(src)
