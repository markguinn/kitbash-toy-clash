shader_type spatial;
render_mode unshaded, fog_disabled;

const int MAX_PALETTE_SIZE = 256;
const vec2 SCREEN_PIXEL_SIZE = vec2(1., 1.);

uniform vec2 size = vec2(8.0, 8.0); // size of pixel - adjust to taste
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;

uniform int quantization_algorithm;
//uniform int active_colors;
//uniform vec3[MAX_PALETTE_SIZE] palette;
uniform sampler2D palette_texture : source_color;
uniform vec2 palette_size;

uniform bool creases = true;
uniform float crease_slope_tol = 0.001;
uniform bool outline = true;
uniform bool use_closest_point_in_pixel = true;
uniform vec3 outline_color : source_color;
uniform float depth_threshold = 1.0;
uniform float min_depth_for_outlines = 100.0;

vec3 rgb_to_hsv(vec3 c) {
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	float e = 1e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv_to_rgb(vec3 c) {
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

// RGB to LAB implementation from
// https://github.com/sv3/gift/blob/master/RGB2Lab.glsl
vec3 rgb_to_lab(vec3 rgb){
    float R = rgb.x;
    float G = rgb.y;
    float B = rgb.z;
    // threshold
    float T = 0.008856;

    float X = R * 0.412453 + G * 0.357580 + B * 0.180423;
    float Y = R * 0.212671 + G * 0.715160 + B * 0.072169;
    float Z = R * 0.019334 + G * 0.119193 + B * 0.950227;

    // Normalize for D65 white point
    X = X / 0.950456;
    Y = Y;
    Z = Z / 1.088754;

    bool XT, YT, ZT;
    XT = false; YT=false; ZT=false;
    if(X > T) XT = true;
    if(Y > T) YT = true;
    if(Z > T) ZT = true;

    float Y3 = pow(Y,1.0/3.0);
    float fX, fY, fZ;
    if(XT){ fX = pow(X, 1.0/3.0);} else{ fX = 7.787 * X + 16.0/116.0; }
    if(YT){ fY = Y3; } else{ fY = 7.787 * Y + 16.0/116.0 ; }
    if(ZT){ fZ = pow(Z,1.0/3.0); } else{ fZ = 7.787 * Z + 16.0/116.0; }

    float L; if(YT){ L = (116.0 * Y3) - 16.0; }else { L = 903.3 * Y; }
    float a = 500.0 * ( fX - fY );
    float b = 200.0 * ( fY - fZ );

    return vec3(L,a,b);
}

float measure_dist(vec3 original_color, vec3 palette_color) {
	if (quantization_algorithm == 3) {
		vec3 ohsv = rgb_to_lab(original_color);
		vec3 phsv = rgb_to_lab(palette_color);
		return distance(ohsv, phsv);
	}
	return distance(original_color, palette_color);
}

vec3 quantize_color(vec3 original_color) {
	float min_dist = 9999.0;
	vec3 quantized_color = vec3(0.0, 1.0, 0.0); //bright debug-green color

	//for (int i = 0; i < active_colors; i++) {
		//vec3 palette_color = palette[i];
		//float dist = measure_dist(original_color.rgb, palette_color);
		//if (dist < min_dist) {
			//min_dist = dist;
			//quantized_color = palette_color;
		//}
	//}

	vec2 step_size = 1.0 / palette_size;
	for (float x = step_size.x * 0.5; x < 1.0; x += step_size.x) {
		for (float y = step_size.y * 0.5; y < 1.0; y += step_size.y) {
			vec3 palette_color = textureLod(palette_texture, vec2(x, y), 0.0).rgb;
			float dist = measure_dist(original_color.rgb, palette_color);
			if (dist < min_dist) {
				min_dist = dist;
				quantized_color = palette_color;
			}
		}
	}
	
	return quantized_color;
}

float get_linear_depth(vec2 uv, mat4 inv_projection_matrix) {
	float depth = texture(depth_texture, uv).x;
	vec3 ndc = vec3(uv, depth) * 2.0 - 1.0;
	vec4 view = inv_projection_matrix * vec4(ndc, 1.0);
	view.xyz /= view.w;
	return pow(-view.z, 0.8) * 5.0;
}

void vertex() {
  POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

float get_outline_strength(vec2 uv, vec2 texel_size, mat4 inv_projection_matrix) {
	float d = get_linear_depth(uv, inv_projection_matrix);
	if (d > min_depth_for_outlines) {
		return 0.0;
	}
	float d2 = 2.0;
	float du = get_linear_depth(uv + vec2(0.0, -texel_size.y), inv_projection_matrix);
	float dd = get_linear_depth(uv + vec2(0.0, texel_size.y), inv_projection_matrix);
	float dl = get_linear_depth(uv + vec2(-texel_size.x, 0.0), inv_projection_matrix);
	float dr = get_linear_depth(uv + vec2(texel_size.x, 0.0), inv_projection_matrix);
	
	float maxd = max(d - du, max(d - dd, max(d - dl, d - dr)));
	
	//if (
		//abs((du2 - du) - (du - d)) < crease_slope_tol &&
		//abs((dd2 - dd) - (dd - d)) < crease_slope_tol &&
		//sign(du2 - d) == sign(dd2 - d)
	//) {
		//return 0.0;
	//}
	if (creases) {
		float du2 = get_linear_depth(uv + vec2(0.0, -texel_size.y * d2), inv_projection_matrix);
		float dd2 = get_linear_depth(uv + vec2(0.0, texel_size.y * d2), inv_projection_matrix);
		float dl2 = get_linear_depth(uv + vec2(-texel_size.x * d2, 0.0), inv_projection_matrix);
		float dr2 = get_linear_depth(uv + vec2(texel_size.x * d2, 0.0), inv_projection_matrix);
		if (
			(
				abs((dl2 - dl) - (dl - d)) < crease_slope_tol &&
				abs((dr2 - dr) - (dr - d)) < crease_slope_tol &&
				sign(dl2 - d) != sign(dr2 - d) &&
				(abs(dl2 - d) > depth_threshold || abs(dr2 - d) > depth_threshold) &&
				true
			) || (
				abs((du2 - du) - (du - d)) < crease_slope_tol &&
				abs((dd2 - dd) - (dd - d)) < crease_slope_tol &&
				sign(du2 - d) != sign(dd2 - d) &&
				(abs(du2 - d) > depth_threshold || abs(dd2 - d) > depth_threshold)
			)
		) {
			return 0.0;//smoothstep(min_depth_for_outlines, depth_threshold, d);
		}
	}

	if (maxd < depth_threshold) {
		return 0.0;
	}
	return smoothstep(min_depth_for_outlines, depth_threshold, d);
}

void fragment() {
	if (quantization_algorithm > 0) {
		vec2 texel_size = size / VIEWPORT_SIZE;
		vec2 pixel_size = 1.0 / VIEWPORT_SIZE;
		vec2 uv = SCREEN_UV; // + vec2(texel_size.x, 0.0);
		vec2 final_uv = floor(uv / texel_size) * texel_size;
		vec2 shadow_uv = final_uv;

		if (use_closest_point_in_pixel) {
			float min_depth = get_linear_depth(final_uv, INV_PROJECTION_MATRIX);
			float max_depth = min_depth;
			vec2 starting_uv = final_uv;
			for (float x = 0.0; x < texel_size.x - pixel_size.x; x += pixel_size.x) {
				for (float y = 0.0; y < texel_size.y - pixel_size.y; y += pixel_size.y) {
					vec2 my_uv = vec2(starting_uv.x + x, starting_uv.y + y);
					float my_depth = get_linear_depth(my_uv, INV_PROJECTION_MATRIX);
					if (my_depth < min_depth) {
						min_depth = my_depth;
						final_uv = my_uv;
					}
					if (my_depth > max_depth) {
						max_depth = my_depth;
						shadow_uv = my_uv;
					}
				}
			}
		}
		//shadow_uv = final_uv;
		
		vec4 original_color = textureLod(screen_texture, final_uv, 0.0);

		if (outline) {
			float amount = get_outline_strength(shadow_uv, texel_size, INV_PROJECTION_MATRIX);
			original_color = mix(original_color, vec4(outline_color, 1.0), amount);
		}
		if (quantization_algorithm > 1) {
			vec3 quantized_color = quantize_color(original_color.rgb);
			ALBEDO.rgb = quantized_color;
		} else {
			ALBEDO.rgb = original_color.rgb;
		}
		//ALBEDO.rgb = vec3(get_linear_depth(SCREEN_UV, INV_PROJECTION_MATRIX) / 400.0);
	} else {
		ALBEDO.rgb = textureLod(screen_texture, SCREEN_UV, 0.0).rgb;
	}
}