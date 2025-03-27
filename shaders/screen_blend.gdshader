shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform vec4 blend_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float color_tint_r : hint_range(0.0, 1.0) = 0.5;
uniform float color_tint_g : hint_range(0.0, 1.0) = 0.5;
uniform float color_tint_b : hint_range(0.0, 1.0) = 0.5;

void fragment() {
    vec4 color = texture(TEXTURE, UV);
    vec4 bg_color = texture(SCREEN_TEXTURE, SCREEN_UV);

    // スクリーンモードの計算（色の寄せ方を調整）
    vec3 screen = vec3(
        1.0 - (1.0 - color.r) * (1.0 - mix(bg_color.r, color_tint_r, 0.5)),
        1.0 - (1.0 - color.g) * (1.0 - mix(bg_color.g, color_tint_g, 0.5)),
        1.0 - (1.0 - color.b) * (1.0 - mix(bg_color.b, color_tint_b, 0.5))
    );

    COLOR = vec4(screen, color.a * blend_color.a);
}