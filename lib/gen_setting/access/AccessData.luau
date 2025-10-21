local Access = require(script.Parent.Parent.Parent.gen_elements.access.Access)
local Directions = require(script.Parent.Parent.Parent.gen_data.Directions)
local Room = require(script.Parent.Parent.Parent.gen_elements.room.Room)

local AccessData = {}
AccessData.__index = AccessData

export type AccessData = typeof(AccessData.new())

function AccessData.new(accessType: number, relativePos: Vector3, direction: Directions.Direction)
	return setmetatable({
		_accessType = accessType,
		_relativePos = relativePos,
		_direction = direction,
	}, AccessData)
end

function AccessData.getAccessType(self: AccessData)
	return self._accessType
end

function AccessData.getRelativePosition(self: AccessData)
	return self._relativePos
end

function AccessData.getRelativeEntrancePos(self: AccessData)
	return self._relativePos + self._direction
end

function AccessData.getDirection(self: AccessData)
	return self._direction
end

function AccessData.wrap(self: AccessData, room: Room.Room)
	local accessPos = room:getPos() + self:getRelativePosition() + self._direction

	return Access.createAccess(room, self, accessPos.X, accessPos.Y, accessPos.Z)
end

return AccessData
