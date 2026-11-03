// the classic inverted-hull outline effect
shader_type spatial;
render_mode unshaded, cull_front, depth_draw_opaque;
void vertex() { VERTEX += NORMAL * 0.025; }
void fragment() { ALBEDO = vec3(0.0, 0.0, 0.0); }

// how it works:
// draws an inside-out larger black version of your mesh
// how to use:
// add a "Next Pass" to a material
// set it to a ShaderMaterial using this
