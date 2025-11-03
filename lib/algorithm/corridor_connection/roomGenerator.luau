local AccessConnectStack = require(script.Parent.Parent.Parent.gen_data.AccessConnectStack)
local FlagGrid = require(script.Parent.Parent.Parent.gen_data.FlagGrid)
local RoomStorage = require(script.Parent.Parent.Parent.gen_data.storage.RoomStorage)
local Access = require(script.Parent.Parent.Parent.gen_elements.access.Access)
local Room = require(script.Parent.Parent.Parent.gen_elements.room.Room)
local Settings = require(script.Parent.Parent.Parent.gen_setting.Settings)
local RoomDataSet = require(script.Parent.Parent.Parent.gen_setting.room_data_set.RoomDataSet)
local SeededRandom = require(script.Parent.Parent.SeededRandom)

local TIMEOUT_AMOUNT = 10000

return function(
	genSettings: Settings.gen_settings,
	roomDataSet: RoomDataSet.RoomDataSet,
	seededRandom: SeededRandom.SeededRandom,
	roomGrid: FlagGrid.FlagGrid,
	roomStorage: RoomStorage.RoomStorage,
	accessConnectStack: AccessConnectStack.AccessConnectStack,
	roomAmount: number?,
	debugMode: boolean?
)
	--TODO This is one of the worst shit algorithm, approximately a lot of byte of trash data and useless call, you really need to optimize this
	--TODO make it place the consecutive room next to each other so the accessStack don't need to be sorted
	roomAmount = roomAmount
		or math.floor(roomGrid:getXSize() * roomGrid:getYSize() * roomGrid:getZSize() / (5 * 3 * 5))

	local i = 1

	local gridSize = Vector3.new(roomGrid:getXSize(), roomGrid:getYSize(), roomGrid:getZSize())

	local selector = roomDataSet:startRoomSelection()

	while roomAmount > 0 and i < TIMEOUT_AMOUNT do
		local roomData = selector:getRandomRoom(seededRandom)
		local minPos = Vector3.new(1, 1, 1)
		local maxPos = gridSize - roomData:getSize()

		local deltaPos = maxPos - minPos

		local p1 = Vector3.new(
			minPos.X + (seededRandom:random() / 1023) * deltaPos.X,
			minPos.Y + (seededRandom:random() / 1023) * deltaPos.Y,
			minPos.Z + (seededRandom:random() / 1023) * deltaPos.Z
		):Floor()
		local p2 = p1 + roomData:getSize()

		local canPlace = not roomGrid:volumeOr(p1.X, p1.Y, p1.Z, p2.X, p2.Y, p2.Z)

		if not canPlace then
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
			local accessPos = room:getPos() + roomData:getAccessRelativeEntrancePos(accessNum)
			accessConnectStack:push(
				Access.createAccess(room, access, accessPos.X, accessPos.Y, accessPos.Z)
			)
		end

		if debugMode then
			coroutine.yield(roomGrid, nil, accessConnectStack)
		end

		roomAmount -= 1
	end
end
