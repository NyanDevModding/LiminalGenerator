local AccessSelector = require(script.Parent.AccessSelector)
local FlagGrid = require(script.Parent.Parent.FlagGrid)
local SeededRandom = require(script.Parent.Parent.Parent.algorithm.SeededRandom)
local Access = require(script.Parent.Parent.Parent.gen_elements.access.Access)
local Room = require(script.Parent.Parent.Parent.gen_elements.room.Room)

local AccessConnectStorage = {}
AccessConnectStorage.__index = AccessConnectStorage

export type AccessConnectStorage = typeof(AccessConnectStorage.new())

function AccessConnectStorage.new(xSize, ySize, zSize)
	return setmetatable({
		_toConnectStorage = {} :: { Access.Access },
		_connectedStorage = {} :: { Access.Access },
		_cantConnectStorage = {} :: { Access.Access },

		_toConnectSize = 0,
		_connectedSize = 0,
		_cantConnectSize = 0,

		_flagGrid = FlagGrid.new(xSize, ySize, zSize) :: FlagGrid.FlagGrid,
		_duplicatedAccessList = {} :: { Access.Access },
	}, AccessConnectStorage)
end

function AccessConnectStorage.isToConnectEmpty(self: AccessConnectStorage)
	return self._toConnectStorage[1] == nil
end

function AccessConnectStorage.getToConnectSize(self: AccessConnectStorage)
	return self._toConnectSize
end

function AccessConnectStorage._addToGrid(self: AccessConnectStorage, access: Access.Access)
	local direction = access.direction

	if
		self._flagGrid:get(access.x + direction.X, access.y + direction.Y, access.z + direction.Z)
		== 1
	then
		-- We need to know how much accesses are stacked at the same position
		-- because, else, when one is removed, it would remove every other
		-- from the grid
		table.insert(self._duplicatedAccessList, access)
		return
	end

	self._flagGrid:set(access.x + direction.X, access.y + direction.Y, access.z + direction.Z)
end
function AccessConnectStorage._removeFromGrid(self: AccessConnectStorage, access: Access.Access)
	local direction = access.direction
	local entrancePos =
		Vector3.new(access.x + direction.X, access.y + direction.Y, access.z + direction.Z)

	for i, duplicated in ipairs(self._duplicatedAccessList) do
		if
			entrancePos.X == duplicated.x + duplicated.direction.X
			and entrancePos.Z == duplicated.z + duplicated.direction.Z
			and entrancePos.Y == duplicated.y + duplicated.direction.Y
		then
			-- Remove duplicated from duplicatedAccessList and do not reset it in flagGrid
			if self._duplicatedAccessList[2] == nil then
				self._duplicatedAccessList[1] = nil
			else
				self._duplicatedAccessList[i] =
					self._duplicatedAccessList[#self._duplicatedAccessList]
			end

			return
		end
	end

	self._flagGrid:reset(access.x + direction.X, access.y + direction.Y, access.z + direction.Z)
end

function AccessConnectStorage.addAlreadyConnectedAccess(
	self: AccessConnectStorage,
	access: Access.Access
)
	table.insert(self._connectedStorage, access)
	self._connectedSize += 1

	self:_addToGrid(access)
end

function AccessConnectStorage.addAccessToConnect(self: AccessConnectStorage, access: Access.Access)
	table.insert(self._toConnectStorage, access)
	self._toConnectSize += 1

	self:_addToGrid(access)
end

function AccessConnectStorage.makeConnected(self: AccessConnectStorage, access: Access.Access)
	for i, actualAccess in ipairs(self._toConnectStorage) do
		if actualAccess == access then
			if self._toConnectSize == 1 then
				self._toConnectStorage[1] = nil
				self._toConnectSize = 0
				break
			end

			self._toConnectStorage[i] = self._toConnectStorage[self._toConnectSize]
			self._toConnectStorage[self._toConnectSize] = nil
			self._toConnectSize -= 1
			break
		end
	end

	table.insert(self._connectedStorage, access)
	self._connectedSize += 1
end

function AccessConnectStorage.makeCantConnect(self: AccessConnectStorage, access: Access.Access)
	for i, actualAccess in ipairs(self._toConnectStorage) do
		if actualAccess == access then
			if self._toConnectSize == 1 then
				self._toConnectStorage[1] = nil
				self._toConnectSize = 0
				break
			end

			self._toConnectStorage[i] = self._toConnectStorage[self._toConnectSize]
			self._toConnectStorage[self._toConnectSize] = nil
			self._toConnectSize -= 1
			break
		end
	end

	table.insert(self._cantConnectStorage, access)
	self._cantConnectSize += 1
end

function AccessConnectStorage.getRandomAccessToConnect(
	self: AccessConnectStorage,
	seededRandom: SeededRandom.SeededRandom
): Access.Access?
	if self._toConnectSize == 0 then
		return nil
	end

	return self._toConnectStorage[seededRandom:randomInt(1, self._toConnectSize)]
end

function AccessConnectStorage.getDifferentAccessToConnect(
	self: AccessConnectStorage,
	seededRandom: SeededRandom.SeededRandom,
	room: Room.Room
): Access.Access?
	if
		self._toConnectSize == 0
		or (self._toConnectSize == 1 and self._toConnectStorage[1].room == room)
	then
		return nil
	end

	local num = seededRandom:randomInt(1, self._toConnectSize)

	if self._toConnectStorage[num].room ~= room then
		return self._toConnectStorage[num]
	end

	local limit = num

	repeat
		num -= 1
		if num == 0 then
			num = self._toConnectSize
		end

		if self._toConnectStorage[num].room ~= room then
			return self._toConnectStorage[num]
		end
	until num == limit

	return nil
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

function AccessConnectStorage.getAccessNotConnectedTo(
	self: AccessConnectStorage,
	room: Room.Room,
	searchDepth: number
): Access.Access?
	local i = self._toConnectSize

	while i > 0 do
		local access = self._toConnectStorage[i]

		if room == access.room then
			i -= 1
			continue
		end

		local isConnected = isConnectedToRoom(room, access.room, searchDepth)

		if isConnected then
			i -= 1
			continue
		end

		return access
	end

	return nil
end

function AccessConnectStorage.startSelection(self: AccessConnectStorage)
	return AccessSelector.new(table.clone(self._toConnectStorage))
end

function AccessConnectStorage.getGrid(self: AccessConnectStorage)
	return self._flagGrid
end

function AccessConnectStorage.iterateToConnect(self: AccessConnectStorage)
	return ipairs(self._toConnectStorage)
end

function AccessConnectStorage.iterateConnected(self: AccessConnectStorage)
	return ipairs(self._connectedStorage)
end

function AccessConnectStorage.removeAccess(self: AccessConnectStorage, access: Access.Access)
	for i, actualAccess in ipairs(self._connectedSize) do
		if actualAccess == access then
			self._connectedStorage[i] = self._connectedStorage[self._connectedSize]
			self._connectedStorage[self._connectedSize] = nil
			self._connectedSize -= 1
		end
	end

	for i, actualAccess in ipairs(self._toConnectSize) do
		if actualAccess == access then
			self._toConnectStorage[i] = self._toConnectStorage[self._toConnectSize]
			self._toConnectStorage[self._toConnectSize] = nil
			self._toConnectSize -= 1
		end
	end

	for i, actualAccess in ipairs(self._cantConnectStorage) do
		if actualAccess == access then
			self._cantConnectStorage[i] = self._cantConnectStorage[self._cantConnectSize]
			self._cantConnectStorage[self._cantConnectSize] = nil
			self._cantConnectSize -= 1
		end
	end

	self:_removeFromGrid(access)
end

return AccessConnectStorage
