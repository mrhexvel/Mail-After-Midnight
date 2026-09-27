--!strict

local Strings = {
	Phase = table.freeze({
		idle = "WAITING FOR WORKER",
		preparation = "SHIFT STARTS SOON",
		active = "NIGHT SHIFT",
		results = "SHIFT RESULTS",
	}),
	Action = table.freeze({
		send = ">> SEND",
		["return"] = "< RETURN",
		isolate = "! ISOLATE",
	}),
	Reason = table.freeze({
		redSeal = "Dangerous red seal. Isolate takes priority.",
		moving = "The parcel moved by itself. Isolate it.",
		unknownDistrict = "Unknown district. Return the parcel.",
		missingStamp = "The stamp field is empty. Return the parcel.",
		readyToSend = "District and stamp are valid. Send the parcel.",
	}),
	Notice = table.freeze({
		parcelBusy = "Another worker is examining this parcel.",
		parcelUnavailable = "That parcel is no longer available.",
		claimRequired = "Examine the parcel before choosing an action.",
		invalidRequest = "The request was rejected by the server.",
		tooManyRequests = "Please slow down and try again.",
	}),
	Rules = "ISOLATE: red seal OR moving parcel\nRETURN: unknown district OR missing stamp\nSEND: district A / B / C AND stamp present\n\nDanger rules always have priority.",
	ExaminePrompt = "Examine parcel",
	ParcelObject = "Incoming parcel",
	ParcelCardTitle = "PARCEL INSPECTION",
	NoParcel = "Walk to the incoming table and examine the parcel.",
	WaitingForParcel = "Waiting for the next parcel...",
	Correct = "CORRECT",
	Incorrect = "INCORRECT",
	TimedResult = "SHIFT COMPLETE",
	MistakeResult = "OFFICE CLOSED: TOO MANY ERRORS",
	Replay = "PLAY AGAIN",
	RulesButton = "RULES",
	ParcelLabel = "DISTRICT: %s\nSTAMP FIELD: %s\nSEAL: %s\nMOVEMENT: %s",
	Hud = table.freeze({
		Time = "TIME %s",
		Mistakes = "ERRORS %d/%d",
		Correct = "CORRECT %d",
		Tokens = "TOKENS %d",
	}),
	ParcelDetails = table.freeze({
		District = "DISTRICT: %s",
		Stamp = "STAMP FIELD: %s",
		Seal = "SEAL: %s",
		Movement = "MOVEMENT: %s",
	}),
	Results = table.freeze({
		Correct = "PERSONAL CORRECT: %d",
		Errors = "PERSONAL ERRORS: %d",
		TeamCorrect = "TEAM CORRECT: %d",
		Tokens = "TOKENS THIS SHIFT: %d",
	}),
}

return table.freeze(Strings)
