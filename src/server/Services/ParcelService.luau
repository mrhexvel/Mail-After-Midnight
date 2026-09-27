local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Strings = require(ReplicatedStorage.Shared.Strings)

type Template = {
	id: string,
	district: string,
	hasStamp: boolean,
	seal: string,
	isMoving: boolean,
	appearance: { color: Color3 },
	expectedAction: string,
	expectedReason: string,
}

type ActiveParcel = {
	id: string,
	template: Template,
	model: Model,
	prompt: ProximityPrompt,
	claimedBy: Player?,
	processed: boolean,
}

local ParcelService = {}
ParcelService.__index = ParcelService

local function makeTextLabel(parent: Instance, text: string)
	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.BackgroundColor3 = Color3.fromRGB(12, 14, 18)
	label.BackgroundTransparency = 0.1
	label.BorderSizePixel = 0
	label.Font = Enum.Font.GothamBold
	label.Size = UDim2.fromScale(1, 1)
	label.Text = text
	label.TextColor3 = Color3.fromRGB(245, 240, 218)
	label.TextScaled = true
	label.TextWrapped = true
	label.Parent = parent
end

function ParcelService.new(room: Model, templates: { Template }, onChanged: () -> (), onNotice: (Player, string) -> ())
	local self = setmetatable({}, ParcelService)
	self._room = room
	self._templates = templates
	self._onChanged = onChanged
	self._onNotice = onNotice
	self._active = nil :: ActiveParcel?
	self._random = Random.new()
	self._lastTemplateId = nil :: string?
	self._lastAction = nil :: string?
	self._repeatCount = 0
	return self
end

function ParcelService:_chooseTemplate(): Template
	local candidates = {}
	for _, template in self._templates do
		local repeatsTooLong = self._repeatCount >= 3 and template.expectedAction == self._lastAction
		if template.id ~= self._lastTemplateId and not repeatsTooLong then
			table.insert(candidates, template)
		end
	end

	if #candidates == 0 then
		candidates = self._templates
	end

	local template = candidates[self._random:NextInteger(1, #candidates)]
	if template.expectedAction == self._lastAction then
		self._repeatCount += 1
	else
		self._lastAction = template.expectedAction
		self._repeatCount = 1
	end
	self._lastTemplateId = template.id
	return template
end

function ParcelService:_buildModel(parcelId: string, template: Template): (Model, ProximityPrompt)
	local tableTop = self._room.IncomingTable.Top :: BasePart
	local baseCFrame = tableTop.CFrame * CFrame.new(0, 1.5, 0)

	local model = Instance.new("Model")
	model.Name = "ActiveParcel"
	model:SetAttribute("ParcelId", parcelId)

	local box = Instance.new("Part")
	box.Name = "Box"
	box.Anchored = true
	box.CanCollide = false
	box.Color = template.appearance.color
	box.Material = Enum.Material.Cardboard
	box.Size = Vector3.new(3.5, 2, 2.5)
	box.CFrame = baseCFrame
	box.Parent = model
	model.PrimaryPart = box

	local stamp = Instance.new("Part")
	stamp.Name = "StampField"
	stamp.Anchored = true
	stamp.CanCollide = false
	stamp.Color = if template.hasStamp then Color3.fromRGB(224, 216, 181) else Color3.fromRGB(35, 36, 40)
	stamp.Material = Enum.Material.SmoothPlastic
	stamp.Size = Vector3.new(1.1, 0.7, 0.08)
	stamp.CFrame = baseCFrame * CFrame.new(0.8, 0, -1.29)
	stamp.Parent = model

	local stampGui = Instance.new("SurfaceGui")
	stampGui.Face = Enum.NormalId.Front
	stampGui.CanvasSize = Vector2.new(240, 140)
	stampGui.LightInfluence = 0
	stampGui.Parent = stamp
	makeTextLabel(stampGui, if template.hasStamp then "STAMP" else "EMPTY")

	local seal = Instance.new("Part")
	seal.Name = "Seal"
	seal.Anchored = true
	seal.CanCollide = false
	seal.Color = if template.seal == "red" then Color3.fromRGB(220, 35, 42) else Color3.fromRGB(74, 124, 151)
	seal.Material = Enum.Material.Neon
	seal.Size = Vector3.new(0.9, 0.12, 0.9)
	seal.CFrame = baseCFrame * CFrame.new(0, 1.06, 0)
	seal.Parent = model

	local sealGui = Instance.new("SurfaceGui")
	sealGui.Face = Enum.NormalId.Top
	sealGui.CanvasSize = Vector2.new(160, 160)
	sealGui.LightInfluence = 0
	sealGui.Parent = seal
	makeTextLabel(sealGui, if template.seal == "red" then "!" else "OK")

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "VisibleTraits"
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 45
	billboard.Size = UDim2.fromOffset(300, 135)
	billboard.StudsOffset = Vector3.new(0, 2.7, 0)
	billboard.Parent = box
	makeTextLabel(
		billboard,
		string.format(
			Strings.ParcelLabel,
			template.district,
			if template.hasStamp then "PRESENT" else "EMPTY",
			string.upper(template.seal),
			if template.isMoving then "MOVING" else "STILL"
		)
	)

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = Strings.ExaminePrompt
	prompt.ObjectText = Strings.ParcelObject
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = box

	model:PivotTo(baseCFrame)
	model.Parent = self._room
	return model, prompt
end

function ParcelService:spawn(roundId: number): boolean
	if self._active then
		return false
	end

	local template = self:_chooseTemplate()
	local parcelId = string.format("%d:%s:%d", roundId, template.id, self._random:NextInteger(100000, 999999))
	local model, prompt = self:_buildModel(parcelId, template)
	local active: ActiveParcel = {
		id = parcelId,
		template = template,
		model = model,
		prompt = prompt,
		claimedBy = nil,
		processed = false,
	}
	self._active = active

	prompt.Triggered:Connect(function(player)
		if self._active ~= active or active.processed then
			self._onNotice(player, "parcelUnavailable")
			return
		end
		if not self:_isPlayerNear(active, player) then
			self._onNotice(player, "parcelUnavailable")
			return
		end
		if active.claimedBy and active.claimedBy ~= player then
			self._onNotice(player, "parcelBusy")
			return
		end

		active.claimedBy = player
		active.prompt.Enabled = false
		self._onChanged()

		task.delay(Config.Round.ClaimDuration, function()
			if self._active == active and not active.processed and active.claimedBy == player then
				active.claimedBy = nil
				active.prompt.Enabled = true
				self._onChanged()
			end
		end)
	end)

	if template.isMoving then
		task.spawn(function()
			local startedAt = os.clock()
			while self._active == active and model.Parent do
				local wave = math.sin((os.clock() - startedAt) * 8)
				model:PivotTo(
					(self._room.IncomingTable.Top :: BasePart).CFrame
						* CFrame.new(0, 1.5 + wave * 0.12, 0)
						* CFrame.Angles(0, 0, wave * 0.08)
				)
				task.wait(0.05)
			end
		end)
	end

	self._onChanged()
	return true
end

function ParcelService:getViewFor(player: Player): { [string]: any }?
	local active = self._active
	if not active or active.claimedBy ~= player or active.processed then
		return nil
	end

	local template = active.template
	return {
		id = active.id,
		district = template.district,
		hasStamp = template.hasStamp,
		seal = template.seal,
		isMoving = template.isMoving,
	}
end

function ParcelService:hasActive(): boolean
	return self._active ~= nil
end

function ParcelService:_isPlayerNear(active: ActiveParcel, player: Player): boolean
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local box = active.model.PrimaryPart
	if not root or not root:IsA("BasePart") or not box then
		return false
	end

	return (root.Position - box.Position).Magnitude <= active.prompt.MaxActivationDistance + 2
end

function ParcelService:tryResolve(player: Player, parcelId: string): (Template?, string?)
	local active = self._active
	if not active or active.id ~= parcelId or active.processed then
		return nil, "parcelUnavailable"
	end
	if active.claimedBy ~= player then
		return nil, "claimRequired"
	end
	if not self:_isPlayerNear(active, player) then
		return nil, "claimRequired"
	end

	active.processed = true
	self._active = nil
	active.model:Destroy()
	return active.template, nil
end

function ParcelService:releaseClaim(player: Player)
	local active = self._active
	if active and not active.processed and active.claimedBy == player then
		active.claimedBy = nil
		active.prompt.Enabled = true
		self._onChanged()
	end
end

function ParcelService:clear()
	local active = self._active
	self._active = nil
	if active then
		active.processed = true
		active.model:Destroy()
	end
end

return ParcelService
