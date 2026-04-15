class_name HexUtils
# HexUtils.gd — Reusable static helpers for a flat-top hex grid.
#
# ── Coordinate system: AXIAL (q, r) ───────────────────────────────────────────
#
#  Axial coordinates use two axes that are 60° apart instead of 90°.
#  For flat-top hexes the axes point like this:
#
#          q →
#        ___
#       /   \        +q goes right
#  r ↘ /     \ ↗    +r goes down-right
#      \     /
#       \___/
#
#  The third cube axis s is implicit: s = -q - r  (q + r + s = 0 always).
#  Keeping s implicit is what makes these "axial" (2 numbers, not 3).
#
# ── Why axial over offset? ────────────────────────────────────────────────────
#  • Neighbour directions are the same 6 vectors regardless of position.
#  • Distance = max(|Δq|, |Δr|, |Δq+Δr|)  — one clean formula.
#  • No even/odd column special-casing.
# ─────────────────────────────────────────────────────────────────────────────

# Radius from hex center to any corner (pixels).
# Change this constant to scale the whole grid.
const SIZE: float = 40.0

# The 6 axial direction vectors (same for every hex, flat-top or pointy-top).
const DIRECTIONS: Array[Vector2i] = [
	Vector2i( 1,  0),   # East
	Vector2i( 1, -1),   # North-East
	Vector2i( 0, -1),   # North-West
	Vector2i(-1,  0),   # West
	Vector2i(-1,  1),   # South-West
	Vector2i( 0,  1),   # South-East
]

# ── hex_to_world ──────────────────────────────────────────────────────────────
#
#  Converts axial (q, r) → pixel Vector2 (center of the hex).
#
#  Derivation (flat-top):
#    The flat-top hex has corners at 0°, 60°, 120°, …
#    Moving one step in q shifts x by 3/2·size and y by √3/2·size.
#    Moving one step in r shifts x by 0       and y by √3·size.
#
#    x = size · (3/2 · q)
#    y = size · (√3/2 · q  +  √3 · r)
#
static func hex_to_world(q: int, r: int) -> Vector2:
	var x = SIZE * (1.5 * q)
	var y = SIZE * (sqrt(3.0) * 0.5 * q  +  sqrt(3.0) * r)
	return Vector2(x, y)

# ── world_to_hex ──────────────────────────────────────────────────────────────
#
#  Converts a pixel Vector2 → the nearest axial hex (q, r).
#
#  Step 1 — Invert the matrix from hex_to_world:
#    q_f = (2/3 · x) / size
#    r_f = (-1/3 · x  +  √3/3 · y) / size
#
#  Step 2 — Round to the nearest valid hex using cube-coordinate rounding:
#    Compute s_f = -q_f - r_f, round all three, then fix whichever
#    axis had the largest rounding error (so q + r + s = 0 still holds).
#
static func world_to_hex(pos: Vector2) -> Vector2i:
	# Step 1: fractional axial coords
	var q_f: float = (2.0 / 3.0 * pos.x) / SIZE
	var r_f: float = (-1.0 / 3.0 * pos.x  +  sqrt(3.0) / 3.0 * pos.y) / SIZE
	var s_f: float = -q_f - r_f

	# Step 2: round to nearest cube coord
	var q = roundi(q_f)
	var r = roundi(r_f)
	var s = roundi(s_f)

	# Fix rounding: restore the axis with the biggest error
	var q_diff = abs(q - q_f)
	var r_diff = abs(r - r_f)
	var s_diff = abs(s - s_f)

	if q_diff > r_diff and q_diff > s_diff:
		q = -r - s
	elif r_diff > s_diff:
		r = -q - s
	# else s is wrong but we don't store s

	return Vector2i(q, r)

# ── get_neighbors ─────────────────────────────────────────────────────────────
#
#  Returns the 6 axial neighbours of hex (q, r).
#  Simply adds each direction vector — no special-casing for even/odd position.
#
static func get_neighbors(q: int, r: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for dir in DIRECTIONS:
		result.append(Vector2i(q + dir.x, r + dir.y))
	return result

# ── hex_distance ──────────────────────────────────────────────────────────────
#
#  Number of steps between two hexes.
#  In cube coordinates: max(|Δq|, |Δr|, |Δq+Δr|)
#
static func hex_distance(a: Vector2i, b: Vector2i) -> int:
	var dq = a.x - b.x
	var dr = a.y - b.y
	return (abs(dq) + abs(dr) + abs(dq + dr)) / 2

# =============================================================================
# EXAMPLE USAGE (paste into any _ready() to test):
# =============================================================================
#
#   # Convert axial → pixel
#   var center = HexUtils.hex_to_world(2, -1)
#   print(center)                          # → (120, 51.96)
#
#   # Convert pixel back → axial
#   var coord = HexUtils.world_to_hex(center)
#   print(coord)                           # → (2, -1)
#
#   # Get all 6 neighbours of (0, 0)
#   var neighbours = HexUtils.get_neighbors(0, 0)
#   print(neighbours)
#   # → [(1,0), (1,-1), (0,-1), (-1,0), (-1,1), (0,1)]
#
#   # Distance between two hexes
#   print(HexUtils.hex_distance(Vector2i(0,0), Vector2i(3,-2)))  # → 3
