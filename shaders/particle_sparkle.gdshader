shader_type particles;

uniform vec4 sparkle_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float sparkle_intensity : hint_range(0.0, 2.0) = 1.0;
uniform float sparkle_speed : hint_range(0.0, 5.0) = 1.0;

void start() {
	// パーティクルの初期設定
	VELOCITY = mix(VELOCITY, VELOCITY * (1.0 + randf() * 0.5), 0.5);
}

void process() {
	// キラキラ効果の計算
	float sparkle = sin(TIME * sparkle_speed + randf() * 6.28) * 0.5 + 0.5;
	COLOR = sparkle_color * (1.0 + sparkle * sparkle_intensity);
	
	// 徐々に透明に
	COLOR.a *= 1.0 - (LIFETIME / LIFETIME_MAX);
} 