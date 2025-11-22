local DisplayUtils = require(script.Parent.DisplayUtils)
local Generator = require(script.Parent.Parent.LiminalGenerator.algorithm.Generator)
local FlagGrid = require(script.Parent.Parent.LiminalGenerator.gen_data.FlagGrid)
local AccessConnectStorage =
	require(script.Parent.Parent.LiminalGenerator.gen_data.storage.AccessConnectStorage)
local CorridorStorage =
	require(script.Parent.Parent.LiminalGenerator.gen_data.storage.CorridorStorage)
local RoomStorage = require(script.Parent.Parent.LiminalGenerator.gen_data.storage.RoomStorage)
local Corridor = require(script.Parent.Parent.LiminalGenerator.gen_elements.corridor.Corridor)

return function(
	worldPos: Vector3,
	cellSize: number,
	size: Vector3,
	seed,
	genSettings,
	setData,
	deltaStepTime: number
)
	local generator = Generator.new(seed, genSettings, setData)
	local generatorFolder = Instance.new("Folder")
	generatorFolder.Name = "generator_test"
	generatorFolder.Parent = workspace

	if deltaStepTime == 0 then
		local roomStorage, corridorStorage = generator:generate(size.X, size.Y, size.Z, false)

		-- Display the rooms
		if roomStorage ~= nil then
			local roomGrid = FlagGrid.new(size.X, size.Y, size.Z)

			for _, room in roomStorage:iterateRoom() do
				local p1 = room:getPos()
				local p2 = room:getPos() + room:getSize()
				roomGrid:volumeSet(p1.X, p1.Y, p1.Z, p2.X, p2.Y, p2.Z)
			end

			local roomFolder = Instance.new("Folder")

			roomFolder = DisplayUtils.createFlag2DGrid(roomGrid, worldPos, cellSize)
			roomFolder.Name = "room_grid"
			roomFolder.Parent = generatorFolder
		end

		-- Plot the corridors
		if corridorStorage ~= nil then
			local corridorFolder = Instance.new("Folder")
			corridorFolder = DisplayUtils.plotCorridorStorage(
				worldPos,
				cellSize,
				corridorStorage,
				nil,
				nil,
				2,
				0.5,
				0.5,
				corridorFolder
			)

			corridorFolder.Name = "corridor_grid"
			corridorFolder.Parent = generatorFolder
		end
	else
		local generatorCoroutine = coroutine.create(generator.generate)

		local roomGridFolder = Instance.new("Folder")
		local corridorGridFolder = Instance.new("Folder")
		local accessFolder = Instance.new("Folder")
		local adjacentsFolder = Instance.new("Folder")

		local corridorColorDict = {}

		local firstIteration = true
		while true do
			-- Prevent wainting on the first iteration when nothing is done
			if not firstIteration then
				wait(deltaStepTime)
			else
				firstIteration = false
			end

			local ok, roomGrid: FlagGrid.FlagGrid, roomStorage: RoomStorage.RoomStorage | string, corridorStorage: CorridorStorage.CorridorStorage?, accessConnectStorage: AccessConnectStorage.AccessConnectStorage?, newCorridor: Corridor.Corridor? =
				coroutine.resume(generatorCoroutine, generator, size.X, size.Y, size.Z, true)

			if coroutine.status(generatorCoroutine) == "dead" then
				print("thread died")

				if not ok then
					error(roomGrid)
				end

				break
			end

			roomGridFolder:Destroy()
			roomGridFolder = DisplayUtils.createFlag2DGrid(roomGrid, worldPos, cellSize)
			roomGridFolder.Name = "room_grid"
			roomGridFolder.Parent = generatorFolder

			if accessConnectStorage ~= nil then
				print("actual AccessToConnect size: " .. accessConnectStorage:getToConnectSize())

				accessFolder:Destroy()

				accessFolder = DisplayUtils.createSelective2dGrid(
					accessConnectStorage:getGrid(),
					worldPos + Vector3.new(0, 0.5, 0),
					cellSize,
					0,
					Color3.fromRGB(253, 136, 27)
				)

				for _, part: Part in ipairs(accessFolder:GetChildren()) do
					part.Size = Vector3.new(cellSize / 3, cellSize / 3, cellSize / 3)
				end

				accessFolder.Name = "access_grid"
				accessFolder.Parent = generatorFolder
			end

			if corridorStorage ~= nil then
				corridorGridFolder:Destroy()
				corridorGridFolder = Instance.new("Folder")

				for _, corridor in corridorStorage:iterateCorridor() do
					if corridorColorDict[corridor] == nil then
						corridorColorDict[corridor] = Color3.fromRGB(
							math.random(0, 255),
							math.random(0, 255),
							math.random(0, 255)
						)
					end
				end

				corridorGridFolder = DisplayUtils.plotCorridorStorage(
					worldPos,
					cellSize,
					corridorStorage,
					nil,
					corridorColorDict,
					2,
					0.5,
					0.5,
					corridorGridFolder
				)

				corridorGridFolder.Name = "corridor_grid"
				corridorGridFolder.Parent = generatorFolder
			end

			local newCorridorFolder = generatorFolder:FindFirstChild("new_corridor")
			if newCorridorFolder ~= nil then
				newCorridorFolder:Destroy()
			end

			if newCorridor ~= nil then
				newCorridorFolder = Instance.new("Folder")
				newCorridorFolder.Name = "new_corridor"

				DisplayUtils.plotCorridor(worldPos, cellSize, corridorGridFolder, newCorridor)

				newCorridorFolder.Parent = generatorFolder
			end

			if corridorStorage ~= nil or roomStorage ~= nil then
				adjacentsFolder:Destroy()

				adjacentsFolder = DisplayUtils.plotAdjacents(
					worldPos + Vector3.new(0, 2, 0),
					cellSize,
					roomStorage,
					corridorStorage,
					nil,
					nil,
					0.5,
					0.2
				)
				adjacentsFolder.Name = "adjacents"
				adjacentsFolder.Parent = generatorFolder
			end
		end
	end
end
