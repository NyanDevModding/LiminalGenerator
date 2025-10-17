local AccessWrapper = require(script.Parent.AccessWrapper)
local Directions = require(script.Parent.Parent.Parent.gen_data.Directions)
local WrappedRoom = require(script.Parent.Parent.Parent.gen_data.storage.WrappedRoom)

local Access = {}
Access.__index = Access

export type Access = typeof(Access.new())

function Access.new(accessType: number, relativePos: Vector3, direction: Directions.Direction)
	return setmetatable({
		_accessType = accessType,
		_relativePos = relativePos,
		_direction = direction,
	}, Access)
end

function Access.getAccessType(self: Access)
	return self._accessType
end

function Access.getRelativePosition(self: Access)
	return self._relativePos
end

function Access.getRelativeEntrancePos(self: Access)
	return self._relativePos + self._direction
end

function Access.getDirection(self: Access)
	return self._direction
end

function Access.wrap(self: Access, wrappedRoom: WrappedRoom.WrappedRoom)
	local accessPos = wrappedRoom:getPos() + self:getRelativePosition() + self._direction

	return AccessWrapper.createAccessWrapper(
		wrappedRoom,
		self,
		accessPos.X,
		accessPos.Y,
		accessPos.Z
	)
end

return Access
