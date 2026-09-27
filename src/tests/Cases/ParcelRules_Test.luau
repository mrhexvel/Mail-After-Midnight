return function(t)
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Actions = require(ReplicatedStorage.Shared.Actions)
	local ParcelRules = require(ReplicatedStorage.Shared.ParcelRules)
	local expect = t.expect

	local function parcel(overrides)
		local data = {
			district = "A",
			hasStamp = true,
			seal = "normal",
			isMoving = false,
		}
		for key, value in overrides or {} do
			data[key] = value
		end
		return data
	end

	-- A safe parcel with a valid district and stamp is sent.
	t.test("sends a fully valid parcel", function()
		local result = ParcelRules.evaluate(parcel())
		expect.equal(result.action, Actions.Send)
		expect.equal(result.reason, ParcelRules.Reasons.ReadyToSend)
	end)

	-- A missing stamp returns an otherwise safe parcel.
	t.test("returns a parcel with no stamp", function()
		local result = ParcelRules.evaluate(parcel({ hasStamp = false }))
		expect.equal(result.action, Actions.Return)
		expect.equal(result.reason, ParcelRules.Reasons.MissingStamp)
	end)

	-- An unknown district returns an otherwise safe parcel.
	t.test("returns a parcel from an unknown district", function()
		local result = ParcelRules.evaluate(parcel({ district = "X" }))
		expect.equal(result.action, Actions.Return)
		expect.equal(result.reason, ParcelRules.Reasons.UnknownDistrict)
	end)

	-- A red seal overrides the missing-stamp return rule.
	t.test("red seal takes priority over missing stamp", function()
		local result = ParcelRules.evaluate(parcel({ hasStamp = false, seal = "red" }))
		expect.equal(result.action, Actions.Isolate)
		expect.equal(result.reason, ParcelRules.Reasons.RedSeal)
	end)

	-- Movement overrides the unknown-district return rule.
	t.test("movement takes priority over unknown district", function()
		local result = ParcelRules.evaluate(parcel({ district = "Z", isMoving = true }))
		expect.equal(result.action, Actions.Isolate)
		expect.equal(result.reason, ParcelRules.Reasons.Moving)
	end)

	-- Invalid seal values fail instead of silently choosing an answer.
	t.test("rejects an invalid seal", function()
		expect.throws(function()
			ParcelRules.evaluate(parcel({ seal = "green" }))
		end)
	end)
end
