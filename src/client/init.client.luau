print("Client script loaded Rojo OG!")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for MainUI and WelcomeMessage to exist
local mainUI = playerGui:WaitForChild("MainUI")
local welcomeMessage = mainUI:WaitForChild("WelcomeMessage")
local StarterGui = game:GetService("StarterGui")
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, true)


-- Variable definitions
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local counterGui = playerGui:WaitForChild("CounterGui")
local beeCounterLabel = counterGui:WaitForChild("BeeCounter")
local honeyDripLabel = counterGui:WaitForChild("HoneyDripCount")



-- Consolidated UI positioning for all counters/messages
beeCounterLabel.AnchorPoint = Vector2.new(0.5, 0)
beeCounterLabel.Position = UDim2.new(0.5, 0, 0, 0)
beeCounterLabel.TextXAlignment = Enum.TextXAlignment.Center
beeCounterLabel.TextYAlignment = Enum.TextYAlignment.Top
beeCounterLabel.Size = UDim2.new(0, 200, 0, 40)

honeyDripLabel.AnchorPoint = Vector2.new(0.5, 0)
honeyDripLabel.Position = UDim2.new(0.5, 0, 0, 45) -- 45 pixels below beeCounterLabel
honeyDripLabel.TextXAlignment = Enum.TextXAlignment.Center
honeyDripLabel.TextYAlignment = Enum.TextYAlignment.Top
honeyDripLabel.Size = UDim2.new(0, 200, 0, 40)

-- Center the message
welcomeMessage.AnchorPoint = Vector2.new(0.5, 0.5)
welcomeMessage.Position = UDim2.new(0.5, 0, 0.5, 0)



-- Show the message
welcomeMessage.Visible = true

-- Hide after 5 seconds
task.delay(5, function()
    welcomeMessage.Visible = false
end)

-- Respawn timer variables
local respawnTime = 5
local deaths = 0
local respawnGui
local respawnLabel
local respawnCountdown = 0
local respawnConnection

-- Create respawn timer GUI
local function createRespawnGui()
    if respawnGui then respawnGui:Destroy() end
    respawnGui = Instance.new("ScreenGui")
    respawnGui.Name = "RespawnGui"
    respawnGui.ResetOnSpawn = false
    respawnGui.Parent = player:WaitForChild("PlayerGui")

    respawnLabel = Instance.new("TextLabel")
    respawnLabel.Size = UDim2.new(0, 300, 0, 80)
    respawnLabel.Position = UDim2.new(0.5, -150, 0.4, 0)
    respawnLabel.BackgroundTransparency = 0.3
    respawnLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    respawnLabel.TextColor3 = Color3.new(1, 1, 1)
    respawnLabel.TextStrokeTransparency = 0.5
    respawnLabel.Font = Enum.Font.SourceSansBold
    respawnLabel.TextScaled = true
    respawnLabel.Text = ""
    respawnLabel.Parent = respawnGui
end

local function showRespawnTimer()
    createRespawnGui()
    if not respawnLabel then return end -- Safety check
    
    respawnCountdown = respawnTime
    respawnLabel.Text = "Respawning in " .. respawnCountdown .. "..."
    
    if respawnConnection then respawnConnection:Disconnect() end
    respawnConnection = game:GetService("RunService").RenderStepped:Connect(function(dt)
        if not respawnLabel or not respawnLabel.Parent then return end -- Safety check
        
        if respawnCountdown > 0 then
            respawnCountdown = respawnCountdown - dt
            local display = math.ceil(respawnCountdown)
            respawnLabel.Text = "Respawning in " .. display .. "..."
            if respawnCountdown <= 0 then
                respawnLabel.Text = "Respawning..."
                if respawnConnection then
                    respawnConnection:Disconnect()
                    respawnConnection = nil
                end
                -- Request respawn
                local requestRespawnEvent = ReplicatedStorage:WaitForChild("RequestRespawnEvent")
                if requestRespawnEvent then
                    requestRespawnEvent:FireServer()
                else
                    warn("RequestRespawnEvent not found in ReplicatedStorage!")
                end
                task.wait(0.5)
                if respawnGui then 
                    respawnGui:Destroy()
                    respawnGui = nil
                    respawnLabel = nil
                end
            end
        end
    end)
end

-- Listen for deaths and trigger respawn timer
player.CharacterAdded:Connect(function(character)
    -- Remove respawn GUI if it exists (player has respawned)
    if respawnGui then
        respawnGui:Destroy()
        respawnGui = nil
        respawnLabel = nil
    end
    
    local humanoid = character:WaitForChild("Humanoid")
    humanoid.Died:Connect(function()
        deaths = deaths + 1
        respawnTime = 5 * deaths -- Increase by 5 seconds per death
        task.spawn(showRespawnTimer) -- Spawn in a new thread to ensure proper initialization
    end)
end)

-- Remove old MainUI bee/honey counter references
-- Only use CounterGui for bee and honey drip counters
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local counterGui = playerGui:WaitForChild("CounterGui")
local beeCounterLabel = counterGui:WaitForChild("BeeCounter")
local honeyDripLabel = counterGui:WaitForChild("HoneyDripCount")

local beeCountDisplay = game:GetService("ReplicatedStorage"):WaitForChild("BeeCountDisplay")
beeCounterLabel.Text = beeCountDisplay.Value
beeCountDisplay.Changed:Connect(function(value)
    beeCounterLabel.Text = value
end)

-- Function to update the label
local function updateHoneyDripCount()
    local leaderstats = player:WaitForChild("leaderstats")
    local honeyDrips = leaderstats:WaitForChild("HoneyDrips")
    honeyDripLabel.Text = "Honey Drips: " .. tostring(honeyDrips.Value)
    honeyDrips.Changed:Connect(function(newValue)
        honeyDripLabel.Text = "Honey Drips: " .. tostring(newValue)
    end)
end

if player:FindFirstChild("leaderstats") then
    updateHoneyDripCount()
else
    player.ChildAdded:Connect(function(child)
        if child.Name == "leaderstats" then
            updateHoneyDripCount()
        end
    end)
end