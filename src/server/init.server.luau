local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

workspace:WaitForChild("SortingRoom")
print(string.format("[%s] Stage 0 room ready", Config.GameName))
