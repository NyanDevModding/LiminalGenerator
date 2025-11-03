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

return RoomStorage
