-- Place as a Script named AbilityServer in ServerScriptService.
-- The server owns cooldowns, target validation and damage.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("AbilityConfig"))

local remotes = ReplicatedStorage:FindFirstChild("AetherRemotes")
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "AetherRemotes"
	remotes.Parent = ReplicatedStorage
end

local function ensureRemote(name)
	local event = remotes:FindFirstChild(name)
	if not event then
		event = Instance.new("RemoteEvent")
		event.Name = name
		event.Parent = remotes
	end
	return event
end

local requestEvent = ensureRemote("RequestAbility")
local effectsEvent = ensureRemote("AbilityEffects")
local feedbackEvent = ensureRemote("AbilityFeedback")

local cooldowns = {} -- [Player] = { ArcSlash = expiration, ThunderStrike = expiration }

local function getAliveCharacter(player)
	local character = player.Character
	if not character then return nil end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root or humanoid.Health <= 0 then
		return nil
	end
	return character, humanoid, root
end

local function canDamage(attacker, model)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return nil end
	if attacker.Character == model then return nil end
	local victimPlayer = Players:GetPlayerFromCharacter(model)
	if victimPlayer and not Config.AllowPvP then return nil end
	return humanoid
end

local function getTargetsInRadius(attacker, position, radius, facing, halfAngle)
	local overlap = OverlapParams.new()
	overlap.FilterType = Enum.RaycastFilterType.Exclude
	overlap.FilterDescendantsInstances = { attacker.Character }
	overlap.MaxParts = 0

	local unique = {}
	local results = {}
	for _, part in ipairs(workspace:GetPartBoundsInRadius(position, radius, overlap)) do
		local model = part:FindFirstAncestorOfClass("Model")
		if model and not unique[model] then
			local humanoid = canDamage(attacker, model)
			if humanoid then
				local targetRoot = model:FindFirstChild("HumanoidRootPart")
					or model:FindFirstChild("Torso")
					or model:FindFirstChild("UpperTorso")
				if targetRoot and targetRoot:IsA("BasePart") then
					local offset = targetRoot.Position - position
					local planar = Vector3.new(offset.X, 0, offset.Z)
					local inCone = true
					if facing and planar.Magnitude > 0.1 then
						inCone = facing:Dot(planar.Unit) >= math.cos(math.rad(halfAngle))
					end
					if planar.Magnitude <= radius + 2 and inCone then
						unique[model] = true
						table.insert(results, humanoid)
					end
				end
			end
		end
	end
	return results
end

local function getGroundTarget(player, root, rawTarget)
	if typeof(rawTarget) ~= "Vector3" then return nil end
	-- Reject NaN/infinities and absurd coordinates; don't trust client mouse input.
	for _, value in ipairs({rawTarget.X, rawTarget.Y, rawTarget.Z}) do
		if value ~= value or math.abs(value) > 100000 then return nil end
	end
	local offset = Vector3.new(rawTarget.X - root.Position.X, 0, rawTarget.Z - root.Position.Z)
	if offset.Magnitude > Config.ThunderStrike.MaxRange then return nil end

	local ignore = {}
	for _, activePlayer in ipairs(Players:GetPlayers()) do
		if activePlayer.Character then
			table.insert(ignore, activePlayer.Character)
		end
	end
	local dummies = workspace:FindFirstChild("AetherTargets")
	if dummies then table.insert(ignore, dummies) end

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = ignore
	local start = Vector3.new(rawTarget.X, root.Position.Y + 80, rawTarget.Z)
	local hit = workspace:Raycast(start, Vector3.new(0, -240, 0), rayParams)
	if not hit then return nil end
	if math.abs(hit.Position.Y - root.Position.Y) > 28 then return nil end
	return hit.Position
end

requestEvent.OnServerEvent:Connect(function(player, abilityName, targetPosition)
	if abilityName ~= "ArcSlash" and abilityName ~= "ThunderStrike" then return end
	local character, _, root = getAliveCharacter(player)
	if not character then return end
	local ability = Config[abilityName]
	if not ability then return end

	local now = workspace:GetServerTimeNow()
	local state = cooldowns[player]
	if not state then
		state = {}
		cooldowns[player] = state
	end
	if now < (state[abilityName] or 0) then return end

	if abilityName == "ArcSlash" then
		local forward = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
		if forward.Magnitude < 0.01 then return end
		forward = forward.Unit
		state[abilityName] = now + ability.Cooldown
		feedbackEvent:FireClient(player, abilityName, ability.Cooldown)
		effectsEvent:FireAllClients("ArcSlash", root.Position, forward)

		-- Damage after the first sweep frames, never on the client.
		task.delay(0.12, function()
			local currentCharacter, _, currentRoot = getAliveCharacter(player)
			if currentCharacter ~= character then return end
			if not currentRoot then return end
			local hitOrigin = root.Position + forward * 5
			for _, targetHumanoid in ipairs(getTargetsInRadius(
				player, hitOrigin, ability.Radius, forward, ability.HalfAngleDegrees
				)) do
				targetHumanoid:TakeDamage(ability.Damage)
			end
		end)

	elseif abilityName == "ThunderStrike" then
		local ground = getGroundTarget(player, root, targetPosition)
		if not ground then return end
		state[abilityName] = now + ability.Cooldown
		feedbackEvent:FireClient(player, abilityName, ability.Cooldown)
		effectsEvent:FireAllClients("ThunderWarning", ground, ability.Radius, ability.TelegraphSeconds)

		task.delay(ability.TelegraphSeconds, function()
			if not player.Parent then return end
			effectsEvent:FireAllClients("ThunderImpact", ground, ability.Radius)
			for _, targetHumanoid in ipairs(getTargetsInRadius(player, ground, ability.Radius)) do
				targetHumanoid:TakeDamage(ability.Damage)
			end
		end)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	cooldowns[player] = nil
end)
