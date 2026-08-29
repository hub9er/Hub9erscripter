-- Delta Compatible GUI Builder for Toilet Verse Tower Defense
local Fluent = loadstring(game:HttpGet("https://github.com"))()

local Window = Fluent:CreateWindow({
    Title = "Toilet Verse TD Hub 🛠️ Delta",
    SubTitle = "by AI Custom",
    TabWidth = 160,
    Size = UDim2.fromOffset(500, 320),
    Acrylic = true,
    Theme = "Dark"
})

local Tabs = {
    Main = Window:AddTab({ Title = "Main Cheats", Icon = "home" }),
    Spawner = Window:AddTab({ Title = "Unit Spawner", Icon = "user" })
}

-- [1] TIME STOP LOGIC (FREEZE ENEMIES CLIENT-SIDE/GAME SPEED CONTROL)
local EnemyFolder = workspace:FindFirstChild("Enemies") or workspace:FindFirstChild("Toilets")
local timeStopped = false

Tabs.Main:AddToggle("TimeStopToggle", {
    Title = "Activate Time Stop",
    Default = false,
    Callback = function(Value)
        timeStopped = Value
        task.spawn(function()
            while timeStopped do
                -- Freeze Enemy Movement Configs & Rig Velocities
                if EnemyFolder then
                    for _, enemy in ipairs(EnemyFolder:GetChildren()) do
                        local humanoid = enemy:FindFirstChildOfClass("Humanoid")
                        local root = enemy:FindFirstChild("HumanoidRootPart")
                        if humanoid then humanoid.WalkSpeed = 0 end
                        if root then root.Anchored = true end
                    end
                end
                task.wait(0.2)
            end
            
            -- Restore Enemy Speed when turned off
            if not timeStopped and EnemyFolder then
                for _, enemy in ipairs(EnemyFolder:GetChildren()) do
                    local humanoid = enemy:FindFirstChildOfClass("Humanoid")
                    local root = enemy:FindFirstChild("HumanoidRootPart")
                    if humanoid then humanoid.WalkSpeed = 16 end -- Standard default
                    if root then root.Anchored = false end
                end
            end
        end)
    end
})

-- ALTERNATIVE TIME STOP: GAME SPEED CHANGER TO 0
Tabs.Main:AddSlider("GameSpeedSlider", {
    Title = "Game Speed Control (0 = Freeze)",
    Description = "Forces the map timeline speed.",
    Default = 1,
    Min = 0,
    Max = 10,
    Rounding = 1,
    Callback = function(Value)
        -- Targets standard Tower Defense speed state replicates
        local StateRE = game:GetService("ReplicatedStorage"):FindFirstChild("ChangeSpeed", true) 
                        or game:GetService("ReplicatedStorage"):FindFirstChild("GameSpeed", true)
        if StateRE and StateRE:IsA("RemoteEvent") then
            StateRE:FireServer(Value)
        end
    end
})

-- [2] TROOP SPAWNING LOGIC
local selectedUnit = "Titan Cameraman"

Tabs.Spawner:AddInput("UnitInput", {
    Title = "Unit Full Placement Name",
    Default = "Titan Cameraman",
    Placeholder = "Enter exact unit name...",
    Numeric = false,
    Finished = true,
    Callback = function(Value)
        selectedUnit = Value
    end
})

Tabs.Spawner:AddButton({
    Title = "Force Spawn Unit at Character",
    Description = "Attempts to fire placement remotes targeting your exact position.",
    Callback = function()
        local hrp = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return Fluent:Notify({Title = "Error", Content = "Character not found!", Duration = 3}) end
        
        -- Scanning for Placement/Spawn Remote
        local SpawnRemote = game:GetService("ReplicatedStorage"):FindFirstChild("PlaceUnit", true) 
                            or game:GetService("ReplicatedStorage"):FindFirstChild("SpawnUnit", true)
                            or game:GetService("ReplicatedStorage"):FindFirstChild("Place", true)
        
        if SpawnRemote and SpawnRemote:IsA("RemoteFunction") then
            SpawnRemote:InvokeServer(selectedUnit, hrp.CFrame)
        elseif SpawnRemote and SpawnRemote:IsA("RemoteEvent") then
            SpawnRemote:FireServer(selectedUnit, hrp.CFrame)
        else
            Fluent:Notify({
                Title = "Remote Missing", 
                Content = "Could not identify standard placement remote. Check game updates.", 
                Duration = 5
            })
        end
    end
})

Window:SelectTab(1)
