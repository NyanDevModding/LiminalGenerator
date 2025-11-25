local RoomDataSet = require(script.Parent.Parent.gen_setting.room_data_set.RoomDataSet)
local SimpleTileDirections = require(script.Parent.Parent.gen_setting.SimpleTileDirections)

local CorridorStorage = require(script.Parent.Parent.gen_data.storage.CorridorStorage)
local Corridor = require(script.Parent.Parent.gen_elements.corridor.Corridor)
local RoomStorage = require(script.Parent.Parent.gen_data.storage.RoomStorage)

local function debugPaintModel(model: Model, color: Color3)
	for _, part in model:GetDescendants() do
		if part:IsA("Part") then
			part.Color = color
		end
	end
end

local function createCorridorModel(
	cellSize: number,
	roomDataSet: RoomDataSet.RoomDataSet,
	corridor: Corridor.Corridor
)
	local color = Color3.fromRGB(math.random(0, 255), math.random(0, 255), math.random(0, 255))

	local model = Instance.new("Model")

	local pos = corridor:getPos()
	local accessType: number = corridor:getAccessData(1):getAccessType()

	-- Generate the first vertex
	local firstVertexDirection = SimpleTileDirections.toDirection(
		corridor:getAccessData(1):getDirection(),
		corridor:getVertexEndingDirection(1)
	)

	local firstVertexModel =
		roomDataSet:getSimpleUniformTiles(accessType, firstVertexDirection)[1]:getModel():Clone()
	firstVertexModel:PivotTo(firstVertexModel:GetPivot() + cellSize * pos)
	firstVertexModel.Name = "vx#1_cell#0"

	debugPaintModel(firstVertexModel, color)

	firstVertexModel.Parent = model

	-- Generate the other vertices and the lines between vertices
	local previousVertex = corridor:getVertex(1)
	for vertexNum, vertex in corridor:iterateMiddleVertices() do
		-- Generate the line
		local line = vertex - previousVertex
		local lineLength = line.Magnitude

		local cellDirection = SimpleTileDirections.toDirection(line.Unit, -line.Unit)
		for i = 1, lineLength - 1, 1 do
			local cellModel =
				roomDataSet:getSimpleUniformTiles(accessType, cellDirection)[1]:getModel():Clone()
			cellModel:PivotTo(
				cellModel:GetPivot() + cellSize * ((line * i) / lineLength + previousVertex)
			)
			cellModel.Name = "vx#" .. tostring(vertexNum) .. "_cell#" .. tostring(i)

			debugPaintModel(cellModel, color)

			cellModel.Parent = model
		end

		-- Generate the vertex
		local vertexDirection = SimpleTileDirections.toDirection(
			corridor:getVertexStartingDirection(vertexNum),
			corridor:getVertexEndingDirection(vertexNum)
		)

		local vertexModel =
			roomDataSet:getSimpleUniformTiles(accessType, vertexDirection)[1]:getModel():Clone()
		vertexModel:PivotTo(vertexModel:GetPivot() + cellSize * vertex)
		vertexModel.Name = "vx#" .. tostring(vertexNum) .. "_cell#0"

		vertexModel.PrimaryPart.Color = color

		debugPaintModel(vertexModel, color)

		vertexModel.Parent = model

		previousVertex = vertex
	end

	-- Generate last line
	local lastVertexNum = corridor:getVertexAmount()
	local lastLine = corridor:getVertex(lastVertexNum) - previousVertex
	local lastLineLength = lastLine.Magnitude

	local cellDirection = SimpleTileDirections.toDirection(lastLine.Unit, -lastLine.Unit)
	for i = 1, lastLineLength - 1, 1 do
		local cellModel =
			roomDataSet:getSimpleUniformTiles(accessType, cellDirection)[1]:getModel():Clone()
		cellModel:PivotTo(
			cellModel:GetPivot() + cellSize * ((lastLine * i) / lastLineLength + previousVertex)
		)
		cellModel.Name = "vx#" .. tostring(lastVertexNum) .. "_cell#" .. tostring(i)

		debugPaintModel(cellModel, color)

		cellModel.Parent = model
	end

	-- Generate last vertex
	local lastVertexDirection = SimpleTileDirections.toDirection(
		corridor:getVertexStartingDirection(lastVertexNum),
		corridor:getAccessData(2):getDirection()
	)

	local lastVertexModel =
		roomDataSet:getSimpleUniformTiles(accessType, lastVertexDirection)[1]:getModel():Clone()
	lastVertexModel:PivotTo(
		lastVertexModel:GetPivot() + cellSize * (corridor:getVertex(lastVertexNum))
	)
	lastVertexModel.Name = "vx#" .. tostring(lastVertexNum) .. "_cell#1"

	debugPaintModel(lastVertexModel, color)

	lastVertexModel.Parent = model

	return model
end

local function createCorridorStorageModel(
	cellSize: number,
	roomDataSet: RoomDataSet.RoomDataSet,
	corridorStorage: CorridorStorage.CorridorStorage
)
	local anchor = Instance.new("Part")
	anchor.Size = Vector3.zero
	anchor.Name = "primary"
	anchor.Anchored = true
	anchor.CanCollide = false
	-- anchor.Transparency = 1
	anchor.Position = Vector3.zero

	local storageModel = Instance.new("Model")
	anchor.Parent = storageModel
	storageModel.PrimaryPart = anchor

	for i, corridor in corridorStorage:iterateCorridor() do
		local corridorModel = createCorridorModel(cellSize, roomDataSet, corridor)

		corridorModel.Name = "corridor#" .. tostring(i)
		corridorModel.Parent = storageModel
	end

	return storageModel
end

local function createRoomStorageModel(
	cellSize: number,
	roomDataSet: RoomDataSet.RoomDataSet,
	roomStorage: RoomStorage.RoomStorage
)
	local anchor = Instance.new("Part")
	anchor.Size = Vector3.zero
	anchor.Name = "primary"
	anchor.Anchored = true
	anchor.CanCollide = false
	-- anchor.Transparency = 1
	anchor.Position = Vector3.zero

	local storageModel = Instance.new("Model")
	anchor.Parent = storageModel
	storageModel.PrimaryPart = anchor

	for i, room in roomStorage:iterateRoom() do
		local roomModel = room:getRoomData():getModel():Clone()
		roomModel:PivotTo(roomModel:GetPivot() + (cellSize * (room:getPos() + room:getSize() / 2)))

		roomModel.Name = "room#" .. tostring(i)
		print(roomModel.Name .. ": " .. room:getRoomData():getName())
		roomModel.Parent = storageModel
	end

	return storageModel
end

local function createGenerated(
	cellSize: number,
	worldPos: CFrame,
	roomDataSet: RoomDataSet.RoomDataSet,
	corridorStorage: CorridorStorage.CorridorStorage,
	roomStorage: RoomStorage.RoomStorage
)
	local model = Instance.new("Model")
	model.Name = "generated"

	local corridorsModel = createCorridorStorageModel(cellSize, roomDataSet, corridorStorage)
	local roomsModel = createRoomStorageModel(cellSize, roomDataSet, roomStorage)

	corridorsModel.Parent = model
	roomsModel.Parent = model

	model.PrimaryPart = roomsModel.PrimaryPart
	model:PivotTo(CFrame.new(worldPos))

	return model
end

return {
	createCorridorModel = createCorridorModel,
	createCorridorStorageModel = createCorridorStorageModel,
	createRoomStorageModel = createRoomStorageModel,
	createGenerated = createGenerated,
}
