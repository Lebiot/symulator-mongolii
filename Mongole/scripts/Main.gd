extends Node2D
# Main.gd — Root scene controller.
# Creates the grid, units, and UI; handles selection, movement, turns, and AI.

var grid:     HexGrid
var ui:       UIPanel
var units:    Array[Unit] = []

var selected_unit: Unit            = null
var reachable:     Array[Vector2i] = []
var game_ended:    bool            = false

# ══════════════════════════════════════════════════════════
# Initialization
# ══════════════════════════════════════════════════════════

func _ready() -> void:
	_setup_grid()
	_setup_units()
	_setup_ui()
	_connect_signals()
	_start_player_turn()

func _setup_grid() -> void:
	grid          = HexGrid.new()
	# Offset so the grid sits below the HUD bar with a small margin.
	grid.position = Vector2(60, 90)
	add_child(grid)

func _setup_units() -> void:
	# Player starts bottom-centre
	_spawn(Unit.WARRIOR, Unit.PLAYER, Vector2i(5, 7))
	_spawn(Unit.CAVALRY, Unit.PLAYER, Vector2i(6, 7))
	# AI starts top area
	_spawn(Unit.WARRIOR, Unit.AI, Vector2i(5, 1))
	_spawn(Unit.CAVALRY, Unit.AI, Vector2i(6, 1))

func _spawn(type: int, owner: int, coord: Vector2i) -> void:
	var u = Unit.new()
	u.setup(type, owner, coord)
	u.position = grid.hex_to_pixel(coord.x, coord.y)
	grid.add_child(u)   # child of grid so it shares the grid transform
	units.append(u)

	# Claim the starting tile (and neutral neighbours) right away
	var tile_owner = HexTile.PLAYER if owner == Unit.PLAYER else HexTile.AI
	grid.claim_around(coord, tile_owner)

func _setup_ui() -> void:
	ui = UIPanel.new()
	add_child(ui)
	ui.btn_end.pressed.connect(end_turn)

func _connect_signals() -> void:
	grid.tile_clicked.connect(_on_tile_clicked)
	GameState.game_over.connect(_on_game_over)
	GameState.tile_ownership_changed.connect(_refresh_tile_pct)

# ══════════════════════════════════════════════════════════
# Player turn
# ══════════════════════════════════════════════════════════

func _start_player_turn() -> void:
	GameState.is_player_turn = true

	# Reset all player units' move points
	for u in units:
		if u.unit_owner == Unit.PLAYER:
			u.reset_mp()
			u.queue_redraw()

	_apply_economy()
	_check_win()
	if not game_ended:
		GameState.turn_changed.emit(GameState.current_turn, true)
		_refresh_tile_pct()

func _apply_economy() -> void:
	var income = Economy.calculate_player_income(grid.tiles)
	GameState.food   += income["food"]
	GameState.horses += income["horses"]
	GameState.gold   += income["gold"]

	# Food upkeep: −1 per player unit per turn
	var player_count = 0
	for u in units:
		if u.unit_owner == Unit.PLAYER:
			player_count += 1
	GameState.food = max(0, GameState.food - player_count)

	GameState.resources_changed.emit()

# ══════════════════════════════════════════════════════════
# Unit selection & movement (player only)
# ══════════════════════════════════════════════════════════

func _on_tile_clicked(coord: Vector2i) -> void:
	if not GameState.is_player_turn or game_ended:
		return

	var clicked_unit = _unit_at(coord)

	if clicked_unit != null and clicked_unit.unit_owner == Unit.PLAYER:
		# Click on own unit → select it
		_select(clicked_unit)
	elif selected_unit != null and coord in reachable:
		# Click on highlighted tile → move selected unit there
		_move(selected_unit, coord)
	else:
		# Click on empty / enemy tile → deselect
		_deselect()

func _select(u: Unit) -> void:
	_deselect()
	selected_unit = u
	u.selected    = true
	u.queue_redraw()
	reachable = grid.get_reachable(u.coord, u.mp_left)
	grid.set_highlighted(reachable)

func _deselect() -> void:
	if selected_unit != null:
		selected_unit.selected = false
		selected_unit.queue_redraw()
	selected_unit = null
	reachable     = []
	grid.set_highlighted([])

func _move(u: Unit, target: Vector2i) -> void:
	# Spend AP equal to the target tile's move cost
	u.mp_left -= grid.tiles[target].move_cost()
	u.coord    = target
	u.position = grid.hex_to_pixel(target.x, target.y)
	grid.claim_around(target, HexTile.PLAYER)
	u.queue_redraw()

	# If the unit still has AP, keep it selected; otherwise deselect
	if u.mp_left > 0:
		_select(u)
	else:
		_deselect()

	_check_win()

func _unit_at(coord: Vector2i) -> Unit:
	for u in units:
		if u.coord == coord:
			return u
	return null

# ══════════════════════════════════════════════════════════
# End turn / AI turn
# ══════════════════════════════════════════════════════════

func end_turn() -> void:
	if game_ended:
		return
	_deselect()
	_ai_turn()

# AI turn is async so we can add a short pause before handing back.
func _ai_turn() -> void:
	GameState.is_player_turn = false
	GameState.turn_changed.emit(GameState.current_turn, false)

	for u in units:
		if u.unit_owner == Unit.AI:
			u.reset_mp()
			_ai_move(u)

	# Brief pause so the player can see what the AI did
	await get_tree().create_timer(0.7).timeout

	GameState.current_turn += 1
	_check_win()
	if not game_ended:
		_start_player_turn()

# ── Simple greedy AI ───────────────────────────────────────
# Each AI unit moves toward the closest tile it does not own.

func _ai_move(u: Unit) -> void:
	var target = _nearest_non_ai(u.coord)
	if target == Vector2i(-1, -1):
		return   # nothing left to claim

	var reachable_ai = grid.get_reachable(u.coord, u.mp_left)

	var destination: Vector2i
	if target in reachable_ai:
		# Can reach it directly
		destination = target
	else:
		# Step toward target: pick the reachable tile closest to target
		destination = u.coord
		var best_d  = _approx_dist(u.coord, target)
		for r in reachable_ai:
			var d = _approx_dist(r, target)
			if d < best_d:
				best_d      = d
				destination = r

	if destination == u.coord:
		return   # already there or blocked

	u.coord    = destination
	u.position = grid.hex_to_pixel(destination.x, destination.y)
	grid.claim_around(destination, HexTile.AI)
	u.queue_redraw()

func _nearest_non_ai(origin: Vector2i) -> Vector2i:
	var best   = Vector2i(-1, -1)
	var best_d = 9999
	for coord in grid.tiles:
		if grid.tiles[coord].owner != HexTile.AI:
			var d = _approx_dist(origin, coord)
			if d < best_d:
				best_d = d
				best   = coord
	return best

# Simple Manhattan-like distance in offset coords (good-enough for greedy AI).
func _approx_dist(a: Vector2i, b: Vector2i) -> int:
	return abs(a.x - b.x) + abs(a.y - b.y)

# ══════════════════════════════════════════════════════════
# Win condition
# ══════════════════════════════════════════════════════════

func _check_win() -> void:
	if game_ended:
		return

	var total  = GameState.COLS * GameState.ROWS
	var counts = Economy.count_tiles(grid.tiles)
	var p      = counts[HexTile.PLAYER]
	var a      = counts[HexTile.AI]

	if p >= int(total * 0.6):
		_end_game("Victory!  You dominate the great steppe!")
	elif a >= int(total * 0.6):
		_end_game("Defeat.  The enemy has overrun your tribe.")
	elif GameState.current_turn > GameState.MAX_TURNS:
		if p > a:
			_end_game("Time is up — You hold more land.  Victory!")
		elif a > p:
			_end_game("Time is up — The enemy holds more land.  Defeat.")
		else:
			_end_game("Time is up — A draw on the steppe.")

func _end_game(message: String) -> void:
	game_ended = true
	GameState.game_over.emit(message)

func _on_game_over(message: String) -> void:
	ui.show_game_over(message)

# ══════════════════════════════════════════════════════════
# HUD helpers
# ══════════════════════════════════════════════════════════

func _refresh_tile_pct(_ignored = null) -> void:
	var total  = GameState.COLS * GameState.ROWS
	var counts = Economy.count_tiles(grid.tiles)
	var pct    = int(counts[HexTile.PLAYER] * 100.0 / total)
	ui.set_tile_percent(pct)
