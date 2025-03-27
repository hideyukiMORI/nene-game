shader_type canvas_item;

uniform vec4 color_top : source_color = vec4(0.0, 1.0, 1.0, 1.0);    // シアン
uniform vec4 color_bottom : source_color = vec4(0.0, 0.0, 0.0, 0.0); // 透明

void fragment() {
    // UVのY座標でグラデーションを作成
    vec4 gradient_color = mix(color_top, color_bottom, UV.y);
    COLOR = gradient_color;
} 