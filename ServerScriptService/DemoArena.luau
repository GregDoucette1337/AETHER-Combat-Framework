local Lighting = game:GetService("Lighting")

if workspace:FindFirstChild("AetherArena") then return end

local arena = Instance.new("Folder")
arena.Name = "AetherArena"
arena.Parent = workspace

local targets = Instance.new("Folder")
targets.Name = "AetherTargets"
targets.Parent = workspace

local function block(name, size, position, color, material, parent)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Anchored = true
	part.Material = material or Enum.Material.SmoothPlastic
	part.Color = color
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent or arena
	return part
end

local navy = Color3.fromRGB(12, 20, 34)
local blue = Color3.fromRGB(45, 188, 229)
local violet = Color3.fromRGB(146, 87, 231)

block("Floor", Vector3.new(140, 2, 140), Vector3.new(0, 0, 0), navy, Enum.Material.Slate)
block("NorthWall", Vector3.new(140, 12, 3), Vector3.new(0, 6, -70), navy)
block("EastWall", Vector3.new(3, 12, 140), Vector3.new(70, 6, 0), navy)
block("WestWall", Vector3.new(3, 12, 140), Vector3.new(-70, 6, 0), navy)
block("SouthWall", Vector3.new(140, 12, 3), Vector3.new(0, 6, 70), navy)

for i = -2, 2 do
	block("FloorStripe", Vector3.new(0.4, 0.06, 126), Vector3.new(i * 25, 1.04, 0), blue, Enum.Material.Neon)
	block("FloorStripe", Vector3.new(126, 0.06, 0.4), Vector3.new(0, 1.05, i * 25), violet, Enum.Material.Neon)
end

for _, x in ipairs({-58, -29, 29, 58}) do
	local pillar = block("PowerPillar", Vector3.new(3, 22, 3), Vector3.new(x, 12, -54), navy, Enum.Material.Metal)
	local lamp = block("EnergyLamp", Vector3.new(4, 2, 4), Vector3.new(x, 21, -54), blue, Enum.Material.Neon)
	lamp.CanCollide = false
	local light = Instance.new("PointLight")
	light.Brightness = 2.5
	light.Range = 30
	light.Color = blue
	light.Parent = lamp
end

local spawn = Instance.new("SpawnLocation")
spawn.Name = "AetherSpawn"
spawn.Size = Vector3.new(9, 1, 9)
spawn.Position = Vector3.new(0, 1.6, 48)
spawn.Anchored = true
spawn.Neutral = true
spawn.Duration = 0
spawn.Color = blue
spawn.Material = Enum.Material.Neon
spawn.Transparency = 0.45
spawn.Parent = arena

Lighting.ClockTime = 21
Lighting.Brightness = 2
Lighting.Ambient = Color3.fromRGB(55, 67, 104)
Lighting.OutdoorAmbient = Color3.fromRGB(33, 48, 75)

local function createTarget(x, z, index)
	local model = Instance.new("Model")
	model.Name = "TrainingDummy_" .. index
	model.Parent = targets

	local root = block("HumanoidRootPart", Vector3.new(2, 2, 1), Vector3.new(x, 4, z), navy, Enum.Material.SmoothPlastic, model)
	root.Transparency = 1
	root.CanCollide = false
	root.CanQuery = false
	model.PrimaryPart = root

	local torso = block("Torso", Vector3.new(3.4, 4, 1.6), Vector3.new(x, 4, z), Color3.fromRGB(39, 56, 80), Enum.Material.Metal, model)
	local head = block("Head", Vector3.new(2, 2, 2), Vector3.new(x, 7, z), blue, Enum.Material.Neon, model)
	block("Core", Vector3.new(1.6, 1.5, 0.2), Vector3.new(x, 4.3, z + 0.91), violet, Enum.Material.Neon, model)
	block("LeftArm", Vector3.new(1, 3.5, 1), Vector3.new(x - 2.5, 4, z), Color3.fromRGB(39, 56, 80), Enum.Material.Metal, model)
	block("RightArm", Vector3.new(1, 3.5, 1), Vector3.new(x + 2.5, 4, z), Color3.fromRGB(39, 56, 80), Enum.Material.Metal, model)
	torso.CanQuery = true
	head.CanQuery = true

	local humanoid = Instance.new("Humanoid")
	humanoid.Name = "Humanoid"
	humanoid.RequiresNeck = false
	humanoid.BreakJointsOnDeath = false
	humanoid.MaxHealth = 200
	humanoid.Health = 200
	humanoid.DisplayName = "TRAINING BOT " .. index
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOn
	humanoid.Parent = model

	humanoid.Died:Connect(function()
		task.delay(2, function()
			model:Destroy()
			if targets.Parent then
				createTarget(x, z, index)
			end
		end)
	end)
end

for index, x in ipairs({-20, 0, 20}) do
	createTarget(x, -16, index)
end

print("[AETHER] Demo arena + 3 respawning training targets created.")
