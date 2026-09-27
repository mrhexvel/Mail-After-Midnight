--!strict

local Actions = {
	Send = "send",
	Return = "return",
	Isolate = "isolate",
}

export type Action = "send" | "return" | "isolate"

function Actions.isValid(value: unknown): boolean
	return value == Actions.Send or value == Actions.Return or value == Actions.Isolate
end

return table.freeze(Actions)
