shader_type canvas_item;

uniform vec4 color : source_color = vec4(0.0, 0.9, 1.0, 0.1);

// render_mode blend_screen;  // スクリーンモードを追加

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    if (tex_color.a > 0.0) {  // 透明でない部分だけ色を変更
        COLOR = color;
    } else {
        COLOR = vec4(0.0);  // 透明部分はそのまま
    }
}
