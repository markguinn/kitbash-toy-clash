shader_type canvas_item;
uniform vec2 size = vec2(8.0, 8.0); // size of pixel - adjust to taste
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
void fragment() {
        vec2 s = size * SCREEN_PIXEL_SIZE;
        vec2 uv = SCREEN_UV + vec2(s.x, 0.0);
        vec2 final_uv = floor(uv / s) * s;
        COLOR = textureLod(screen_texture, final_uv, 0.0);
}