local IRoomStorable = require(script.Parent.Parent.Parent.gen_data.storage.IRoomStorable)
local IAccessData = require(script.Parent.Parent.Parent.gen_setting.access.IAccessData)
local RoomData = require(script.Parent.Parent.Parent.gen_setting.room.RoomData)

-- implements IRoomStorable
local Room = {}
Room.__index = Room

export type Room = typeof(Room.new())

function Room.new(pos: Vector3, roomData: RoomData.RoomData)
	return setmetatable({
		_pos = pos,
		_roomData = roomData,
		_accessNumber = roomData:getAccessNumber(),
		_adjacents = table.create(roomData:getAccessNumber(), nil),
	}, Room)
end

function Room.getRoomData(self: Room)
	return self._roomData
end

function Room.getPos(self: Room)
	return self._pos
end

function Room.getSize(self: Room)
	return self._roomData:getSize()
end

function Room.getMaxPos(self: Room)
	return self._roomData:getSize()
end

function Room.getAccessData(self: Room, accessNum: number)
	return self._roomData:getAccessData(accessNum)
end

function Room.isIncludingCell(self: Room, cellPos: Vector3)
	local minPos = self:getPos()
	local maxPos = self:getMaxPos()

	return (minPos.X <= cellPos.X and cellPos.X <= maxPos.X)
		and (minPos.Y <= cellPos.Y and cellPos.Y <= maxPos.Y)
		and (minPos.Z <= cellPos.Z and cellPos.Z <= maxPos.Z)
end

function Room.setAdjacent(
	self: Room,
	adjacent: IRoomStorable.IRoomStorable,
	accessData: IAccessData.IAccessData
)
	for accessNum, thisAccessData in self._roomData:iterateAccessDatas() do
		if thisAccessData == accessData then
			self._adjacents[accessNum] = adjacent
			return
		end
	end
end

function Room.setAdjacentByNum(self: Room, adjacent: IRoomStorable.IRoomStorable, accessNum: number)
	self._adjacents[accessNum] = adjacent
end

function Room.changeAdjacent(
	self: Room,
	adjacent: IRoomStorable.IRoomStorable,
	newAdjacent: IRoomStorable.IRoomStorable
)
	for i, actualAdjacent in self:iterateAdjacents() do
		if actualAdjacent == adjacent then
			self._adjacents[i] = newAdjacent
			return
		end
	end
end

function Room.check(self: Room, errorLog: string)
	for i = 1, self._accessNumber, 1 do
		if self._adjacents[i] == nil then
			error(
				(
					"Error in a Room, expected all of its accesses "
					.. "to be used, got the access n°%i to nil. In %s."
				):format(i, errorLog)
			)
		end
	end
end

function Room.iterateAccessDatas(self: Room)
	return self._roomData:iterateAccessDatas()
end

local function adjacentsIterator(self: Room, i)
	while true do
		i += 1

		if i > self._roomData:getAccessNumber() then
			return nil
		end

		if self._adjacents[i] ~= nil then
			return i, self._adjacents[i]
		end
	end
end

function Room.iterateAdjacents(self: Room)
	return adjacentsIterator, self, 0
end

return Room
