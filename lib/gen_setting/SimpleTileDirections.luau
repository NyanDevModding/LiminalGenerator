local Directions = require(script.Parent.Parent.gen_data.Directions)
export type Direction = {
	[number]: Directions.Direction,
}

local SimpleTileDirections = {
	-- simple directions
	NORTH_WEST = { Directions.NORTH, Directions.WEST },
	NORTH_SOUTH = { Directions.NORTH, Directions.SOUTH },
	NORTH_EAST = { Directions.NORTH, Directions.EAST },
	WEST_SOUTH = { Directions.WEST, Directions.SOUTH },
	WEST_EAST = { Directions.WEST, Directions.EAST },
	SOUTH_EAST = { Directions.SOUTH, Directions.EAST },
}

local function toDirection(dir1: Vector3, dir2: Vector3)
	if
		(dir1 == Directions.NORTH and dir2 == Directions.WEST)
		or (dir1 == Directions.WEST and dir2 == Directions.NORTH)
	then
		return SimpleTileDirections.NORTH_WEST
	elseif
		(dir1 == Directions.NORTH and dir2 == Directions.SOUTH)
		or (dir1 == Directions.SOUTH and dir2 == Directions.NORTH)
	then
		return SimpleTileDirections.NORTH_SOUTH
	elseif
		(dir1 == Directions.NORTH and dir2 == Directions.EAST)
		or (dir1 == Directions.EAST and dir2 == Directions.NORTH)
	then
		return SimpleTileDirections.NORTH_EAST
	elseif
		(dir1 == Directions.SOUTH and dir2 == Directions.WEST)
		or (dir1 == Directions.WEST and dir2 == Directions.SOUTH)
	then
		return SimpleTileDirections.WEST_SOUTH
	elseif
		(dir1 == Directions.WEST and dir2 == Directions.EAST)
		or (dir1 == Directions.EAST and dir2 == Directions.WEST)
	then
		return SimpleTileDirections.WEST_EAST
	elseif
		(dir1 == Directions.SOUTH and dir2 == Directions.EAST)
		or (dir1 == Directions.EAST and dir2 == Directions.SOUTH)
	then
		return SimpleTileDirections.SOUTH_EAST
	end

	error(
		("Couldn't transform the directions: {%s} and {%s} into a SimpleTileDirection"):format(
			tostring(dir1),
			tostring(dir2)
		)
	)
end

return setmetatable(SimpleTileDirections, { __index = { toDirection = toDirection } })
