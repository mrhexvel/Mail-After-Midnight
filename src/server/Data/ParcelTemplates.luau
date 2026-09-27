--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Actions = require(ReplicatedStorage.Shared.Actions)
local ParcelRules = require(ReplicatedStorage.Shared.ParcelRules)

local templates = {
	{
		id = "valid_a_blue",
		district = "A",
		hasStamp = true,
		seal = "normal",
		isMoving = false,
		appearance = { color = Color3.fromRGB(151, 103, 58) },
		expectedAction = Actions.Send,
		expectedReason = ParcelRules.Reasons.ReadyToSend,
	},
	{
		id = "missing_stamp_b",
		district = "B",
		hasStamp = false,
		seal = "normal",
		isMoving = false,
		appearance = { color = Color3.fromRGB(127, 91, 62) },
		expectedAction = Actions.Return,
		expectedReason = ParcelRules.Reasons.MissingStamp,
	},
	{
		id = "unknown_district_x",
		district = "X",
		hasStamp = true,
		seal = "normal",
		isMoving = false,
		appearance = { color = Color3.fromRGB(171, 132, 83) },
		expectedAction = Actions.Return,
		expectedReason = ParcelRules.Reasons.UnknownDistrict,
	},
	{
		id = "red_seal_no_stamp",
		district = "C",
		hasStamp = false,
		seal = "red",
		isMoving = false,
		appearance = { color = Color3.fromRGB(104, 76, 54) },
		expectedAction = Actions.Isolate,
		expectedReason = ParcelRules.Reasons.RedSeal,
	},
	{
		id = "moving_unknown_district",
		district = "Z",
		hasStamp = true,
		seal = "normal",
		isMoving = true,
		appearance = { color = Color3.fromRGB(139, 112, 79) },
		expectedAction = Actions.Isolate,
		expectedReason = ParcelRules.Reasons.Moving,
	},
}

for _, template in templates do
	table.freeze(template.appearance)
	table.freeze(template)
end

return table.freeze(templates)
