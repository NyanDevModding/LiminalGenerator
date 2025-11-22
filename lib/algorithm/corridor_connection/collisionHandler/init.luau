local Corridor = require(script.Parent.Parent.Parent.gen_elements.corridor.Corridor)

local Settings = require(script.Parent.Parent.Parent.gen_setting.Settings)
local RoomDataSet = require(script.Parent.Parent.Parent.gen_setting.room_data_set.RoomDataSet)
local SeededRandom = require(script.Parent.Parent.SeededRandom)
local FlagGrid = require(script.Parent.Parent.Parent.gen_data.FlagGrid)
local AccessConnectStorage =
	require(script.Parent.Parent.Parent.gen_data.storage.AccessConnectStorage)
local CorridorStorage = require(script.Parent.Parent.Parent.gen_data.storage.CorridorStorage)
local RoomStorage = require(script.Parent.Parent.Parent.gen_data.storage.RoomStorage)
local Access = require(script.Parent.Parent.Parent.gen_elements.access.Access)

local handleRegenerate = require(script.handleRegenerate)
local handleIncrustation = require(script.handleIncrustation)

local function handleDeadEnd(
	corridor: Corridor.Corridor,
	secondAccess: Access.Access,
	collision: Vector3,
	genSettings: Settings.gen_settings,
	roomDataSet: RoomDataSet.RoomDataSet,
	seededRandom: SeededRandom.SeededRandom,
	roomGrid: FlagGrid.FlagGrid,
	roomStorage: RoomStorage.RoomStorage,
	corridorGrid: FlagGrid.FlagGrid,
	corridorStorage: CorridorStorage.CorridorStorage,
	accessConnectStorage: AccessConnectStorage.AccessConnectStorage
)
	local deadEndNum = corridor:getFirstVertexBefore(collision)

	--TODO handle deadEnd at vertex #1
	print("vertex dead end: " .. tostring(deadEndNum))

	if deadEndNum ~= nil and deadEndNum ~= 1 then
		local deadEndRoomDatas = roomDataSet:getDeadEndTiles(
			corridor:getAccessData(1):getAccessType(),
			corridor:getVertexStartingDirection(deadEndNum)
		)
		if deadEndRoomDatas[1] == nil then
			return nil
		end

		local deadEndRoom = corridor:makeDeadEnd(deadEndRoomDatas[1], deadEndNum)

		print(tostring(roomGrid))

		local deadEndPos = deadEndRoom:getPos()
		roomStorage:addRoom(deadEndRoom)
		roomGrid:set(deadEndPos.X, deadEndPos.Y, deadEndPos.Z)
		corridor:addOnGrid(corridorGrid)
		corridorStorage:addCorridor(corridor)

		return true
	end

	return false
end

return function(
	corridor: Corridor.Corridor,
	collision: Vector3,
	genSettings: Settings.gen_settings,
	roomDataSet: RoomDataSet.RoomDataSet,
	seededRandom: SeededRandom.SeededRandom,
	roomGrid: FlagGrid.FlagGrid,
	roomStorage: RoomStorage.RoomStorage,
	corridorGrid: FlagGrid.FlagGrid,
	corridorStorage: CorridorStorage.CorridorStorage,
	accessConnectStorage: AccessConnectStorage.AccessConnectStorage,
	debugMode: boolean
)
	local collisionCorridor = corridorStorage:getCorridorAt(collision)

	if collisionCorridor == nil then
		print("fantom corridor with collision at: " .. tostring(collision))
		print(corridorGrid)
	end

	-- The corridor is not yet written in the grid.
	-- Every function add a corridor in the grid and the world.

	local firstAccess = corridor:createAdjacentAccess(1)
	local secondAccess = corridor:createAdjacentAccess(2)

	print("try regenerate")
	-- try swap
	if
		handleRegenerate(
			corridor,
			firstAccess,
			secondAccess,
			collisionCorridor,
			genSettings,
			seededRandom,
			roomGrid,
			corridorGrid,
			corridorStorage,
			accessConnectStorage
		)
	then
		if debugMode then
			coroutine.yield(roomGrid, roomStorage, corridorStorage, accessConnectStorage)
		end

		return true
	end

	print("try incrustation")
	print("	Quickly check CorridorStorage OK after try regenerate")
	corridorStorage:debugIsOk(
		Vector3.new(corridorGrid:getXSize(), corridorGrid:getYSize(), corridorGrid:getZSize())
	)
	-- try incrustation
	if
		handleIncrustation(
			corridor,
			genSettings,
			roomDataSet,
			seededRandom,
			roomGrid,
			roomStorage,
			corridorGrid,
			corridorStorage,
			accessConnectStorage
		)
	then
		if debugMode then
			coroutine.yield(roomGrid, roomStorage, corridorStorage, accessConnectStorage)
		end

		return true
	end

	warn("try dead end")
	-- try dead end
	if
		handleDeadEnd(
			corridor,
			secondAccess,
			collision,
			genSettings,
			roomDataSet,
			seededRandom,
			roomGrid,
			roomStorage,
			corridorGrid,
			corridorStorage,
			accessConnectStorage,
			debugMode
		)
	then
		if debugMode then
			coroutine.yield(roomGrid, roomStorage, corridorStorage, accessConnectStorage)
		end

		return true
	end

	if debugMode then
		coroutine.yield(roomGrid, roomStorage, corridorStorage, accessConnectStorage)
	end

	return false
end
