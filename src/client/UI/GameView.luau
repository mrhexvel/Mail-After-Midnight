local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Actions = require(ReplicatedStorage.Shared.Actions)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local Strings = require(ReplicatedStorage.Shared.Strings)

local COLORS = {
	background = Color3.fromRGB(10, 12, 18),
	panel = Color3.fromRGB(21, 25, 35),
	panelLight = Color3.fromRGB(34, 39, 52),
	text = Color3.fromRGB(244, 241, 224),
	muted = Color3.fromRGB(175, 183, 198),
	send = Color3.fromRGB(35, 140, 91),
	returnParcel = Color3.fromRGB(194, 119, 22),
	isolate = Color3.fromRGB(176, 38, 44),
	correct = Color3.fromRGB(88, 210, 132),
	incorrect = Color3.fromRGB(246, 93, 82),
}

local GameView = {}
GameView.__index = GameView

local function addCorner(instance: GuiObject, radius: number?)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 10)
	corner.Parent = instance
end

local function addStroke(instance: GuiObject, color: Color3?, transparency: number?)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or Color3.fromRGB(77, 86, 108)
	stroke.Transparency = transparency or 0.35
	stroke.Thickness = 1
	stroke.Parent = instance
end

local function makeLabel(parent: Instance, name: string, text: string, size: UDim2, position: UDim2): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.Position = position
	label.Size = size
	label.Text = text
	label.TextColor3 = COLORS.text
	label.TextScaled = true
	label.TextWrapped = true
	label.Parent = parent
	return label
end

local function makeButton(parent: Instance, name: string, text: string, color: Color3): TextButton
	local button = Instance.new("TextButton")
	button.Name = name
	button.AutoButtonColor = true
	button.BackgroundColor3 = color
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBold
	button.Size = UDim2.fromScale(0.32, 1)
	button.Text = text
	button.TextColor3 = Color3.new(1, 1, 1)
	button.TextScaled = true
	button.Parent = parent
	addCorner(button, 8)
	return button
end

function GameView.new(playerGui: PlayerGui)
	local self = setmetatable({}, GameView)
	self._snapshot = nil
	self._parcelId = nil
	self._onAction = nil
	self._onReplay = nil
	self._inputLocked = false
	self._replayLocked = false
	self._messageVersion = 0

	local gui = Instance.new("ScreenGui")
	gui.Name = "GameUI"
	gui.DisplayOrder = 10
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = playerGui
	self._gui = gui

	local hud = Instance.new("Frame")
	hud.Name = "HUD"
	hud.AnchorPoint = Vector2.new(0.5, 0)
	hud.BackgroundColor3 = COLORS.panel
	hud.BackgroundTransparency = 0.05
	hud.BorderSizePixel = 0
	hud.Position = UDim2.new(0.5, 0, 0, 12)
	hud.Size = UDim2.new(0.94, 0, 0, 100)
	hud.Parent = gui
	self._hud = hud
	addCorner(hud, 12)
	addStroke(hud)
	local hudConstraint = Instance.new("UISizeConstraint")
	hudConstraint.MaxSize = Vector2.new(780, 100)
	hudConstraint.MinSize = Vector2.new(330, 100)
	hudConstraint.Parent = hud
	self._hudConstraint = hudConstraint

	self._phase = makeLabel(hud, "Phase", Strings.Phase.idle, UDim2.new(0.7, 0, 0, 30), UDim2.fromOffset(12, 7))
	self._phase.TextXAlignment = Enum.TextXAlignment.Left

	local stats = Instance.new("Frame")
	stats.Name = "Stats"
	stats.BackgroundTransparency = 1
	stats.Position = UDim2.fromOffset(12, 45)
	stats.Size = UDim2.new(1, -134, 0, 42)
	stats.Parent = hud
	self._stats = stats
	local statsLayout = Instance.new("UIListLayout")
	statsLayout.FillDirection = Enum.FillDirection.Horizontal
	statsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	statsLayout.Padding = UDim.new(0, 8)
	statsLayout.Parent = stats

	self._time = makeLabel(stats, "Time", "TIME --:--", UDim2.new(0.25, -6, 1, 0), UDim2.new())
	self._mistakes = makeLabel(stats, "Mistakes", "ERRORS 0/5", UDim2.new(0.25, -6, 1, 0), UDim2.new())
	self._correct = makeLabel(stats, "Correct", "CORRECT 0", UDim2.new(0.25, -6, 1, 0), UDim2.new())
	self._tokens = makeLabel(stats, "Tokens", "TOKENS 0", UDim2.new(0.25, -6, 1, 0), UDim2.new())
	self._time.LayoutOrder = 1
	self._mistakes.LayoutOrder = 2
	self._correct.LayoutOrder = 3
	self._tokens.LayoutOrder = 4
	for _, label in { self._time, self._mistakes, self._correct, self._tokens } do
		label.BackgroundColor3 = COLORS.panelLight
		label.BackgroundTransparency = 0.15
		addCorner(label, 7)
	end

	local rulesButton = makeButton(hud, "RulesButton", Strings.RulesButton, COLORS.panelLight)
	rulesButton.Position = UDim2.new(1, -112, 0, 10)
	rulesButton.Size = UDim2.fromOffset(100, 34)
	self._rulesButton = rulesButton

	local feedback = makeLabel(gui, "Feedback", "", UDim2.new(0.9, 0, 0, 54), UDim2.new(0.05, 0, 0, 122))
	feedback.BackgroundColor3 = COLORS.panel
	feedback.BackgroundTransparency = 0.05
	feedback.Visible = false
	feedback.ZIndex = 5
	addCorner(feedback, 10)
	addStroke(feedback)
	self._feedback = feedback

	local card = Instance.new("Frame")
	card.Name = "ParcelCard"
	card.AnchorPoint = Vector2.new(0.5, 1)
	card.BackgroundColor3 = COLORS.panel
	card.BackgroundTransparency = 0.02
	card.BorderSizePixel = 0
	card.Position = UDim2.new(0.5, 0, 1, -18)
	card.Size = UDim2.new(0.92, 0, 0, 330)
	card.Parent = gui
	addCorner(card, 14)
	addStroke(card)
	local cardConstraint = Instance.new("UISizeConstraint")
	cardConstraint.MaxSize = Vector2.new(720, 330)
	cardConstraint.MinSize = Vector2.new(330, 300)
	cardConstraint.Parent = card
	self._cardConstraint = cardConstraint
	self._card = card
	local cardScale = Instance.new("UIScale")
	cardScale.Parent = card
	self._cardScale = cardScale

	makeLabel(card, "Title", Strings.ParcelCardTitle, UDim2.new(1, -24, 0, 38), UDim2.fromOffset(12, 10))
	self._instruction =
		makeLabel(card, "Instruction", Strings.NoParcel, UDim2.new(1, -32, 0, 86), UDim2.fromOffset(16, 58))
	self._instruction.TextColor3 = COLORS.muted

	local traits = Instance.new("Frame")
	traits.Name = "Traits"
	traits.BackgroundColor3 = COLORS.panelLight
	traits.BackgroundTransparency = 0.25
	traits.BorderSizePixel = 0
	traits.Position = UDim2.fromOffset(16, 54)
	traits.Size = UDim2.new(1, -32, 0, 150)
	traits.Visible = false
	traits.Parent = card
	addCorner(traits, 9)
	self._traits = traits

	self._district = makeLabel(traits, "District", "", UDim2.new(0.5, -12, 0.5, -8), UDim2.fromOffset(8, 6))
	self._stamp = makeLabel(traits, "Stamp", "", UDim2.new(0.5, -12, 0.5, -8), UDim2.new(0.5, 4, 0, 6))
	self._seal = makeLabel(traits, "Seal", "", UDim2.new(0.5, -12, 0.5, -8), UDim2.new(0, 8, 0.5, 2))
	self._movement = makeLabel(traits, "Movement", "", UDim2.new(0.5, -12, 0.5, -8), UDim2.new(0.5, 4, 0.5, 2))

	local actions = Instance.new("Frame")
	actions.Name = "Actions"
	actions.BackgroundTransparency = 1
	actions.Position = UDim2.new(0, 16, 1, -102)
	actions.Size = UDim2.new(1, -32, 0, 82)
	actions.Visible = false
	actions.Parent = card
	local actionLayout = Instance.new("UIListLayout")
	actionLayout.FillDirection = Enum.FillDirection.Horizontal
	actionLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	actionLayout.Padding = UDim.new(0.02, 0)
	actionLayout.Parent = actions
	self._actions = actions

	local sendButton = makeButton(actions, "Send", Strings.Action.send, COLORS.send)
	local returnButton = makeButton(actions, "Return", Strings.Action["return"], COLORS.returnParcel)
	local isolateButton = makeButton(actions, "Isolate", Strings.Action.isolate, COLORS.isolate)

	local rules = Instance.new("Frame")
	rules.Name = "RulesPanel"
	rules.AnchorPoint = Vector2.new(0.5, 0.5)
	rules.BackgroundColor3 = COLORS.background
	rules.BackgroundTransparency = 0.02
	rules.BorderSizePixel = 0
	rules.Position = UDim2.fromScale(0.5, 0.5)
	rules.Size = UDim2.new(0.9, 0, 0, 380)
	rules.Visible = false
	rules.ZIndex = 20
	rules.Parent = gui
	addCorner(rules, 14)
	addStroke(rules, COLORS.text, 0.5)
	local rulesConstraint = Instance.new("UISizeConstraint")
	rulesConstraint.MaxSize = Vector2.new(650, 380)
	rulesConstraint.MinSize = Vector2.new(330, 330)
	rulesConstraint.Parent = rules
	self._rulesConstraint = rulesConstraint
	local rulesScale = Instance.new("UIScale")
	rulesScale.Parent = rules
	self._rulesScale = rulesScale
	local rulesText = makeLabel(rules, "Rules", Strings.Rules, UDim2.new(1, -36, 1, -92), UDim2.fromOffset(18, 18))
	rulesText.ZIndex = 21
	local closeRules = makeButton(rules, "Close", "CLOSE", COLORS.panelLight)
	closeRules.AnchorPoint = Vector2.new(0.5, 1)
	closeRules.Position = UDim2.new(0.5, 0, 1, -16)
	closeRules.Size = UDim2.new(0.7, 0, 0, 54)
	closeRules.ZIndex = 21
	self._rules = rules
	self._rulesText = rulesText
	self._closeRules = closeRules

	local results = Instance.new("Frame")
	results.Name = "Results"
	results.AnchorPoint = Vector2.new(0.5, 0.5)
	results.BackgroundColor3 = COLORS.background
	results.BackgroundTransparency = 0.02
	results.BorderSizePixel = 0
	results.Position = UDim2.fromScale(0.5, 0.5)
	results.Size = UDim2.new(0.9, 0, 0, 410)
	results.Visible = false
	results.ZIndex = 15
	results.Parent = gui
	addCorner(results, 14)
	addStroke(results)
	local resultsConstraint = Instance.new("UISizeConstraint")
	resultsConstraint.MaxSize = Vector2.new(560, 410)
	resultsConstraint.MinSize = Vector2.new(330, 380)
	resultsConstraint.Parent = results
	self._resultsConstraint = resultsConstraint
	local resultsScale = Instance.new("UIScale")
	resultsScale.Parent = results
	self._resultsScale = resultsScale
	self._resultTitle = makeLabel(results, "Title", "", UDim2.new(1, -28, 0, 70), UDim2.fromOffset(14, 18))
	self._resultTitle.ZIndex = 16
	self._resultStats = makeLabel(results, "Stats", "", UDim2.new(1, -36, 0, 190), UDim2.fromOffset(18, 100))
	self._resultStats.TextColor3 = COLORS.muted
	self._resultStats.ZIndex = 16
	local replay = makeButton(results, "Replay", Strings.Replay, COLORS.send)
	replay.AnchorPoint = Vector2.new(0.5, 1)
	replay.Position = UDim2.new(0.5, 0, 1, -20)
	replay.Size = UDim2.new(0.75, 0, 0, 66)
	replay.ZIndex = 16
	self._results = results
	self._replay = replay

	rulesButton.Activated:Connect(function()
		rules.Visible = not rules.Visible
	end)
	closeRules.Activated:Connect(function()
		rules.Visible = false
	end)
	replay.Activated:Connect(function()
		if self._onReplay and not self._replayLocked then
			self._replayLocked = true
			self._onReplay()
		end
	end)

	local function bindAction(button: TextButton, action: string)
		button.Activated:Connect(function()
			if self._onAction and self._parcelId and not self._inputLocked then
				self._inputLocked = true
				self._onAction(self._parcelId, action)
			end
		end)
	end
	bindAction(sendButton, Actions.Send)
	bindAction(returnButton, Actions.Return)
	bindAction(isolateButton, Actions.Isolate)

	return self
end

function GameView:setCallbacks(onAction: (string, string) -> (), onReplay: () -> ())
	self._onAction = onAction
	self._onReplay = onReplay
end

function GameView:setTimer(seconds: number)
	local wholeSeconds = math.max(0, math.ceil(seconds))
	local minutes = math.floor(wholeSeconds / 60)
	local remainder = wholeSeconds % 60
	self._time.Text = string.format(Strings.Hud.Time, string.format("%02d:%02d", minutes, remainder))
end

function GameView:setViewportSize(viewportSize: Vector2)
	local compact = viewportSize.Y < 500
	self._cardScale.Scale = 1
	self._rulesScale.Scale = 1
	self._resultsScale.Scale = 1

	if compact then
		self._hud.Position = UDim2.new(0.5, 0, 0, 6)
		self._hud.Size = UDim2.new(0.94, 0, 0, 82)
		self._hudConstraint.MinSize = Vector2.new(330, 82)
		self._hudConstraint.MaxSize = Vector2.new(780, 82)
		self._phase.Position = UDim2.fromOffset(10, 4)
		self._phase.Size = UDim2.new(0.68, 0, 0, 25)
		self._stats.Position = UDim2.fromOffset(10, 36)
		self._stats.Size = UDim2.new(1, -116, 0, 36)
		self._rulesButton.Position = UDim2.new(1, -98, 0, 7)
		self._rulesButton.Size = UDim2.fromOffset(88, 30)

		self._card.Position = UDim2.new(0.5, 0, 1, -8)
		self._card.Size = UDim2.new(0.92, 0, 0, 170)
		self._cardConstraint.MinSize = Vector2.new(330, 170)
		self._cardConstraint.MaxSize = Vector2.new(720, 170)
		self._instruction.Position = UDim2.fromOffset(16, 44)
		self._instruction.Size = UDim2.new(1, -32, 0, 52)
		self._traits.Position = UDim2.fromOffset(16, 38)
		self._traits.Size = UDim2.new(1, -32, 0, 70)
		self._actions.Position = UDim2.new(0, 16, 1, -54)
		self._actions.Size = UDim2.new(1, -32, 0, 44)

		self._rules.Size = UDim2.new(0.9, 0, 0, 250)
		self._rulesConstraint.MinSize = Vector2.new(330, 250)
		self._rulesConstraint.MaxSize = Vector2.new(650, 250)
		self._rulesText.Size = UDim2.new(1, -36, 1, -68)
		self._closeRules.Position = UDim2.new(0.5, 0, 1, -10)
		self._closeRules.Size = UDim2.new(0.7, 0, 0, 44)

		self._results.Size = UDim2.new(0.9, 0, 0, 250)
		self._resultsConstraint.MinSize = Vector2.new(330, 250)
		self._resultsConstraint.MaxSize = Vector2.new(560, 250)
		self._resultTitle.Position = UDim2.fromOffset(14, 10)
		self._resultTitle.Size = UDim2.new(1, -28, 0, 48)
		self._resultStats.Position = UDim2.fromOffset(18, 60)
		self._resultStats.Size = UDim2.new(1, -36, 0, 120)
		self._replay.Position = UDim2.new(0.5, 0, 1, -10)
		self._replay.Size = UDim2.new(0.75, 0, 0, 44)
	else
		self._hud.Position = UDim2.new(0.5, 0, 0, 12)
		self._hud.Size = UDim2.new(0.94, 0, 0, 100)
		self._hudConstraint.MinSize = Vector2.new(330, 100)
		self._hudConstraint.MaxSize = Vector2.new(780, 100)
		self._phase.Position = UDim2.fromOffset(12, 7)
		self._phase.Size = UDim2.new(0.7, 0, 0, 30)
		self._stats.Position = UDim2.fromOffset(12, 45)
		self._stats.Size = UDim2.new(1, -134, 0, 42)
		self._rulesButton.Position = UDim2.new(1, -112, 0, 10)
		self._rulesButton.Size = UDim2.fromOffset(100, 34)

		self._card.Position = UDim2.new(0.5, 0, 1, -18)
		self._card.Size = UDim2.new(0.92, 0, 0, 330)
		self._cardConstraint.MinSize = Vector2.new(330, 300)
		self._cardConstraint.MaxSize = Vector2.new(720, 330)
		self._instruction.Position = UDim2.fromOffset(16, 58)
		self._instruction.Size = UDim2.new(1, -32, 0, 86)
		self._traits.Position = UDim2.fromOffset(16, 54)
		self._traits.Size = UDim2.new(1, -32, 0, 150)
		self._actions.Position = UDim2.new(0, 16, 1, -102)
		self._actions.Size = UDim2.new(1, -32, 0, 82)

		self._rules.Size = UDim2.new(0.9, 0, 0, 380)
		self._rulesConstraint.MinSize = Vector2.new(330, 330)
		self._rulesConstraint.MaxSize = Vector2.new(650, 380)
		self._rulesText.Size = UDim2.new(1, -36, 1, -92)
		self._closeRules.Position = UDim2.new(0.5, 0, 1, -16)
		self._closeRules.Size = UDim2.new(0.7, 0, 0, 54)

		self._results.Size = UDim2.new(0.9, 0, 0, 410)
		self._resultsConstraint.MinSize = Vector2.new(330, 380)
		self._resultsConstraint.MaxSize = Vector2.new(560, 410)
		self._resultTitle.Position = UDim2.fromOffset(14, 18)
		self._resultTitle.Size = UDim2.new(1, -28, 0, 70)
		self._resultStats.Position = UDim2.fromOffset(18, 100)
		self._resultStats.Size = UDim2.new(1, -36, 0, 190)
		self._replay.Position = UDim2.new(0.5, 0, 1, -20)
		self._replay.Size = UDim2.new(0.75, 0, 0, 66)
	end
end

function GameView:render(snapshot: { [string]: any })
	local previousParcelId = self._parcelId
	self._snapshot = snapshot
	self._phase.Text = Strings.Phase[snapshot.phase] or string.upper(tostring(snapshot.phase))
	self._mistakes.Text = string.format(Strings.Hud.Mistakes, snapshot.mistakes or 0, snapshot.maxMistakes or 0)
	self._correct.Text = string.format(Strings.Hud.Correct, snapshot.correct or 0)
	self._tokens.Text = string.format(Strings.Hud.Tokens, snapshot.tokens or 0)

	local isActive = snapshot.phase == Protocol.Phases.Active
	self._card.Visible = isActive
	self._results.Visible = snapshot.phase == Protocol.Phases.Results

	local parcel = snapshot.parcel
	self._parcelId = if parcel then parcel.id else nil
	if self._parcelId ~= previousParcelId then
		self._inputLocked = false
	end
	if snapshot.phase ~= Protocol.Phases.Results then
		self._replayLocked = false
	end
	self._traits.Visible = parcel ~= nil
	self._actions.Visible = parcel ~= nil
	self._instruction.Visible = parcel == nil
	if parcel then
		self._district.Text = string.format(Strings.ParcelDetails.District, parcel.district)
		self._stamp.Text = string.format(Strings.ParcelDetails.Stamp, if parcel.hasStamp then "PRESENT" else "EMPTY")
		self._seal.Text = string.format(Strings.ParcelDetails.Seal, string.upper(parcel.seal))
		self._movement.Text =
			string.format(Strings.ParcelDetails.Movement, if parcel.isMoving then "MOVING" else "STILL")
	else
		self._instruction.Text = if snapshot.parcelAvailable then Strings.NoParcel else Strings.WaitingForParcel
	end

	if snapshot.phase == Protocol.Phases.Results then
		self._resultTitle.Text = if snapshot.endReason == Protocol.EndReasons.Time
			then Strings.TimedResult
			else Strings.MistakeResult
		self._resultStats.Text = table.concat({
			string.format(Strings.Results.Correct, snapshot.correct or 0),
			string.format(Strings.Results.Errors, snapshot.errors or 0),
			string.format(Strings.Results.TeamCorrect, snapshot.teamCorrect or 0),
			string.format(Strings.Results.Tokens, snapshot.tokens or 0),
		}, "\n\n")
	end
end

function GameView:showFeedback(correct: boolean, reasonText: string)
	self._messageVersion += 1
	local version = self._messageVersion
	self._feedback.Text = string.format("%s: %s", if correct then Strings.Correct else Strings.Incorrect, reasonText)
	self._feedback.TextColor3 = if correct then COLORS.correct else COLORS.incorrect
	self._feedback.Visible = true
	task.delay(4, function()
		if self._messageVersion == version then
			self._feedback.Visible = false
		end
	end)
end

function GameView:showNotice(text: string)
	self._inputLocked = false
	self._replayLocked = false
	self._messageVersion += 1
	local version = self._messageVersion
	self._feedback.Text = text
	self._feedback.TextColor3 = COLORS.muted
	self._feedback.Visible = true
	task.delay(3, function()
		if self._messageVersion == version then
			self._feedback.Visible = false
		end
	end)
end

return GameView
