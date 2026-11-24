extends Area3D

@export var target: BodyPartContainer

func _ready() -> void:
	if not target and get_parent() is BodyPartContainer:
		target = get_parent()
	if not target and get_parent() is Enemy:
		target = get_parent().body
	if not target:
		for c in get_children():
			if c is BodyPartContainer:
				target = c
				break
			if c is Enemy:
				target = c.body
				break
	body_entered.connect(_on_body_enter)


func _on_body_enter(body) -> void:
	if body is Player:
		body.init_swap.call_deferred(target)
