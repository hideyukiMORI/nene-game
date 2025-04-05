shader_type canvas_item;

uniform vec4 color : source_color = vec4(0.0, 0.8, 1.0, 0.5);

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    COLOR = color;
    COLOR.a *= tex_color.a;  // 元のスプライトの透明度を維持
} 