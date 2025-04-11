extends Node2D

@onready var settings_panel = $CanvasLayer/SettingPanel

enum BGM {
	STAGE_01,
	CAVE_01
}

@export var bgm: BGM = BGM.STAGE_01

signal score_changed(value: int)

var cell_size = Vector2(16, 16)
var tile_coords = {}
var is_paused = false

var Item = preload('res://items/item.tscn')

func _ready():
	set_process_input(true)
	$Camera2D.make_current()
	
	# タイルセットの読み込みが完了してから初期化を進める
	tile_coords["coin_01"] = find_tile_coords_by_name($Items.tile_set, "coin_01")
	set_camera_limits()
	spawn_items()
	
	$Player.dead.connect(self._on_player_dead)
	$Player.reset($SpawnPoints/PlayerSpawn.position)
	$CanvasLayer.visible = true
	$Items.hide()
	
	AudioManager.play_bgm(BGM.keys()[bgm])
	
	# グローバルなスコア変更シグナルを接続
	GameState.score_changed.connect(_on_global_score_changed)

func set_camera_limits() -> void:
	var map_size = $World.get_used_rect()
	$Camera2D.limit_left = map_size.position.x * cell_size.x
	$Camera2D.limit_top = map_size.position.y * cell_size.y
	$Camera2D.limit_right = map_size.end.x * cell_size.x
	$Camera2D.limit_bottom = map_size.end.y * cell_size.y

func _process(_delta: float) -> void:
	var player_position = $Player.global_position
	var camera = $Camera2D
	var camera_margin = Vector2(50, 50) # カメラが追随を開始するマージン
	var camera_position = camera.global_position

	if abs(player_position.x - camera_position.x) > camera_margin.x:
		camera_position.x = player_position.x - sign(player_position.x - camera_position.x) * camera_margin.x

	if abs(player_position.y - camera_position.y) > camera_margin.y:
		camera_position.y = player_position.y - sign(player_position.y - camera_position.y) * camera_margin.y

	camera.global_position = camera_position

func spawn_items() -> void:
	for cell in $Items.get_used_cells():
		var coords = $Items.get_cell_atlas_coords(cell)
		var pos = $Items.map_to_local(cell)
		for key in tile_coords:
			if coords == tile_coords[key]:
				var c = Item.instantiate()
				c.initialize(key, pos + cell_size / 2)
				# c.initialize(key, pos)
				add_child(c)
				
				c.connect('pickup', Callable(self, '_on_Collectible_pickup'))


# func create_ladders():
# 	var cells = $World.get_used_cells(0)
# 	for cell in cells:
# 		var data = $World.get_cell_tile_data(0, cell)
# 		if data.get_custom_data("special") == "ladder":
# 			var c = CollisionShape2D.new()
# 			$Ladders.add_child(c)
# 			c.position = $World.map_to_local(cell)
# 			var s = RectangleShape2D.new()
# 			s.size = Vector2(8, 16)
# 			c.shape = s

func _on_global_score_changed(value: int) -> void:
	score_changed.emit(value)

func _on_Collectible_pickup():
	GameState.add_score(1)  # スコアを更新

func _on_player_dead():
	AudioManager.reset_bgm()
	GameState.reset_game_state()
	GameState.restart()

func _on_ladders_body_entered(body):
	body.is_on_ladder = true


func _on_ladders_body_exited(body):
	body.is_on_ladder = false


func find_tile_coords_by_name(tile_set: TileSet, target_name: String) -> Vector2i:
	if not tile_set:
		print("Warning: Invalid tileset")
		return Vector2i(-1, -1)

	for source_index in tile_set.get_source_count():
		var source_id = tile_set.get_source_id(source_index)
		var atlas = tile_set.get_source(source_id) as TileSetAtlasSource
		if atlas:
			var size = atlas.get_atlas_grid_size()
			for x in size.x:
				for y in size.y:
					var coords = Vector2i(x, y)
					if atlas.has_tile(coords):
						var tile_data = atlas.get_tile_data(coords, 0)
						if tile_data and tile_data.get_custom_data("type") == target_name:
							return coords
	return Vector2i(-1, -1)

func _input(event: InputEvent) -> void:
	if not settings_panel.visible and event.is_action_pressed("pause") and not DialogueManager.is_dialogue_open:
		get_tree().paused = not get_tree().paused
		is_paused = get_tree().paused
		$CanvasLayer/SettingPanel.is_paused = is_paused
		var hud = $CanvasLayer/HUD
		if get_tree().paused:
			hud.show_message("Paused")
			AudioManager.pause_all_with_se()
		else:
			hud.hide_message()
			AudioManager.resume_all()
