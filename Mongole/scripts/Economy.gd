class_name Economy
# Economy.gd — Pure calculation functions; not a Node.
# Called once per turn by Main.gd.

# Sum up income from all tiles owned by the player.
static func calculate_player_income(tiles: Dictionary) -> Dictionary:
	var income = {"food": 0, "horses": 0, "gold": 0}
	for coord in tiles:
		var tile: HexTile = tiles[coord]
		if tile.owner == HexTile.PLAYER:
			var y = tile.get_income()
			income["food"]   += y["food"]
			income["horses"] += y["horses"]
			income["gold"]   += y["gold"]
	return income

# Count tiles by owner.  Returns { NEUTRAL: n, PLAYER: n, AI: n }.
static func count_tiles(tiles: Dictionary) -> Dictionary:
	var counts = { HexTile.NEUTRAL: 0, HexTile.PLAYER: 0, HexTile.AI: 0 }
	for coord in tiles:
		counts[tiles[coord].owner] += 1
	return counts
