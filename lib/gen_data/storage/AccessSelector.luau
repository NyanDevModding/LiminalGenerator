local Access = require(script.Parent.Parent.Parent.gen_elements.access.Access)
local Room = require(script.Parent.Parent.Parent.gen_elements.room.Room)

--[=[
	Access Selector is used to choose bewteen some accesses based on their
	characteristics such as their proximity with another access. Each method
	return the object so you can use the selector in one line without storing
	it into a variable.
]=]
local AccessSelector = {}
AccessSelector.__index = AccessSelector

export type AccessSelector = typeof(AccessSelector.new())

function AccessSelector.new(selection: { Access.Access })
	return setmetatable({
		_selection = selection,
	}, AccessSelector)
end

function AccessSelector.getSelection(self: AccessSelector)
	return self._selection
end

function AccessSelector.iterateSelection(self: AccessSelector)
	return ipairs(self._selection)
end

function AccessSelector._refillSelection(self: AccessSelector, lastIndex: number)
	local selection = self._selection
	local selectionSize = 1

	for i = lastIndex, 1, -1 do
		if selectionSize >= i then
			break
		end

		if selection[i] == nil then
			continue
		end

		selection[selectionSize] = selection[i]
		selection[i] = nil
		selectionSize += 1

		if selection[selectionSize] ~= nil then
			while selection[selectionSize] ~= nil do
				selectionSize += 1
			end
		end
	end
end

-- Select the access if the given function returns true.
function AccessSelector.select(self: AccessSelector, f: (access: Access.Access) -> boolean)
	local lastIndex = #self._selection

	for i, access in self:iterateSelection() do
		if not f(access) then
			self._selection[i] = nil
		end
	end

	self:_refillSelection(lastIndex)

	return self
end

-- Select the access if its y coordinate is the same as pos and if its x and
-- z coordinates are at a distance from pos above the length
function AccessSelector.selectMinProximity(self: AccessSelector, pos: Vector3, length: number)
	local lastIndex = #self._selection

	for i, access in self:iterateSelection() do
		if
			math.abs(access.x + access.direction.Z - pos.x) <= length
			or pos.y ~= access.y + access.direction.y
			or math.abs(access.z + access.direction.Z - pos.z) <= length
		then
			self._selection[i] = nil
		end
	end

	self:_refillSelection(lastIndex)

	return self
end

-- Select the access if its y coordinate is the same as pos and if its x and
-- z coordinates are at a distance from pos under the length
function AccessSelector.selectMaxProximity(self: AccessSelector, pos: Vector3, length: number)
	local lastIndex = #self._selection

	for i, access in self:iterateSelection() do
		if
			math.abs(access.x + access.direction.X - pos.x) > length
			or access.y + access.direction.Y ~= pos.Y
			or math.abs(access.z + access.direction.Z - pos.z) > length
		then
			self._selection[i] = nil
		end
	end

	self:_refillSelection(lastIndex)

	return self
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

-- Select by checking if an access is somehow connected via rooms with another
-- with a given maxDepth
function AccessSelector.selectByConnection(
	self: AccessSelector,
	room: Room.Room,
	searchDepth: number
)
	local lastIndex = #self._selection

	for i, access in self:iterateSelection() do
		if access.room == room then
			self._selection[i] = nil
		end

		if isConnectedToRoom(room, access.room, searchDepth) then
			self._selection[i] = nil
		end
	end

	self:_refillSelection(lastIndex)

	return self
end

function AccessSelector.getFirstAccess(self: AccessSelector): Access.Access?
	return self._selection[1]
end

-- Return an access that is not the provided access
function AccessSelector.getAccessNot(self: AccessSelector, access: Access.Access): Access.Access?
	if self._selection[1] == access then
		return self._selection[2]
	end

	return self._selection[1]
end

return AccessSelector
