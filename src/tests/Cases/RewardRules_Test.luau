return function(t)
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Protocol = require(ReplicatedStorage.Shared.Protocol)
	local RewardRules = require(game.ServerScriptService.Server.Logic.RewardRules)
	local expect = t.expect

	-- A correct classification awards the configured parcel reward.
	t.test("awards two tokens for a correct parcel", function()
		expect.equal(RewardRules.forParcel(true), 2)
	end)

	-- An incorrect classification never awards parcel tokens.
	t.test("awards no tokens for an incorrect parcel", function()
		expect.equal(RewardRules.forParcel(false), 0)
	end)

	-- Finishing through the timer awards the completion bonus.
	t.test("awards completion bonus when time expires", function()
		expect.equal(RewardRules.forRound(Protocol.EndReasons.Time), 10)
	end)

	-- Closing from mistakes does not award the completion bonus.
	t.test("awards no completion bonus after five mistakes", function()
		expect.equal(RewardRules.forRound(Protocol.EndReasons.Mistakes), 0)
	end)

	-- Invalid reward inputs fail instead of being coerced.
	t.test("rejects a non-boolean parcel result", function()
		expect.throws(function()
			RewardRules.forParcel("yes")
		end)
	end)
end
