extends Node2D
class_name HexTileNode
# HexTileNode.gd — Visual + data for a single hex tile in the scene tree.
# Instantiated by MapManager for each cell of the grid.

# ── Terrain constants ──────────────────────────────────────
const STEPPE   = 0
const MOUNTAIN = 1
const RIVER    = 2

# ── Terrain display data ───────────────────────────────────
const TERRAIN_COLOR: Dictionary = {
	STEPPE:   Color(0.55, 0.72, 0.47),   # soft green
	MOUNTAIN: Color(0.54, 0.54, 0.54),   # grey
	RIVER:    Color(0.35, 0.56, 0.78),   # blue
}

const TERRAIN_ICON: Dictionary = {
	STEPPE:   "",
	MOUNTAIN: "▲",
	RIVER:    "~",
}

# ── Per-tile state ─────────────────────────────────────────
var q:       int = 0
var r:       int = 0
var terrain: int = STEPPE
var is_selected: bool = false

# ── Public API ─────────────────────────────────────────────

# Call right after instantiate() to configure the tile.
func setup(tile_q: int, tile_r: int, tile_terrain: int) -> void:
	q       = tile_q
	r       = tile_r
	terrain = tile_terrain
	queue_redraw()

# Change the terrain at runtime and redraw.
func set_terrain(new_terrain: int) -> void:
	terrain = new_terrain
	queue_redraw()

# Change the selection state visually.
func set_selected(selected: bool) -> void:
	if is_selected != selected:
		is_selected = selected
		queue_redraw()

# ── Drawing ────────────────────────────────────────────────

func _draw() -> void:
	var size = HexUtils.SIZE    # radius center → corner

	# Build the 6 corner points (flat-top: first corner at 0°)
	var corners = PackedVector2Array()
	for i in 6:
		var angle = deg_to_rad(60.0 * i)
		corners.append(Vector2(cos(angle), sin(angle)) * size)

	# Fill
	var fill = TERRAIN_COLOR.get(terrain, Color.WHITE)
	draw_colored_polygon(corners, fill)

	# Border / Highlight
	var border_color = Color(0.1, 0.1, 0.1, 0.6)
	var border_width = 1.0

	if is_selected:
		border_color = Color.WHITE
		border_width = 2.5

	for i in 6:
		draw_line(corners[i], corners[(i + 1) % 6], border_color, border_width)

	# Terrain icon (skip for steppe to keep the map readable)
	var icon: String = TERRAIN_ICON.get(terrain, "")
	if icon != "":
		draw_string(
			ThemeDB.fallback_font,
			Vector2(-7, 7),
			icon,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 14,
			Color(0.0, 0.0, 0.0, 0.55)
		)
