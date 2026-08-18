-- Toilet Verse Tower Defense Utility Controller
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- Time Stop Function (Freezes enemy models locally by setting WalkSpeed/Anchoring)
local function toggleTimeStop(isStopped)
    local enemiesFolder = workspace:FindFirstChild("Enemies") or workspace:FindFirstChild("Zombies")
    if enemiesFolder then
        for _, enemy in ipairs(enemiesFolder:GetChildren()) do
            local humanoid = enemy:FindFirstChildOfClass("Humanoid")
            local rootPart = enemy:FindFirstChild("HumanoidRootPart")
            
            if humanoid then
                humanoid.WalkSpeed = isStopped and 0 or 16 -- Restore or zero out speed
            end
            if rootPart then
                rootPart.Anchored = isStopped
            end
        end
    end
    print("Time Stop Active: " .. tostring(isStopped))
end

-- Spawn Unit Function (Interacts with remote handlers or placement folders)
local function spawnUnitInGame(unitName, cframePosition)
    local remoteFolder = ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage
    local spawnRemote = remoteFolder:FindFirstChild("PlaceUnit") or remoteFolder:FindFirstChild("SpawnUnit")
    
    if spawnRemote and spawnRemote:IsA("RemoteEvent") then
        -- Fire server event if the game utilizes standard remotes for building
        spawnRemote:FireServer(unitName, cframePosition)
        print("Requested spawn for unit: " .. unitName)
    else
        warn("Placement RemoteEvent not found; verify game's network structure.")
    end
end

-- Example Usage:
-- toggleTimeStop(true)  -- Stops time for enemies
-- toggleTimeStop(false) -- Resumes time
-- spawnUnitInGame("Upgraded Titan Cinemaman", LocalPlayer.Character.PrimaryPart.CFrame)
