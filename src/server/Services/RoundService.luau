local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Actions = require(ReplicatedStorage.Shared.Actions)
local Config = require(ReplicatedStorage.Shared.Config)
local ParcelRules = require(ReplicatedStorage.Shared.ParcelRules)
local Protocol = require(ReplicatedStorage.Shared.Protocol)

local ServerRoot = script.Parent.Parent
local ParcelService = require(script.Parent.ParcelService)
local ParcelTemplates = require(ServerRoot.Data.ParcelTemplates)
local RewardRules = require(ServerRoot.Logic.RewardRules)

type PlayerStats = {
	correct: number,
	errors: number,
	tokens: number,
}

type RateState = {
	windowStarted: number,
	count: number,
}

local RoundService = {}
RoundService.__index = RoundService

function RoundService.new(remotes, room: Model)
	local self = setmetatable({}, RoundService)
	self._remotes = remotes
	self._room = room
	self._phase = Protocol.Phases.Idle
	self._phaseEndsAt = 0
	self._roundId = 0
	self._generation = 0
	self._mistakes = 0
	self._teamCorrect = 0
	self._endReason = nil :: string?
	self._stats = {} :: { [Player]: PlayerStats }
	self._rate = {} :: { [Player]: RateState }
	self._random = Random.new()

	for _, template in ParcelTemplates do
		local evaluation = ParcelRules.evaluate(template)
		assert(
			evaluation.action == template.expectedAction,
			string.format("Template %s has incorrect expectedAction", template.id)
		)
		assert(
			evaluation.reason == template.expectedReason,
			string.format("Template %s has incorrect expectedReason", template.id)
		)
	end

	self._parcelService = ParcelService.new(room, ParcelTemplates, function()
		self:_broadcastState()
	end, function(player, notice)
		self:_sendNotice(player, notice)
	end)

	return self
end

function RoundService:_ensureStats(player: Player): PlayerStats
	local stats = self._stats[player]
	if not stats then
		stats = { correct = 0, errors = 0, tokens = 0 }
		self._stats[player] = stats
	end
	return stats
end

function RoundService:_makeSnapshot(player: Player): { [string]: any }
	local stats = self:_ensureStats(player)
	return {
		phase = self._phase,
		phaseEndsAt = self._phaseEndsAt,
		serverNow = workspace:GetServerTimeNow(),
		roundId = self._roundId,
		mistakes = self._mistakes,
		maxMistakes = Config.Round.MaxMistakes,
		correct = stats.correct,
		errors = stats.errors,
		tokens = stats.tokens,
		teamCorrect = self._teamCorrect,
		endReason = self._endReason,
		parcelAvailable = self._parcelService:hasActive(),
		parcel = self._parcelService:getViewFor(player),
	}
end

function RoundService:_sendState(player: Player)
	self._remotes.event:FireClient(player, Protocol.Messages.State, self:_makeSnapshot(player))
end

function RoundService:_broadcastState()
	for _, player in Players:GetPlayers() do
		self:_sendState(player)
	end
end

function RoundService:_sendNotice(player: Player, notice: string)
	self._remotes.event:FireClient(player, Protocol.Messages.Notice, { key = notice })
end

function RoundService:_resetStats()
	self._mistakes = 0
	self._teamCorrect = 0
	self._endReason = nil
	for _, player in Players:GetPlayers() do
		self._stats[player] = { correct = 0, errors = 0, tokens = 0 }
	end
end

function RoundService:_beginPreparation()
	self._generation += 1
	local generation = self._generation
	self._roundId += 1
	self._parcelService:clear()
	self:_resetStats()
	self._phase = Protocol.Phases.Preparation
	self._phaseEndsAt = workspace:GetServerTimeNow() + Config.Round.PreparationDuration
	self:_broadcastState()

	task.delay(Config.Round.PreparationDuration, function()
		if self._generation == generation and self._phase == Protocol.Phases.Preparation then
			self:_beginActive(generation)
		end
	end)
end

function RoundService:_spawnParcel(generation: number)
	if self._generation == generation and self._phase == Protocol.Phases.Active then
		self._parcelService:spawn(self._roundId)
	end
end

function RoundService:_scheduleNextParcel(generation: number)
	local delaySeconds = self._random:NextNumber(Config.Round.SoloSpawnIntervalMin, Config.Round.SoloSpawnIntervalMax)
	task.delay(delaySeconds, function()
		self:_spawnParcel(generation)
	end)
end

function RoundService:_beginActive(generation: number)
	self._phase = Protocol.Phases.Active
	self._phaseEndsAt = workspace:GetServerTimeNow() + Config.Round.ActiveDuration
	self:_broadcastState()
	task.delay(Config.Round.FirstParcelDelay, function()
		self:_spawnParcel(generation)
	end)

	task.delay(Config.Round.ActiveDuration, function()
		if self._generation == generation and self._phase == Protocol.Phases.Active then
			self:_finishRound(Protocol.EndReasons.Time)
		end
	end)
end

function RoundService:_finishRound(reason: string)
	if self._phase ~= Protocol.Phases.Active then
		return
	end

	self._generation += 1
	local generation = self._generation
	self._parcelService:clear()
	self._phase = Protocol.Phases.Results
	self._phaseEndsAt = workspace:GetServerTimeNow() + Config.Round.ResultsDuration
	self._endReason = reason

	local completionBonus = RewardRules.forRound(reason)
	if completionBonus > 0 then
		for _, player in Players:GetPlayers() do
			self:_ensureStats(player).tokens += completionBonus
		end
	end
	self:_broadcastState()

	task.delay(Config.Round.ResultsDuration, function()
		if self._generation == generation and self._phase == Protocol.Phases.Results then
			if #Players:GetPlayers() > 0 then
				self:_beginPreparation()
			else
				self._phase = Protocol.Phases.Idle
				self._phaseEndsAt = 0
			end
		end
	end)
end

function RoundService:_allowRequest(player: Player): boolean
	local now = os.clock()
	local state = self._rate[player]
	if not state or now - state.windowStarted >= Config.Network.RequestWindow then
		self._rate[player] = { windowStarted = now, count = 1 }
		return true
	end

	state.count += 1
	return state.count <= Config.Network.MaxRequestsPerWindow
end

function RoundService:_resolveParcel(player: Player, payload: unknown)
	if self._phase ~= Protocol.Phases.Active or type(payload) ~= "table" then
		self:_sendNotice(player, "invalidRequest")
		return
	end

	local parcelId = payload.parcelId
	local action = payload.action
	if type(parcelId) ~= "string" or not Actions.isValid(action) then
		self:_sendNotice(player, "invalidRequest")
		return
	end

	local template, resolveError = self._parcelService:tryResolve(player, parcelId)
	if not template then
		self:_sendNotice(player, resolveError or "parcelUnavailable")
		return
	end

	local evaluation = ParcelRules.evaluate(template)
	local isCorrect = action == evaluation.action
	local stats = self:_ensureStats(player)
	local tokenReward = RewardRules.forParcel(isCorrect)
	stats.tokens += tokenReward
	if isCorrect then
		stats.correct += 1
		self._teamCorrect += 1
	else
		stats.errors += 1
		self._mistakes += 1
	end

	self._remotes.event:FireClient(player, Protocol.Messages.Feedback, {
		correct = isCorrect,
		reason = evaluation.reason,
		tokensAwarded = tokenReward,
	})

	if self._mistakes >= Config.Round.MaxMistakes then
		self:_finishRound(Protocol.EndReasons.Mistakes)
	else
		self:_broadcastState()
		self:_scheduleNextParcel(self._generation)
	end
end

function RoundService:_handleAction(player: Player, command: unknown, payload: unknown)
	if not self:_allowRequest(player) then
		return
	end
	if type(command) ~= "string" then
		self:_sendNotice(player, "invalidRequest")
		return
	end

	if command == Protocol.Commands.ResolveParcel then
		self:_resolveParcel(player, payload)
	elseif command == Protocol.Commands.Replay and self._phase == Protocol.Phases.Results then
		self:_beginPreparation()
	else
		self:_sendNotice(player, "invalidRequest")
	end
end

function RoundService:start()
	self._remotes.getSnapshot.OnServerInvoke = function(player)
		if not self:_allowRequest(player) then
			return nil
		end
		return self:_makeSnapshot(player)
	end
	self._remotes.action.OnServerEvent:Connect(function(player, command, payload)
		self:_handleAction(player, command, payload)
	end)

	Players.PlayerAdded:Connect(function(player)
		self:_ensureStats(player)
		if self._phase == Protocol.Phases.Idle then
			self:_beginPreparation()
		else
			task.defer(function()
				self:_sendState(player)
			end)
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		self._parcelService:releaseClaim(player)
		self._stats[player] = nil
		self._rate[player] = nil
	end)

	for _, player in Players:GetPlayers() do
		self:_ensureStats(player)
	end
	if #Players:GetPlayers() > 0 then
		self:_beginPreparation()
	end
end

return RoundService
