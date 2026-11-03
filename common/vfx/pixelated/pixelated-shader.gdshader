shader_type canvas_item;

const int PALETTE_SIZE = 27;

uniform vec2 size = vec2(8.0, 8.0); // size of pixel - adjust to taste
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform bool quantize_palette = true;
uniform vec3[PALETTE_SIZE] palette : source_color;

void fragment() {
	vec2 s = size * SCREEN_PIXEL_SIZE;
	vec2 uv = SCREEN_UV + vec2(s.x, 0.0);
	vec2 final_uv = floor(uv / s) * s;
	float min_dist = 9999.0;
	vec4 original_color = textureLod(screen_texture, final_uv, 0.0);
	vec3 quantized_color = vec3(0.0, 1.0, 0.0); //bright debug-green color
	if (quantize_palette) {
		for (int i = 0; i < PALETTE_SIZE; i++) {
			vec3 palette_color = palette[i];
			float dist = distance(original_color.rgb, palette_color);
			if (dist < min_dist) {
				min_dist = dist;
				quantized_color = palette_color;
			}
		}
		COLOR = vec4(quantized_color.r, quantized_color.g, quantized_color.b, original_color.a);
	} else {
		COLOR = original_color;
	}
}