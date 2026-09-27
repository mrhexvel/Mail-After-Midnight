--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NetworkService = {}

export type Remotes = {
	action: RemoteEvent,
	event: RemoteEvent,
	getSnapshot: RemoteFunction,
}

local function getOrCreate(parent: Instance, className: string, name: string): Instance
	local existing = parent:FindFirstChild(name)
	if existing then
		assert(existing.ClassName == className, string.format("%s must be a %s", existing:GetFullName(), className))
		return existing
	end

	local instance = Instance.new(className)
	instance.Name = name
	instance.Parent = parent
	return instance
end

function NetworkService.create(): Remotes
	local folder = getOrCreate(ReplicatedStorage, "Folder", "Remotes") :: Folder

	return {
		action = getOrCreate(folder, "RemoteEvent", "GameAction") :: RemoteEvent,
		event = getOrCreate(folder, "RemoteEvent", "GameEvent") :: RemoteEvent,
		getSnapshot = getOrCreate(folder, "RemoteFunction", "GetSnapshot") :: RemoteFunction,
	}
end

return table.freeze(NetworkService)
