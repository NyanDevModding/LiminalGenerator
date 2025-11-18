local AccessConnectStack = require(script.Parent.Parent.gen_data.AccessConnectStack)
local FlagGrid = require(script.Parent.Parent.gen_data.FlagGrid)
local FlagGridsWrapper = require(script.Parent.Parent.gen_data.FlagGridsWrapper)
local CorridorStorage = require(script.Parent.Parent.gen_data.storage.CorridorStorage)
local RoomStorage = require(script.Parent.Parent.gen_data.storage.RoomStorage)
local Settings = require(script.Parent.Parent.gen_setting.Settings)
local RoomDataSet = require(script.Parent.Parent.gen_setting.room_data_set.RoomDataSet)
local room_data_set_json_type =
	require(script.Parent.Parent.gen_setting.room_data_set.room_data_set_json_type)
local SeededRandom = require(script.Parent.SeededRandom)

local collisionHandler = require(script.Parent.corridor_connection.collisionHandler)
local pathfinder = require(script.Parent.corridor_connection.pathfinder)
local roomGenerator = require(script.Parent.corridor_connection.roomGenerator)

local Generator = {}
Generator.__index = Generator

export type Generator = typeof(Generator.new())

function Generator.new(
	seed: number,
	genSettings: Settings.gen_settings,
	setData: room_data_set_json_type.roomDataSetJson,
	debugMode: boolean
)
	return setmetatable({
		_seed = seed,
		_genSettings = genSettings,
		_roomDataSet = RoomDataSet.new(setData),
	}, Generator)
end

local DEFAULT_ACCESS_SEARCH = 2

function Generator.generate(
	self: Generator,
	xSize: number,
	ySize: number,
	zSize: number,
	debugMode: boolean
)
	local seededRandom = SeededRandom.new(self._seed)

	local roomGrid = FlagGrid.new(xSize, ySize, zSize)
	local corridorGrid = FlagGrid.new(xSize, ySize, zSize)

	local accessConnectStack = AccessConnectStack.new(xSize, ySize, zSize)
	local roomStorage = RoomStorage.new()
	local corridorStorage = CorridorStorage.new()

	local accessRoomGrid = FlagGridsWrapper.new({ roomGrid, accessConnectStack:getGrid() })

	print(
		("Generating on a (%i, %i, %i) area\nFrom RoomDataSet: %s"):format(
			xSize,
			ySize,
			zSize,
			self._roomDataSet:getVersion()
		)
	)

	-- First, generate some rooms all around the map
	roomGenerator(
		self._genSettings,
		self._roomDataSet,
		seededRandom,
		roomGrid,
		roomStorage,
		accessConnectStack,
		debugMode
	)

	local MAX_TIMEOUT = 1000

	local deadEndsStack = AccessConnectStack.new(xSize, ySize, zSize)

	-- Then connect the corridors
	local timeout = 0
	while not accessConnectStack:isEmpty() and timeout <= MAX_TIMEOUT do
		local access1 = accessConnectStack:pop()
		local access2 = accessConnectStack:popRoomDifferent(
			access1.room,
			self._genSettings.access_search_depth or DEFAULT_ACCESS_SEARCH
		)

		if access2 == nil then
			if accessConnectStack:isEmpty() then
				break
			end

			access2 = accessConnectStack:pop()
		end

		timeout += 1

		print("pathfinding")
		local corridor = pathfinder(accessRoomGrid, access1, access2)

		if corridor == nil then
			deadEndsStack:push(access1)
			deadEndsStack:push(access2)
			continue
		end

		if debugMode then
			coroutine.yield(roomGrid, corridorStorage, accessConnectStack, corridor)
		end

		print("searching collision")

		local collision = corridor:getFirstCollision(corridorGrid)

		if collision then
			local handled = collisionHandler(
				corridor,
				collision,
				self._genSettings,
				self._roomDataSet,
				seededRandom,
				roomGrid,
				roomStorage,
				corridorGrid,
				corridorStorage,
				accessConnectStack,
				debugMode
			)

			if not handled then
				--TODO handle deadEndStack
				warn("Collision not handled")
				deadEndsStack:push(access1)
				deadEndsStack:push(access2)
			end
		else
			corridor:addOnGrid(corridorGrid)
			corridorStorage:addCorridor(corridor)

			access1.room:setAdjacent(corridor, access1.access)
		end

		if debugMode then
			coroutine.yield(roomGrid, corridorStorage, accessConnectStack)
		end
	end

	return roomStorage, corridorStorage
end

return Generator
