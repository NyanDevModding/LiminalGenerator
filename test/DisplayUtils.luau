local Directions = require(script.Parent.Parent.LiminalGenerator.gen_data.Directions)
local FlagGrid = require(script.Parent.Parent.LiminalGenerator.gen_data.FlagGrid)
local CorridorStorage =
	require(script.Parent.Parent.LiminalGenerator.gen_data.storage.CorridorStorage)

local Corridor = require(script.Parent.Parent.LiminalGenerator.gen_elements.corridor.Corridor)
local AccessData = require(script.Parent.Parent.LiminalGenerator.gen_setting.access.AccessData)

local DisplayUtils = {}

function DisplayUtils.createGridPart(cellSize: number)
	local part = Instance.new("Part")
	part.Anchored = true
	part.Size = Vector3.new(cellSize - 0.1, 1, cellSize - 0.1)
	return part
end

function DisplayUtils.create2DGrid(
	grid: FlagGrid.FlagGrid,
	worldPos: Vector3,
	cellSize: number,
	vertexQueue: { Vector3 },
	visitedStack: { Vector3 },
	path: { Vector3 },
	yLayer: number?
)
	local COLOR_0 = Color3.new(0, 0, 0)
	local COLOR_1 = Color3.new(1, 1, 1)
	local COLOR_ENQUEUED = Color3.new(0.980392, 0.67451, 0.015686)
	local COLOR_VISITED = Color3.new(0.011765, 0.192157, 1)
	local COLOR_PATH = Color3.new(0.019608, 0.568627, 0.047059)

	yLayer = yLayer or 1

	local folder = Instance.new("Folder")

	for i = 1, grid:getXSize(), 1 do
		for j = 1, grid:getZSize(), 1 do
			-- create the part
			local part = DisplayUtils.createGridPart(cellSize)
			part.Name = tostring(i) .. "_" .. tostring(j)
			part.Position = worldPos + Vector3.new(i * cellSize, 0, -j * cellSize)
			part.Parent = folder

			-- change the part with its state
			if grid:get(i, yLayer, j) == 0 then
				part.Color = COLOR_0
			else
				part.Color = COLOR_1
			end
		end
	end

	for _, vertex in ipairs(vertexQueue) do
		local part: Part = folder:FindFirstChild(tostring(vertex.X) .. "_" .. tostring(vertex.Z))
		part.Color = COLOR_ENQUEUED
	end

	for _, visited in ipairs(visitedStack) do
		local part: Part = folder:FindFirstChild(tostring(visited.X) .. "_" .. tostring(visited.Z))
		part.Color = COLOR_VISITED
	end

	for _, pathVertex in ipairs(path) do
		local part: Part =
			folder:FindFirstChild(tostring(pathVertex.X) .. "_" .. tostring(pathVertex.Z))
		part.Color = COLOR_PATH
	end

	return folder
end

function DisplayUtils.createFlag2DGrid(
	grid: FlagGrid.FlagGrid,
	worldPos: Vector3,
	cellSize: number,
	yLayer: number?
)
	local COLOR_0 = Color3.new(0, 0, 0)
	local COLOR_1 = Color3.new(1, 1, 1)

	yLayer = yLayer or 1

	local folder = Instance.new("Folder")

	for i = 1, grid:getXSize(), 1 do
		for j = 1, grid:getZSize(), 1 do
			-- create the part
			local part = DisplayUtils.createGridPart(cellSize)
			part.Name = tostring(i) .. "_" .. tostring(j)
			part.Position = worldPos + Vector3.new(i * cellSize, 0, -j * cellSize)
			part.Parent = folder

			-- change the part with its state
			if grid:get(i, yLayer, j) == 0 then
				part.Color = COLOR_0
			else
				part.Color = COLOR_1
			end
		end
	end

	return folder
end

function DisplayUtils.createSelective2dGrid(
	grid: FlagGrid.FlagGrid,
	worldPos: Vector3,
	cellSize: number,
	transparency: number,
	color1: Color3,
	yLayer: number?
)
	color1 = color1 or Color3.new(0.019608, 0.47451, 0.058824)

	transparency = transparency or 1
	yLayer = yLayer or 1

	local folder = Instance.new("Folder")

	for i = 1, grid:getXSize(), 1 do
		for j = 1, grid:getZSize(), 1 do
			-- Skip 0 cells
			if grid:get(i, yLayer, j) == 0 then
				continue
			end

			-- Create the part
			local part = DisplayUtils.createGridPart(cellSize)
			part.Name = tostring(i) .. "_" .. tostring(j)
			part.Position = worldPos + Vector3.new(i * cellSize, 0, -j * cellSize)
			part.Color = color1
			part.Transparency = transparency
			part.Parent = folder
		end
	end

	return folder
end

function DisplayUtils.createCorridorPart(
	firstPos: Vector3,
	secondPos: Vector3,
	segmentSize: number?
)
	local part = Instance.new("Part")
	part.Anchored = true
	part.Size = Vector3.new(segmentSize or 1, segmentSize or 1, (secondPos - firstPos).Magnitude)
	part.CFrame = CFrame.new((secondPos + firstPos) / 2, secondPos)
	return part
end

function DisplayUtils.plotCorridor(
	worldPos: Vector3,
	cellSize: number,
	folder: Folder,
	corridor: Corridor.Corridor,
	vertexSize: number?,
	segmentSize: number?,
	transparency: number?,
	color: Color3?
)
	vertexSize = vertexSize or 3
	segmentSize = segmentSize or 1
	transparency = transparency or 0
	color = color or Color3.new(0, 0.368627, 0.847059)

	for i, vertex in corridor:iterateVertices() do
		local nextVertex = corridor:getVertex(i + 1)

		local vertexPart = Instance.new("Part")
		vertexPart.Name = "vx_" .. tostring(i)
		vertexPart.Anchored = true
		vertexPart.Size = Vector3.new(vertexSize, vertexSize, vertexSize)
		vertexPart.Color = color
		vertexPart.Transparency = transparency
		vertexPart.Material = Enum.Material.Neon
		vertexPart.Position = worldPos + (vertex * cellSize)
		vertexPart.Position = Vector3.new(vertexPart.Position.X, worldPos.Y, -vertexPart.Position.Z)
		vertexPart.Parent = folder

		if nextVertex == nil then
			break
		end

		local firstWorldPos = worldPos + (vertex * cellSize)
		firstWorldPos = Vector3.new(firstWorldPos.X, worldPos.Y, -firstWorldPos.Z)
		local secondWorldPos = worldPos + (nextVertex * cellSize)
		secondWorldPos = Vector3.new(secondWorldPos.X, worldPos.Y, -secondWorldPos.Z)

		local linkPart = DisplayUtils.createCorridorPart(firstWorldPos, secondWorldPos, segmentSize)
		linkPart.Position = Vector3.new(linkPart.Position.X, worldPos.Y + 1, linkPart.Position.Z)
		linkPart.Name = "lk_" .. tostring(i)
		linkPart.Material = Enum.Material.Neon
		linkPart.Color = color
		linkPart.Transparency = transparency
		linkPart.Parent = folder
	end

	return folder
end

function DisplayUtils.plotCorridorStorage(
	worldPos: Vector3,
	cellSize: number,
	corridorStorage: CorridorStorage.CorridorStorage,
	corridorColor: Color3?,
	corridorColorDict: { [Corridor.Corridor]: Color3 }?,
	vertexSize: number?,
	segmentSize: number?,
	transparency: number?
)
	local corridorGridFolder = Instance.new("Folder")
	corridorColorDict = corridorColorDict or {}

	for _, corridor in corridorStorage:iterateCorridor() do
		local color = corridorColor or corridorColorDict[corridor] or Color3.fromRGB(0, 100, 0)

		DisplayUtils.plotCorridor(
			worldPos + Vector3.yAxis,
			cellSize,
			corridorGridFolder,
			corridor,
			vertexSize,
			segmentSize,
			transparency,
			color
		)
	end

	return corridorGridFolder
end

DisplayUtils.TEST_ACCESS_1 = AccessData.new(1, Vector3.new(0, 0, 0), Directions.EAST)
DisplayUtils.TEST_ACCESS_2 = AccessData.new(1, Vector3.new(0, 0, 0), Directions.WEST)
DisplayUtils.TEST_ACCESS_3 = AccessData.new(1, Vector3.new(0, 0, 0), Directions.NORTH)
DisplayUtils.TEST_ACCESS_4 = AccessData.new(1, Vector3.new(0, 0, 0), Directions.SOUTH)

return DisplayUtils
