-- AETHER V3 | StarterPlayer > StarterPlayerScripts > AetherV3Client (LocalScript)
-- New controls and visual effects. Runs ALONGSIDE the original AbilityClient.
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local remotes = ReplicatedStorage:WaitForChild("AetherV3Remotes")
local requests = remotes:WaitForChild("Requests")
local feedback = remotes:WaitForChild("Feedback")
local effects = remotes:WaitForChild("Effects")

local CYAN = Color3.fromRGB(67, 229, 255)
local PURPLE = Color3.fromRGB(175, 89, 255)
local GOLD = Color3.fromRGB(255, 188, 78)
local WHITE = Color3.fromRGB(239, 248, 255)
local DARK = Color3.fromRGB(15, 20, 36)
local RED = Color3.fromRGB(255, 95, 142)
local readyAt, durationByAbility, lastSend = {}, {}, {}
local airJumpUsed = false
local shakeUntil, shakePower = 0, 0

local fxFolder = workspace:FindFirstChild("AetherV3LocalEffects")
if not fxFolder then
	fxFolder = Instance.new("Folder")
	fxFolder.Name = "AetherV3LocalEffects"
	fxFolder.Parent = workspace
end
local function getCharacterParts()
	local char = player.Character
	if not char then return nil end
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	local root = char:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not root then return nil end
	return humanoid, root
end
local function send(name)
	local hum, root = getCharacterParts()
	if not hum then return end
	local now = workspace:GetServerTimeNow()
	if now < (readyAt[name] or 0) or now < (lastSend[name] or 0) then return end
	lastSend[name] = now + 0.18
	if name == "AirJump" then
		if hum.FloorMaterial ~= Enum.Material.Air or airJumpUsed then return end
		requests:FireServer(name)
	elseif name == "GravityWell" or name == "MeteorBarrage" then
		requests:FireServer(name, mouse.Hit.Position)
	else
		local direction = hum.MoveDirection
		if direction.Magnitude < 0.1 then direction = root.CFrame.LookVector end
		requests:FireServer(name, direction)
	end
end

-- Compact second action bar. The original six-slot HUD stays unchanged.
local oldGui = player:WaitForChild("PlayerGui"):FindFirstChild("AetherV3HUD")
if oldGui then oldGui:Destroy() end
local gui = Instance.new("ScreenGui")
gui.Name = "AetherV3HUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.Parent = player.PlayerGui

local panel = Instance.new("Frame")
panel.Name = "MovementAndPowers"
panel.AnchorPoint = Vector2.new(0, 0)
panel.Position = UDim2.new(1, -338, 0, 155)
panel.Size = UDim2.fromOffset(320, 220)
panel.BackgroundColor3 = DARK
panel.BackgroundTransparency = 0.16
panel.BorderSizePixel = 0
panel.Parent = gui
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 14)
corner.Parent = panel
local stroke = Instance.new("UIStroke")
stroke.Color = PURPLE
stroke.Transparency = 0.55
stroke.Thickness = 1.4
stroke.Parent = panel
local scale = Instance.new("UIScale")
scale.Scale = UIS.TouchEnabled and 0.72 or 1
scale.Parent = panel

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -22, 0, 36)
title.Position = UDim2.fromOffset(11, 3)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.Text = "AETHER // V3 MOVEMENT + POWERS"
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextSize = 14
title.TextColor3 = CYAN
title.Parent = panel
local slots = Instance.new("Frame")
slots.BackgroundTransparency = 1
slots.Size = UDim2.new(1, -16, 1, -49)
slots.Position = UDim2.fromOffset(8, 42)
slots.Parent = panel
local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.fromOffset(147, 48)
grid.CellPadding = UDim2.fromOffset(7, 8)
grid.FillDirectionMaxCells = 2
grid.SortOrder = Enum.SortOrder.LayoutOrder
grid.Parent = slots
local abilities = {
	{name = "AirJump", key = "SPACE", title = "DOUBLE JUMP", color = CYAN},
	{name = "AirDash", key = "ALT", title = "AIR DASH", color = CYAN},
	{name = "Slide", key = "C", title = "POWER SLIDE", color = GOLD},
	{name = "Blink", key = "X", title = "PHASE BLINK", color = PURPLE},
	{name = "GravityWell", key = "G", title = "GRAVITY WELL", color = PURPLE},
	{name = "MeteorBarrage", key = "Z", title = "METEOR ULT", color = RED},
}
local cards = {}
for index, ability in ipairs(abilities) do
	local b = Instance.new("TextButton")
	b.Name = ability.name
	b.LayoutOrder = index
	b.Text = ""
	b.BackgroundColor3 = Color3.fromRGB(24, 32, 53)
	b.BorderSizePixel = 0
	b.AutoButtonColor = false
	b.Parent = slots
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 9)
	c.Parent = b
	local line = Instance.new("UIStroke")
	line.Color = ability.color
	line.Transparency = 0.4
	line.Parent = b
	local key = Instance.new("TextLabel")
	key.BackgroundTransparency = 1
	key.Size = UDim2.fromOffset(49, 25)
	key.Position = UDim2.fromOffset(4, 4)
	key.Font = Enum.Font.GothamBold
	key.Text = ability.key
	key.TextSize = ability.key == "SPACE" and 11 or 16
	key.TextColor3 = ability.color
	key.Parent = b
	local text = Instance.new("TextLabel")
	text.BackgroundTransparency = 1
	text.Position = UDim2.fromOffset(49, 4)
	text.Size = UDim2.fromOffset(96, 19)
	text.Font = Enum.Font.GothamBold
	text.Text = ability.title
	text.TextSize = 10
	text.TextXAlignment = Enum.TextXAlignment.Left
	text.TextColor3 = WHITE
	text.Parent = b
	local timer = Instance.new("TextLabel")
	timer.BackgroundTransparency = 1
	timer.Position = UDim2.fromOffset(49, 23)
	timer.Size = UDim2.fromOffset(92, 16)
	timer.Font = Enum.Font.Gotham
	timer.TextSize = 11
	timer.TextXAlignment = Enum.TextXAlignment.Left
	timer.Text = "READY"
	timer.TextColor3 = ability.color
	timer.Parent = b
	local bar = Instance.new("Frame")
	bar.BackgroundColor3 = ability.color
	bar.BorderSizePixel = 0
	bar.Position = UDim2.new(0, 5, 1, -5)
	bar.Size = UDim2.new(1, -10, 0, 2)
	bar.Parent = b
	cards[ability.name] = {timer=timer, bar=bar, color=ability.color}
	b.Activated:Connect(function() send(ability.name) end)
end
UIS.InputBegan:Connect(function(input, consumed)
	if consumed or UIS:GetFocusedTextBox() then return end
	local code = input.KeyCode
	if code == Enum.KeyCode.LeftAlt or code == Enum.KeyCode.RightAlt then send("AirDash")
	elseif code == Enum.KeyCode.C then send("Slide")
	elseif code == Enum.KeyCode.X then send("Blink")
	elseif code == Enum.KeyCode.G then send("GravityWell")
	elseif code == Enum.KeyCode.Z then send("MeteorBarrage") end
end)

local function onCharacter(character)
	airJumpUsed = false
	local hum = character:WaitForChild("Humanoid", 8)
	if not hum then return end
	hum.StateChanged:Connect(function(_, new)
		if player.Character ~= character then return end
		if new == Enum.HumanoidStateType.Landed or new == Enum.HumanoidStateType.Running then
			airJumpUsed = false
		end
	end)
end
player.CharacterAdded:Connect(onCharacter)
if player.Character then onCharacter(player.Character) end

-- JumpRequest is better than InputBegan: normal first jump still works.
local lastJumpRequest = 0
UIS.JumpRequest:Connect(function()
	local now = os.clock()
	if now - lastJumpRequest < 0.18 then return end
	lastJumpRequest = now
	local hum = getCharacterParts()
	if hum and hum.FloorMaterial == Enum.Material.Air then send("AirJump") end
end)
feedback.OnClientEvent:Connect(function(name, duration, endsAt)
	local card = cards[name]
	if not card then return end
	if type(duration) ~= "number" or type(endsAt) ~= "number" then return end
	readyAt[name] = endsAt
	durationByAbility[name] = math.max(duration, 0.01)
	if name == "AirJump" then
		airJumpUsed = true
		-- Responsive prediction AFTER server approval, not before.
		local hum, root = getCharacterParts()
		if root then
			local v = root.AssemblyLinearVelocity
			root.AssemblyLinearVelocity = Vector3.new(v.X, 68, v.Z)
		end
	end
end)

-- Geometry helpers: procedural effects need no external assets or upload IDs.
local function createPart(shape, size, frame, color, alpha)
	local p = Instance.new("Part")
	p.Name = "AetherV3FX"
	p.Shape = shape
	p.Size = size
	p.CFrame = frame
	p.Material = Enum.Material.Neon
	p.Color = color
	p.Transparency = alpha or 0
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Parent = fxFolder
	return p
end
local function tweenDestroy(obj, seconds, goal)
	TweenService:Create(obj, TweenInfo.new(seconds, Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out), goal):Play()
	Debris:AddItem(obj, seconds + 0.1)
end
local function pulse(position, radius, color, seconds, y)
	local disc = createPart(Enum.PartType.Ball, Vector3.new(1,0.16,1),
		CFrame.new(position + Vector3.new(0, y or 0.24, 0)), color, 0.22)
	tweenDestroy(disc, seconds, {Size=Vector3.new(radius*2,0.03,radius*2), Transparency=1})
end
local function burst(position, radius, color, seconds)
	local p = createPart(Enum.PartType.Ball, Vector3.new(1.3,1.3,1.3),
		CFrame.new(position), color, 0.16)
	tweenDestroy(p, seconds, {Size=Vector3.new(radius*2,radius*2,radius*2), Transparency=1})
end
local function beam(a, b, width, color, seconds)
	local delta = b-a
	if delta.Magnitude < 0.03 then return end
	local part = createPart(Enum.PartType.Block, Vector3.new(width,width,delta.Magnitude),
		CFrame.lookAt(a+delta*0.5,b), color, 0.06)
	tweenDestroy(part, seconds, {Transparency=1,Size=Vector3.new(0.06,0.06,delta.Magnitude)})
end
local function sparks(position, count, reach, color)
	for i=1,count do
		local theta = i/count*math.pi*2
		local outward = Vector3.new(math.cos(theta),0,math.sin(theta))
		local shard = createPart(Enum.PartType.Block, Vector3.new(0.4,1.4,0.4),
			CFrame.new(position+Vector3.new(0,1,0)), color, 0.08)
		tweenDestroy(shard, 0.48, {CFrame=shard.CFrame+outward*reach+Vector3.new(0,math.random(1,6),0),
			Size=Vector3.new(0.1,0.3,0.1),Transparency=1})
	end
end
local function cameraShake(position, maxDistance, amount)
	local _, root = getCharacterParts()
	if root and (root.Position-position).Magnitude <= maxDistance then
		shakeUntil = math.max(shakeUntil, os.clock()+0.22)
		shakePower = math.max(shakePower, amount)
	end
end
local function damageNumber(position, amount)
	local anchor = createPart(Enum.PartType.Ball, Vector3.new(0.2,0.2,0.2),
		CFrame.new(position), WHITE, 1)
	local billboard = Instance.new("BillboardGui")
	billboard.AlwaysOnTop = true
	billboard.Size = UDim2.fromOffset(100,50)
	billboard.Parent = anchor
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1,1)
	label.Font = Enum.Font.GothamBlack
	label.TextSize = 26
	label.Text = tostring(math.floor(amount))
	label.TextColor3 = GOLD
	label.TextStrokeTransparency = 0.2
	label.Parent = billboard
	tweenDestroy(anchor, 0.63, {CFrame=anchor.CFrame+Vector3.new(0,3,0)})
	TweenService:Create(label, TweenInfo.new(0.62), {TextTransparency=1,TextStrokeTransparency=1}):Play()
end

effects.OnClientEvent:Connect(function(kind, position, extra, other)
	if typeof(position) ~= "Vector3" then return end
	if kind == "AirJump" then
		pulse(position,5,CYAN,0.32,0.3)
		burst(position+Vector3.new(0,1,0),2,PURPLE,0.28)
		sparks(position,7,4,CYAN)
	elseif kind == "AirDash" and typeof(extra) == "Vector3" then
		for i=1,9 do
			local point=position+extra*(i*2.5)+Vector3.new(0,1.8,0)
			local ghost=createPart(Enum.PartType.Ball,Vector3.new(1.7,3.6,1.7),
				CFrame.new(point),CYAN,0.6)
			tweenDestroy(ghost,0.34,{Transparency=1,Size=Vector3.new(2.5,4.5,2.5)})
		end
		pulse(position,4,PURPLE,0.3,0)
	elseif kind == "Slide" and typeof(extra) == "Vector3" then
		for i=1,10 do
			local at=position+extra*(i*3)+Vector3.new(0,0.4,0)
			local s=createPart(Enum.PartType.Ball,Vector3.new(2,0.25,2),CFrame.new(at),GOLD,0.42)
			tweenDestroy(s,0.46,{Size=Vector3.new(3.4,0.04,3.4),Transparency=1})
		end
	elseif kind == "Blink" and typeof(extra) == "Vector3" then
		burst(position+Vector3.new(0,2,0),5,PURPLE,0.32)
		burst(extra+Vector3.new(0,2,0),5,CYAN,0.38)
		beam(position+Vector3.new(0,2,0),extra+Vector3.new(0,2,0),2.5,PURPLE,0.3)
		pulse(extra,7,CYAN,0.38)
		cameraShake(extra,37,0.16)
	elseif kind == "Well" and type(extra)=="number" and type(other)=="number" then
		local center=position
		pulse(center,extra,PURPLE,0.6)
		burst(center+Vector3.new(0,3,0),5,PURPLE,other)
		task.spawn(function()
			local start=os.clock()
			local index=0
			while os.clock()-start < other do
				index+=1
				local theta=index*0.88
				local orbit=Vector3.new(math.cos(theta)*extra*0.65,2+math.sin(theta*2)*2,
					math.sin(theta)*extra*0.65)
				local orb=createPart(Enum.PartType.Ball,Vector3.new(1.2,1.2,1.2),
					CFrame.new(center+orbit),PURPLE,0.15)
				tweenDestroy(orb,0.46,{CFrame=CFrame.new(center+Vector3.new(0,2,0)),Transparency=1})
				task.wait(0.13)
			end
		end)
	elseif kind == "WellPulse" and type(extra)=="number" then
		pulse(position,extra,CYAN,0.4)
		cameraShake(position,48,0.11)
	elseif kind == "MeteorWarning" and type(extra)=="number" and type(other)=="number" then
		local disc=createPart(Enum.PartType.Ball,Vector3.new(extra*2,0.12,extra*2),
			CFrame.new(position+Vector3.new(0,0.2,0)),RED,0.6)
		tweenDestroy(disc,other,{Transparency=0.86,Size=Vector3.new(extra*2.4,0.07,extra*2.4)})
		pulse(position,extra,GOLD,other,0.3)
	elseif kind == "MeteorImpact" and type(extra)=="number" then
		beam(position+Vector3.new(0,70,0),position+Vector3.new(0,1,0),3.4,WHITE,0.28)
		beam(position+Vector3.new(0,70,0),position+Vector3.new(0,1,0),6.3,RED,0.21)
		burst(position+Vector3.new(0,3,0),extra*0.55,GOLD,0.42)
		pulse(position,extra*1.3,RED,0.5)
		sparks(position,12,extra,GOLD)
		cameraShake(position,90,0.5)
	elseif kind == "MeteorFinal" and type(extra)=="number" then
		pulse(position,extra*1.3,RED,0.85)
		pulse(position,extra,PURPLE,0.62)
		burst(position+Vector3.new(0,5,0),extra*0.95,WHITE,0.65)
		sparks(position,24,extra*1.1,RED)
		cameraShake(position,110,0.8)
	elseif kind == "Damage" and type(extra)=="number" then
		damageNumber(position,extra)
	end
end)
RunService.RenderStepped:Connect(function()
	local now = workspace:GetServerTimeNow()
	for name, card in pairs(cards) do
		local timeRemaining = math.max(0,(readyAt[name] or 0)-now)
		local duration = durationByAbility[name] or 1
		local fraction = math.clamp(1-timeRemaining/duration,0,1)
		card.bar.Size=UDim2.new(fraction, -10*fraction, 0,2)
		card.timer.Text=timeRemaining>0 and string.format("%.1fs",timeRemaining) or "READY"
		card.timer.TextColor3=timeRemaining>0 and Color3.fromRGB(148,155,172) or card.color
	end
	if airJumpUsed then cards.AirJump.timer.Text = "USED IN AIR" end
end)
RunService:BindToRenderStep("AetherV3CameraShake",Enum.RenderPriority.Camera.Value+2,function()
	local remaining = shakeUntil-os.clock()
	if remaining <= 0 then shakePower=0; return end
	local camera=workspace.CurrentCamera
	if not camera then return end
	local power=shakePower*math.clamp(remaining/0.22,0,1)
	camera.CFrame*=CFrame.new((math.random()-0.5)*power,(math.random()-0.5)*power,0)
end)
print("[AETHER V3] Movement and ultimate HUD online.")
