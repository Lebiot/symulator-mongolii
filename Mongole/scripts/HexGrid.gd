extends Node2D
class_name HexGrid
# HexGrid.gd — Builds the map, draws every tile, and reports clicks.
#
# Coordinate system: flat-top hexes, even-q offset.
#   hex_to_pixel:  offset (col, row)  →  local Vector2
#   pixel_to_hex:  local Vector2      →  offset (col, row)

const COLS = 12
const ROWS = 9
const SIZE = 40.0   # hex radius: center → corner

var tiles: Dictionary = {}           # Vector2i → HexTile
var hovered:     Vector2i = Vector2i(-1, -1)
var highlighted: Array[Vector2i] = []

signal tile_clicked(coord: Vector2i)

# ── Setup ──────────────────────────────────────────────────

func _ready() -> void:
	_generate_map()

func _generate_map() -> void:
	var rng = RandomNumberGenerator.new()
	rng.randomize()

	for c in COLS:
		for r in ROWS:
			tiles[Vector2i(c, r)] = HexTile.new(c, r, _random_terrain(rng))

	# AI territory: top two rows
	for c in COLS:
		for r in range(0, 2):
			tiles[Vector2i(c, r)].owner = HexTile.AI

	# Player territory: bottom-centre block
	for c in range(4, 8):
		for r in range(ROWS - 2, ROWS):
			tiles[Vector2i(c, r)].owner = HexTile.PLAYER

	queue_redraw()

func _random_terrain(rng: RandomNumberGenerator) -> int:
	var v = rng.randf()
	if   v < 0.40: return HexTile.STEPPE
	elif v < 0.70: return HexTile.PLAIN
	elif v < 0.87: return HexTile.MOUNTAIN
	else:          return HexTile.RIVER

# ── Coordinate helpers ─────────────────────────────────────

func hex_to_pixel(col: int, row: int) -> Vector2:
	var x = SIZE * 1.5 * col
	var y = SIZE * sqrt(3.0) * (row + 0.5 * (col % 2))
	return Vector2(x, y)

func pixel_to_hex(point: Vector2) -> Vector2i:
	var col = int(round(point.x / (SIZE * 1.5)))
	col = clampi(col, 0, COLS - 1)
	var row = int(round(point.y / (SIZE * sqrt(3.0)) - 0.5 * (col % 2)))
	row = clampi(row, 0, ROWS - 1)
	return Vector2i(col, row)

# Returns valid neighbours of 'coord' (even-q offset, flat-top).
func get_neighbors(coord: Vector2i) -> Array[Vector2i]:
	var c = coord.x
	var r = coord.y
	var raw: Array[Vector2i]
	if c % 2 == 0:
		raw = [
			Vector2i(c,     r - 1), Vector2i(c,     r + 1),
			Vector2i(c + 1, r - 1), Vector2i(c + 1, r    ),
			Vector2i(c - 1, r - 1), Vector2i(c - 1, r    ),
		]
	else:
		raw = [
			Vector2i(c,     r - 1), Vector2i(c,     r + 1),
			Vector2i(c + 1, r    ), Vector2i(c + 1, r + 1),
			Vector2i(c - 1, r    ), Vector2i(c - 1, r + 1),
		]
	var valid: Array[Vector2i] = []
	for n in raw:
		if tiles.has(n):
			valid.append(n)
	return valid

# BFS: all tiles reachable within 'move_points' AP.
func get_reachable(start: Vector2i, move_points: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var frontier: Array = [{"coord": start, "cost": 0}]
	var visited: Dictionary = {start: 0}

	while frontier.size() > 0:
		var current = frontier.pop_front()
		var coord: Vector2i = current["coord"]
		var cost:  int      = current["cost"]

		for nb in get_neighbors(coord):
			var tile: HexTile = tiles[nb]
			var new_cost = cost + tile.move_cost()
			if new_cost <= move_points:
				if not visited.has(nb) or visited[nb] > new_cost:
					visited[nb] = new_cost
					result.append(nb)
					frontier.append({"coord": nb, "cost": new_cost})

	return result

# Claim 'center' + all neutral neighbours for 'owner'.
func claim_around(center: Vector2i, owner: int) -> void:
	tiles[center].owner = owner
	for nb in get_neighbors(center):
		if tiles[nb].owner == HexTile.NEUTRAL:
			tiles[nb].owner = owner
	queue_redraw()
	GameState.tile_ownership_changed.emit()

func set_highlighted(coords: Array[Vector2i]) -> void:
	highlighted = coords
	queue_redraw()

# ── Drawing ────────────────────────────────────────────────

func _hex_corners(center: Vector2) -> PackedVector2Array:
	var pts = PackedVector2Array()
	for i in 6:
		var angle = deg_to_rad(60.0 * i)  # flat-top: first corner at 0°
		pts.append(center + Vector2(cos(angle), sin(angle)) * SIZE)
	return pts

func _draw() -> void:
	for coord in tiles:
		var tile: HexTile = tiles[coord]
		var center  = hex_to_pixel(coord.x, coord.y)
		var corners = _hex_corners(center)

		# 1. Base terrain fill (tinted by owner)
		draw_colored_polygon(corners, tile.get_color())

		# 2. Movement-range highlight (yellow)
		if coord in highlighted:
			draw_colored_polygon(corners, Color(1.0, 1.0, 0.2, 0.30))

		# 3. Hover glow (white)
		if coord == hovered:
			draw_colored_polygon(corners, Color(1.0, 1.0, 1.0, 0.18))

		# 4. Border
		var border_col = Color(0.08, 0.08, 0.08, 0.75)
		var border_w   = 1.0
		if coord == hovered:
			border_col = Color.WHITE
			border_w   = 2.0
		for i in 6:
			draw_line(corners[i], corners[(i + 1) % 6], border_col, border_w)

		# 5. Terrain icon
		var icon = _terrain_icon(tile.terrain)
		if icon != "":
			draw_string(
				ThemeDB.fallback_font,
				center + Vector2(-7, 7),
				icon,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 15,
				Color(0.0, 0.0, 0.0, 0.55)
			)

func _terrain_icon(t: int) -> String:
	match t:
		HexTile.MOUNTAIN: return "▲"
		HexTile.RIVER:    return "~"
		_:                return ""

# ── Input ──────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var local_pos = to_local(get_global_mouse_position())
			var coord = pixel_to_hex(local_pos)
			if tiles.has(coord):
				tile_clicked.emit(coord)

func _process(_delta: float) -> void:
	var local_pos = to_local(get_global_mouse_position())
	var coord = pixel_to_hex(local_pos)
	if coord != hovered:
		hovered = coord
		queue_redraw()
