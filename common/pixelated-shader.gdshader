shader_type canvas_item;
// size of pixel - adjust to taste
uniform vec2 size = vec2(8.0, 8.0);
// grab the normally rendered view
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
// and round the UVs to make it blocky
void fragment() {
        vec2 norm_size = size * SCREEN_PIXEL_SIZE;
        vec2 uv = SCREEN_UV + vec2(norm_size.x, 0.0);
        vec2 center_uv = floor(uv / norm_size) * norm_size;
        vec2 norm_uv = mod(uv, norm_size) / norm_size;
        COLOR = textureLod(screen_texture, center_uv, 0.0);
}