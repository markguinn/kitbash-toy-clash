class_name BodyPartContainer
extends Node3D

@export var host: Node3D
@export var animation_player: AnimationPlayer

func _ready() -> void:
	if not host:
		host = get_parent()
	if not animation_player:
		animation_player = host.get_node("AnimationPlayer")
