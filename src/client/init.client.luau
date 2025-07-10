print("Client script loaded Rojo OG!")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

local RemoteEventsManager = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteEventsManager"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local mainUI = playerGui:WaitForChild("MainUI")
local counterGui = playerGui:WaitForChild("CounterGui")

local welcomeMessage = mainUI:WaitForChild("WelcomeMessage")
-- Update respawnTimerLabel to be under counterGui
local respawnTimerLabel = counterGui:WaitForChild("RespawnTimer")
local beeCounterLabel = counterGui:WaitForChild("BeeCounter")
local honeyDripLabel = counterGui:WaitForChild("HoneyDripCount")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))

-- GUI Defaults
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, true)

-- Welcome message setup
welcomeMessage.AnchorPoint = Vector2.new(0.5, 0.5)
welcomeMessage.Position = UDim2.new(0.5, 0, 0.5, 0)
welcomeMessage.Visible = true
task.delay(5, function()
    welcomeMessage.Visible = false
end)

-- Counter layout setup
local function setupCounterLabel(label, offsetY)
    label.AnchorPoint = Vector2.new(0.5, 0)
    label.Position = UDim2.new(0.5, 0, 0, offsetY)
    label.Size = UDim2.new(0, 200, 0, 40)
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Top
end
setupCounterLabel(beeCounterLabel, 0)
setupCounterLabel(honeyDripLabel, 45)

-- Bee count display from server
local beeCountDisplay = ReplicatedStorage:WaitForChild("BeeCountDisplay")
beeCounterLabel.Text = beeCountDisplay.Value
beeCountDisplay.Changed:Connect(function(value)
    beeCounterLabel.Text = value
end)

-- Honey drip label update
local function updateHoneyDripLabel()
    local leaderstats = player:WaitForChild("leaderstats")
    local honeyDrips = leaderstats:WaitForChild("HoneyDrips")
    honeyDripLabel.Text = "Honey Drips: " .. tostring(honeyDrips.Value)

    honeyDrips.Changed:Connect(function(newValue)
        honeyDripLabel.Text = "Honey Drips: " .. tostring(newValue)
    end)
end
if player:FindFirstChild("leaderstats") then
    updateHoneyDripLabel()
else
    player.ChildAdded:Connect(function(child)
        if child.Name == "leaderstats" then
            updateHoneyDripLabel()
        end
    end)
end

-- Respawn Timer UI Setup (CENTERED)
respawnTimerLabel.AnchorPoint = Vector2.new(0.5, 0.5)
respawnTimerLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
respawnTimerLabel.TextXAlignment = Enum.TextXAlignment.Center
respawnTimerLabel.TextYAlignment = Enum.TextYAlignment.Center
respawnTimerLabel.Visible = false
respawnTimerLabel.Text = ""

-- Respawn state variables
local deaths = 0
local respawnCountdown = 0
local respawnConnection = nil
local humanoidDiedConnection = nil

local function clearRespawnTimer()
    if respawnConnection then
        respawnConnection:Disconnect()
        respawnConnection = nil
    end
    respawnTimerLabel.Visible = false
    respawnTimerLabel.Text = ""
end

local function showRespawnTimer()
    respawnCountdown = GameConfig.RESPAWN_BASE_TIME * (GameConfig.RESPAWN_TIME_MULTIPLIER * deaths)
    if respawnCountdown < GameConfig.RESPAWN_BASE_TIME then
        respawnCountdown = GameConfig.RESPAWN_BASE_TIME
    end

    respawnTimerLabel.Visible = true
    respawnTimerLabel.Text = GameConfig.RESPAWN_LABEL_PREFIX .. math.ceil(respawnCountdown) .. "..."

    if respawnConnection then
        respawnConnection:Disconnect()
        respawnConnection = nil
    end

    local requestRespawnEvent = RemoteEventsManager.getRemoteEvent("RequestRespawnEvent")

    respawnConnection = RunService.RenderStepped:Connect(function(dt)
        if respawnCountdown > 0 then
            respawnCountdown = respawnCountdown - dt
            local display = math.ceil(respawnCountdown)
            respawnTimerLabel.Text = GameConfig.RESPAWN_LABEL_PREFIX .. display .. "..."
        else
            -- Disconnect and cleanup first
            clearRespawnTimer()

            -- Fire respawn event once
            if requestRespawnEvent then
                requestRespawnEvent:FireServer()
            else
                warn("RequestRespawnEvent not found!")
            end
        end
    end)
end

local function setupRespawnTimerForCharacter(character)
    -- Disconnect previous death connection if any
    if humanoidDiedConnection then
        humanoidDiedConnection:Disconnect()
        humanoidDiedConnection = nil
    end

    deaths = 0
    respawnCountdown = 0
    clearRespawnTimer()

    local humanoid = character:WaitForChild("Humanoid")
    humanoidDiedConnection = humanoid.Died:Connect(function()
        deaths = deaths + 1
        showRespawnTimer()
    end)
end

player.CharacterAdded:Connect(setupRespawnTimerForCharacter)
if player.Character then
    setupRespawnTimerForCharacter(player.Character)
end

