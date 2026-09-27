--!strict

local Protocol = {
	Commands = table.freeze({
		ResolveParcel = "resolveParcel",
		Replay = "replay",
	}),
	Messages = table.freeze({
		State = "state",
		Feedback = "feedback",
		Notice = "notice",
	}),
	Phases = table.freeze({
		Idle = "idle",
		Preparation = "preparation",
		Active = "active",
		Results = "results",
	}),
	EndReasons = table.freeze({
		Time = "time",
		Mistakes = "mistakes",
	}),
}

return table.freeze(Protocol)
