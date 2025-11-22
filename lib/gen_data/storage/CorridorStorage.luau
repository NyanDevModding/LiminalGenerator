local FlagGrid = require(script.Parent.Parent.FlagGrid)
local Corridor = require(script.Parent.Parent.Parent.gen_elements.corridor.Corridor)

local CorridorStorage = {}
CorridorStorage.__index = CorridorStorage

export type CorridorStorage = typeof(CorridorStorage.new())

function CorridorStorage.new()
	return setmetatable({
		_storage = {} :: { Corridor.Corridor },
	}, CorridorStorage)
end

function CorridorStorage.addCorridor(self: CorridorStorage, corridor: Corridor.Corridor)
	table.insert(self._storage, corridor)
end

function CorridorStorage.getCorridorAt(self: CorridorStorage, pos: Vector3): Corridor.Corridor?
	for _, corridor in ipairs(self._storage) do
		if corridor:isIncludingCell(pos) then
			return corridor
		end
	end

	return nil
end

function CorridorStorage.removeCorridor(self: CorridorStorage, corridor: Corridor.Corridor)
	for i, storedCorridor in ipairs(self._storage) do
		if storedCorridor == corridor then
			-- if it is the last of the Storage
			if self._storage[i + 1] == nil then
				self._storage[i] = nil
				break
			end

			self._storage[i] = self._storage[#self._storage]
			self._storage[#self._storage] = nil

			break
		end
	end
end

function CorridorStorage.iterateCorridor(self: CorridorStorage)
	return ipairs(self._storage)
end

local function corridorVolumeAnd(grid: FlagGrid.FlagGrid, corridor: Corridor.Corridor)
	local previousVertex = corridor:getVertex(1)

	for vertexNum, vertex in corridor:iterateMiddleVertices() do
		local min = Vector3.min(previousVertex, vertex)
		local max = Vector3.max(previousVertex, vertex)

		if not grid:volumeAnd(min.X, min.Y, min.Z, max.X, max.Y, max.Z) then
			return false, vertexNum
		end

		previousVertex = vertex
	end

	local vertex = corridor:getVertex(corridor:getVertexAmount())

	local min = Vector3.min(previousVertex, vertex)
	local max = Vector3.max(previousVertex, vertex)

	if not grid:volumeAnd(min.X, min.Y, min.Z, max.X, max.Y, max.Z) then
		return false, corridor:getVertexAmount()
	end

	return true
end

local function corridorVolumeOr(grid: FlagGrid.FlagGrid, corridor: Corridor.Corridor)
	local previousVertex = corridor:getVertex(1)

	for vertexNum, vertex in corridor:iterateMiddleVertices() do
		local min = Vector3.min(previousVertex, vertex)
		local max = Vector3.max(previousVertex, vertex)

		if grid:volumeOr(min.X, min.Y, min.Z, max.X, max.Y, max.Z) then
			return true, vertexNum
		end

		previousVertex = vertex
	end

	local vertex = corridor:getVertex(corridor:getVertexAmount())

	local min = Vector3.min(previousVertex, vertex)
	local max = Vector3.max(previousVertex, vertex)

	if grid:volumeOr(min.X, min.Y, min.Z, max.X, max.Y, max.Z) then
		return true, corridor:getVertexAmount()
	end

	return false
end

function CorridorStorage.debugCheckSyncWithGrid(self: CorridorStorage, grid: FlagGrid.FlagGrid)
	local ok = true

	for i, corridor in self:iterateCorridor() do
		local result, vertexNum = corridorVolumeAnd(grid, corridor)

		if not result then
			ok = false
			warn(
				("Unsync between the corridorStorage and its grid: For the corridor #%i, at the vertices: #%i:{%s} and #%i:{%s}"):format(
					i,
					vertexNum - 1,
					tostring(corridor:getVertex(vertexNum - 1)),
					vertexNum,
					tostring(corridor:getVertex(vertexNum))
				)
			)
		end
	end

	if ok then
		print("	✅ Corridor Storage and Corridor Grid in sync")
	else
		print("Here is the grid: \n" .. tostring(grid))
	end
end

-- Check that no corrridor are on top of each other
function CorridorStorage.debugIsOk(self: CorridorStorage, worldSize: Vector3)
	local ok = true

	local testGrid = FlagGrid.new(worldSize.X, worldSize.Y, worldSize.Z)

	for _, corridor in self:iterateCorridor() do
		local hasCollision, vertexNum = corridorVolumeOr(testGrid, corridor)

		if hasCollision then
			ok = false
			warn(
				(
					"Problem: CorridorStorage not ok, got corridors on "
					.. "top of each other between vertices: {%s}-{%s}"
				):format(
					tostring(corridor:getVertex(vertexNum - 1)),
					tostring(corridor:getVertex(vertexNum))
				)
			)
		end

		corridor:addOnGrid(testGrid)
	end

	if ok then
		print("	✅ Corridor Storage OK")
	else
		print("Here is the grid of the storage: \n" .. tostring(testGrid))
	end
end

return CorridorStorage
