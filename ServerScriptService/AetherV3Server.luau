local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Config = require(ReplicatedStorage:WaitForChild("AetherV3Config"))

local folder = ReplicatedStorage:FindFirstChild("AetherV3Remotes")
if not folder then
	folder = Instance.new("Folder")
	folder.Name = "AetherV3Remotes"
	folder.Parent = ReplicatedStorage
end
local function getRemote(name)
	local obj = folder:FindFirstChild(name)
	if not obj then
		obj = Instance.new("RemoteEvent")
		obj.Name = name
		obj.Parent = folder
	end
	return obj
end
local requests = getRemote("Requests")
local feedback = getRemote("Feedback")
local effects = getRemote("Effects")

local states = {}
local function newState()
	return { ready = {}, lastRequest = 0, usedAirJump = false,
		usedAirDash = false, airborneAt = 0 }
end
local function stateOf(player)
	if not states[player] then states[player] = newState() end
	return states[player]
end
local function living(player)
	local character = player.Character
	if not character then return nil end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then return nil end
	return character, humanoid, root
end
local function finiteVector3(value)
	if typeof(value) ~= "Vector3" then return false end
	for _, n in ipairs({value.X, value.Y, value.Z}) do
		if n ~= n or math.abs(n) > 100000 then return false end
	end
	return true
end
local function flatUnit(vector)
	if not finiteVector3(vector) then return nil end
	local v = Vector3.new(vector.X, 0, vector.Z)
	return v.Magnitude > 0.01 and v.Unit or nil
end
local function canHit(player, model)
	if model == player.Character then return nil end
	local hum = model:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return nil end
	local other = Players:GetPlayerFromCharacter(model)
	if other and not Config.AllowPvP then return nil end
	return hum
end
local function targetRoot(model)
	local root = model:FindFirstChild("HumanoidRootPart")
		or model:FindFirstChild("UpperTorso") or model:FindFirstChild("Torso")
	return root and root:IsA("BasePart") and root or nil
end
local function rayParams(ignore)
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.FilterDescendantsInstances = ignore
	rp.IgnoreWater = true
	return rp
end
local function ignoreForGround()
	local ignore = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Character then table.insert(ignore, p.Character) end
	end
	local dummies = workspace:FindFirstChild("AetherTargets")
	if dummies then table.insert(ignore, dummies) end
	return ignore
end
local function groundAt(player, root, desired, maxRange)
	if not finiteVector3(desired) then return nil end
	local horizontal = Vector3.new(desired.X - root.Position.X, 0, desired.Z - root.Position.Z)
	if horizontal.Magnitude > maxRange or math.abs(desired.Y - root.Position.Y) > 55 then return nil end
	local start = Vector3.new(desired.X, root.Position.Y + 45, desired.Z)
	local result = workspace:Raycast(start, Vector3.new(0, -105, 0), rayParams(ignoreForGround()))
	if not result or result.Normal.Y < 0.65 then return nil end
	if math.abs(result.Position.Y - root.Position.Y) > 30 then return nil end
	return result.Position
end
local function circleTargets(player, origin, radius, limit)
	local overlap = OverlapParams.new()
	overlap.FilterType = Enum.RaycastFilterType.Exclude
	overlap.FilterDescendantsInstances = {player.Character}
	local seen, results = {}, {}
	for _, part in ipairs(workspace:GetPartBoundsInRadius(origin, radius, overlap)) do
		local model = part:FindFirstAncestorOfClass("Model")
		if model and not seen[model] then
			seen[model] = true
			local hum, root = canHit(player, model), targetRoot(model)
			if hum and root and (root.Position - origin).Magnitude <= radius + 3 then
				local eye = origin + Vector3.new(0, 3, 0)
				local line = workspace:Raycast(eye, root.Position - eye,
					rayParams({player.Character, model}))
				if not line then table.insert(results, {hum = hum, root = root}) end
			end
		end
	end
	table.sort(results, function(a,b)
		return (a.root.Position - origin).Magnitude < (b.root.Position - origin).Magnitude
	end)
	while #results > (limit or 30) do table.remove(results) end
	return results
end
local function damage(player, hum, points)
	if not hum.Parent or hum.Health <= 0 or not player.Parent then return end
	local applied = math.min(hum.Health, points)
	hum:TakeDamage(points)
	local root = targetRoot(hum.Parent)
	if root and applied > 0 then
		effects:FireClient(player, "Damage", root.Position + Vector3.new(0, 4, 0), applied)
	end
end
local function applyVelocity(root, direction, speed, duration)
	local attachment = Instance.new("Attachment")
	attachment.Name = "AetherV3MotionAttachment"
	attachment.Parent = root
	local velocity = Instance.new("LinearVelocity")
	velocity.Name = "AetherV3MotionVelocity"
	velocity.Attachment0 = attachment
	velocity.RelativeTo = Enum.ActuatorRelativeTo.World
	velocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	velocity.VectorVelocity = direction * speed
	velocity.MaxForce = math.max(80000, root.AssemblyMass * 15000)
	velocity.ForceLimitsEnabled = true
	velocity.Parent = root
	Debris:AddItem(velocity, duration)
	Debris:AddItem(attachment, duration)
end
local function clearMovement(root)
	for _, obj in ipairs(root:GetChildren()) do
		if obj.Name == "AetherV3MotionVelocity" or obj.Name == "AetherV3MotionAttachment" then
			obj:Destroy()
		end
	end
end
local function bindCharacter(player, character)
	local state = newState()
	states[player] = state
	local hum = character:WaitForChild("Humanoid", 8)
	if not hum then return end
	hum.StateChanged:Connect(function(_, new)
		if player.Character ~= character or states[player] ~= state then return end
		if new == Enum.HumanoidStateType.Landed or new == Enum.HumanoidStateType.Running then
			state.usedAirJump = false
			state.usedAirDash = false
			state.airborneAt = 0
		elseif new == Enum.HumanoidStateType.Jumping or new == Enum.HumanoidStateType.Freefall then
			if state.airborneAt == 0 then state.airborneAt = workspace:GetServerTimeNow() end
		end
	end)
end
local function register(player)
	player.CharacterAdded:Connect(function(character) bindCharacter(player, character) end)
	if player.Character then bindCharacter(player, player.Character) end
end
Players.PlayerAdded:Connect(register)
for _, p in ipairs(Players:GetPlayers()) do register(p) end
Players.PlayerRemoving:Connect(function(p) states[p] = nil end)

local supported = { AirJump=true, AirDash=true, Slide=true, Blink=true,
	GravityWell=true, MeteorBarrage=true }
requests.OnServerEvent:Connect(function(player, name, payload)
	if type(name) ~= "string" or not supported[name] then return end
	local character, hum, root = living(player)
	if not character then return end
	local state = stateOf(player)
	local now = workspace:GetServerTimeNow()
	if now - state.lastRequest < 0.07 then return end
	state.lastRequest = now
	local cfg = Config[name]
	if not cfg or now < (state.ready[name] or 0) then return end

	local origin = root.Position
	local direction = flatUnit(payload)
	local function accept()
		state.ready[name] = now + cfg.Cooldown
		feedback:FireClient(player, name, cfg.Cooldown, state.ready[name])
	end

	if name == "AirJump" then
		if hum.FloorMaterial ~= Enum.Material.Air or state.usedAirJump then return end
		if state.airborneAt == 0 or now - state.airborneAt < 0.12 then return end
		state.usedAirJump = true
		accept()
		local v = root.AssemblyLinearVelocity
		root.AssemblyLinearVelocity = Vector3.new(v.X, cfg.UpwardSpeed, v.Z)
		effects:FireAllClients("AirJump", origin)

	elseif name == "AirDash" then
		if hum.FloorMaterial ~= Enum.Material.Air or state.usedAirDash then return end
		if state.airborneAt == 0 or now - state.airborneAt < 0.10 then return end
		direction = direction or flatUnit(root.CFrame.LookVector)
		if not direction then return end
		local wall = workspace:Raycast(origin + Vector3.new(0, 1, 0),
			direction * (cfg.Speed * cfg.Duration + 2), rayParams({character}))
		if wall and wall.Distance < 4 then return end
		state.usedAirDash = true
		accept()
		clearMovement(root)
		applyVelocity(root, direction + Vector3.new(0, 0.07, 0), cfg.Speed, cfg.Duration)
		effects:FireAllClients("AirDash", origin, direction)

	elseif name == "Slide" then
		if hum.FloorMaterial == Enum.Material.Air or hum.Sit then return end
		direction = direction or flatUnit(root.CFrame.LookVector)
		if not direction then return end
		accept()
		clearMovement(root)
		applyVelocity(root, direction, cfg.Speed, cfg.Duration)
		effects:FireAllClients("Slide", origin, direction)

	elseif name == "Blink" then
		if hum.Sit then return end
		direction = direction or flatUnit(root.CFrame.LookVector)
		if not direction then return end
		local wall = workspace:Raycast(origin + Vector3.new(0, 1, 0),
			direction * cfg.Range, rayParams({character}))
		local travel = wall and math.max(0, wall.Distance - cfg.WallPadding) or cfg.Range
		if travel < 5 then return end
		local wanted = origin + direction * travel
		local ground = groundAt(player, root, wanted, cfg.Range + 1)
		if not ground then return end
		local destination = ground + Vector3.new(0, 3.5, 0)
		local overlap = OverlapParams.new()
		overlap.FilterType = Enum.RaycastFilterType.Exclude
		overlap.FilterDescendantsInstances = {character}
		for _, p in ipairs(workspace:GetPartBoundsInBox(
			CFrame.new(destination), Vector3.new(3.5, 5, 3.5), overlap)) do
			if p.CanCollide and not p:IsDescendantOf(character) then return end
		end
		accept()
		clearMovement(root)
		root.AssemblyLinearVelocity = Vector3.zero
		root.CFrame = CFrame.lookAt(destination, destination + direction)
		effects:FireAllClients("Blink", origin, destination)

	elseif name == "GravityWell" then
		local ground = groundAt(player, root, payload, cfg.Range)
		if not ground then return end
		accept()
		effects:FireAllClients("Well", ground, cfg.Radius, cfg.Duration)
		local pulses = math.floor(cfg.Duration / cfg.PulseEvery)
		for index = 1, pulses do
			task.delay(index * cfg.PulseEvery, function()
				if player.Character ~= character or not player.Parent then return end
				for _, obj in ipairs(circleTargets(player, ground, cfg.Radius, cfg.MaxTargetsPerPulse)) do
					damage(player, obj.hum, cfg.PulseDamage)
					if not obj.root.Anchored and not Players:GetPlayerFromCharacter(obj.hum.Parent) then
						local pull = flatUnit(ground - obj.root.Position)
						if pull then obj.root.AssemblyLinearVelocity += pull * 18 end
					end
				end
				effects:FireAllClients("WellPulse", ground, cfg.Radius)
			end)
		end

	elseif name == "MeteorBarrage" then
		local ground = groundAt(player, root, payload, cfg.Range)
		if not ground then return end
		accept()
		local random = Random.new(math.floor(now * 1000) % 2147483646)
		for index = 1, cfg.Count do
			local offset = index == cfg.Count and Vector3.zero or
				Vector3.new(random:NextNumber(-cfg.Spread, cfg.Spread), 0,
					random:NextNumber(-cfg.Spread, cfg.Spread))
			local candidate = ground + offset
			local impact = groundAt(player, root, candidate, cfg.Range + cfg.Spread + 1)
			if impact then
				local thisImpact = impact
				local delayBefore = (index - 1) * cfg.Interval
				task.delay(delayBefore, function()
					if player.Character ~= character or not player.Parent then return end
					effects:FireAllClients("MeteorWarning", thisImpact, cfg.Radius, cfg.Warning)
				end)
				task.delay(delayBefore + cfg.Warning, function()
					if player.Character ~= character or not player.Parent then return end
					effects:FireAllClients("MeteorImpact", thisImpact, cfg.Radius, index == cfg.Count)
					for _, obj in ipairs(circleTargets(player, thisImpact, cfg.Radius, 25)) do
						damage(player, obj.hum, cfg.Damage)
					end
				end)
			end
		end
		local finishTime = (cfg.Count - 1) * cfg.Interval + cfg.Warning + 0.35
		task.delay(finishTime, function()
			if player.Character ~= character or not player.Parent then return end
			effects:FireAllClients("MeteorFinal", ground, cfg.FinalRadius)
			for _, obj in ipairs(circleTargets(player, ground, cfg.FinalRadius, 25)) do
				damage(player, obj.hum, cfg.FinalDamage)
			end
		end)
	end
end)
print("[AETHER V3] Movement + powers server online.")
