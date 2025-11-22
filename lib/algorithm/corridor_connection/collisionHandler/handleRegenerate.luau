local Directions = require(script.Parent.Parent.Parent.Parent.gen_data.Directions)
local Corridor = require(script.Parent.Parent.Parent.Parent.gen_elements.corridor.Corridor)

local Settings = require(script.Parent.Parent.Parent.Parent.gen_setting.Settings)
local SeededRandom = require(script.Parent.Parent.Parent.SeededRandom)
local FlagGrid = require(script.Parent.Parent.Parent.Parent.gen_data.FlagGrid)
local FlagGridsWrapper = require(script.Parent.Parent.Parent.Parent.gen_data.FlagGridsWrapper)
local IReadableGrid = require(script.Parent.Parent.Parent.Parent.gen_data.IReadableGrid)
local AccessConnectStorage =
	require(script.Parent.Parent.Parent.Parent.gen_data.storage.AccessConnectStorage)
local CorridorStorage = require(script.Parent.Parent.Parent.Parent.gen_data.storage.CorridorStorage)
local Access = require(script.Parent.Parent.Parent.Parent.gen_elements.access.Access)

local pathfinder = require(script.Parent.Parent.pathfinder)

local DEFAULT_BFS_DIRECTIONS =
	{ Directions.NORTH, Directions.WEST, Directions.SOUTH, Directions.EAST }
local OFFSET_BFS_DIRECTIONS =
	{ Directions.SOUTH, Directions.EAST, Directions.NORTH, Directions.WEST }

local function swapCorridors(
	corridor: Corridor.Corridor,
	collisionCorridor: Corridor.Corridor,
	corridorGrid: FlagGrid.FlagGrid,
	gridWrapper: IReadableGrid.IReadableGrid
): (Corridor.Corridor?, Corridor.Corridor?)
	local firstAccess = corridor:createAdjacentAccess(1)
	local secondAccess = corridor:createAdjacentAccess(2)

	local otherFirstAccess = collisionCorridor:createAdjacentAccess(1)
	local otherSecondAccess = collisionCorridor:createAdjacentAccess(2)

	-- Check that the access aren't too close to each other
	if
		((firstAccess.x - otherSecondAccess.x) ^ 2 + (firstAccess.y - otherSecondAccess.y) ^ 2 + (firstAccess.z - otherSecondAccess.z) ^ 2)
			^ 0.5
		<= 2
	then
		return nil, nil
	end

	if
		((secondAccess.x - otherFirstAccess.x) ^ 2 + (secondAccess.y - otherFirstAccess.y) ^ 2 + (secondAccess.z - otherFirstAccess.z) ^ 2)
			^ 0.5
		<= 2
	then
		return nil, nil
	end

	local newFirstCorridor =
		pathfinder(gridWrapper, firstAccess, otherSecondAccess, DEFAULT_BFS_DIRECTIONS)

	if newFirstCorridor == nil then
		return nil, nil
	end

	newFirstCorridor:addOnGrid(corridorGrid)

	local newSecondCorridor =
		pathfinder(gridWrapper, otherFirstAccess, secondAccess, OFFSET_BFS_DIRECTIONS)

	newFirstCorridor:removeFromGrid(corridorGrid)

	if newSecondCorridor == nil then
		return nil, nil
	end

	if newFirstCorridor:getFirstCollisionWith(newSecondCorridor) ~= nil then
		return nil, nil
	end

	return newFirstCorridor, newSecondCorridor
end

return function(
	corridor: Corridor.Corridor,
	firstAccess: Access.Access,
	secondAccess: Access.Access,
	collisionCorridor: Corridor.Corridor,
	genSettings: Settings.gen_settings,
	seededRandom: SeededRandom.SeededRandom,
	roomGrid: FlagGrid.FlagGrid,
	corridorGrid: FlagGrid.FlagGrid,
	corridorStorage: CorridorStorage.CorridorStorage,
	accessConnectStorage: AccessConnectStorage.AccessConnectStorage
)
	-- try regenerating the corridors w/ the corridor grid and access grid in addition
	local wrappedGrid = FlagGridsWrapper.new({
		roomGrid,
		corridorGrid,
		accessConnectStorage:getGrid(),
	})

	-- Regenerate a corridor, this time by taking into account corridors
	local regenerated = pathfinder(wrappedGrid, firstAccess, secondAccess, DEFAULT_BFS_DIRECTIONS)

	-- Add and remove the collision corridor as it blocks the swap function
	collisionCorridor:removeFromGrid(corridorGrid)
	local swapped1, swapped2 = swapCorridors(corridor, collisionCorridor, corridorGrid, wrappedGrid)

	collisionCorridor:addOnGrid(corridorGrid)

	-- Couldn't regenerate nor swap
	if regenerated == nil and swapped1 == nil then
		return false
	end

	-- Couldn't create a swapped
	if regenerated ~= nil and swapped1 == nil then
		regenerated:addOnGrid(corridorGrid)
		corridorStorage:addCorridor(regenerated)

		regenerated:connectToAdjacents()

		return true
	end

	-- From here, swapped1 and 2 aren't nil.
	if regenerated == nil and swapped1 ~= nil then
		collisionCorridor:removeFromGrid(corridorGrid)
		corridorStorage:removeCorridor(collisionCorridor)

		swapped1:addOnGrid(corridorGrid)
		swapped2:addOnGrid(corridorGrid)
		corridorStorage:addCorridor(swapped1)
		corridorStorage:addCorridor(swapped2)

		swapped1:connectToAdjacents()
		swapped2:connectToAdjacents()

		return true
	end

	-- regenerated ~= nil and swapped1 ~= nil

	-- If the swapped version is just longer then keep the old one
	if
		swapped1:getLength() + swapped2:getLength()
		< regenerated:getLength() + collisionCorridor:getLength()
	then
		collisionCorridor:removeFromGrid(corridorGrid)
		corridorStorage:removeCorridor(collisionCorridor)

		swapped1:addOnGrid(corridorGrid)
		swapped2:addOnGrid(corridorGrid)
		corridorStorage:addCorridor(swapped1)
		corridorStorage:addCorridor(swapped2)

		swapped1:connectToAdjacents()
		swapped2:connectToAdjacents()

		return true
	end

	-- Else, juste plot the regenerated
	regenerated:addOnGrid(corridorGrid)
	corridorStorage:addCorridor(regenerated)

	regenerated:connectToAdjacents()

	return true
end
