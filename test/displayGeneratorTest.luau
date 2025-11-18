local DisplayUtils = require(script.Parent.DisplayUtils)
local Generator = require(script.Parent.Parent.LiminalGenerator.algorithm.Generator)
local AccessConnectStack =
	require(script.Parent.Parent.LiminalGenerator.gen_data.AccessConnectStack)
local FlagGrid = require(script.Parent.Parent.LiminalGenerator.gen_data.FlagGrid)
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

	local result: RoomStorage.RoomStorage
	if deltaStepTime == 0 then
		result = generator:generate(size.X, size.Y, size.Z, false)
	else
		local generatorCoroutine = coroutine.create(generator.generate)

		local roomGridFolder, corridorGridFolder, accessFolder =
			Instance.new("Folder"), Instance.new("Folder"), Instance.new("Folder")

		local corridorColorDict = {}

		local firstIteration = true
		while true do
			-- Prevent wainting on the first iteration when nothing is done
			if not firstIteration then
				wait(deltaStepTime)
			else
				firstIteration = false
			end

			local ok, roomGrid: FlagGrid.FlagGrid | RoomStorage.RoomStorage | string, corridorStorage: CorridorStorage.CorridorStorage?, accessConnectStack: AccessConnectStack.AccessConnectStack?, newCorridor: Corridor.Corridor? =
				coroutine.resume(generatorCoroutine, generator, size.X, size.Y, size.Z, true)

			if coroutine.status(generatorCoroutine) == "dead" then
				print("thread died")

				if not ok then
					error(roomGrid)
				end

				result = roomGrid -- as roomGrid, here, is the RoomStorage

				break
			end

			print("actual AccessConnectStack size: " .. accessConnectStack:getSize())

			roomGridFolder:Destroy()
			roomGridFolder = DisplayUtils.createFlag2DGrid(roomGrid, worldPos, cellSize)
			roomGridFolder.Name = "room_grid"
			roomGridFolder.Parent = generatorFolder

			if accessConnectStack ~= nil then
				accessFolder:Destroy()

				accessFolder = DisplayUtils.createSelective2dGrid(
					accessConnectStack:getGrid(),
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

			local folder = generatorFolder:FindFirstChild("new_corridor")
			if folder ~= nil then
				folder:Destroy()
			end

			if newCorridor ~= nil then
				folder = Instance.new("Folder")
				folder.Name = "new_corridor"

				DisplayUtils.plotCorridor(worldPos, cellSize, corridorGridFolder, newCorridor)

				folder.Parent = generatorFolder
			end
		end
	end

	if result == nil then
		warn("Unable to recreate the generated world as we got a nil result.")
	end

	-- Recreate the roomGrid from the RoomStorage
	local roomGrid = FlagGrid.new(size.X, size.Y, size.Z)

	for _, room in result:iterateRoom() do
		local pos = room:getPos()
		local maxPos = pos + room:getSize()

		roomGrid:volumeSet(pos.X, pos.Y, pos.Z, maxPos.X, maxPos.Y, maxPos.Z)
	end

	local folder = DisplayUtils.createFlag2DGrid(roomGrid, worldPos, cellSize)
	folder.Name = "generated"
	folder.Parent = generatorFolder
end
