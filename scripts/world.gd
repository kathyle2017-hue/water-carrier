extends Node2D

const TILE := 16
const MAP: PackedStringArray = [
	"################################################################",
	"#,,,,,,,,,,,,,,TTTTTT,,,,,,,,,,,,,,TTTT,,,,,,,,,,,,,,,,,,,,,,,,#",
	"#,,TTTT,,,,,,,,t..t..t,,,,,,,,TTTT,,t,,,,,,,,,,,,,,,,,,dddddddd#",
	"#,,tRRRRt,,,,,,.......,,,,,,,,t..t,,,,,,,,,,,,,,,,,,,bbkkkkdddd#",
	"#,,tRRRRt,yyyyyyyyyyyy,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,bbkkkkdddd#",
	"#,,tWWWWt,yyyyUyyyyyyy........,,.....................bbkkkkdddd#",
	"#,,tWhhWt,yyyyyyyyyyyy..g..g.................g.......bbkkkkdddd#",
	"#,,tWhhWt,yyyyPyyyyyyy...............................bbFkkkdddd#",
	"#,,tWWWW,,yyyyyyyyyyyy....g..............g...........bbkkkkdddd#",
	"#,,,,,,,,,,yyyyyyyyyyyy..............................bbkkkkdddd#",
	"#,,,,,,,,,,,,,,........g.....g.......................bbkkkkdddd#",
	"#,,,,TTTT,,,,,,......................................bbkkkkdddd#",
	"#,,,,t..t,,,,,,TTTT..............TTTT,,,,,,,,,TTTT,,,bbkkkkdddd#",
	"#,,,,,,,,,,,,,,t..t,,,,,,,,,,,,,,t..t,,,,,,,,,t..t,,,dddddddddd#",
	"################################################################",
]

const TILE_INDEX := {
	",": 0,  # grass
	".": 2,  # road
	"y": 4,  # yard
	"h": 5,  # floor
	"W": 6,  # wall
	"R": 7,  # roof
	"b": 8,  # bank
	"s": 9,  # shallow (unused, bank leads to knee)
	"k": 10, # knee water
	"d": 11, # deep
	"T": 12, # foliage
	"t": 12,
	"U": 14, # cistern
	"P": 4,
	"F": 10,
	"g": 2,
	"#": 13,
}

const SOLID: PackedStringArray = ["#", "W", "R", "T", "d"]


func _ready() -> void:
	_build_tiles()
	_build_collision()
	_spawn_glass()
	_spawn_areas()
	_add_rain()
	_add_grade()


func _build_tiles() -> void:
	var texture: Texture2D = load("res://assets/tiles.png")
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(TILE, TILE)
	var atlas := TileSetAtlasSource.new()
	atlas.texture = texture
	atlas.texture_region_size = Vector2i(TILE, TILE)
	var tile_count: int = texture.get_width() / TILE
	for i in tile_count:
		atlas.create_tile(Vector2i(i, 0))
	tileset.add_source(atlas)

	var ground := TileMapLayer.new()
	ground.name = "Ground"
	ground.tile_set = tileset
	ground.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(ground)

	var overlay := TileMapLayer.new()
	overlay.name = "Overlay"
	overlay.tile_set = tileset
	overlay.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	overlay.y_sort_enabled = true
	add_child(overlay)

	for y in MAP.size():
		var row: String = MAP[y]
		for x in row.length():
			var ch: String = row[x]
			var atlas_x := int(TILE_INDEX.get(ch, 0))
			# Wet the grass a little everywhere — mùa mưa.
			if ch == "," and ((x + y) % 5 == 0):
				atlas_x = 1
			# Puddles on the road.
			if ch == "." and ((x * 3 + y) % 7 == 0):
				atlas_x = 3
			if ch == "T" or ch == "t":
				atlas_x = 1 if ((x + y) % 5 == 0) else 0
			ground.set_cell(Vector2i(x, y), 0, Vector2i(atlas_x, 0))
			if ch == "T" or ch == "t":
				overlay.set_cell(Vector2i(x, y), 0, Vector2i(12, 0))


func _build_collision() -> void:
	var body := StaticBody2D.new()
	body.name = "Solids"
	add_child(body)
	for y in MAP.size():
		var row: String = MAP[y]
		for x in row.length():
			if row[x] not in SOLID:
				continue
			var shape := CollisionShape2D.new()
			var rect := RectangleShape2D.new()
			rect.size = Vector2(TILE, TILE)
			shape.shape = rect
			shape.position = Vector2(x * TILE + TILE / 2.0, y * TILE + TILE / 2.0)
			body.add_child(shape)


func _spawn_glass() -> void:
	var packed := preload("res://scenes/glass_shard.tscn")
	for y in MAP.size():
		var row: String = MAP[y]
		for x in row.length():
			if row[x] != "g":
				continue
			var shard: Node2D = packed.instantiate()
			shard.position = Vector2(x * TILE + TILE / 2.0, y * TILE + TILE / 2.0)
			add_child(shard)


func _spawn_areas() -> void:
	add_child(_make_zone("FillZone", PackedStringArray(["k", "F"]), Vector2(TILE, TILE)))
	add_child(_make_zone("UnloadZone", PackedStringArray(["U"]), Vector2(28, 28)))


func _make_zone(zone_name: String, marks: PackedStringArray, size: Vector2) -> Area2D:
	var area := Area2D.new()
	area.name = zone_name
	area.collision_layer = 0
	area.collision_mask = 1
	area.monitoring = true
	area.monitorable = false
	for y in MAP.size():
		var row: String = MAP[y]
		for x in row.length():
			if row[x] not in marks:
				continue
			var shape := CollisionShape2D.new()
			var rect := RectangleShape2D.new()
			rect.size = size
			shape.shape = rect
			shape.position = Vector2(x * TILE + TILE / 2.0, y * TILE + TILE / 2.0)
			area.add_child(shape)
	return area


func spawn_point() -> Vector2:
	for y in MAP.size():
		var row: String = MAP[y]
		for x in row.length():
			if row[x] == "P":
				return Vector2(x * TILE + TILE / 2.0, y * TILE + TILE / 2.0)
	return Vector2(80, 120)


func map_pixel_size() -> Vector2:
	return Vector2(MAP[0].length() * TILE, MAP.size() * TILE)


func place_at(world_x: float) -> String:
	var stream_x := 50 * TILE
	if world_x >= stream_x:
		return "Phú Bình"
	return "Huỳnh Thúc Kháng"


func _add_rain() -> void:
	var rain := CPUParticles2D.new()
	rain.name = "Rain"
	rain.amount = 420
	rain.lifetime = 0.85
	rain.preprocess = 0.8
	rain.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	rain.emission_rect_extents = Vector2(200, 110)
	rain.direction = Vector2(0.18, 1)
	rain.spread = 4.0
	rain.gravity = Vector2(18, 220)
	rain.initial_velocity_min = 70.0
	rain.initial_velocity_max = 110.0
	rain.scale_amount_min = 0.4
	rain.scale_amount_max = 1.1
	rain.texture = load("res://assets/rain.png")
	rain.color = Color(0.93, 0.88, 0.78, 0.55)
	# Follow the camera from the water-carrier; reparent in the scene tree after spawn.
	rain.local_coords = true
	rain.z_index = 40
	add_child(rain)
	rain.set_meta("follow_camera", true)


func _add_grade() -> void:
	var grade := CanvasModulate.new()
	grade.name = "WarmGrade"
	# Wet and warm, not grey.
	grade.color = Color(1.0, 0.93, 0.82)
	add_child(grade)
