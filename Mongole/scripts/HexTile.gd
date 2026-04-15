class_name HexTile
# HexTile.gd — Data-only class for a single hex cell.
# Not a Node; created and stored in a Dictionary by HexGrid.

# ── Terrain constants ──────────────────────────────────────
const STEPPE   = 0
const PLAIN    = 1
const MOUNTAIN = 2
const RIVER    = 3

# ── Owner constants ────────────────────────────────────────
const NEUTRAL = 0
const PLAYER  = 1
const AI      = 2

# ── Per-tile data ──────────────────────────────────────────
var col:     int
var row:     int
var terrain: int
var owner:   int = NEUTRAL

func _init(c: int, r: int, t: int) -> void:
	col     = c
	row     = r
	terrain = t

# Returns the display color, tinted by ownership.
func get_color() -> Color:
	var base: Color
	match terrain:
		STEPPE:   base = Color(0.55, 0.72, 0.47)  # soft green
		PLAIN:    base = Color(0.78, 0.72, 0.47)  # sandy tan
		MOUNTAIN: base = Color(0.54, 0.54, 0.54)  # grey
		RIVER:    base = Color(0.35, 0.56, 0.78)  # blue
		_:        base = Color.WHITE
	match owner:
		PLAYER: base = base.lerp(Color(0.27, 0.53, 1.00), 0.35)
		AI:     base = base.lerp(Color(1.00, 0.27, 0.27), 0.35)
	return base

# How many move-points it costs to enter this tile.
func move_cost() -> int:
	return 2 if terrain == MOUNTAIN else 1

# Per-turn resource income when owned by PLAYER.
func get_income() -> Dictionary:
	match terrain:
		STEPPE:   return {"food": 1, "horses": 0, "gold": 0}
		PLAIN:    return {"food": 1, "horses": 0, "gold": 0}
		MOUNTAIN: return {"food": 0, "horses": 0, "gold": 1}
		RIVER:    return {"food": 0, "horses": 0, "gold": 2}
		_:        return {"food": 0, "horses": 0, "gold": 0}
