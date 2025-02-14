extends Node2D

signal score_changed(value: int)

var score = 0 : set = set_score
var cell_size = Vector2(16, 16)
var tile_coords = {}

var Item = preload('res://items/item.tscn')

func _ready():
	score_changed.connect($CanvasLayer/HUD._on_score_changed)
	score = 0
	$Items.hide()
	$Player.reset($PlayerSpawn.position)
	set_camera_limits()
	spawn_items()
	# create_ladders()
	var tile_set = load("res://assets/tile_set/items.tres")
	tile_coords["coin_01"] = find_tile_coords_by_name(tile_set, "coin_01")
	spawn_items()

func set_camera_limits() -> void:
	var map_size = $World.get_used_rect()
	# $Player/Camera2D.limit_left = (map_size.position.x - 5) * cell_size.x
	# $Player/Camera2D.limit_right = (map_size.end.x + 5) * cell_size.x
	print('map_size::', map_size.position.y)
	print('map_size-end::', map_size.end.y)
	$Player/Camera2D.limit_left = (map_size.position.x - 5) * cell_size.x
	$Player/Camera2D.limit_top = (map_size.position.y - 5) * cell_size.y
	$Player/Camera2D.limit_right = (map_size.end.x + 5) * cell_size.x
	$Player/Camera2D.limit_bottom = (map_size.end.y) * cell_size.y

func _process(delta: float) -> void:
	pass


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

func _on_Collectible_pickup():
	score += 1

func set_score(value):
	score = value
	score_changed.emit(score)

# func _on_door_entered(body):
# 	GameState.next_level()
	
func _on_player_died():
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