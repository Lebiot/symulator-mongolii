# New Unit representation mapping to MapManager's axial system
class_name AxialUnit
extends Node2D
# AxialUnit.gd — Basic functional unit tracking properties and movement.

# ── Properties ─────────────────────────────────────────────
var movement_points: int = 0
var max_movement: int = 2
var unit_owner: int = 0 # e.g. 0 for player, 1 for AI

# The axial coordinate (q, r) where this unit is located.
var current_hex: Vector2i = Vector2i.ZERO

# ── Signals ────────────────────────────────────────────────
signal moved(unit: AxialUnit, from_hex: Vector2i, to_hex: Vector2i)

# ── Public API ─────────────────────────────────────────────

# Sets up the unit's starting state
func setup(owner_id: int, start_hex: Vector2i, movement: int = 2) -> void:
    unit_owner = owner_id
    current_hex = start_hex
    max_movement = movement
    reset_turn()
    
    # Update position right away
    position = HexUtils.hex_to_world(current_hex.x, current_hex.y)

# Checks if the unit has enough move points to reach the target hex.
# (Currently assumes cost is 1 per step; can be expanded easily).
func can_move_to(target_hex: Vector2i) -> bool:
    var cost = HexUtils.hex_distance(current_hex, target_hex)
    return movement_points >= cost

# Moves the unit, spends points, and updates visual position.
# Returns true if successful, false if not enough points.
func move_to(target_hex: Vector2i) -> bool:
    if not can_move_to(target_hex):
        return false

    var cost = HexUtils.hex_distance(current_hex, target_hex)
    movement_points -= cost
    
    var start_hex = current_hex
    current_hex = target_hex
    position = HexUtils.hex_to_world(current_hex.x, current_hex.y)
    
    moved.emit(self, start_hex, current_hex)
    return true

# Resets movement points for a new turn.
func reset_turn() -> void:
    movement_points = max_movement
