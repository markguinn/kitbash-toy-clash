class_name Life
extends Node

const SHOW_HP_SECONDS = 2.0

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
var healthBar: TextureProgressBar

var hp: float
var label_seconds_remaining: float = 0.0


func _ready() -> void:
	hp = starting_hp
	if starting_hp > max_hp: max_hp = starting_hp
	if not host:
		host = get_parent()
	
	# label above head eg. "hp: 9"
	label = get_node_or_null("HealthLabel")
	if not label:
		label = host.get_node_or_null("HealthLabel")
	if label and not Game.config.get_value("display", "hp_labels_enabled", false):
		label.hide()
		label = null

	# red progress bar style health bar
	healthBar = get_node_or_null("HealthBar/the/health/bar")
	if not healthBar:
		healthBar = host.get_node_or_null("HealthBar/the/health/bar")
	if healthBar and not Game.config.get_value("display", "healthbars_enabled", false):
		healthBar.hide()
		healthBar = null

	_update_label()
	if Game.config.get_value("display", "hide_healthbars_after", 0.0) > 0.0:
		_hide_label()
		label_seconds_remaining = -1.0


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
		_update_label.call_deferred(!!from_hit_box)
	return damage


func _update_label(show = true) -> void:
	if label:
		label.text = "hp: %d" % [int(hp)]
		if show:
			label.show()
	if healthBar:
		healthBar.value = (hp / max_hp) * 100
		if show:
			healthBar.show()
	var hide_after: float = Game.config.get_value("display", "hide_healthbars_after", 0.0)
	if show and hide_after > 0.0:
		label_seconds_remaining = hide_after


func _hide_label() -> void:
	if label:
		label.hide()
	if healthBar:
		healthBar.hide()


func _process(delta: float) -> void:
	if label_seconds_remaining > 0.0:
		label_seconds_remaining -= delta
		if label_seconds_remaining <= 0.0:
			label_seconds_remaining = 0.0
			_hide_label()
