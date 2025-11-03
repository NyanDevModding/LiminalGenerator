local SeededRandom = require(script.Parent.Parent.Parent.algorithm.SeededRandom)
local RoomData = require(script.Parent.Parent.room.RoomData)

--[=[
	Room Selector is used to choose bewteen a set of rooms based on their
	characteristicssuch as their size or accesses. The method return the
	object so you can use the selector in one line without storing it into
	a variable:
	i.e. ```dataSet:startSelection():selectMaxSize(5, 5, 5):getSelection()```
]=]
local RoomSelector = {}
RoomSelector.__index = RoomSelector

export type RoomSelector = typeof(RoomSelector.new())

function RoomSelector.new(selection: { RoomData.RoomData })
	return setmetatable({
		_selection = selection,
	}, RoomSelector)
end

function RoomSelector.getSelection(self: RoomSelector)
	return self._selection
end

function RoomSelector.iterateSelection(self: RoomSelector)
	return ipairs(self._selection)
end

function RoomSelector._refillSelection(self: RoomSelector, lastIndex: number)
	local selection = self._selection

	for i = 1, lastIndex, 1 do
		if selection[i] == nil then
			selection[i] = selection[lastIndex]
			selection[lastIndex] = nil
			lastIndex -= 1
		end
	end
end

-- Select the rooms containing minimum one Access of type accessType.
function RoomSelector.selectAccessType(self: RoomSelector, accessType: number)
	local lastIndex = #self._selection

	for i, roomData in self:iterateSelection() do
		local hasAccessType = false

		for _, accessData in roomData:iterateAccessDatas() do
			if accessData:getAccessType() == accessType then
				hasAccessType = true
				break
			end
		end

		if not hasAccessType then
			self._selection[i] = nil
		end
	end

	self:_refillSelection(lastIndex)

	return self
end

-- Select the rooms under a given size.
function RoomSelector.selectMaxSize(
	self: RoomSelector,
	sizeX: number?,
	sizeY: number?,
	sizeZ: number?
)
	sizeX = sizeX or math.huge
	sizeY = sizeY or math.huge
	sizeZ = sizeZ or math.huge

	local lastIndex = #self._selection

	for i, roomData in self:iterateSelection() do
		local size = roomData:getSize()

		if size.X > sizeX or size.Y > sizeY or size.Z > sizeZ then
			self._selection[i] = nil
		end
	end

	self:_refillSelection(lastIndex)

	return self
end

-- Select the rooms if the function given returns true.
function RoomSelector.select(self: RoomSelector, f: (roomData: RoomData.RoomData) -> boolean)
	local lastIndex = #self._selection

	for i, roomData in self:iterateSelection() do
		if not f(roomData) then
			self._selection[i] = nil
		end
	end

	self:_refillSelection(lastIndex)

	return self
end

function RoomSelector.getRandomRoom(self: RoomSelector, seededRandom: SeededRandom.SeededRandom)
	-- First calculate the addition of all the chances to spawn
	local totalLuck = 0
	for _, roomData in self:iterateSelection() do
		totalLuck += roomData:getChanceToSpawn()
	end

	-- Calculate a number between 0 and the total chance to spawn of all the rooms
	local result = math.round((seededRandom:random() / 1023) * totalLuck)

	-- calculate on which room it fell
	local actualLuck = 0
	for _, roomData in self:iterateSelection() do
		actualLuck += roomData:getChanceToSpawn()

		if actualLuck >= result then
			return roomData
		end
	end

	error(
		(
			"Error while choosing between several rooms: expected "
			.. "a room to be found, got none. For a total luck of: "
			.. "%i got the result: %i"
		):format(totalLuck, result)
	)
end

return RoomSelector
