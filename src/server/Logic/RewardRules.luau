--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Protocol = require(ReplicatedStorage.Shared.Protocol)

local RewardRules = {}

function RewardRules.forParcel(isCorrect: boolean): number
	assert(type(isCorrect) == "boolean", "isCorrect must be a boolean")
	return if isCorrect then Config.Rewards.CorrectParcelTokens else 0
end

function RewardRules.forRound(endReason: string): number
	assert(type(endReason) == "string", "endReason must be a string")
	return if endReason == Protocol.EndReasons.Time then Config.Rewards.TimedCompletionBonus else 0
end

return table.freeze(RewardRules)
