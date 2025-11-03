local Directions = require(script.Parent.Parent.Parent.gen_data.Directions)
local FlagGrid = require(script.Parent.Parent.Parent.gen_data.FlagGrid)
local IRoomStorable = require(script.Parent.Parent.Parent.gen_data.storage.IRoomStorable)
local DeadEndTileRoomData =
	require(script.Parent.Parent.Parent.gen_setting.corridor_tile.uniform.DeadEndTileRoomData)
local Access = require(script.Parent.Parent.access.Access)
local Room = require(script.Parent.Parent.room.Room)

-- implements IRoomStorable
local Corridor = {}
Corridor.__index = Corridor

export type Corridor = typeof(Corridor.new())

function Corridor.new(firstAccess: Access.Access, secondAccess: Access.Access)
	local p1 = Vector3.new(firstAccess.x, firstAccess.y, firstAccess.z)
	local p2 = Vector3.new(secondAccess.x, secondAccess.y, secondAccess.z)

	if p1.Y ~= p2.Y then
		warn(
			"WARNING: You are using different Y coordinates for "
				.. "a corridor. It is not yet coded to handle that."
		)
	end

	return setmetatable({
		_adjacents = { firstAccess.room, secondAccess.room } :: { IRoomStorable.IRoomStorable },
		_firstAccess = firstAccess.access,
		_secondAccess = secondAccess.access,
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
		_firstAccess = accessData1,
		_secondAccess = accessData2,
		_vertices = { p1, p2 },
	}, Corridor)
end

function Corridor.getPos(self: Corridor)
	return self:getVertex(1)
end

function Corridor.getAccessData(self: Corridor, accessNumero: number)
	if accessNumero == 1 then
		return self._firstAccess
	end

	return self._secondAccess
end

function Corridor.setAdjacent(
	self: Corridor,
	adjacent: IRoomStorable.IRoomStorable,
	accessNumero: number,
	otherAccessNumero: number
)
	self._adjacents[accessNumero] = adjacent

	if accessNumero == 1 then
		self._firstAccess = Access.createAccess(
			adjacent,
			adjacent:getAccessData(otherAccessNumero),
			self._firstAccess.x,
			self._firstAccess.y,
			self._firstAccess.z
		)
		return
	end

	self._secondAccess = Access.createAccess(
		adjacent,
		adjacent:getAccessData(otherAccessNumero),
		self._secondAccess.x,
		self._secondAccess.y,
		self._secondAccess.z
	)
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
	if
		(previousVertex.X > cellPos.X or cellPos.X > vertex.X)
		or (previousVertex.Y > cellPos.Y or cellPos.Y > vertex.Y)
		or (previousVertex.Z > cellPos.Z or cellPos.Z > vertex.Z)
	then
		return false
	end

	return true
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

function Corridor.addVertex(self: Corridor, vertexNum: number)
	for i = #self._vertices, vertexNum, -1 do
		self._vertices[i + 1] = self._vertices[i]
	end
	local vertex = self._vertices[vertexNum]
	self._vertices[vertexNum] = Vector3.new(vertex.X, vertex.Y, vertex.Z)
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

function Corridor.iterateMiddleVertices(self: Corridor)
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

--TODO
function Corridor.getFirstCollisionWith(self: Corridor, otherCorridor: Corridor) end

--TODO
function Corridor.getFirstVertexBefore(self: Corridor, pos: Vector3) end

-- The vertexNum is the numero of the vertex that is transformed into the end
-- vertex. Thus the vertexNum + 1 vertex is the start of the new corridor.
-- Please start by creating to vertices at newEnd and newStart accesses
-- positions.
function Corridor.divide(
	self: Corridor,
	vertexNum: Vector3,
	newEndAccess: Access.Access,
	newStartAccess: Access.Access
)
	local newStartAccessPos = Vector3.new(newStartAccess.x, newStartAccess.y, newStartAccess.z)
	local newEndAccessPos = Vector3.new(newEndAccess.x, newEndAccess.y, newEndAccess.z)

	-- Corridor mitosis PLUH
	local vertex = self._vertices[vertexNum]
	local nextVertex = self._vertices[vertexNum + 1]
	-- Check if the both the accesses are included between the vertex and the next one.
	if
		(newEndAccessPos.x > nextVertex.X and newStartAccessPos.x < vertex.X)
		and (newEndAccessPos.y > nextVertex.Y and newStartAccessPos.y < vertex.Y)
		and (newEndAccessPos.z > nextVertex.Z and newStartAccessPos.z < vertex.Z)
	then
		error(
			(
				"Error while dividing a corridor: expected the new accesses to be aligned "
				.. "with the vertices, got the accesse entrances: newEnd:{%i, %i, %i} and newStart:"
				.. "{%i, %i, %i} and the vertices: vertex:{%i, %i, %i} and nextVertex:{%i, %i, %i}"
			):format(
				newStartAccess.x,
				newStartAccess.y,
				newStartAccess.z,
				newStartAccessPos.x,
				newStartAccessPos.y,
				newStartAccessPos.z,
				vertex.X,
				vertex.Y,
				vertex.Z,
				nextVertex.X,
				nextVertex.Y,
				nextVertex.Z
			)
		)
	end

	-- Create the new corridor that occupy the second part of this one
	local secondAccessPos = self:getVertex(self:getVertexAmount())
	local newCorridor = Corridor.new(
		newStartAccess,
		Access.createAccess(
			self._adjacents[2],
			self._secondAccess,
			secondAccessPos.X,
			secondAccessPos.Y,
			secondAccessPos.Z
		)
	)

	-- Change this secondAccess to be the new EndAccess
	self._secondAccess = newEndAccess
	self._vertices[vertexNum] = newEndAccessPos
	self._vertices[vertexNum + 1] = nil

	-- Update the new corridor
	local vertexAmount = #self._vertices
	-- i = 3 cause the 1st is the newStartAccess and cause we set manually the 2nd vertex
	-- (vertexAmount - 1) cause we exclude the endVertex
	newCorridor:setVertex(2, self._vertices[vertexNum + 2])
	self._vertices[vertexNum + 2] = nil
	for i = 3, (vertexAmount - 1) - vertexNum, 1 do
		--TODO a better optimized way to do this
		newCorridor:addVertex(i)
		newCorridor:setVertex(i, self._vertices[vertexNum + i])

		-- + delete the duplicated part of this corridor
		self._vertices[vertexNum + i] = nil
	end
	self._vertices[vertexAmount] = nil

	return newCorridor
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

-- This method does not add to any storage the newly created deadEnd, you have
-- to add it yourself.
function Corridor.makeDeadEnd(
	self: Corridor,
	deadEndTileRoomData: DeadEndTileRoomData.DeadEndTileRoomData,
	vertexNum: number
)
	for i = vertexNum + 1, self:getVertexAmount(), 1 do
		self._vertices[i] = nil
	end
	self._secondAccess = nil

	local vertex = self:getVertex(vertexNum)

	local newVertex = vertex + deadEndTileRoomData:getDirection()
	local deadEndTileRoom = Room.new(vertex, deadEndTileRoomData)

	self:setVertex(vertexNum, newVertex)
	self._secondAccess = deadEndTileRoomData:getAccessData(1)

	return deadEndTileRoom
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
