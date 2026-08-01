class_name HurtBox
extends Area3D

signal hurt(lost_hp: float, from_hit_box: HitBox)
signal dead(from_hit_box: HitBox)

@export var starting_hp := 1.0
@export var armor := 1.0
@export var host: Node3D

var label: Label3D
var hp: float


func _ready() -> void:
	label = get_node_or_null("HealthLabel")
	hp = starting_hp
	_update_label()
	area_entered.connect(_on_area_entered)
	if is_zero_approx(armor):
		armor = 0.001
	if not host:
		host = get_parent_node_3d()


func add_damage(incoming_damage: float, from_hit_box: HitBox = null, bypass_armor = false) -> void:
	var damage: float = incoming_damage
	if not bypass_armor:
		damage /= armor
	hp -= damage
	if from_hit_box:
		from_hit_box.caused_damage.emit.call_deferred(damage, self)
	if hp <= 0.0:
		dead.emit.call_deferred(from_hit_box)
	else:
		hurt.emit.call_deferred(damage, from_hit_box)
		_update_label.call_deferred()


func _on_area_entered(area: Area3D) -> void:
	if area is HitBox:
		add_damage(area.damage, area)


func _update_label() -> void:
	if label:
		label.text = "hp: %0.1f" % [hp]
