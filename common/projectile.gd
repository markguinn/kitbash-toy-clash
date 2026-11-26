class_name Projectile
extends RigidBody3D

## how long will the particle stay before being removed?
@export var lifetime_ms := 1000
## should the mesh body rotate to match it's velocity? or maintain its orientation?
@export var rotate_with_motion := true
## should it explode when impacting a wall or target (anything the rigidbody collides with, not the hit box) 
@export var explode_on_impact := false
## should it explode when time runs out?
@export var explode_on_time := false
## how much should the hit box scale up during the explosion?
@export var explosion_size := 10.0

@export_group("optional overrides")
## will automatically discover $ExplosionParticles. this is for a manual override
@export var explosion_particles: CPUParticles3D
## will automatically discover $Body. this is for a manual override
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
	if created_at > 0 and Now.msec > created_at + lifetime_ms:
		if explode_on_time:
			explode.call_deferred()
		else:
			queue_free()
	if body and rotate_with_motion:
		# NOTE: this may not look right if the body mesh isn't centered at the
		# origin and pointing towards the camera on the z axis
		body.global_rotation.x = -asin(linear_velocity.normalized().y)
		body.global_rotation.y = Coords.vec3_to_angle(linear_velocity.normalized())
		Log.d_info(self, "rot", linear_velocity, body.rotation.y, body.rotation.z)


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
