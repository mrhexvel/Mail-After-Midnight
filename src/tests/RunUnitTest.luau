local ServerStorage = game:GetService("ServerStorage")

local function formatValue(value)
	if type(value) == "string" then
		return string.format("%q", value)
	end
	return tostring(value)
end

local expect = {}

function expect.equal(actual, expected)
	if actual ~= expected then
		error(string.format("expected %s, got %s", formatValue(expected), formatValue(actual)), 2)
	end
end

function expect.truthy(value)
	if not value then
		error(string.format("expected truthy, got %s", formatValue(value)), 2)
	end
end

function expect.falsy(value)
	if value then
		error(string.format("expected falsy, got %s", formatValue(value)), 2)
	end
end

function expect.throws(callback)
	local ok, message = pcall(callback)
	if ok then
		error("expected the function to throw, but it returned normally", 2)
	end
	return message
end

local function runOne(callback, timeout)
	local done = false
	local ok = false
	local message = nil
	local cpuStart = os.clock()

	local thread = task.spawn(function()
		ok, message = pcall(callback)
		done = true
	end)

	local waited = 0
	while not done and waited < timeout do
		waited += task.wait()
	end
	local elapsed = if waited > 0 then waited else os.clock() - cpuStart

	if not done then
		task.cancel(thread)
		return "timeout", elapsed, string.format("exceeded %.1fs", timeout)
	elseif ok then
		return "pass", elapsed, nil
	else
		return "fail", elapsed, tostring(message)
	end
end

return function(filter, timeout)
	timeout = timeout or 5
	local totals = { run = 0, passed = 0, failed = 0 }
	local sessionStart = os.clock()

	for _, module in ServerStorage.UnitTest.Cases:GetDescendants() do
		if module:IsA("ModuleScript") and (filter == nil or string.find(module.Name, filter, 1, true)) then
			local okRequire, caseFunction = pcall(require, module)
			if not okRequire or type(caseFunction) ~= "function" then
				totals.run += 1
				totals.failed += 1
				warn(string.format("[FAIL] %s | case did not return a function: %s", module.Name, tostring(caseFunction)))
			else
				local context = { expect = expect }
				function context.test(name, callback)
					totals.run += 1
					local status, elapsed, message = runOne(callback, timeout)
					if status == "pass" then
						totals.passed += 1
						print(string.format("[PASS] %s > %s (%.3fs)", module.Name, name, elapsed))
					else
						totals.failed += 1
						warn(string.format("[%s] %s > %s (%.3fs) | %s", string.upper(status), module.Name, name, elapsed, message))
					end
				end

				local okRun, runError = pcall(caseFunction, context)
				if not okRun then
					totals.run += 1
					totals.failed += 1
					warn(string.format("[FAIL] %s | error while building cases: %s", module.Name, tostring(runError)))
				end
			end
		end
	end

	print(string.format("[SUMMARY] %d run, %d passed, %d failed, %.3fs", totals.run, totals.passed, totals.failed, os.clock() - sessionStart))
	return totals
end
