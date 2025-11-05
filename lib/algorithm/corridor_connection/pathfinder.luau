local Directions = require(script.Parent.Parent.Parent.gen_data.Directions)
local IReadableGrid = require(script.Parent.Parent.Parent.gen_data.IReadableGrid)
local Access = require(script.Parent.Parent.Parent.gen_elements.access.Access)
local Corridor = require(script.Parent.Parent.Parent.gen_elements.corridor.Corridor)

-- The area around the base vertex where it can search for a way out.
local MAX_BASE_VERTEX_SEARCH_AREA = Vector3.new(5, 5, 5)

return function(
	grid: IReadableGrid.IReadableGrid,
	firstAccess: Access.Access,
	secondAccess: Access.Access,
	bfsDirectionsOrder: { Directions.Direction },
	debugMode: boolean
): Corridor.Corridor?
	-- BFS algorithm
	local firstPos = Vector3.new(firstAccess.x, firstAccess.y, firstAccess.z)
	local secondPos = Vector3.new(secondAccess.x, secondAccess.y, secondAccess.z)

	local minPos = Vector3.min(firstPos, secondPos)
	local maxPos = Vector3.max(firstPos, secondPos)

	local searchMin = minPos - MAX_BASE_VERTEX_SEARCH_AREA
	local searchMax = maxPos + MAX_BASE_VERTEX_SEARCH_AREA
	searchMin = Vector3.new(
		if searchMin.X < 1
			then 1
			else (if searchMin.X > grid:getXSize() then grid:getXSize() else searchMin.X),
		if searchMin.Y < 1
			then 1
			else (if searchMin.Y > grid:getYSize() then grid:getYSize() else searchMin.Y),
		if searchMin.Z < 1
			then 1
			else (if searchMin.Z > grid:getXSize() then grid:getZSize() else searchMin.Z)
	)
	searchMax = Vector3.new(
		if searchMax.X < 1
			then 1
			else (if searchMax.X > grid:getXSize() then grid:getXSize() else searchMax.X),
		if searchMax.Y < 1
			then 1
			else (if searchMax.Y > grid:getYSize() then grid:getYSize() else searchMax.Y),
		if searchMax.Z < 1
			then 1
			else (if searchMax.Z > grid:getXSize() then grid:getZSize() else searchMax.Z)
	)

	local vertexQueue: { Vector3 } = { firstPos }
	local visitedStack: { Vector3 } = {}
	local parentDict = {}

	bfsDirectionsOrder = bfsDirectionsOrder
		or {
			Directions.NORTH,
			Directions.WEST,
			Directions.SOUTH,
			Directions.EAST,
		}

	while vertexQueue[1] ~= nil do
		local vertex = vertexQueue[1]
		table.remove(vertexQueue, 1)

		if vertex.X == secondPos.X and vertex.Y == secondPos.Y and vertex.Z == secondPos.Z then
			table.insert(visitedStack, vertex)
			break
		end

		for i = 1, 4, 1 do
			local direction = bfsDirectionsOrder[i]
			local otherVertex = vertex + direction

			if
				otherVertex.X < searchMin.X
				or otherVertex.Y < searchMin.Y
				or otherVertex.Z < searchMin.Z
				or otherVertex.X > searchMax.X
				or otherVertex.Y > searchMax.Y
				or otherVertex.Z > searchMax.Z
				or grid:get(otherVertex.X, otherVertex.Y, otherVertex.Z) == 1
			then
				continue
			end

			-- Check if its already visited
			local alreadyVisitedOrInQueue = false
			for _, visitedVertex in ipairs(visitedStack) do
				if
					visitedVertex.X == otherVertex.X
					and visitedVertex.Y == otherVertex.Y
					and visitedVertex.Z == otherVertex.Z
				then
					alreadyVisitedOrInQueue = true
					break
				end
			end

			if alreadyVisitedOrInQueue then
				continue
			end

			-- check if its already in queue
			for _, enqueued in ipairs(vertexQueue) do
				if
					enqueued.X == otherVertex.X
					and enqueued.Y == otherVertex.Y
					and enqueued.Z == otherVertex.Z
				then
					alreadyVisitedOrInQueue = true
					break
				end
			end

			if alreadyVisitedOrInQueue then
				continue
			end

			table.insert(vertexQueue, otherVertex)
			parentDict[otherVertex] = vertex
		end

		table.insert(visitedStack, vertex)

		if debugMode then
			coroutine.yield(vertexQueue, visitedStack)
		end
	end

	if visitedStack[#visitedStack] ~= secondPos then
		return nil
	end

	local actualVertex = visitedStack[#visitedStack]

	local path

	if actualVertex == secondPos then
		local reversePath = {}

		repeat
			table.insert(reversePath, actualVertex)
			actualVertex = parentDict[actualVertex]

			if debugMode then
				coroutine.yield(reversePath)
			end
		until actualVertex == firstPos

		table.insert(reversePath, firstPos)

		if debugMode then
			coroutine.yield(reversePath)
		end

		-- Create the actual path
		path = {}
		for i = #reversePath, 1, -1 do
			table.insert(path, reversePath[i])
		end
	end

	if path == nil then
		return nil
	end

	local corridor = Corridor.new(firstAccess, secondAccess)

	-- Transform the straight lines of the path into vertices
	local vertices = {}
	local actualDirection = Vector3.zero
	local previousPoint = path[1]

	for i, point in ipairs(path) do
		if i == 1 then
			continue
		end

		if point ~= previousPoint + actualDirection then
			actualDirection = point - previousPoint
			table.insert(vertices, previousPoint)
		end

		previousPoint = point
	end

	-- and we rereverse the reverse path but its okay
	for i = #vertices, 2, -1 do
		corridor:addVertex(2)
		corridor:setVertex(2, vertices[i])
	end

	return corridor
end
