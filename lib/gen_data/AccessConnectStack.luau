local FlagGrid = require(script.Parent.FlagGrid)
local Access = require(script.Parent.Parent.gen_elements.access.Access)
local Room = require(script.Parent.Parent.gen_elements.room.Room)

local AccessConnectStack = {}
AccessConnectStack.__index = AccessConnectStack

export type AccessConnectStack = typeof(AccessConnectStack.new())

--TODO make the accessStack ordered by distance between accesses
function AccessConnectStack.new(xSize, ySize, zSize)
	return setmetatable({
		_stack = {} :: { Access.Access },
		_size = 0,
		_flagGrid = FlagGrid.new(xSize, ySize, zSize) :: FlagGrid.FlagGrid,
	}, AccessConnectStack)
end

function AccessConnectStack.isEmpty(self: AccessConnectStack)
	return self._size == 0
end

function AccessConnectStack.getSize(self: AccessConnectStack)
	return self._size
end

function AccessConnectStack.push(self: AccessConnectStack, access: Access.Access)
	self._size += 1
	self._stack[self._size] = access
	local direction = access.direction
	self._flagGrid:set(access.x + direction.X, access.y + direction.Y, access.z + direction.Z)
end

function AccessConnectStack.pop(self: AccessConnectStack): Access.Access?
	if self._size == 0 then
		return nil
	end

	local popped = self._stack[self._size]
	self._stack[self._size] = nil
	self._size -= 1
	return popped
end

function AccessConnectStack.popRoomDifferent(
	self: AccessConnectStack,
	room: Room.Room
): Access.Access?
	local result = nil
	local i = self._size

	while i > 0 do
		local access = self._stack[i]

		if access.room == room then
			i -= 1
			continue
		end

		result = access
		self._stack[i] = self._stack[self._size]
		self._stack[self._size] = nil
		self._size -= 1
		break
	end

	return result
end

function AccessConnectStack.getGrid(self: AccessConnectStack)
	return self._flagGrid
end

function AccessConnectStack.iterate(self: AccessConnectStack)
	return ipairs(self._stack)
end

return AccessConnectStack
