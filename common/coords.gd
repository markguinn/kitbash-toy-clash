class_name Coords


static func vec2_to_vec3(dir: Vector2) -> Vector3:
	return Vector3(dir.x, 0.0, dir.y)


static func vec3_to_vec2(dir: Vector3) -> Vector2:
	return Vector2(dir.x, dir.z)


static func vec3_to_angle(dir: Vector3) -> float:
	return fix_angle(vec3_to_vec2(dir).angle())


static func vec2_to_angle(dir: Vector2) -> float:
	return fix_angle(dir.angle())


static func fix_angle(angle: float) -> float:
	return -angle + PI / 2.0


static func angle_to_vec2(angle: float) -> Vector2:
	return Vector2.RIGHT.rotated(fix_angle(angle))


static func angle_to_vec3(angle: float) -> Vector3:
	return vec2_to_vec3(angle_to_vec2(angle))
