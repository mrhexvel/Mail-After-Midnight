local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameView = require(script.Parent.Parent.UI.GameView)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local Strings = require(ReplicatedStorage.Shared.Strings)

local GameController = {}

function GameController.start()
	local player = Players.LocalPlayer
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local actionRemote = remotes:WaitForChild("GameAction") :: RemoteEvent
	local eventRemote = remotes:WaitForChild("GameEvent") :: RemoteEvent
	local getSnapshot = remotes:WaitForChild("GetSnapshot") :: RemoteFunction
	local view = GameView.new(player:WaitForChild("PlayerGui") :: PlayerGui)
	local camera = workspace.CurrentCamera
	local currentSnapshot = nil

	local function updateViewport()
		if camera then
			view:setViewportSize(camera.ViewportSize)
		end
	end
	updateViewport()
	if camera then
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateViewport)
	end

	view:setCallbacks(function(parcelId, action)
		actionRemote:FireServer(Protocol.Commands.ResolveParcel, {
			parcelId = parcelId,
			action = action,
		})
	end, function()
		actionRemote:FireServer(Protocol.Commands.Replay)
	end)

	eventRemote.OnClientEvent:Connect(function(message, payload)
		if message == Protocol.Messages.State and type(payload) == "table" then
			currentSnapshot = payload
			view:render(payload)
		elseif message == Protocol.Messages.Feedback and type(payload) == "table" then
			view:showFeedback(payload.correct == true, Strings.Reason[payload.reason] or "")
		elseif message == Protocol.Messages.Notice and type(payload) == "table" then
			view:showNotice(Strings.Notice[payload.key] or Strings.Notice.invalidRequest)
		end
	end)

	local ok, snapshot = pcall(function()
		return getSnapshot:InvokeServer()
	end)
	if ok and type(snapshot) == "table" then
		currentSnapshot = snapshot
		view:render(snapshot)
	else
		view:showNotice(Strings.Notice.invalidRequest)
	end

	task.spawn(function()
		while true do
			if currentSnapshot and currentSnapshot.phaseEndsAt then
				view:setTimer(currentSnapshot.phaseEndsAt - workspace:GetServerTimeNow())
			end
			task.wait(0.1)
		end
	end)
end

return table.freeze(GameController)
