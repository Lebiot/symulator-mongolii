extends Node2D
class_name Unit
# Unit.gd — A single moveable piece on the hex grid.
# Drawn in _draw(); position is set to hex_to_pixel(coord).

# ── Type constants ─────────────────────────────────────────
const WARRIOR = 0   # slower, drawn as diamond
const CAVALRY = 1   # faster,  drawn as circle

# ── Owner constants ────────────────────────────────────────
const PLAYER = 0
const AI     = 1

# ── Move-points per type ───────────────────────────────────
const MOVE_POINTS = { WARRIOR: 3, CAVALRY: 4 }

# ── Per-unit state ─────────────────────────────────────────
var unit_type:  int
var unit_owner: int
var coord:      Vector2i
var mp_max:     int
var mp_left:    int
var selected:   bool = false

# Call right after Unit.new() to configure the unit.
func setup(type: int, owner: int, start: Vector2i) -> void:
	unit_type  = type
	unit_owner = owner
	coord      = start
	mp_max     = MOVE_POINTS[type]
	mp_left    = mp_max

func reset_mp() -> void:
	mp_left = mp_max

# ── Drawing ────────────────────────────────────────────────

func _draw() -> void:
	var radius = GameState.HEX_SIZE * 0.38

	# Colour by owner
	var fill: Color
	if unit_owner == PLAYER:
		fill = Color(0.13, 0.27, 0.82)   # blue
	else:
		fill = Color(0.82, 0.13, 0.13)   # red

	# Selection ring (drawn first, underneath unit)
	if selected:
		draw_circle(Vector2.ZERO, radius + 6.0, Color(1.0, 0.9, 0.1, 0.9))

	# Shape depends on type
	match unit_type:
		WARRIOR:
			# Diamond
			var pts = PackedVector2Array([
				Vector2(0,       -radius),
				Vector2(radius,   0     ),
				Vector2(0,        radius),
				Vector2(-radius,  0     ),
			])
			draw_colored_polygon(pts, fill)
		CAVALRY:
			# Circle
			draw_circle(Vector2.ZERO, radius, fill)

	# White outline when selected
	if selected:
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, Color.WHITE, 2.0)

	# Letter label ("W" or "C")
	var label = "W" if unit_type == WARRIOR else "C"
	draw_string(
		ThemeDB.fallback_font,
		Vector2(-5, 6),
		label,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14,
		Color.WHITE
	)

	# AP dots along the bottom of the unit
	for i in mp_max:
		var dot_col = Color.WHITE if i < mp_left else Color(0.25, 0.25, 0.25, 0.7)
		draw_circle(
			Vector2((i - mp_max / 2.0 + 0.5) * 8.0, radius + 9.0),
			3.0,
			dot_col
		)
