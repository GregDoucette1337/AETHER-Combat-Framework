if workspace:FindFirstChild("AetherArena") then
	warn("[AETHER V3] Existing AetherArena found. Skipping duplicate arena generation.")
	return
end
local Lighting = game:GetService("Lighting")
local arena = Instance.new("Folder")
arena.Name = "AetherArena"
arena.Parent = workspace
local targets = workspace:FindFirstChild("AetherTargets")
if not targets then
	targets = Instance.new("Folder")
	targets.Name = "AetherTargets"
	targets.Parent = workspace
end
local NAVY = Color3.fromRGB(14, 21, 38)
local STEEL = Color3.fromRGB(36, 52, 82)
local CYAN = Color3.fromRGB(52, 215, 255)
local PURPLE = Color3.fromRGB(159, 76, 247)
local GOLD = Color3.fromRGB(255, 192, 93)

local function block(name, size, pos, color, material, parent)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = CFrame.new(pos)
	part.Anchored = true
	part.Color = color
	part.Material = material or Enum.Material.Metal
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent or arena
	return part
end

block("Floor", Vector3.new(182, 2, 182), Vector3.new(0,0,0), NAVY, Enum.Material.Slate)
for _, z in ipairs({-90, 90}) do
	block("Wall",Vector3.new(182,14,3),Vector3.new(0,7,z),STEEL)
end
for _, x in ipairs({-90, 90}) do
	block("Wall",Vector3.new(3,14,182),Vector3.new(x,7,0),STEEL)
end
for i=-3,3 do
	local x=i*24
	local line=block("EnergyGrid",Vector3.new(0.32,0.08,166),Vector3.new(x,1.05,0),CYAN,Enum.Material.Neon)
	line.CanCollide=false
	local row=block("EnergyGrid",Vector3.new(166,0.08,0.32),Vector3.new(0,1.06,x),PURPLE,Enum.Material.Neon)
	row.CanCollide=false
end
for _, x in ipairs({-72,-48,48,72}) do
	local pillar=block("VoidPillar",Vector3.new(4,16,4),Vector3.new(x,9,-60),STEEL)
	pillar.Reflectance=0.2
	local lamp=block("VoidLamp",Vector3.new(6,2,6),Vector3.new(x,18,-60),PURPLE,Enum.Material.Neon)
	lamp.CanCollide=false
	local light=Instance.new("PointLight")
	light.Color=PURPLE
	light.Brightness=2.3
	light.Range=33
	light.Parent=lamp
end
for _, x in ipairs({-60,60}) do
	block("DashRamp",Vector3.new(17,2,20),Vector3.new(x,1.7,26),STEEL)
	local glow=block("RampEdge",Vector3.new(17,0.15,0.5),Vector3.new(x,2.83,17),GOLD,Enum.Material.Neon)
	glow.CanCollide=false
end
local spawn=Instance.new("SpawnLocation")
spawn.Name="AetherV3Spawn"
spawn.Size=Vector3.new(9,1,9)
spawn.Position=Vector3.new(0,1.8,64)
spawn.Anchored=true
spawn.Neutral=true
spawn.Duration=0
spawn.Color=CYAN
spawn.Transparency=0.35
spawn.Material=Enum.Material.Neon
spawn.Parent=arena

Lighting.ClockTime=21
Lighting.Brightness=2.4
Lighting.Ambient=Color3.fromRGB(57,70,118)
Lighting.OutdoorAmbient=Color3.fromRGB(26,35,62)

local function makeTarget(x,z,label,health,scale)
	scale=scale or 1
	local model=Instance.new("Model")
	model.Name="AetherTarget_"..label
	model.Parent=targets
	local root=block("HumanoidRootPart",Vector3.new(2,2,1)*scale,
		Vector3.new(x,1+3*scale,z),STEEL,Enum.Material.SmoothPlastic,model)
	root.Transparency=1
	root.CanCollide=false
	root.CanQuery=false
	model.PrimaryPart=root
	local torso=block("Torso",Vector3.new(3.3,4,1.8)*scale,
		Vector3.new(x,1+3*scale,z),STEEL,Enum.Material.Metal,model)
	local head=block("Head",Vector3.new(2,2,2)*scale,
		Vector3.new(x,1+6*scale,z),health>1000 and GOLD or CYAN,Enum.Material.Neon,model)
	local core=block("Reactor",Vector3.new(1.4,1.4,0.28)*scale,
		Vector3.new(x,1+3.5*scale,z+1.05*scale),PURPLE,Enum.Material.Neon,model)
	core.CanCollide=false
	for _, side in ipairs({-1,1}) do
		block("Arm",Vector3.new(1,3.4,1)*scale,
			Vector3.new(x+side*2.4*scale,1+3*scale,z),STEEL,Enum.Material.Metal,model)
	end
	local humanoid=Instance.new("Humanoid")
	humanoid.Name="Humanoid"
	humanoid.RequiresNeck=false
	humanoid.BreakJointsOnDeath=false
	humanoid.MaxHealth=health
	humanoid.Health=health
	humanoid.HealthDisplayType=Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.DisplayName=label
	humanoid.Parent=model
	local plate=Instance.new("BillboardGui")
	plate.Name="HealthPlate"
	plate.Size=UDim2.fromOffset(180,57)
	plate.StudsOffset=Vector3.new(0,2.8*scale,0)
	plate.AlwaysOnTop=true
	plate.Parent=head
	local text=Instance.new("TextLabel")
	text.Size=UDim2.fromScale(1,0.48)
	text.BackgroundTransparency=1
	text.TextColor3=health>1000 and GOLD or CYAN
	text.TextStrokeTransparency=0.2
	text.Font=Enum.Font.GothamBold
	text.TextSize=14
	text.Parent=plate
	local back=Instance.new("Frame")
	back.Size=UDim2.new(0.95,0,0,9)
	back.Position=UDim2.new(0.025,0,0.62,0)
	back.BackgroundColor3=Color3.fromRGB(39,45,57)
	back.BorderSizePixel=0
	back.Parent=plate
	local fill=Instance.new("Frame")
	fill.BackgroundColor3=health>1000 and GOLD or PURPLE
	fill.Size=UDim2.fromScale(1,1)
	fill.BorderSizePixel=0
	fill.Parent=back
	local function refresh()
		text.Text=string.format("%s  |  %d / %d HP",label,math.ceil(humanoid.Health),health)
		fill.Size=UDim2.fromScale(math.max(0,humanoid.Health/health),1)
	end
	refresh()
	humanoid.HealthChanged:Connect(refresh)
	humanoid.Died:Connect(function()
		task.delay(2.5,function()
			model:Destroy()
			if targets.Parent then makeTarget(x,z,label,health,scale) end
		end)
	end)
end
for i,x in ipairs({-48,-24,0,24,48}) do
	makeTarget(x,-12,"DRONE "..i,400,1)
end
makeTarget(0,-53,"TITAN CORE",2000,1.65)
print("[AETHER V3] Arena loaded: five 400HP drones + 2000HP Titan Core.")
