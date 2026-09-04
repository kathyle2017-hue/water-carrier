extends Node2D

const TILE := 16
const MAP: PackedStringArray = [
	"################################################################",
	"#,,,,,,,,,,,,,,TTTTTT,,,,,,,,,,,,,,TTTT,,,,,,,,,,,,,,,,,,,,,,,,#",
	"#,,TTTT,,,,,,,,t..t..t,,,,,,,,TTTT,,t,,,,,,,,,,,,,,,,,,dddddddd#",
	"#,,tRRRRt,,,,,,.......,,,,,,,,t..t,,,,,,,,,,,,,,,,,,,bbkkkkdddd#",
	"#,,tRRRRt,yyyyyyyyyyyy,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,bbkkkkdddd#",
	"#,,tWWWWt,yyyyUyyyyyyyD.......,,.....................bbkkkkdddd#",
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
	"D": 2,  # Đông stall approach
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
	_spawn_dong_stall()
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
	add_child(_make_zone("DongZone", PackedStringArray(["D"]), Vector2(28, 28)))


func _spawn_dong_stall() -> void:
	var stall := Node2D.new()
	stall.name = "DongStall"
	stall.position = _mark_point("D") + Vector2(0, -20)
	stall.z_index = 3
	var wall := Polygon2D.new()
	wall.polygon = PackedVector2Array([Vector2(-15, -12), Vector2(15, -12), Vector2(15, 8), Vector2(-15, 8)])
	wall.color = Color(0.72, 0.48, 0.28)
	stall.add_child(wall)
	var awning := Polygon2D.new()
	awning.polygon = PackedVector2Array([Vector2(-17, -14), Vector2(17, -14), Vector2(13, -8), Vector2(-13, -8)])
	awning.color = Color(0.82, 0.66, 0.36)
	stall.add_child(awning)
	var sign := Label.new()
	sign.text = "Đông"
	sign.position = Vector2(-12, -13)
	sign.add_theme_font_size_override("font_size", 8)
	sign.add_theme_color_override("font_color", Color(0.28, 0.16, 0.1))
	stall.add_child(sign)
	add_child(stall)


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
	var point := _mark_point("P")
	return point if point.x >= 0.0 else Vector2(80, 120)


func _mark_point(mark: String) -> Vector2:
	for y in MAP.size():
		var row: String = MAP[y]
		for x in row.length():
			if row[x] == mark:
				return Vector2(x * TILE + TILE / 2.0, y * TILE + TILE / 2.0)
	return Vector2(-1, -1)


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


func show_household(father_home: bool) -> void:
	var family := Node2D.new()
	family.set_script(load("res://scripts/household_view.gd"))
	family.father_home = father_home
	family.name = "Household"
	family.position = spawn_point() + Vector2(0, -28)
	family.z_index = 4
	add_child(family)


func set_flood(opening: bool, day: int) -> void:
	# Street water recurs in later mùa mưa. The ruined house and the 1978
	# household Talk are confined to the opening days.
	var street_water := Polygon2D.new()
	street_water.name = "StreetWater"
	street_water.polygon = PackedVector2Array([Vector2(270, 142), Vector2(700, 147), Vector2(736, 174), Vector2(300, 174)])
	street_water.color = Color(0.58, 0.66, 0.54, 0.48 if opening else 0.25)
	street_water.z_index = 1
	add_child(street_water)
	if not opening:
		return
	var ruin := Node2D.new()
	ruin.name = "NeighborsHouse"
	ruin.position = Vector2(485, 65)
	ruin.z_index = 3
	var floor_remains := Polygon2D.new()
	floor_remains.polygon = PackedVector2Array([Vector2(-4, 2), Vector2(58, 2), Vector2(67, 21), Vector2(-9, 21)])
	floor_remains.color = Color("b3946c")
	ruin.add_child(floor_remains)
	var broken_wall := Polygon2D.new()
	broken_wall.polygon = PackedVector2Array([Vector2(0, 9), Vector2(0, -20), Vector2(14, -20), Vector2(14, -9), Vector2(26, -13), Vector2(26, 9)])
	broken_wall.color = Color("c4ae82")
	ruin.add_child(broken_wall)
	var fallen_roof := Polygon2D.new()
	fallen_roof.polygon = PackedVector2Array([Vector2(18, -3), Vector2(42, -8), Vector2(62, 12), Vector2(33, 16)])
	fallen_roof.color = Color("91624b")
	ruin.add_child(fallen_roof)
	for i in 5:
		var plank := Polygon2D.new()
		plank.polygon = PackedVector2Array([Vector2(i * 10, 0), Vector2(i * 10 + 5, -16 + i * 2), Vector2(i * 10 + 10, 4)])
		plank.color = Color("977757")
		ruin.add_child(plank)
	var sign := Label.new()
	sign.text = "Neighbors · 1978"
	sign.position = Vector2(-4, -30)
	sign.add_theme_font_size_override("font_size", 8)
	ruin.add_child(sign)
	for i in (2 if day == 0 else 1):
		var neighbor := Sprite2D.new()
		neighbor.name = "Neighbor%d" % i
		neighbor.texture = load("res://assets/water_carrier.png")
		neighbor.hframes = 3
		neighbor.vframes = 4
		neighbor.position = Vector2(12 + i * 20, 13)
		neighbor.modulate = Color("baa88b")
		ruin.add_child(neighbor)
	add_child(ruin)
