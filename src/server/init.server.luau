local NetworkService = require(script.Services.NetworkService)
local RoundService = require(script.Services.RoundService)

local room = workspace:WaitForChild("SortingRoom")
local remotes = NetworkService.create()
local roundService = RoundService.new(remotes, room)

roundService:start()
