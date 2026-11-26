class_name RangedAttackBodyPart
extends BodyPart

@export var projectile_speed := 50.0
@export var projectile_tpl: PackedScene
@export var fire_delay := 0.1
@export var fire_cooldown_during_special := 0.01
@export var fire_position: Node3D
@export var fire_angle_deg: float = 0.0

var fire_after: float = 0.0
var in_special: bool = false


func _ready() -> void:
	super._ready()
	Log.debug(self, "ready", name, container)
	if projectile_tpl:
		SceneCacheWarmer.add(projectile_tpl)


func _on_attack_start(_dir: Vector3) -> void:
	Log.debug(self, "on attack start", fire_delay)
	fire_after = fire_delay


func _fire_projectile(dir: Vector3) -> void:
	Log.debug(self, "firing projectile")
	Log.measure_start(&"projectile")
	var p: Projectile = projectile_tpl.instantiate()
	var fire_height = sin(deg_to_rad(fire_angle_deg))
	var fire_dir: Vector3 = Vector3(dir.x, fire_height, dir.z).normalized()
	Log.debug(self, "fire dir", fire_dir, dir)
	p.tree_entered.connect( ## Shoot the projectile once it's valid
		p.apply_impulse.bind(fire_dir * projectile_speed),
		CONNECT_ONE_SHOT
	)
	p.ready.connect(
		Log.measure_end.bind(&"projectile", 100),
		CONNECT_ONE_SHOT
	)
	Level.add_to_scene(p, fire_position.global_position)


func _on_special_start(_dir: Vector3) -> void:
	fire_after = fire_cooldown_during_special
	in_special = true


func _on_special_end(_dir: Vector3) -> void:
	fire_after = 0.0
	in_special = false


func _process(delta: float) -> void:
	if fire_after > 0.0:
		fire_after -= delta
		if fire_after <= 0.0:
			_fire_projectile.call_deferred(container.get_facing_dir())
			fire_after = fire_cooldown_during_special if in_special else 0.0
