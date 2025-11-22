local FlagGrid = require(script.Parent.Parent.FlagGrid)
local Room = require(script.Parent.Parent.Parent.gen_elements.room.Room)

local RoomStorage = {}
RoomStorage.__index = RoomStorage

export type RoomStorage = typeof(RoomStorage.new())

function RoomStorage.new()
	return setmetatable({
		_storage = {} :: { Room.Room },
	}, RoomStorage)
end

function RoomStorage.addRoom(self: RoomStorage, room: Room.Room)
	table.insert(self._storage, room)
end

function RoomStorage.getRoomAt(self: RoomStorage, pos: Vector3): Room.Room?
	for _, room in ipairs(self._storage) do
		if room:isIncludingCell(pos) then
			return room
		end
	end

	return nil
end

function RoomStorage.iterateRoom(self: RoomStorage)
	return ipairs(self._storage)
end

function RoomStorage.debugCheckSyncWithGrid(self: RoomStorage, grid: FlagGrid.FlagGrid)
	local ok = true

	for i, room in self:iterateRoom() do
		local p1 = room:getPos()
		local p2 = room:getPos() + room:getSize()

		if not grid:volumeAnd(p1.X, p1.Y, p1.Z, p2.X, p2.Y, p2.Z) then
			ok = false
			warn(
				("Unsync between the roomStorage and its grid: For the room #%i, at the pos: {%s}-{%s}"):format(
					i,
					tostring(p1),
					tostring(p2)
				)
			)
		end
	end

	if ok then
		print("	✅ Room Storage and Room Grid in sync")
	else
		print("Here is the grid: \n" .. tostring(grid))
	end
end

return RoomStorage
