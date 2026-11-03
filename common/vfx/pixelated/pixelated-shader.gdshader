shader_type canvas_item;

const int PALETTE_SIZE = 27;

uniform vec2 size = vec2(8.0, 8.0); // size of pixel - adjust to taste
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform int dist_type = 0;
uniform bool quantize_palette = true;
uniform vec3[PALETTE_SIZE] palette : source_color;
uniform sampler2D palette_texture : source_color;
uniform vec2 palette_size;

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
	if (dist_type == 1) {
		vec3 ohsv = rgb_to_lab(original_color);
		vec3 phsv = rgb_to_lab(palette_color);
		return distance(ohsv, phsv);
	}
	return distance(original_color, palette_color);
}

vec3 quantize_color(vec3 original_color) {
	float min_dist = 9999.0;
	vec3 quantized_color = vec3(0.0, 1.0, 0.0); //bright debug-green color

	//for (int i = 0; i < PALETTE_SIZE; i++) {
		//vec3 palette_color = palette[i];
		//float dist = distance(original_color.rgb, palette_color);
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

void fragment() {
	vec2 s = size * SCREEN_PIXEL_SIZE;
	vec2 uv = SCREEN_UV + vec2(s.x, 0.0);
	vec2 final_uv = floor(uv / s) * s;
	vec4 original_color = textureLod(screen_texture, final_uv, 0.0);
	if (quantize_palette) {
		vec3 quantized_color = quantize_color(original_color.rgb);
		COLOR = vec4(quantized_color, original_color.a);
	} else {
		COLOR = original_color;
	}
}