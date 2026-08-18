-- Services
ReplicatedStorage = game:GetService("ReplicatedStorage")
TweenService = game:GetService("TweenService")
RunService = game:GetService("RunService")

-- Folders & Remotes
Remotes = ReplicatedStorage:WaitForChild("Remotes")
SpawnUnitRemote = Remotes:WaitForChild("SpawnUnit")
TimeStopRemote = Remotes:WaitForChild("TimeStop")

-- Game State Folders
EnemiesFolder = workspace:WaitForChild("ActiveEnemies")
TowersFolder = workspace:WaitForChild("ActiveTowers")

-- Settings
local TIME_STOP_COOLDOWN = 30
local isTimeStopped = false
local lastTimeStopTick = 0

--------------------------------------------------------------------------------
-- MODULE 1: TIME STOP SYSTEM
--------------------------------------------------------------------------------

local function setEnemyFrozenState(enemy, frozen)
	local humanoid = enemy:FindFirstChildOfClass("Humanoid")
	local rootPart = enemy:FindFirstChild("HumanoidRootPart")
	
	if humanoid and rootPart then
		if frozen then
			-- Store original velocity/speed and freeze
			enemy:SetAttribute("OriginalSpeed", humanoid.WalkSpeed)
			humanoid.WalkSpeed = 0
			rootPart.Anchored = true
			
			-- Pause active animations if Animator exists
			local animator = humanoid:FindFirstChildOfClass("Animator")
			if animator then
				for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
					track:AdjustSpeed(0)
				end
			end
		else
			-- Restore movement
			rootPart.Anchored = false
			local origSpeed = enemy:GetAttribute("OriginalSpeed") or 16
			humanoid.WalkSpeed = origSpeed
			
			-- Resume animations
			local animator = humanoid:FindFirstChildOfClass("Animator")
			if animator then
				for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
					track:AdjustSpeed(1)
				end
			end
		end
	end
end

function TriggerTimeStop(player, duration)
	local currentTime = tick()
	if currentTime - lastTimeStopTick < TIME_STOP_COOLDOWN then
		warn(player.Name .. " tried to use Time Stop, but it's on cooldown.")
		return false
	end
	
	if isTimeStopped then return false end
	
	isTimeStopped = true
	lastTimeStopTick = currentTime
	print("TIMESTOP ACTIVATED by " .. player.Name)
	
	-- Freeze all current enemies
	for _, enemy in ipairs(EnemiesFolder:GetChildren()) do
		setEnemyFrozenState(enemy, true)
	end
	
	-- Listen for newly spawned enemies during time stop
	local connection
	connection = EnemiesFolder.ChildAdded:Connect(function(newEnemy)
		if isTimeStopped then
			task.defer(function()
				setEnemyFrozenState(newEnemy, true)
			end)
		end
	end)
	
	-- Wait for duration
	task.wait(duration)
	
	-- Unfreeze everything
	isTimeStopped = false
	connection:Disconnect()
	
	for _, enemy in ipairs(EnemiesFolder:GetChildren()) do
		setEnemyFrozenState(enemy, false)
	end
	
	print("TIMESTOP ENDED")
	return true
end

--------------------------------------------------------------------------------
-- MODULE 2: UNIT SPAWNING SYSTEM
--------------------------------------------------------------------------------

-- Example registry of units (Stats, Costs, Models)
local UnitRegistry = {
	["CameraSpeakerUnit"] = {
		Cost = 350,
		Damage = 50,
		Range = 15,
		FireRate = 1.2, -- Attacks per second
		Model = ReplicatedStorage.Units:WaitForChild("CameraSpeakerUnit")
	}
}

local function setupTowerBehavior(towerModel, stats)
	local range = stats.Range
	local damage = stats.Damage
	local fireRate = stats.FireRate
	
	task.spawn(function()
		while towerModel.Parent do
			if not isTimeStopped then
				-- Find closest enemy within range
				local targetEnemy = nil
				local shortestDistance = range
				local towerPos = towerModel.PrimaryPart.Position
				
				for _, enemy in ipairs(EnemiesFolder:GetChildren()) do
					local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")
					if enemyRoot then
						local distance = (enemyRoot.Position - towerPos).Magnitude
						if distance <= shortestDistance then
							shortestDistance = distance
							targetEnemy = enemy
						end
					end
				end
				
				-- Attack Target
				if targetEnemy then
					local enemyHumanoid = targetEnemy:FindFirstChildOfClass("Humanoid")
					if enemyHumanoid then
						enemyHumanoid:TakeDamage(damage)
						-- Optional: Play shooting effects or projectile code here
					end
					task.wait(1 / fireRate)
				else
					task.wait(0.5) -- Scan delay if no target
				end
			else
				-- Optional: If towers freeze during timestop, add logic here. Currently, towers can still act or be frozen.
				task.wait(0.2)
			end
		end
	end)
end

function SpawnUnit(player, unitName, cframe)
	local unitData = UnitRegistry[unitName]
	if not unitData then 
		warn("Invalid unit requested: " .. tostring(unitName))
		return false 
	end
	
	-- Currency check (Assuming player has a 'Coins' leaderstats or attribute folder)
	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("Coins")
	
	if not coins or coins.Value < unitData.Cost then
		warn(player.Name .. " does not have enough currency to spawn " .. unitName)
		return false
	end
	
	-- Deduct currency
	coins.Value = coins.Value - unitData.Cost
	
	-- Instantiate model
	local newTower = unitData.Model:Clone()
	newTower:SetAttribute("Owner", player.UserId)
	newTower:SetPrimaryPartCFrame(cframe)
	newTower.Parent = TowersFolder
	
	-- Initialize AI / Attack loop for the tower
	setupTowerBehavior(newTower, unitData)
	
	print(player.Name .. " successfully placed " .. unitName)
	return true
end

--------------------------------------------------------------------------------
-- EVENT BINDINGS
--------------------------------------------------------------------------------

SpawnUnitRemote.OnServerInvoke = function(player, unitName, cframe)
	return SpawnUnit(player, unitName, cframe)
end

TimeStopRemote.OnServerInvoke = function(player, duration)
	return TriggerTimeStop(player, duration)
end
