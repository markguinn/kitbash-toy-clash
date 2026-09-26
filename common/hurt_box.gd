class_name HurtBox
extends Area3D

## Combined with the armor on the life node (allows some body parts to be more vulnerable than others)
## >1 reduces damage, <1 multiplies damage
@export var armor := 1.0
## Defaults to the parent node
@export var host: Node3D
## Defaults to a sibling node named "Life"
@export var life: Life


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	if not host:
		host = get_parent_node_3d()
	if not life:
		life = host.get_node_or_null("Life")


func _on_area_entered(area: Area3D) -> void:
	if area is HitBox:
		var damage = area.damage
		if not is_zero_approx(armor):
			damage /= armor
		life.add_damage(damage, area)
