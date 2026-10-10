local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local remotes = ReplicatedStorage:WaitForChild("AetherRemotes")
local requestEvent = remotes:WaitForChild("RequestAbility")
local effectsEvent = remotes:WaitForChild("AbilityEffects")
local feedbackEvent = remotes:WaitForChild("AbilityFeedback")

local CYAN = Color3.fromRGB(55, 228, 255)
local PURPLE = Color3.fromRGB(169, 91, 255)
local WHITE = Color3.fromRGB(230, 249, 255)
local readyAt = { ArcSlash = 0, ThunderStrike = 0 }
local cooldownLength = { ArcSlash = 1, ThunderStrike = 1 }
local shakeUntil = 0
local shakeStrength = 0

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AetherHUD"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = player:WaitForChild("PlayerGui")

local header = Instance.new("TextLabel")
header.Name = "Branding"
header.AnchorPoint = Vector2.new(0.5, 0)
header.Position = UDim2.new(0.5, 0, 0, 25)
header.Size = UDim2.fromOffset(450, 40)
header.BackgroundTransparency = 1
header.Text = "A E T H E R   / /   COMBAT FRAMEWORK"
header.TextColor3 = WHITE
header.TextScaled = true
header.Font = Enum.Font.GothamBold
header.Parent = screenGui

local headerConstraint = Instance.new("UITextSizeConstraint")
headerConstraint.MaxTextSize = 21
headerConstraint.Parent = header

local holder = Instance.new("Frame")
holder.Name = "AbilityBar"
holder.AnchorPoint = Vector2.new(0.5, 1)
holder.Position = UDim2.new(0.5, 0, 1, -30)
holder.Size = UDim2.fromOffset(450, 100)
holder.BackgroundTransparency = 1
holder.Parent = screenGui

local scale = Instance.new("UIScale")
scale.Scale = UIS.TouchEnabled and 0.75 or 1
scale.Parent = holder

local function createAbilityCard(name, key, caption, color, xPosition)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = UDim2.fromOffset(215, 88)
	button.Position = UDim2.fromOffset(xPosition, 0)
	button.BackgroundColor3 = Color3.fromRGB(14, 23, 40)
	button.BorderSizePixel = 0
	button.AutoButtonColor = false
	button.Text = ""
	button.Parent = holder

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = button

	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = 2
	stroke.Transparency = 0.2
	stroke.Parent = button

	local keyLabel = Instance.new("TextLabel")
	keyLabel.Size = UDim2.fromOffset(48, 62)
	keyLabel.Position = UDim2.fromOffset(8, 12)
	keyLabel.BackgroundTransparency = 1
	keyLabel.Text = key
	keyLabel.Font = Enum.Font.GothamBlack
	keyLabel.TextColor3 = color
	keyLabel.TextSize = 35
	keyLabel.Parent = button

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Position = UDim2.fromOffset(68, 12)
	nameLabel.Size = UDim2.fromOffset(138, 26)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Text = caption
	nameLabel.TextColor3 = WHITE
	nameLabel.TextSize = 17
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Parent = button

	local timerLabel = Instance.new("TextLabel")
	timerLabel.Position = UDim2.fromOffset(68, 44)
	timerLabel.Size = UDim2.fromOffset(138, 20)
	timerLabel.BackgroundTransparency = 1
	timerLabel.TextXAlignment = Enum.TextXAlignment.Left
	timerLabel.Text = "READY"
	timerLabel.TextColor3 = color
	timerLabel.TextSize = 15
	timerLabel.Font = Enum.Font.Gotham
	timerLabel.Parent = button

	local fill = Instance.new("Frame")
	fill.Name = "CooldownFill"
	fill.Position = UDim2.fromOffset(8, 77)
	fill.Size = UDim2.new(1, -16, 0, 4)
	fill.BackgroundColor3 = color
	fill.BorderSizePixel = 0
	fill.Parent = button
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = fill

	return button, timerLabel, fill, stroke
end

local slashButton, slashTimer, slashFill, slashStroke = createAbilityCard("ArcSlash", "Q", "ARC SLASH", CYAN, 0)
local thunderButton, thunderTimer, thunderFill, thunderStroke = createAbilityCard("ThunderStrike", "E", "THUNDER STRIKE", PURPLE, 235)
local ui = {
	ArcSlash = {button = slashButton, timer = slashTimer, fill = slashFill, stroke = slashStroke, color = CYAN},
	ThunderStrike = {button = thunderButton, timer = thunderTimer, fill = thunderFill, stroke = thunderStroke, color = PURPLE},
}

local function pulse(button)
	local uiScale = button:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
	uiScale.Parent = button
	uiScale.Scale = 1
	TweenService:Create(uiScale, TweenInfo.new(0.12, Enum.EasingStyle.Back), {Scale = 1.06}):Play()
	task.delay(0.12, function()
		if uiScale.Parent then
			TweenService:Create(uiScale, TweenInfo.new(0.18), {Scale = 1}):Play()
		end
	end)
end

local function useAbility(name)
	if workspace:GetServerTimeNow() < readyAt[name] then return end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end
	if name == "ThunderStrike" then
		if not mouse.Hit then return end
		requestEvent:FireServer(name, mouse.Hit.Position)
	else
		requestEvent:FireServer(name)
	end
end

slashButton.Activated:Connect(function() useAbility("ArcSlash") end)
thunderButton.Activated:Connect(function() useAbility("ThunderStrike") end)
UIS.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed or UIS:GetFocusedTextBox() then return end
	if input.KeyCode == Enum.KeyCode.Q then useAbility("ArcSlash") end
	if input.KeyCode == Enum.KeyCode.E then useAbility("ThunderStrike") end
end)

feedbackEvent.OnClientEvent:Connect(function(name, seconds)
	if not ui[name] or typeof(seconds) ~= "number" then return end
	cooldownLength[name] = seconds
	readyAt[name] = workspace:GetServerTimeNow() + seconds
	pulse(ui[name].button)
end)

local function makeFXPart(shape, size, cf, color, transparency)
	local part = Instance.new("Part")
	part.Name = "AetherFX"
	part.Shape = shape
	part.Size = size
	part.CFrame = cf
	part.Color = color
	part.Material = Enum.Material.Neon
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.Transparency = transparency or 0
	part.Parent = workspace
	return part
end

local function tweenAndCleanup(part, seconds, goal)
	TweenService:Create(part, TweenInfo.new(seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goal):Play()
	Debris:AddItem(part, seconds + 0.15)
end

local function burst(position, radius, color)
	local orb = makeFXPart(Enum.PartType.Ball, Vector3.new(2, 2, 2), CFrame.new(position), color, 0.2)
	tweenAndCleanup(orb, 0.55, {Size = Vector3.new(radius * 2, radius * 2, radius * 2), Transparency = 1})
	local disc = makeFXPart(Enum.PartType.Ball, Vector3.new(2, 0.2, 2), CFrame.new(position + Vector3.new(0, 0.25, 0)), color, 0.1)
	tweenAndCleanup(disc, 0.65, {Size = Vector3.new(radius * 2.3, 0.2, radius * 2.3), Transparency = 1})
end

local function arcSlash(position, forward)
	local look = CFrame.lookAt(position, position + forward)
	for i = 1, 13 do
		local fraction = (i - 1) / 12
		local angle = math.rad(-80 + 160 * fraction)
		local distance = 8 + math.sin(math.pi * fraction) * 3
		local point = position + (look * CFrame.Angles(0, angle, 0)).LookVector * distance + Vector3.new(0, 3.2, 0)
		local shard = makeFXPart(Enum.PartType.Ball, Vector3.new(1.5, 3.2, 1.5), CFrame.new(point), CYAN, 0.1)
		tweenAndCleanup(shard, 0.36, {Size = Vector3.new(3.5, 5.5, 3.5), Transparency = 1})
	end
	burst(position + forward * 8 + Vector3.new(0, 2.5, 0), 5, CYAN)
end

local function lightningBolt(ground)
	local previous = ground + Vector3.new(math.random(-4, 4), 42, math.random(-4, 4))
	local segments = 9
	for i = 1, segments do
		local alpha = i / segments
		local current = ground + Vector3.new(
			i == segments and 0 or math.random(-5, 5),
			(1 - alpha) * 42,
			i == segments and 0 or math.random(-5, 5)
		)
		local segment = current - previous
		local mid = previous + segment * 0.5
		local part = makeFXPart(Enum.PartType.Block, Vector3.new(0.8, 0.8, segment.Magnitude), CFrame.lookAt(mid, current), WHITE, 0)
		tweenAndCleanup(part, 0.28, {Transparency = 1, Size = Vector3.new(0.15, 0.15, segment.Magnitude)})
		previous = current
	end
end

local function nearEnoughToShake(position, radius)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	return root and (root.Position - position).Magnitude < radius
end

effectsEvent.OnClientEvent:Connect(function(kind, position, extra, other)
	if typeof(position) ~= "Vector3" then return end
	if kind == "ArcSlash" and typeof(extra) == "Vector3" then
		arcSlash(position, extra)
		if nearEnoughToShake(position, 30) then
			shakeUntil = math.max(shakeUntil, os.clock() + 0.18)
			shakeStrength = 0.22
		end
	elseif kind == "ThunderWarning" and typeof(extra) == "number" and typeof(other) == "number" then
		local radius = extra
		local indicator = makeFXPart(Enum.PartType.Ball, Vector3.new(radius * 2, 0.12, radius * 2), CFrame.new(position + Vector3.new(0, 0.15, 0)), PURPLE, 0.58)
		TweenService:Create(indicator, TweenInfo.new(other * 0.8), {Transparency = 0.82}):Play()
		Debris:AddItem(indicator, other)
	elseif kind == "ThunderImpact" and typeof(extra) == "number" then
		lightningBolt(position)
		burst(position + Vector3.new(0, 1, 0), extra, PURPLE)
		if nearEnoughToShake(position, 90) then
			shakeUntil = math.max(shakeUntil, os.clock() + 0.3)
			shakeStrength = 0.65
		end
	end
end)

RunService.RenderStepped:Connect(function()
	local now = workspace:GetServerTimeNow()
	for name, entry in pairs(ui) do
		local remaining = math.max(0, readyAt[name] - now)
		local fraction = 1 - math.clamp(remaining / cooldownLength[name], 0, 1)
		entry.timer.Text = remaining > 0 and string.format("%.1fs COOLDOWN", remaining) or "READY"
		entry.timer.TextColor3 = remaining > 0 and Color3.fromRGB(160, 174, 192) or entry.color
		entry.fill.Size = UDim2.new(fraction, -16 * fraction, 0, 4)
		entry.stroke.Transparency = remaining > 0 and 0.72 or 0.2
	end
end)

RunService:BindToRenderStep("AetherShake", Enum.RenderPriority.Camera.Value + 1, function()
	if os.clock() >= shakeUntil then return end
	local camera = workspace.CurrentCamera
	if not camera then return end
	local remaining = math.clamp((shakeUntil - os.clock()) / 0.3, 0, 1)
	local strength = shakeStrength * remaining
	camera.CFrame = camera.CFrame * CFrame.new(
		(math.random() - 0.5) * strength,
		(math.random() - 0.5) * strength,
		0
	)
end)
