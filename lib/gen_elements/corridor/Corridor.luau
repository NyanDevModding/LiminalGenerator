local FlagGrid = require(script.Parent.Parent.Parent.gen_data.FlagGrid)
local IRoomStorable = require(script.Parent.Parent.Parent.gen_data.storage.IRoomStorable)
local AccessData = require(script.Parent.Parent.Parent.gen_setting.access.AccessData)

-- implements IRoomStorable
local Corridor = {}
Corridor.__index = Corridor

export type Corridor = typeof(Corridor.new())

function Corridor.new(firstAccess: AccessData.AccessData, secondAccess: AccessData.AccessData)
	local p1 = Vector3.new(firstAccess.x, firstAccess.y, firstAccess.z) + firstAccess.direction
	local p2 = Vector3.new(secondAccess.x, secondAccess.y, secondAccess.z) + secondAccess.direction

	if p1.Y ~= p2.Y then
		warn(
			"WARNING: You are using different Y coordinates for "
				.. "a corridor. It is not yet coded to handle that."
		)
	end

	return setmetatable({
		_adjacents = { firstAccess.room, secondAccess.room },
		_firstAccess = firstAccess,
		_secondAccess = secondAccess,
		_vertices = { p1, p2 },
	}, Corridor)
end

function Corridor.getPos(self: Corridor)
	return self:getVertex(1)
end

function Corridor.setAdjacent(
	self: Corridor,
	adjacent: IRoomStorable.IRoomStorable,
	accessNumero: number,
	otherAccessNumero: number
)
	self._adjacents[accessNumero] = adjacent

	if accessNumero == 1 then
		self._firstAccess = AccessData.createAccess(
			adjacent,
			adjacent:getAccess(otherAccessNumero),
			self._firstAccess.x,
			self._firstAccess.y,
			self._firstAccess.z
		)
		return
	end

	self._secondAccess = AccessData.createAccess(
		adjacent,
		adjacent:getAccess(otherAccessNumero),
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

-- The vertexNum is the numero of the vertex that is transformed into the end
-- vertex. Thus the vertexNum + 1 vertex is the start of the new corridor.
-- Please start by creating to vertices at newEnd and newStart accesses
-- positions.
function Corridor.divide(
	self: Corridor,
	vertexNum: Vector3,
	newEndAccess: AccessData.AccessData,
	newStartAccess: AccessData.AccessData
)
	local newStartAccessPos = Vector3.new(newStartAccess.x, newStartAccess.y, newStartAccess.z)
		+ newStartAccess.direction
	local newEndAccessPos = Vector3.new(newEndAccess.x, newEndAccess.y, newEndAccess.z)
		+ newEndAccess.direction

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
	local newCorridor = Corridor.new(newStartAccess, self._secondAccess)

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

--TODO fill() fills the gap between two vertices wit hother vertices.
function Corridor.fill(self: Corridor, vertexNum1: number, vertexNum2: number) end

function Corridor.getAccess(self: Corridor, accessNum: number)
	if accessNum == 1 then
		return self._firstAccess
	end
	return self._secondAccess
end

return Corridor
