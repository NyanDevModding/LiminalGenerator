local FlagGrid = require(script.Parent.Parent.gen_data.FlagGrid)
local FlagGridsWrapper = require(script.Parent.Parent.gen_data.FlagGridsWrapper)
local AccessConnectStorage = require(script.Parent.Parent.gen_data.storage.AccessConnectStorage)
local CorridorStorage = require(script.Parent.Parent.gen_data.storage.CorridorStorage)
local RoomStorage = require(script.Parent.Parent.gen_data.storage.RoomStorage)
local Access = require(script.Parent.Parent.gen_elements.access.Access)
local Settings = require(script.Parent.Parent.gen_setting.Settings)
local RoomDataSet = require(script.Parent.Parent.gen_setting.room_data_set.RoomDataSet)
local SeededRandom = require(script.Parent.SeededRandom)

local collisionHandler = require(script.Parent.corridor_connection.collisionHandler)
local pathfinder = require(script.Parent.corridor_connection.pathfinder)
local roomGenerator = require(script.Parent.corridor_connection.roomGenerator)

local Generator = {}
Generator.__index = Generator

export type Generator = typeof(Generator.new())

local function getOtherAccess(
	accessConnectStorage: AccessConnectStorage.AccessConnectStorage,
	access1: Access.Access,
	proximity: number?,
	searchDepth: number
): Access.Access?
	local accessPos = Vector3.new(
		access1.x + access1.direction.X,
		access1.y + access1.direction.Y,
		access1.z + access1.direction.Z
	)

	local selection = accessConnectStorage:startSelection():selectMinProximity(accessPos, 2)

	if proximity ~= nil then
		selection:selectMaxProximity(accessPos, proximity)
	end

	if searchDepth > 0 then
		selection:selectByConnection(access1.room, searchDepth)
	end

	return selection:getAccessNot(access1)
end

function Generator.new(
	seed: number,
	genSettings: Settings.gen_settings,
	roomDataSet: RoomDataSet.RoomDataSet,
	debugMode: boolean
)
	return setmetatable({
		_seed = seed,
		_genSettings = genSettings,
		_roomDataSet = roomDataSet,
	}, Generator)
end

local DEFAULT_ACCESS_SEARCH = 2
local DEFAULT_ACCESS_PROXIMITY = 10

function Generator.generate(
	self: Generator,
	xSize: number,
	ySize: number,
	zSize: number,
	debugMode: boolean
)
	local beginningDate = os.clock()

	local accessMaxProximity = (
		xSize / (self._genSettings.access_connection_proximity or DEFAULT_ACCESS_PROXIMITY)
		+ zSize / (self._genSettings.access_connection_proximity or DEFAULT_ACCESS_PROXIMITY)
	) / 2
	local accessSearchDepth = self._genSettings.access_search_depth or DEFAULT_ACCESS_SEARCH

	local seededRandom = SeededRandom.new(self._seed)

	local roomGrid = FlagGrid.new(xSize, ySize, zSize)
	local corridorGrid = FlagGrid.new(xSize, ySize, zSize)

	local accessConnectStorage = AccessConnectStorage.new(xSize, ySize, zSize)
	local roomStorage = RoomStorage.new()
	local corridorStorage = CorridorStorage.new()

	local accessAndRoomGrid = FlagGridsWrapper.new({ roomGrid, accessConnectStorage:getGrid() })

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
		accessConnectStorage,
		debugMode
	)

	if debugMode then
		print("Check Sync after roomGeneration")
		roomStorage:debugCheckSyncWithGrid(roomGrid)
		corridorStorage:debugCheckSyncWithGrid(corridorGrid)
	end

	local MAX_TIMEOUT = 1000

	-- Then connect the corridors
	local timeout = 0
	local loopNum = 0
	while not accessConnectStorage:isToConnectEmpty() and timeout <= MAX_TIMEOUT do
		loopNum += 1

		if debugMode then
			print(" - Starting loop #" .. tostring(loopNum))

			print("At the beginning of the loop:")
			print("	Check Sync")
			roomStorage:debugCheckSyncWithGrid(roomGrid)
			corridorStorage:debugCheckSyncWithGrid(corridorGrid)

			print("	Check CorridorStorage OK")
			corridorStorage:debugIsOk(Vector3.new(xSize, ySize, zSize), roomGrid)
		end

		local access1 = accessConnectStorage:getRandomAccessToConnect(seededRandom)

		if accessConnectStorage:getToConnectSize() == 1 then
			accessConnectStorage:makeCantConnect(access1)
			break
		end

		local access1Pos = Vector3.new(
			access1.x + access1.direction.X,
			access1.y + access1.direction.Y,
			access1.z + access1.direction.Z
		)
		local access2 = accessConnectStorage
			:startSelection()
			:selectMinProximity(access1Pos, 2)
			:selectMaxProximity(access1Pos, accessMaxProximity)
			:selectByConnection(access1.room, accessSearchDepth)
			:getAccessNot(access1)

		-- Try to get accessNum2 by testing larger and larger configurations
		if access2 == nil then
			debug.profilebegin("Searching for a second access")

			local i = 2
			local iMax = math.max(xSize - access1.x, access1.x, zSize - access1.z, access1.z)
			local step = math.round(iMax / 10)

			repeat
				local newMaxProximity = math.round(
					1.25 * (accessMaxProximity + (iMax - accessMaxProximity) * (i / iMax))
				)

				local newSearchDepth =
					math.round(accessSearchDepth - accessSearchDepth * (i / iMax))
				if newSearchDepth < 0 then
					newSearchDepth = 0
				end

				-- Try configurations and diminuish the limits
				access2 =
					getOtherAccess(accessConnectStorage, access1, newMaxProximity, newSearchDepth)

				if newMaxProximity >= iMax then
					break
				end

				i += step
			until access2 ~= nil or i >= iMax

			debug.profileend()

			-- The last try
			if access2 == nil then
				local lastTryAccess2 = getOtherAccess(accessConnectStorage, access1, nil, 0)

				if lastTryAccess2 == nil then
					-- Else just mark it as cant connect
					accessConnectStorage:makeCantConnect(access1)
					continue
				end

				access2 = lastTryAccess2
			end
		end

		timeout += 1

		local corridor = pathfinder(accessAndRoomGrid, access1, access2)

		if corridor == nil then
			accessConnectStorage:makeCantConnect(access1)
			accessConnectStorage:makeCantConnect(access2)
			continue
		end

		if debugMode then
			coroutine.yield(roomGrid, roomStorage, corridorStorage, accessConnectStorage, corridor)
		end

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
				accessConnectStorage,
				debugMode
			)

			if debugMode then
				print("After the collision handling")
				print("	Check Sync")
				corridorStorage:debugCheckSyncWithGrid(corridorGrid)
				roomStorage:debugCheckSyncWithGrid(roomGrid)

				print("	Check CorridorStorage OK")
				corridorStorage:debugIsOk(Vector3.new(xSize, ySize, zSize), roomGrid)
			end

			if not handled then
				accessConnectStorage:makeCantConnect(access1)
				accessConnectStorage:makeCantConnect(access2)
				continue
			end
		else
			corridor:addOnGrid(corridorGrid)
			corridorStorage:addCorridor(corridor)

			corridor:connectToAdjacents()

			if debugMode then
				print("After the corridor is added (no collision)")
				print("	Check Sync")
				roomStorage:debugCheckSyncWithGrid(roomGrid)
				corridorStorage:debugCheckSyncWithGrid(corridorGrid)

				print("	Check CorridorStorage OK")
				corridorStorage:debugIsOk(Vector3.new(xSize, ySize, zSize), roomGrid)
			end
		end

		accessConnectStorage:makeConnected(access1)
		accessConnectStorage:makeConnected(access2)

		if debugMode then
			coroutine.yield(roomGrid, roomStorage, corridorStorage, accessConnectStorage)
		end
	end

	local delta = (os.clock() - beginningDate) * 1000
	print("Succesfully generated in " .. tostring(delta) .. "ms")

	return roomStorage, corridorStorage
end

return Generator
