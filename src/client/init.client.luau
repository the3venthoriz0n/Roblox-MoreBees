print("Client script loaded Rojo OG!")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Require GameConfig
local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))

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
local deaths = 0
local respawnCountdown = 0
local respawnConnection

local mainUI = playerGui:WaitForChild("MainUI")
local respawnTimerLabel = mainUI:WaitForChild("RespawnTimer")

local function showRespawnTimer()
    respawnTimerLabel.Visible = true
    respawnCountdown = GameConfig.RESPAWN_BASE_TIME * (GameConfig.RESPAWN_TIME_MULTIPLIER * deaths)
    if respawnCountdown < GameConfig.RESPAWN_BASE_TIME then
        respawnCountdown = GameConfig.RESPAWN_BASE_TIME
    end
    respawnTimerLabel.Text = GameConfig.RESPAWN_LABEL_PREFIX .. math.ceil(respawnCountdown) .. "..."
    if respawnConnection then respawnConnection:Disconnect() end
    respawnConnection = game:GetService("RunService").RenderStepped:Connect(function(dt)
        if respawnCountdown > 0 then
            respawnCountdown = respawnCountdown - dt
            local display = math.ceil(respawnCountdown)
            respawnTimerLabel.Text = GameConfig.RESPAWN_LABEL_PREFIX .. display .. "..."
            if respawnCountdown <= 0 then
                respawnTimerLabel.Text = "Respawning..."
                if respawnConnection then
                    respawnConnection:Disconnect()
                    respawnConnection = nil
                end
                -- Request respawn
                local requestRespawnEvent = game:GetService("ReplicatedStorage"):WaitForChild("RequestRespawnEvent")
                if requestRespawnEvent then
                    requestRespawnEvent:FireServer()
                end
                task.wait(0.5)
                respawnTimerLabel.Visible = false
                respawnTimerLabel.Text = ""
            end
        end
    end)
end

player.CharacterAdded:Connect(function(character)
    respawnTimerLabel.Visible = false
    respawnTimerLabel.Text = ""
    local humanoid = character:WaitForChild("Humanoid")
    humanoid.Died:Connect(function()
        deaths = deaths + 1
        showRespawnTimer()
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