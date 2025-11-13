local Corridor = require(script.Parent.Corridor)

local Directions = require(script.Parent.Parent.Parent.gen_data.Directions)
local FlagGrid = require(script.Parent.Parent.Parent.gen_data.FlagGrid)
local AccessData = require(script.Parent.Parent.Parent.gen_setting.access.AccessData)
local DeadEndTileRoomData =
	require(script.Parent.Parent.Parent.gen_setting.corridor_tile.uniform.DeadEndTileRoomData)
local Access = require(script.Parent.Parent.access.Access)
local RoomData = require(script.Parent.Parent.Parent.gen_setting.room.RoomData)
local Room = require(script.Parent.Parent.room.Room)

local TEST_ACCESS_1 = AccessData.new(1, Vector3.new(0, 0, 0), Directions.EAST)
local TEST_ACCESS_2 = AccessData.new(1, Vector3.new(0, 0, 0), Directions.WEST)

local TEST_ROOM_1 = RoomData.new("test_1", Vector3.new(0, 0, 0), { TEST_ACCESS_1 })
local TEST_ROOM_2 = RoomData.new("test_2", Vector3.new(0, 0, 0), { TEST_ACCESS_2 })
local TEST_ROOM_3 = RoomData.new("test_2", Vector3.new(0, 0, 0), { TEST_ACCESS_1, TEST_ACCESS_2 })

local TEST_WRAPPED_1 = Room.new(Vector3.new(1, 2, 8), TEST_ROOM_1)
local TEST_WRAPPED_2 = Room.new(Vector3.new(11, 2, 2), TEST_ROOM_2)
local TEST_WRAPPED_3 = Room.new(Vector3.new(6, 2, 2), TEST_ROOM_3)

return function()
	local firstAccess: Access.Access = TEST_ACCESS_1:wrap(TEST_WRAPPED_1) -- 2, 2, 8
	local secondAccess: Access.Access = TEST_ACCESS_2:wrap(TEST_WRAPPED_2) -- 10, 2, 2
	local corridor: Corridor.Corridor

	beforeEach(function()
		corridor = Corridor.new(firstAccess, secondAccess)
		corridor:addVertex(2) -- 2, 2, 2
		corridor:setVertex(
			2,
			Vector3.new(
				firstAccess.x + firstAccess.direction.X,
				firstAccess.y + firstAccess.direction.Y,
				secondAccess.z + secondAccess.direction.Z
			)
		)
	end)

	describe("Corridor", function()
		it("should return the pos of the first access for the position of the corridor", function()
			expect(corridor:getPos()).to.equal(
				Vector3.new(
					firstAccess.x + firstAccess.direction.X,
					firstAccess.y + firstAccess.direction.Y,
					firstAccess.z + firstAccess.direction.Z
				)
			)
		end)
		it("should handle adjacents rooms", function()
			corridor:setAdjacent(TEST_WRAPPED_1, 1, TEST_ACCESS_1)
			expect(corridor:getAccessData(1)).to.equal(TEST_ACCESS_1)
			corridor:setAdjacent(TEST_WRAPPED_2, 1, TEST_ACCESS_2)
			expect(corridor:getAccessData(1)).to.equal(TEST_ACCESS_2)
			corridor:setAdjacent(TEST_WRAPPED_1, 2, TEST_ACCESS_1)
			expect(corridor:getAccessData(2)).to.equal(TEST_ACCESS_1)

			local i = 0
			for _ in corridor:iterateAdjacents() do
				i += 1
			end
			expect(i).to.equal(2)
		end)
		it("should retrurn its vertices", function()
			expect(corridor:getVertex(1)).to.be.ok()
			expect(corridor:getVertex(2)).to.be.ok()
			expect(corridor:getVertex(3)).to.be.ok()
		end)
		it("should return the amount of vertices it has", function()
			expect(corridor:getVertexAmount()).to.equal(3)
			corridor:addVertex(2)
			expect(corridor:getVertexAmount()).to.equal(4)
		end)
		it("should mododify a vertex pos", function()
			corridor:addVertex(2)
			corridor:setVertex(
				2,
				Vector3.new(
					firstAccess.x + firstAccess.direction.X,
					firstAccess.y + firstAccess.direction.Y,
					secondAccess.z + firstAccess.direction.Z + 2
				)
			)

			expect(corridor:getVertex(2)).to.equal(
				Vector3.new(
					firstAccess.x + firstAccess.direction.X,
					firstAccess.y + firstAccess.direction.Y,
					secondAccess.z + firstAccess.direction.Z + 2
				)
			)
		end)
		it("should be able to invert a vertex", function()
			corridor:invert(2)

			expect(corridor:getVertex(2)).to.equal(
				Vector3.new(
					secondAccess.x + secondAccess.direction.X,
					secondAccess.y + secondAccess.direction.Y,
					firstAccess.z + firstAccess.direction.Z
				)
			)
		end)
		it("should iterate all the vertices", function()
			corridor:addVertex(2)

			local i = 0
			for _ in corridor:iterateVertices() do
				i += 1
			end

			expect(i).to.equal(4)
		end)
		it("should iterate all the middle vertices", function()
			corridor:addVertex(2)
			corridor:addVertex(2)

			local i = 0
			for _, v in corridor:iterateMiddleVertices() do
				i += 1
			end

			expect(i).to.equal(3)
		end)
		it("should return the first collision in the grid", function()
			local grid = FlagGrid.new(10, 2, 12)
			local collision1 = Vector3.new(7, 2, 2)
			local collision2 = Vector3.new(2, 2, 7)

			grid:set(collision1.X, collision1.Y, collision1.Z)
			expect(corridor:getFirstCollision(grid)).to.equal(collision1)
			grid:set(collision2.X, collision2.Y, collision2.Z)
			expect(corridor:getFirstCollision(grid)).to.equal(collision2)

			corridor:addVertex(3)
			corridor:setVertex(2, corridor:getVertex(2) + Vector3.new(0, 0, 4))
			local vx2, vx4 = corridor:getVertex(2), corridor:getVertex(4)
			corridor:setVertex(3, Vector3.new(vx4.X, vx2.Y, vx2.Z))

			local collision3 = Vector3.new(5, 2, 6)

			expect(corridor:getFirstCollision(grid)).to.equal(collision2)
			grid:reset(collision2.X, collision2.Y, collision2.Z)
			expect(corridor:getFirstCollision(grid)).to.equal(nil)

			grid:set(collision3.X, collision3.Y, collision3.Z)
			expect(corridor:getFirstCollision(grid)).to.equal(collision3)
		end)
		it("should check if a cell is included in the corridor", function()
			local c1 = Vector3.new(7, 2, 2)
			local c2 = Vector3.new(2, 2, 7)
			local c3 = Vector3.new(5, 2, 6)

			expect(corridor:isIncludingCell(c1)).to.equal(true)
			expect(corridor:isIncludingCell(c2)).to.equal(true)
			expect(corridor:isIncludingCell(c3)).to.equal(false)

			corridor:addVertex(3)
			corridor:setVertex(2, corridor:getVertex(2) + Vector3.new(0, 0, 4))
			local vx2, vx4 = corridor:getVertex(2), corridor:getVertex(4)
			corridor:setVertex(3, Vector3.new(vx4.X, vx2.Y, vx2.Z))

			expect(corridor:isIncludingCell(c1)).to.equal(false)
			expect(corridor:isIncludingCell(c2)).to.equal(true)
			expect(corridor:isIncludingCell(c3)).to.equal(true)
		end)
		it("should be able to divide itself into two corridor", function()
			local newEndAccess = Access.createAccess(TEST_WRAPPED_3, TEST_ACCESS_2, 6, 2, 2)
			local newStartAccess = Access.createAccess(TEST_WRAPPED_3, TEST_ACCESS_1, 6, 2, 2)

			local secondCorridor = corridor:divide(newEndAccess, newStartAccess)
			expect(corridor:getVertex(1)).to.equal(Vector3.new(2, 2, 8))
			expect(corridor:getVertex(2)).to.equal(Vector3.new(2, 2, 2))
			expect(corridor:getVertex(3)).to.equal(Vector3.new(5, 2, 2))

			expect(secondCorridor:getVertex(1)).to.equal(Vector3.new(7, 2, 2))
			expect(secondCorridor:getVertex(2)).to.equal(Vector3.new(10, 2, 2))
		end)
		it("should return one of its accesses", function()
			expect(corridor:getAccessData(1)).to.equal(TEST_ACCESS_1)
			expect(corridor:getAccessData(2)).to.equal(TEST_ACCESS_2)
		end)
		it("should return the start direction of a vertex", function()
			expect(corridor:getVertexStartingDirection(2)).to.equal(Directions.NORTH)
		end)
		it("should return the end direction of a vertex", function()
			expect(corridor:getVertexEndingDirection(2)).to.equal(Directions.EAST)
		end)
		it("should make its vertex a deadEnd", function()
			local deadEndData =
				DeadEndTileRoomData.new(Directions.NORTH, 1, 1, Instance.new("Model"))

			local vertex = corridor:getVertex(2)
			local deadEndRoom = corridor:makeDeadEnd(deadEndData, 2)

			expect(corridor:getAccessData(2):getDirection()).to.equal(Directions.NORTH)
			expect(corridor:getVertexAmount()).to.equal(2)
			expect(corridor:getVertex(2)).to.equal(
				deadEndRoom:getPos() + deadEndData:getDirection()
			)
			expect(deadEndRoom:getPos()).to.equal(vertex)
			expect(deadEndRoom:getRoomData()).to.equal(deadEndData)
			expect(deadEndRoom:getSize()).to.equal(Vector3.zero)
		end)
		describe("FlagGrid actions", function()
			it("should add itself onto a flagGrid", function()
				local grid = FlagGrid.new(10, 10, 10)
				corridor:addOnGrid(grid)

				expect(grid:volumeAnd(2, 2, 2, 2, 2, 8)).to.equal(true)
				expect(grid:volumeAnd(2, 2, 2, 10, 2, 2)).to.equal(true)
			end)
			it("should remove itself onto a flagGrid", function()
				local grid = FlagGrid.new(10, 10, 10)
				corridor:addOnGrid(grid)
				corridor:removeFromGrid(grid)

				expect(grid:volumeAnd(2, 2, 2, 2, 2, 8)).to.equal(false)
				expect(grid:volumeAnd(2, 2, 2, 10, 2, 2)).to.equal(false)
			end)
		end)
		it("should check if the corridor is ok", function()
			expect(corridor:isOk()).to.equal(true)

			corridor:addVertex(3)
			corridor:setVertex(3, Vector3.new(5, 2, 4))
			expect(corridor:isOk()).to.equal(false)

			corridor:setVertex(3, Vector3.new(5, 2, 2))
			expect(corridor:isOk()).to.equal(true)
		end)
	end)
end
