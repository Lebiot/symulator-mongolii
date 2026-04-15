extends Node2D
class_name MapManager
# MapManager.gd — Generates a 20x20 hex grid using HexTileNode instances.
#
# Generates a grid of size map_size_q * map_size_r.
# Stores the nodes in a dictionary `tiles` using the Vector2i(q, r) as the key.

@export var map_size_q: int = 20
@export var map_size_r: int = 20
@export var hex_tile_scene: PackedScene = preload("res://scenes/HexTileNode.tscn")
@export var random_seed: int = 0  # 0 means use random time-based seed

# Dictionary mapping axial coordinate Vector2i(q, r) -> HexTileNode
var tiles: Dictionary = {}

# The currently selected tile node, if any
var selected_tile: HexTileNode = null

func _ready() -> void:
    generate_map()

# Generates or regenerates the map.
func generate_map() -> void:
    # 1. Clear existing tiles
    clear_map()

    # 2. Setup RandomNumberGenerator
    var rng = RandomNumberGenerator.new()
    if random_seed != 0:
        rng.seed = random_seed
    else:
        rng.randomize()

    # 3. Generate grid
    for q in range(map_size_q):
        for r in range(map_size_r):
            _create_tile(q, r, rng)

# Instantiates a single tile and adds it to the grid.
func _create_tile(q: int, r: int, rng: RandomNumberGenerator) -> void:
    # Determine terrain
    var rand_val = rng.randf()
    var terrain = HexTileNode.STEPPE

    if rand_val < 0.70:
        terrain = HexTileNode.STEPPE
    elif rand_val < 0.85:
        terrain = HexTileNode.MOUNTAIN
    else:
        terrain = HexTileNode.RIVER

    # Instantiate and configure the tile
    var tile_node: HexTileNode = hex_tile_scene.instantiate() as HexTileNode
    add_child(tile_node)

    # Position the node visually using HexUtils
    tile_node.position = HexUtils.hex_to_world(q, r)

    # Initialize the tile's data and tell it to draw
    tile_node.setup(q, r, terrain)

    # Store in dictionary
    tiles[Vector2i(q, r)] = tile_node

# Removes all current tiles from the dictionary and scene tree.
func clear_map() -> void:
    for coord in tiles:
        var tile = tiles[coord]
        if is_instance_valid(tile):
            tile.queue_free()
    tiles.clear()

# Get a specific tile, or null if it doesn't exist.
func get_tile(q: int, r: int) -> HexTileNode:
    var coord = Vector2i(q, r)
    if tiles.has(coord):
        return tiles[coord]
    return null

# ── Interaction ──────────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        # 1. Get mouse position local to this MapManager node
        var local_mouse_pos = get_local_mouse_position()

        # 2. Convert to hex coordinates
        var hex_coord = HexUtils.world_to_hex(local_mouse_pos)

        # 3. Check if we clicked on a valid tile in our dictionary
        if tiles.has(hex_coord):
            select_tile(tiles[hex_coord])
        else:
            # Clicked outside the grid
            deselect_current_tile()

# Handles selecting a new tile, deselecting the old one first.
func select_tile(tile: HexTileNode) -> void:
    if selected_tile == tile:
        return # Already selected

    deselect_current_tile()
    
    selected_tile = tile
    if selected_tile:
        selected_tile.set_selected(true)

# Deselects the currently selected tile.
func deselect_current_tile() -> void:
    if selected_tile:
        selected_tile.set_selected(false)
        selected_tile = null

# Optional: manually regenerate the map using an input action (for testing).
# func _unhandled_input(event: InputEvent) -> void:
#     if event.is_action_pressed("ui_accept"):  # Press Space/Enter
#         generate_map()
