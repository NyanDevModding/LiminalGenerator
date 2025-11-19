local FlagGrid = require(script.Parent.FlagGrid)
local SeededRandom = require(script.Parent.Parent.algorithm.SeededRandom)
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

-- Place the access at a random pos approximately at the top of the stack
function AccessConnectStack.repush(
	self: AccessConnectStack,
	access: Access.Access,
	seededRandom: SeededRandom.SeededRandom
)
	if self:isEmpty() then
		self:push(access)
		return
	end

	local pos = math.round((seededRandom:random() / 1023) * 3)

	if pos < 0 then
		pos = 0
	end

	if pos > self._size - 1 then
		pos = self._size - 1
	end

	local replaced = self._stack[self._size - pos]
	self._stack[self._size - pos] = access
	self._size += 1
	self._stack[self._size] = replaced

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

local function isConnectedToRoom(roomToCheck: Room.Room, actualRoom: Room.Room, searchDepth: number)
	for _, adjacent in actualRoom:iterateAdjacents() do
		if adjacent == actualRoom then
			continue
		end

		if adjacent == roomToCheck then
			return true
		end

		if searchDepth > 0 then
			if isConnectedToRoom(roomToCheck, adjacent, searchDepth - 1) then
				return true
			end
		end
	end

	return false
end

function AccessConnectStack.popRoomDifferent(
	self: AccessConnectStack,
	room: Room.Room,
	searchDepth: number
): Access.Access?
	local i = self._size

	while i > 0 do
		local access = self._stack[i]

		if room == access.room then
			i -= 1
			continue
		end

		local isConnected = isConnectedToRoom(room, access.room, searchDepth)
		print("is connected: " .. tostring(isConnected))

		if isConnected then
			i -= 1
			continue
		end

		self._stack[i] = self._stack[self._size]
		self._stack[self._size] = nil
		self._size -= 1
		return access
	end

	return nil
end

function AccessConnectStack.getGrid(self: AccessConnectStack)
	return self._flagGrid
end

function AccessConnectStack.iterate(self: AccessConnectStack)
	return ipairs(self._stack)
end

return AccessConnectStack
