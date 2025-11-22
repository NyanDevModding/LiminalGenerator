local SeededRandom = require(script.Parent.Parent.Parent.algorithm.SeededRandom)
local Directions = require(script.Parent.Parent.Parent.gen_data.Directions)
local FlagGrid = require(script.Parent.Parent.Parent.gen_data.FlagGrid)
local IRoomStorable = require(script.Parent.Parent.Parent.gen_data.storage.IRoomStorable)
local AccessData = require(script.Parent.Parent.Parent.gen_setting.access.AccessData)
local IAccessData = require(script.Parent.Parent.Parent.gen_setting.access.IAccessData)
local DeadEndTileRoomData =
	require(script.Parent.Parent.Parent.gen_setting.corridor_tile.uniform.DeadEndTileRoomData)
local RoomDataSet = require(script.Parent.Parent.Parent.gen_setting.room_data_set.RoomDataSet)
local Access = require(script.Parent.Parent.access.Access)
local Room = require(script.Parent.Parent.room.Room)

-- implements IRoomStorable
local Corridor = {}
Corridor.__index = Corridor

export type Corridor = typeof(Corridor.new())

function Corridor.new(firstAccess: Access.Access, secondAccess: Access.Access)
	local p1 = Vector3.new(
		firstAccess.x + firstAccess.direction.X,
		firstAccess.y + firstAccess.direction.Y,
		firstAccess.z + firstAccess.direction.Z
	)
	local p2 = Vector3.new(
		secondAccess.x + secondAccess.direction.X,
		secondAccess.y + secondAccess.direction.Y,
		secondAccess.z + secondAccess.direction.Z
	)

	if p1.Y ~= p2.Y then
		warn(
			"WARNING: You are using different Y coordinates for "
				.. "a corridor. It is not yet coded to handle that."
		)
	end

	local firstAccessNum =
		firstAccess.room:getAccessNum(firstAccess.access:getRelativeEntrancePos())

	local secondAccessNum =
		secondAccess.room:getAccessNum(secondAccess.access:getRelativeEntrancePos())

	return setmetatable({
		_adjacents = { firstAccess.room, secondAccess.room } :: { IRoomStorable.IRoomStorable },
		_adjacentAccessNums = { firstAccessNum, secondAccessNum },
		_firstAccess = AccessData.new(
			firstAccess.access:getAccessType(),
			Vector3.zero,
			-firstAccess.direction
		),
		_secondAccess = AccessData.new(
			secondAccess.access:getAccessType(),
			p2 - p1,
			-secondAccess.direction
		),
		_vertices = { p1, p2 },
	}, Corridor)
end

function Corridor.newFromRooms(
	room1: IRoomStorable.IRoomStorable,
	accessNum1: number,
	room2: IRoomStorable.IRoomStorable,
	accessNum2: number
)
	local accessData1 = room1:getAccessData(accessNum1)
	local accessData2 = room2:getAccessData(accessNum2)

	local p1 = room1:getPos() + accessData1:getRelativeEntrancePos()
	local p2 = room2:getPos() + accessData2:getRelativeEntrancePos()

	if p1.Y ~= p2.Y then
		warn(
			"WARNING: You are using different Y coordinates for "
				.. "a corridor. It is not yet coded to handle that."
		)
	end

	return setmetatable({
		_adjacents = { room1, room2 },
		_adjacentAccessNums = { accessNum1, accessNum2 },
		_firstAccess = AccessData.new(
			accessData1:getAccessType(),
			Vector3.zero,
			-accessData1:getDirection()
		),
		_secondAccess = AccessData.new(
			accessData2:getAccessType(),
			p2 - p1,
			-accessData2:getDirection()
		),
		_vertices = { p1, p2 },
	}, Corridor) :: Corridor
end

function Corridor.getPos(self: Corridor)
	return self:getVertex(1)
end

function Corridor.getAdjacent(self: Corridor, accessNum: number)
	return self._adjacents[accessNum]
end

function Corridor.getLength(self: Corridor)
	local length = 0
	for i = 2, self:getVertexAmount(), 1 do
		length += (self:getVertex(i) - self:getVertex(i - 1)).Magnitude
	end

	-- the last vertex
	length += 1

	return length
end

function Corridor.getAccessData(self: Corridor, accessNumero: number)
	if accessNumero == 1 then
		return self._firstAccess
	end

	return self._secondAccess
end

function Corridor.isSingleCell(self: Corridor)
	return self._vertices[1] == self._vertices[2] and self._vertices[3] == nil
end

-- Used when the Corridor is about to change to create the access to bind
-- something else to the room this access is currently bound to.
function Corridor.createAdjacentAccess(self: Corridor, adjacentNum: number)
	local adjacent = self._adjacents[adjacentNum]
	local accessData = adjacent:getAccessData(self._adjacentAccessNums[adjacentNum])
	local accessPos = adjacent:getPos() + accessData:getRelativePosition()

	return Access.createAccess(adjacent, accessData, accessPos.X, accessPos.Y, accessPos.Z)
end

local function _getAdjacentAccessNum(
	self: Corridor,
	vertex: Vector3,
	adjacent: IRoomStorable.IRoomStorable
)
	local accessNum = adjacent:getAccessNum(vertex - adjacent:getPos())

	if accessNum == nil then
		error(
			"Error while getting an adjacent accessNum in the corridor: "
				.. "Expected it to have an access at the position of the first cell of this "
				.. "of this corridor, got a nil accessNum."
		)
	end

	-- Check that the accessData respects the accesses of this corridor

	local thisAccessData = if vertex == self:getVertex(1)
		then self._firstAccess
		else self._secondAccess
	local accessData = adjacent:getAccessData(accessNum)
	if
		adjacent:getPos() + accessData:getRelativePosition()
		~= self:getPos() + thisAccessData:getRelativeEntrancePos()
	then
		error(
			(
				"Error while getting an adjacent accessNum in the corridor: "
				.. "Expected it to connect its access with the corridor's, Got :"
				.. "otherAccessPos = {%s} and thisEntrancePos = {%s}"
			):format(
				tostring(adjacent:getPos() + accessData:getRelativePosition()),
				tostring(self:getPos() + thisAccessData:getRelativeEntrancePos())
			)
		)
	end

	return accessNum
end

function Corridor.setAdjacent(
	self: Corridor,
	adjacent: IRoomStorable.IRoomStorable,
	accessData: IAccessData.IAccessData
)
	if self._firstAccess == accessData then
		self:setAdjacentByNum(adjacent, 1)
		return
	elseif self._secondAccess == accessData then
		self:setAdjacentByNum(adjacent, 2)
		return
	end

	error(
		(
			"Error while setting an adjacent in a Corridor: Expected the accessData "
			.. "to be one of those in the Corridor, got accessData: %s and in "
			.. "corridor's accessDatas: {%s, %s}"
		):format(tostring(accessData), tostring(self._firstAccess), tostring(self._secondAccess))
	)
end

function Corridor.setAdjacentByNum(
	self: Corridor,
	adjacent: IRoomStorable.IRoomStorable,
	accessNum: number
)
	if accessNum == 1 then
		self._adjacents[1] = adjacent

		-- Update the accessNum of the adjacent inside of this corridor
		local otherAccessNum = _getAdjacentAccessNum(self, self:getVertex(1), adjacent)
		self._adjacentAccessNums[1] = otherAccessNum

		return
	elseif accessNum == 2 then
		self._adjacents[2] = adjacent

		-- Update the accessNum of the adjacent inside of this corridor
		local otherAccessNum =
			_getAdjacentAccessNum(self, self:getVertex(self:getVertexAmount()), adjacent)
		self._adjacentAccessNums[2] = otherAccessNum

		return
	end

	error(
		(
			"Error while setting an adjacent in a Corridor: Expected the accessNum "
			.. "to be either 1 or 2, got accessNum: %s"
		):format(tostring(accessNum))
	)
end

function Corridor.changeAdjacent(
	self: Corridor,
	adjacent: IRoomStorable.IRoomStorable,
	newAdjacent: IRoomStorable.IRoomStorable
)
	if self._adjacents[1] == adjacent then
		local accessNum = _getAdjacentAccessNum(self, self:getVertex(1), newAdjacent)

		self._adjacentAccessNums[1] = accessNum
		self._adjacents[1] = newAdjacent
	elseif self._adjacents[2] == adjacent then
		local accessNum =
			_getAdjacentAccessNum(self, self:getVertex(self:getVertexAmount()), newAdjacent)

		self._adjacentAccessNums[2] = accessNum
		self._adjacents[2] = newAdjacent
	end
end

-- Set the adjacents' adjacent to this corridor
function Corridor.connectToAdjacents(self: Corridor)
	self._adjacents[1]:setAdjacentByNum(self, self._adjacentAccessNums[1])
	self._adjacents[2]:setAdjacentByNum(self, self._adjacentAccessNums[2])
end

function Corridor.iterateAdjacents(self: Corridor)
	return ipairs(self._adjacents)
end

function Corridor.isIncludingCell(self: Corridor, cellPos: Vector3)
	-- Check from the first vertex to the penultimate vertex
	local previousVertex = self:getVertex(1)
	for vertexNum, vertex: Vector3 in self:iterateMiddleVertices() do
		local min, max =
			Vector3.new(
				math.min(previousVertex.X, vertex.X),
				math.min(previousVertex.Y, vertex.Y),
				math.min(previousVertex.Z, vertex.Z)
			),
			Vector3.new(
				math.max(previousVertex.X, vertex.X),
				math.max(previousVertex.Y, vertex.Y),
				math.max(previousVertex.Z, vertex.Z)
			)

		if
			(min.X <= cellPos.X and cellPos.X <= max.X)
			and (min.Y <= cellPos.Y and cellPos.Y <= max.Y)
			and (min.Z <= cellPos.Z and cellPos.Z <= max.Z)
		then
			return true
		end

		previousVertex = vertex
	end

	-- Check for the last vertex
	local vertex = self:getVertex(self:getVertexAmount())
	local min, max =
		Vector3.new(
			math.min(previousVertex.X, vertex.X),
			math.min(previousVertex.Y, vertex.Y),
			math.min(previousVertex.Z, vertex.Z)
		),
		Vector3.new(
			math.max(previousVertex.X, vertex.X),
			math.max(previousVertex.Y, vertex.Y),
			math.max(previousVertex.Z, vertex.Z)
		)

	if
		(min.X <= cellPos.X and cellPos.X <= max.X)
		and (min.Y <= cellPos.Y and cellPos.Y <= max.Y)
		and (min.Z <= cellPos.Z and cellPos.Z <= max.Z)
	then
		return true
	end

	return false
end

function Corridor.getVertex(self: Corridor, vertexNum: number)
	return self._vertices[vertexNum]
end

function Corridor.getVertexStartingDirection(self: Corridor, vertexNum: number)
	local directionVect = self:getVertex(vertexNum - 1) - self:getVertex(vertexNum)

	if directionVect.X > 0 then
		return Directions.EAST
	elseif directionVect.X < 0 then
		return Directions.WEST
	elseif directionVect.Y > 0 then
		return Directions.UP
	elseif directionVect.Y < 0 then
		return Directions.DOWN
	elseif directionVect.Z > 0 then
		return Directions.NORTH
	elseif directionVect.Z < 0 then
		return Directions.SOUTH
	end

	error(
		"Error while getting the starting direction of a vertex in a corridor, "
			.. "got the vertex and the previous one at the same oposition."
	)
end

function Corridor.getVertexEndingDirection(self: Corridor, vertexNum: number)
	local directionVect = self:getVertex(vertexNum + 1) - self:getVertex(vertexNum)

	if directionVect.X > 0 then
		return Directions.EAST
	elseif directionVect.X < 0 then
		return Directions.WEST
	elseif directionVect.Y > 0 then
		return Directions.UP
	elseif directionVect.Y < 0 then
		return Directions.DOWN
	elseif directionVect.Z > 0 then
		return Directions.NORTH
	elseif directionVect.Z < 0 then
		return Directions.SOUTH
	end

	error(
		"Error while getting the ending direction of a vertex in a corridor, "
			.. "got the vertex and the next one at the same oposition."
	)
end

function Corridor.getVertexAmount(self: Corridor)
	return #self._vertices
end

function Corridor.setVertex(self: Corridor, vertexNum: number, newVertex: Vector3)
	self._vertices[vertexNum] = newVertex
end

function Corridor.invert(self: Corridor, vertexNum: number)
	local vertex = self._vertices[vertexNum]
	local previous = self._vertices[vertexNum - 1]
	local nextV = self._vertices[vertexNum + 1]

	if previous.X == vertex.X then
		vertex = Vector3.new(nextV.X, vertex.Y, vertex.Z)
	else
		vertex = Vector3.new(previous.X, vertex.Y, vertex.Z)
	end

	if previous.Z == vertex.Z then
		vertex = Vector3.new(vertex.X, vertex.Y, nextV.Z)
	else
		vertex = Vector3.new(vertex.X, vertex.Y, previous.Z)
	end

	self:setVertex(vertexNum, vertex)
end

-- Move all the vertices from vertexNum to the last one and add a vertex at
-- vertexNum with the value of the old vertex at this vertexNum
function Corridor.addVertex(self: Corridor, vertexNum: number)
	for i = #self._vertices, vertexNum, -1 do
		self._vertices[i + 1] = self._vertices[i]
	end
	local vertex = self._vertices[vertexNum]
	self._vertices[vertexNum] = Vector3.new(vertex.X, vertex.Y, vertex.Z)
end

function Corridor.removeVertex(self: Corridor, vertexNum: number)
	for i = vertexNum, self:getVertexAmount() - 1, 1 do
		self._vertices[i] = self._vertices[i + 1]
	end
	self._vertices[self:getVertexAmount()] = nil
end

function Corridor.iterateVertices(self: Corridor)
	return ipairs(self._vertices)
end

local function middleVerticesIterator(vertices, vertexNum)
	vertexNum += 1

	-- ignore the last one
	if vertices[vertexNum + 1] == nil then
		return nil
	end

	return vertexNum, vertices[vertexNum]
end

function Corridor.iterateMiddleVertices(self: Corridor): ({ Vector3 }, number) -> (number?, Vector3)
	return middleVerticesIterator, self._vertices, 1
end

-- Get the first vertex to have a collision (in the segment between the result
-- vertex and the previous before the latter)
function Corridor.getFirstCollision(self: Corridor, flagGrid: FlagGrid.FlagGrid)
	local p1 = self._vertices[1]

	for i = 2, #self._vertices, 1 do
		local p2 = self._vertices[i]
		local collision = flagGrid:getFirstSetInLine(p1, p2 - p1)
		if collision ~= nil then
			return collision
		end
		p1 = p2
	end

	return nil
end

local function _intersectWithVerticalLine(self: Corridor, firstPos: Vector3, length: number)
	local previousVertex = self:getVertex(1)
	for _, vertex in self:iterateMiddleVertices() do
		-- Check if it intersects with the line
		if
			(
				(firstPos.X ~= vertex.X and firstPos ~= previousVertex.X) -- prevents from fused vertical lines
				and (
					firstPos.Z <= vertex.Z
					and vertex.Z <= firstPos.Z + length
					and previousVertex.X <= firstPos.X
					and firstPos.X <= vertex.X
				)
			)
			or (
				(firstPos.X == vertex.X and firstPos.X == previousVertex.X) -- they can be fused
				and ( -- thus they need to be included in the vertical line
					(firstPos.Z <= vertex.Z and vertex.Z <= firstPos.Z + length) -- vertex in the line
					or (firstPos.Z <= previousVertex.Z and previousVertex.Z <= firstPos.Z + length) -- previousVertex in the line
					or (
						Vector3.min(previousVertex, vertex).Z <= firstPos.Z
						and firstPos.Z + length <= Vector3.max(previousVertex, vertex).Z
					) -- line between vertex and previousVertex
				)
			)
		then
			return Vector3.new(firstPos.X, vertex.Y, vertex.Z)
		end
		previousVertex = vertex
	end

	local vertex = self:getVertex(self:getVertexAmount())
	if
		firstPos.Z <= vertex.Z
		and vertex.Z <= firstPos.Z + length
		and previousVertex.X <= firstPos.X
		and firstPos.X <= vertex.X
	then
		return Vector3.new(firstPos.X, vertex.Y, vertex.Z)
	end
	previousVertex = vertex

	return nil
end

local function _intersectWithHorizontalLine(self: Corridor, firstPos: Vector3, length: number)
	local previousVertex = self:getVertex(1)
	for _, vertex in self:iterateMiddleVertices() do
		-- Check if it intersects with the line
		if

			(
				(firstPos.Z ~= vertex.Z and firstPos ~= previousVertex.Z) -- prevents from fused vertical lines
				and (
					firstPos.X <= vertex.X
					and vertex.X <= firstPos.X + length
					and previousVertex.Z <= firstPos.Z
					and firstPos.Z <= vertex.Z
				)
			)
			or (
				(firstPos.Z == vertex.Z and firstPos.Z == previousVertex.Z) -- they can be fused
				and ( -- thus they need to be included in the vertical line
					(firstPos.X <= vertex.X and vertex.X <= firstPos.X + length) -- vertex in the line
					or (firstPos.X <= previousVertex.X and previousVertex.X <= firstPos.Z + length) -- previousVertex in the line
					or (
						Vector3.min(previousVertex, vertex).X <= firstPos.X
						and firstPos.X + length <= Vector3.max(previousVertex, vertex).X
					) -- line between vertex and previousVertex
				)
			)
		then
			return Vector3.new(vertex.X, vertex.Y, firstPos.Z)
		end
		previousVertex = vertex
	end

	local vertex = self:getVertex(self:getVertexAmount())
	if
		firstPos.X <= vertex.X
		and vertex.X <= firstPos.X + length
		and previousVertex.Z <= firstPos.Z
		and firstPos.Z <= vertex.Z
	then
		return Vector3.new(vertex.X, vertex.Y, firstPos.Z)
	end
	previousVertex = vertex

	return nil
end

function Corridor.getFirstCollisionWith(self: Corridor, otherCorridor: Corridor)
	local otherPreviousVertex = otherCorridor:getVertex(1)

	for _, otherVertex in otherCorridor:iterateMiddleVertices() do
		local firstPos = Vector3.min(otherVertex, otherPreviousVertex)
		local line = otherVertex - otherPreviousVertex

		local intersection = nil
		if line.X == 0 then
			intersection = _intersectWithVerticalLine(self, firstPos, line.Magnitude)
		elseif line.Z == 0 then
			intersection = _intersectWithHorizontalLine(self, firstPos, line.Magnitude)
		else
			error(
				(
					"Error while getting the first collision of a corridor with another, "
					.. " Expected the otherCorridor to be ok, Got a diagonal line between two "
					.. "vertices: {%s} and {%s}"
				):format(tostring(otherPreviousVertex), tostring(otherVertex))
			)
		end

		if intersection ~= nil then
			return intersection
		end

		otherPreviousVertex = otherVertex
	end

	return nil
end

function Corridor.getFirstVertexBefore(self: Corridor, pos: Vector3): number?
	for i = 1, self:getVertexAmount() - 1, 1 do
		local vertex = self:getVertex(i)
		local nextVertex = self:getVertex(i + 1)

		-- Don't include the nextVertex if the pos is actually the nextVertex
		if nextVertex == pos then
			return i + 1
		end

		local min, max = Vector3.min(vertex, nextVertex), Vector3.max(vertex, nextVertex)

		if
			(min.X <= pos.X and pos.X <= max.X)
			and (min.Y <= pos.Y and pos.Y <= max.Y)
			and (min.Z <= pos.Z and pos.Z <= max.Z)
		then
			return i
		end
	end

	-- Check the last vertex, only cell not checked in the corridor
	if self:getVertex(self:getVertexAmount()) == pos then
		return self:getVertexAmount()
	end

	return nil
end

-- The divide method divides the Corridor into two other corridors but keep
-- the divided one as is
function Corridor.divide(self: Corridor, newEndAccess: Access.Access, newStartAccess: Access.Access)
	local newStartAccessPos = Vector3.new(
		newStartAccess.x + newStartAccess.direction.X,
		newStartAccess.y + newStartAccess.direction.Y,
		newStartAccess.z + newStartAccess.direction.Z
	)
	local newEndAccessPos = Vector3.new(
		newEndAccess.x + newEndAccess.direction.X,
		newEndAccess.y + newEndAccess.direction.Y,
		newEndAccess.z + newEndAccess.direction.Z
	)

	-- Corridor mitosis PLUH

	-- Create the new corridor that occupy the first part of this one
	local firstRoomAccessData = self._adjacents[1]:getAccessData(self._adjacentAccessNums[1])

	if firstRoomAccessData == nil then
		error(
			(
				"Error while dividing a Corridor, expected the first "
				.. "adjacent to include accessData n°%s. Adjacent: %s"
			):format(tostring(self._adjacentAccessNums[1]), tostring(self._adjacents[1]))
		)
	end

	-- Create the first half corridor
	local startAccessPos = self._adjacents[1]:getPos() + firstRoomAccessData:getRelativePosition()
	local halfCorridor1 = Corridor.new(
		Access.createAccess(
			self._adjacents[1],
			firstRoomAccessData,
			startAccessPos.X,
			startAccessPos.Y,
			startAccessPos.Z
		),
		newEndAccess
	)

	-- Create the new corridor that occupy the second part of this one
	local secondRoomAccessData = self._adjacents[2]:getAccessData(self._adjacentAccessNums[2])

	if secondRoomAccessData == nil then
		error(
			(
				"Error while dividing a Corridor, expected the second "
				.. "adjacent to include accessData n°%s. Adjacent: %s"
			):format(tostring(self._adjacentAccessNums[2]), tostring(self._adjacents[2]))
		)
	end

	-- Create the second half corridor
	local endAccessPos = self._adjacents[2]:getPos() + secondRoomAccessData:getRelativePosition()
	local halfCorridor2 = Corridor.new(
		newStartAccess,
		Access.createAccess(
			self._adjacents[2],
			secondRoomAccessData,
			endAccessPos.X,
			endAccessPos.Y,
			endAccessPos.Z
		)
	)

	-- Define the vertex num of the new corridors
	local firstVertexBeforeNewEnd = self:getFirstVertexBefore(newEndAccessPos)
	local firstVertexBeforeNewStart = self:getFirstVertexBefore(newStartAccessPos)

	-- Check that the first vertex before new end isn't THE vertex before new end
	if self:getVertex(firstVertexBeforeNewEnd) == newEndAccessPos then
		firstVertexBeforeNewEnd -= 1
	end

	-- Fill the first halfCorridor
	for i = 2, firstVertexBeforeNewEnd, 1 do
		halfCorridor1:addVertex(i)
		halfCorridor1:setVertex(i, self:getVertex(i))
	end

	-- Check that the first vertex before new start isn't THE vertex before new start
	if self:getVertex(firstVertexBeforeNewStart) == newStartAccess then
		firstVertexBeforeNewStart += 1
	end

	-- Fill the second halfCorridor
	local i = 2
	for j = firstVertexBeforeNewStart + 1, self:getVertexAmount() - 1, 1 do
		halfCorridor2:addVertex(i)
		halfCorridor2:setVertex(i, self:getVertex(j))
		i += 1
	end

	return halfCorridor1, halfCorridor2
end

--TODO fill() fills the gap between two vertices with other vertices.
function Corridor.fill(self: Corridor, vertexNum1: number, vertexNum2: number) end

function Corridor.addOnGrid(self: Corridor, grid: FlagGrid.FlagGrid)
	local previousVertex = self:getVertex(1)

	for _, vertex in self:iterateMiddleVertices() do
		local volumeStart, volumeEnd =
			Vector3.new(
				math.min(previousVertex.X, vertex.X),
				math.min(previousVertex.Y, vertex.Y),
				math.min(previousVertex.Z, vertex.Z)
			),
			Vector3.new(
				math.max(previousVertex.X, vertex.X),
				math.max(previousVertex.Y, vertex.Y),
				math.max(previousVertex.Z, vertex.Z)
			)
		grid:volumeSet(
			volumeStart.X,
			volumeStart.Y,
			volumeStart.Z,
			volumeEnd.X,
			volumeEnd.Y,
			volumeEnd.Z
		)

		previousVertex = vertex
	end

	local vertex = self:getVertex(self:getVertexAmount())
	local volumeStart, volumeEnd =
		Vector3.new(
			math.min(previousVertex.X, vertex.X),
			math.min(previousVertex.Y, vertex.Y),
			math.min(previousVertex.Z, vertex.Z)
		),
		Vector3.new(
			math.max(previousVertex.X, vertex.X),
			math.max(previousVertex.Y, vertex.Y),
			math.max(previousVertex.Z, vertex.Z)
		)

	grid:volumeSet(
		volumeStart.X,
		volumeStart.Y,
		volumeStart.Z,
		volumeEnd.X,
		volumeEnd.Y,
		volumeEnd.Z
	)
end

function Corridor.removeFromGrid(self: Corridor, grid: FlagGrid.FlagGrid)
	local previousVertex = self:getVertex(1)

	for _, vertex in self:iterateMiddleVertices() do
		local volumeStart, volumeEnd =
			Vector3.new(
				math.min(previousVertex.X, vertex.X),
				math.min(previousVertex.Y, vertex.Y),
				math.min(previousVertex.Z, vertex.Z)
			),
			Vector3.new(
				math.max(previousVertex.X, vertex.X),
				math.max(previousVertex.Y, vertex.Y),
				math.max(previousVertex.Z, vertex.Z)
			)
		grid:volumeReset(
			volumeStart.X,
			volumeStart.Y,
			volumeStart.Z,
			volumeEnd.X,
			volumeEnd.Y,
			volumeEnd.Z
		)

		previousVertex = vertex
	end

	local vertex = self:getVertex(self:getVertexAmount())
	local volumeStart, volumeEnd =
		Vector3.new(
			math.min(previousVertex.X, vertex.X),
			math.min(previousVertex.Y, vertex.Y),
			math.min(previousVertex.Z, vertex.Z)
		),
		Vector3.new(
			math.max(previousVertex.X, vertex.X),
			math.max(previousVertex.Y, vertex.Y),
			math.max(previousVertex.Z, vertex.Z)
		)

	grid:volumeReset(
		volumeStart.X,
		volumeStart.Y,
		volumeStart.Z,
		volumeEnd.X,
		volumeEnd.Y,
		volumeEnd.Z
	)
end

function Corridor.copyToCorridor(
	self: Corridor,
	other: Corridor,
	from: number?,
	to: number?,
	offset: number?
)
	offset = offset or 0
	for i = from or 1, to or self:getVertexAmount(), 1 do
		other:addVertex(i + offset)
		other:setVertex(i + offset, self:getVertex(i))
	end
end

-- This method does not add to any storage the newly created deadEnd, you have
-- to add it yourself.
function Corridor.makeDeadEnd(
	self: Corridor,
	deadEndTileRoomData: DeadEndTileRoomData.DeadEndTileRoomData,
	vertexNum: number
)
	local vertex = self:getVertex(vertexNum)

	local deadEndTileRoom = Room.new(vertex, deadEndTileRoomData)

	-- Create the new corridor with its new deadEnd
	local firstRoomAccessData = self._adjacents[1]:getAccessData(self._adjacentAccessNums[1])

	if firstRoomAccessData == nil then
		error(
			(
				"Error while making a deadEnd, expected the first "
				.. "adjacent to include accessData n°%s. Adjacent: %s"
			):format(tostring(self._adjacentAccessNums[1]), tostring(self._adjacents[1]))
		)
	end

	-- Create the corridor
	local startAccessPos = self._adjacents[1]:getPos() + firstRoomAccessData:getRelativePosition()
	local deadEndVertexPos = deadEndTileRoom:getPos()
		+ deadEndTileRoom:getAccessData(1):getRelativePosition()

	local deadEndCorridor = Corridor.new(
		Access.createAccess(
			self._adjacents[1],
			firstRoomAccessData,
			startAccessPos.X,
			startAccessPos.Y,
			startAccessPos.Z
		),
		Access.createAccess(
			deadEndTileRoom,
			deadEndTileRoom:getAccessData(1),
			deadEndVertexPos.X,
			deadEndVertexPos.Y,
			deadEndVertexPos.Z
		)
	)

	return deadEndCorridor, deadEndTileRoom
end

function Corridor.iterateAccessDatas(self: Corridor)
	return ipairs({ self._firstAccess, self._secondAccess })
end

--TODO tranform the corridor into a bunch of rooms
function Corridor.roomify(
	self: Corridor,
	roomDataSet: RoomDataSet.RoomDataSet,
	seededRandom: SeededRandom.SeededRandom
): { Room.Room }
	if not self:isSingleCell() then
		error("Trying to roomify a non single cell corridor but it is not yet made for this.")
	end

	local firstDirection = self._firstAccess:getDirection()
	local secondDirection = self._secondAccess:getDirection()

	local isNorth, isWest, isSouth, isEast
	isNorth = firstDirection == Directions.NORTH or secondDirection == Directions.NORTH
	isWest = firstDirection == Directions.WEST or secondDirection == Directions.WEST
	isSouth = firstDirection == Directions.SOUTH or secondDirection == Directions.SOUTH
	isEast = firstDirection == Directions.EAST or secondDirection == Directions.EAST

	local selection = roomDataSet:startRoomSelection():selectTile():selectMaxSize(0, 0, 0)

	-- Select with the access pos
	local accessPositions = {}

	if isNorth then
		table.insert(accessPositions, Directions.NORTH)
	end

	if isWest then
		table.insert(accessPositions, Directions.WEST)
	end

	if isSouth then
		table.insert(accessPositions, Directions.SOUTH)
	end

	if isEast then
		table.insert(accessPositions, Directions.EAST)
	end

	selection:select(function(roomData)
		if roomData:getAccessNumber() ~= 2 then
			return false
		end

		for _, accessData in roomData:iterateAccessDatas() do
			if accessData:getDirection() == -firstDirection then
				return true
			end

			if accessData:getDirection() == -secondDirection then
				return true
			end
		end

		return false
	end)

	local roomData = selection:getRandomRoom(seededRandom)

	if roomData == nil then
		error(
			(
				"Got a nil roomData while searching for a tile that "
				.. "has the directions: {%s} and {%s} and the size: "
				.. "{0, 0, 0}"
			):format(tostring(firstDirection), tostring(secondDirection))
		)
	end

	local room = Room.new(self:getVertex(1), roomData)

	for accessNum, accessData in roomData:iterateAccessDatas() do
		if accessData:getDirection() == firstDirection then
			room:setAdjacent(self._adjacents[1], accessData)
		elseif accessData:getDirection() == secondDirection then
			room:setAdjacent(self._adjacents[2], accessData)
		end
	end

	return { room }
end

-- Check if the corridor has all its segments right like if there is no
-- diagonal segment or anything.
function Corridor.isOk(self: Corridor)
	local previousVertex = self:getVertex(1)

	for _, vertex in self:iterateMiddleVertices() do
		local delta = previousVertex - vertex

		if
			not (
				(delta.X == 0 and delta.Y == 0 and delta.Z ~= 0)
				or (delta.X ~= 0 and delta.Y == 0 and delta.Z == 0)
			)
		then
			return false
		end

		previousVertex = vertex
	end

	local vertex = self:getVertex(self:getVertexAmount())
	local delta = previousVertex - vertex

	if
		not (
			(delta.X == 0 and delta.Y == 0 and delta.Z ~= 0)
			or (delta.X ~= 0 and delta.Y == 0 and delta.Z == 0)
		)
	then
		return false
	end

	return true
end

return Corridor
