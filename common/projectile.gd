class_name Projectile
extends RigidBody3D

@export var lifetime_ms := 1000
@export var explode_on_impact := false
@export var explode_on_time := false
@export var explosion_particles: CPUParticles3D
@export var explosion_size := 10.0
@export var body: Node3D

@onready var hit_box: HitBox = $HitBox

var created_at: int = 0
var exploding := false

func _ready() -> void:
	start_clock()
	if not body:
		body = get_node_or_null("Body")
	if not explosion_particles:
		explosion_particles = get_node_or_null("ExplosionParticles")
	if explosion_particles:
		explosion_particles.emitting = false
		explosion_particles.one_shot = true
		explosion_particles.hide()
	body_entered.connect(_on_body_entered)


func _process(_delta: float) -> void:
	if created_at > 0 and Time.get_ticks_msec() > created_at + lifetime_ms:
		if explode_on_time:
			explode.call_deferred()
		else:
			queue_free()


func start_clock() -> void:
	created_at = Time.get_ticks_msec()


func explode() -> void:
	Log.debug(self, "starting explosion", exploding)
	if exploding:
		return
	exploding = true
	if not explosion_particles:
		Log.error(self, "trying to explode without particles!")
		queue_free()
		return
	explosion_particles.restart()
	explosion_particles.show.call_deferred()
	VFX.shake(VFX.SHORT, VFX.QUAKE)
	if body:
		body.hide()
	hit_box.scale = Vector3.ONE * explosion_size
	freeze = true
	Log.debug(self, "waiting on particles")
	await explosion_particles.finished
	Log.debug(self, "freeing")
	queue_free()


func _on_body_entered(_body: Node3D) -> void:
	Log.debug(self, "contact with", _body)
	if explode_on_impact:
		explode.call_deferred()
