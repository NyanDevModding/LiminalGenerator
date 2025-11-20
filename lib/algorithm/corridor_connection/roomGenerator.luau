local AccessConnectStack = require(script.Parent.Parent.Parent.gen_data.AccessConnectStack)
local FlagGrid = require(script.Parent.Parent.Parent.gen_data.FlagGrid)
local RoomStorage = require(script.Parent.Parent.Parent.gen_data.storage.RoomStorage)
local Access = require(script.Parent.Parent.Parent.gen_elements.access.Access)
local Room = require(script.Parent.Parent.Parent.gen_elements.room.Room)
local Settings = require(script.Parent.Parent.Parent.gen_setting.Settings)
local RoomDataSet = require(script.Parent.Parent.Parent.gen_setting.room_data_set.RoomDataSet)
local SeededRandom = require(script.Parent.Parent.SeededRandom)

local TIMEOUT_AMOUNT = 1000

return function(
	genSettings: Settings.gen_settings,
	roomDataSet: RoomDataSet.RoomDataSet,
	seededRandom: SeededRandom.SeededRandom,
	roomGrid: FlagGrid.FlagGrid,
	roomStorage: RoomStorage.RoomStorage,
	accessConnectStack: AccessConnectStack.AccessConnectStack,
	debugMode: boolean?
)
	--TODO This is one of the worst shit algorithm, approximately a lot of byte of trash data and useless call, you really need to optimize this
	--TODO make it place the consecutive room next to each other so the accessStack don't need to be sorted
	local roomAmount = genSettings.room_amount
		or math.floor(roomGrid:getXSize() * roomGrid:getYSize() * roomGrid:getZSize() / (5 * 3 * 5))

	local i = 1

	local gridSize = Vector3.new(roomGrid:getXSize(), roomGrid:getYSize(), roomGrid:getZSize())

	local selector = roomDataSet:startRoomSelection():selectNonTile()
	local accessGrid = accessConnectStack:getGrid()

	while roomAmount > 0 and i < TIMEOUT_AMOUNT do
		local roomData = selector:getRandomRoom(seededRandom)

		local relativeMin = Vector3.zero
		local relativeMax = roomData:getSize()

		-- Extend minPos and maxPos so entrances do not spawn outisde of the grid
		for _, accessData in roomData:iterateAccessDatas() do
			local relativeEntrancePos = accessData:getRelativeEntrancePos()

			-- Minimize with entrance
			relativeMin = Vector3.min(relativeMin, relativeEntrancePos)

			-- Maximize with entrance
			relativeMax = Vector3.max(relativeMax, relativeEntrancePos)
		end

		local minPos = Vector3.new(1, 1, 1) - relativeMin
		local maxPos = gridSize - relativeMax

		local deltaPos = maxPos - minPos

		if deltaPos.X < 0 or deltaPos.Y < 0 or deltaPos.Z < 0 then
			i += 1
			continue
		end

		local p1 = Vector3.new(
			minPos.X + seededRandom:randomInt(0, deltaPos.X),
			minPos.Y + seededRandom:randomInt(0, deltaPos.Y),
			minPos.Z + seededRandom:randomInt(0, deltaPos.Z)
		)
		local p2 = p1 + roomData:getSize()

		-- Check that there is no room
		if roomGrid:volumeOr(p1.X, p1.Y, p1.Z, p2.X, p2.Y, p2.Z) then
			i += 1
			continue
		end

		-- Check that there
		if accessGrid:volumeOr(p1.X, p1.Y, p1.Z, p2.X, p2.Y, p2.Z) then
			i += 1
			continue
		end

		-- Check for obstrucated entrances
		local obstrucated = false
		for _, accessData in roomData:iterateAccessDatas() do
			local entrancePos = p1 + accessData:getRelativeEntrancePos()

			if roomGrid:get(entrancePos.X, entrancePos.Y, entrancePos.Z) == 1 then
				obstrucated = true
				break
			end

			if accessGrid:get(entrancePos.X, entrancePos.Y, entrancePos.Z) == 1 then
				obstrucated = true
				break
			end
		end

		if obstrucated then
			i += 1
			continue
		end

		-- Reset the timeout
		i = 1

		-- Create and add the room
		roomGrid:volumeSet(p1.X, p1.Y, p1.Z, p2.X, p2.Y, p2.Z)
		local room = Room.new(p1, roomData)
		roomStorage:addRoom(room)

		for accessNum, access in roomData:iterateAccessDatas() do
			local accessPos = room:getPos() + access:getRelativePosition()
			accessConnectStack:push(
				Access.createAccess(room, access, accessPos.X, accessPos.Y, accessPos.Z)
			)
		end

		roomAmount -= 1

		if debugMode then
			coroutine.yield(roomGrid, roomStorage, nil, accessConnectStack)
		end
	end
end
