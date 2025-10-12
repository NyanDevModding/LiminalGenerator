local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TestEZ = require(ReplicatedStorage.Packages.testez)

--* BE AWARE THAT CODE HERE WON'T BE RUN BY TESTEZ COMPANION
--* this will create weird results different from those in the studio console

TestEZ.TestBootstrap:run({
	ReplicatedStorage.Shared,
	nil,
	{
		noXpcallByDefault = true,
	},
})
