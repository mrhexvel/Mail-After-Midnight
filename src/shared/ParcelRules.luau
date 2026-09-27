local Actions = require(script.Parent.Actions)

local ParcelRules = {}

ParcelRules.Reasons = table.freeze({
	RedSeal = "redSeal",
	Moving = "moving",
	UnknownDistrict = "unknownDistrict",
	MissingStamp = "missingStamp",
	ReadyToSend = "readyToSend",
})

export type ParcelData = {
	district: string,
	hasStamp: boolean,
	seal: "normal" | "red",
	isMoving: boolean,
}

export type Evaluation = {
	action: Actions.Action,
	reason: string,
}

local VALID_DISTRICTS = table.freeze({
	A = true,
	B = true,
	C = true,
})

local function validate(data: ParcelData)
	assert(type(data) == "table", "parcel data must be a table")
	assert(type(data.district) == "string", "district must be a string")
	assert(type(data.hasStamp) == "boolean", "hasStamp must be a boolean")
	assert(data.seal == "normal" or data.seal == "red", "seal must be normal or red")
	assert(type(data.isMoving) == "boolean", "isMoving must be a boolean")
end

function ParcelRules.evaluate(data: ParcelData): Evaluation
	validate(data)

	if data.seal == "red" then
		return { action = Actions.Isolate, reason = ParcelRules.Reasons.RedSeal }
	end

	if data.isMoving then
		return { action = Actions.Isolate, reason = ParcelRules.Reasons.Moving }
	end

	if not VALID_DISTRICTS[data.district] then
		return { action = Actions.Return, reason = ParcelRules.Reasons.UnknownDistrict }
	end

	if not data.hasStamp then
		return { action = Actions.Return, reason = ParcelRules.Reasons.MissingStamp }
	end

	return { action = Actions.Send, reason = ParcelRules.Reasons.ReadyToSend }
end

return table.freeze(ParcelRules)
