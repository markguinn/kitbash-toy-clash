class_name Life
extends Node

signal healed(gained_hp: float)
signal hurt(lost_hp: float, from_hit_box: HitBox)
signal dead(from_hit_box: HitBox)

@export var starting_hp := 1.0
## If set, the hp will be capped here
@export var max_hp := 0.0
## Combined with the armor on the hurtbox if relevant
## >1 reduces damage, <1 multiplies damage
@export var armor := 1.0
## Defaults to the parent node if not specified
@export var host: Node

var label: Label3D
var hp: float
var healthBar: TextureProgressBar


func _ready() -> void:
	hp = starting_hp
	if starting_hp > max_hp: max_hp = starting_hp
	if not host:
		host = get_parent()
	label = get_node_or_null("HealthLabel")
	if not label:
		label = host.get_node_or_null("HealthLabel")
	healthBar = get_node_or_null("HealthBar/the/health/bar")
	if not healthBar:
		healthBar = host.get_node_or_null("HealthBar/the/health/bar")
	_update_label()


func add_health(incoming_healing: float) -> float:
	var healing := incoming_healing
	hp += healing
	if max_hp and hp > max_hp:
		healing -= max_hp - hp
		hp = max_hp
	Log.debug(self, self.host.name, "healing ", healing, ". hp=", hp)
	if healing > 0.0:
		healed.emit.call_deferred(healing)
		_update_label.call_deferred()
	return healing


func add_damage(incoming_damage: float, from_hit_box: HitBox = null, bypass_armor = false) -> float:
	var damage: float = incoming_damage
	if not bypass_armor and not is_zero_approx(armor):
		damage /= armor
	if damage > hp:
		damage = hp
	hp -= damage
	Log.debug(self, self.host.name, "taking ", damage, "damage. hp=", hp)
	if from_hit_box:
		from_hit_box.caused_damage.emit.call_deferred(damage, self)
	if hp <= 0.0:
		dead.emit.call_deferred(from_hit_box)
	else:
		hurt.emit.call_deferred(damage, from_hit_box)
		_update_label.call_deferred()
	return damage


func _update_label() -> void:
	if label:
		label.text = "hp: %d" % [int(hp)]
	if healthBar:
		healthBar.value = (hp / max_hp) * 100
		# print("new health bar value:"+str(healthBar.value))
