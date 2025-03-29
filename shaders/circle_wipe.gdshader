shader_type canvas_item;

uniform float progress = 0.0;
uniform vec2 center = vec2(0.5, 0.5);
uniform float radius = 0.5;

void fragment() {
	// UV座標を正規化して正円にする
	vec2 uv = UV;
	
	// センター位置が画面端の場合の処理を改善
	// 中心位置をクランプして画面内に確実に収める
	vec2 safe_center = clamp(center, vec2(0.1, 0.1), vec2(0.9, 0.9));
	
	vec2 normalized_uv = (uv - safe_center) * vec2(2.0, 2.0);  // -1から1の範囲に正規化
	
	// 画面のアスペクト比を考慮して正円にする
	float aspect = SCREEN_PIXEL_SIZE.x / SCREEN_PIXEL_SIZE.y;
	normalized_uv.x *= 1.0 / aspect;  // X座標をアスペクト比で調整
	
	float dist = length(normalized_uv);  // 正規化された距離を計算
	
	// 円のサイズを時間とともに変化させる（画面をカバーするサイズから開始）
	float current_radius = radius * (1.0 - progress);  // 時間とともに円が小さくなる
	
	// 円形のフェードアウト（stepを使用してシャープな縁を作る）
	float alpha = 1.0 - step(dist, current_radius);  // 円の外側が黒く、中が見える
	
	// デバッグ用：円の境界を表示
	float circle = step(dist, radius);
	
	COLOR = vec4(0.0, 0.0, 0.0, alpha);
}
