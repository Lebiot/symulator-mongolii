extends Node
# GameState.gd — Autoloaded singleton.
# Every other script reads/writes shared data through this node.

# ── Resources ──────────────────────────────────────────────
var food:   int = 20
var horses: int = 5
var gold:   int = 10

# ── Turn tracking ──────────────────────────────────────────
var current_turn:   int  = 1
const MAX_TURNS:    int  = 20
var is_player_turn: bool = true

# ── Map constants (shared with HexGrid / HexTile) ─────────
const COLS:     int   = 12
const ROWS:     int   = 9
const HEX_SIZE: float = 40.0

# ── Signals ────────────────────────────────────────────────
signal resources_changed
signal turn_changed(turn: int, is_player: bool)
signal game_over(message: String)
signal tile_ownership_changed
