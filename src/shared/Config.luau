local Config = {
	GameName = "Mail After Midnight",
	MaxPlayers = 4,

	Round = {
		PreparationDuration = 10,
		ActiveDuration = 6 * 60,
		ResultsDuration = 20,
		FirstParcelDelay = 10,
		SoloSpawnIntervalMin = 12,
		SoloSpawnIntervalMax = 16,
		MaxQueuedParcels = 3,
		ClaimDuration = 15,
		MaxMistakes = 5,
	},

	Rewards = {
		CorrectParcelTokens = 2,
		TimedCompletionBonus = 10,
		CosmeticPrices = table.freeze({ 50, 100 }),
	},

	Events = {
		MinimumInterval = 60,
		MinimumDuration = 10,
		MaximumDuration = 20,
		TutorialProtectionDuration = 60,
	},

	Network = {
		RequestWindow = 1,
		MaxRequestsPerWindow = 8,
	},
}

table.freeze(Config.Round)
table.freeze(Config.Rewards)
table.freeze(Config.Events)
table.freeze(Config.Network)

return table.freeze(Config)
