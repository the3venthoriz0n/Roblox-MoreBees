local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Require the shared configurations
local ShopConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ShopConfig"))
local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))

-- Client-specific UI constants
local ACTIVE_EFFECTS_POSITION = UDim2.new(0, 10, 0, 70) -- Position of active effects display
local ACTIVE_EFFECTS_SIZE = UDim2.new(0, 200, 0, 0) -- Size of active effects container


local shopEvent = ReplicatedStorage:WaitForChild("PowerUpShopEvent")
local toggleShopEvent = ReplicatedStorage:WaitForChild("ToggleShopEvent")
local purchaseFeedbackEvent = ReplicatedStorage:WaitForChild("PurchaseFeedbackEvent") -- New: Get feedback event
local PowerUpActiveEvent = ReplicatedStorage:WaitForChild("PowerUpActiveEvent") -- New: Get active power-up event
local PowerUpEndedEvent = ReplicatedStorage:WaitForChild("PowerUpEndedEvent") -- New: Get power-up ended event


-- Active Power-Up Display GUI
local activePowerUpGui = Instance.new("ScreenGui")
activePowerUpGui.Name = "ActivePowerUpDisplayGui"
activePowerUpGui.ResetOnSpawn = false
activePowerUpGui.Parent = player:WaitForChild("PlayerGui")

local activeEffectsContainer = Instance.new("Frame")
activeEffectsContainer.Name = "ActiveEffectsContainer"
activeEffectsContainer.Size = ACTIVE_EFFECTS_SIZE -- Width fixed, height will grow dynamically
activeEffectsContainer.Position = ACTIVE_EFFECTS_POSITION -- Top-left, below default Roblox topbar
activeEffectsContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
activeEffectsContainer.BackgroundTransparency = 0.7
activeEffectsContainer.BorderSizePixel = 0
activeEffectsContainer.ClipsDescendants = true
activeEffectsContainer.Parent = activePowerUpGui

local activeEffectsLayout = Instance.new("UIListLayout")
activeEffectsLayout.Parent = activeEffectsContainer
activeEffectsLayout.FillDirection = Enum.FillDirection.Vertical
activeEffectsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
activeEffectsLayout.Padding = UDim.new(0, 5)
activeEffectsLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- Table to keep track of active power-up labels
local activePowerUpLabels = {}

-- Debug logging function
local function logDebug(...)
    if GameConfig and GameConfig.LOG_LEVEL == "debug" then
        print("[DEBUG]", ...)
    end
end


-- Listen for PowerUpActiveEvent from server
PowerUpActiveEvent.OnClientEvent:Connect(function(powerUpName, duration)
    print("Client: PowerUpActiveEvent received for", powerUpName, "with duration", duration)
    -- Remove existing label if power-up is re-activated
    if activePowerUpLabels[powerUpName] then
        activePowerUpLabels[powerUpName]:Destroy()
        activePowerUpLabels[powerUpName] = nil
    end

    local powerUpLabel = Instance.new("TextLabel")
    powerUpLabel.Name = powerUpName .. "_ActiveDisplay"
    powerUpLabel.Size = UDim2.new(1, 0, 0, 25) -- Fill width of container, fixed height
    powerUpLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    powerUpLabel.BackgroundTransparency = 0.8
    powerUpLabel.TextColor3 = Color3.new(1, 1, 1)
    powerUpLabel.TextScaled = false
    powerUpLabel.TextSize = 18
    powerUpLabel.Font = Enum.Font.GothamBold
    powerUpLabel.TextXAlignment = Enum.TextXAlignment.Left
    powerUpLabel.Text = powerUpName .. ": " .. duration .. "s"
    powerUpLabel.LayoutOrder = #activePowerUpLabels + 1 -- For UIListLayout sorting
    powerUpLabel.Parent = activeEffectsContainer
    
    activePowerUpLabels[powerUpName] = powerUpLabel

    -- Start client-side countdown
    local startTime = tick()
    local connection
    connection = game:GetService("RunService").Heartbeat:Connect(function()
        local remainingTime = duration - (tick() - startTime)
        if powerUpLabel and powerUpLabel.Parent then
            powerUpLabel.Text = powerUpName .. ": " .. math.max(0, math.ceil(remainingTime)) .. "s"
            if remainingTime <= 0 then
                connection:Disconnect()
                activePowerUpLabels[powerUpName] = nil
                powerUpLabel:Destroy()
                activeEffectsContainer.Size = activeEffectsContainer.Size - UDim2.new(0, 0, 0, 25 + activeEffectsLayout.Padding.Offset)
            end
        else
            connection:Disconnect()
            activePowerUpLabels[powerUpName] = nil
        end
    end)
    activeEffectsContainer.Size = activeEffectsContainer.Size + UDim2.new(0, 0, 0, 25 + activeEffectsLayout.Padding.Offset)
end)

-- Listen for PowerUpEndedEvent from server (for non-countdown related removal)
PowerUpEndedEvent.OnClientEvent:Connect(function(powerUpName)
    print("Client: PowerUpEndedEvent received for", powerUpName)
    if activePowerUpLabels[powerUpName] then
        local labelToDestroy = activePowerUpLabels[powerUpName]
        activePowerUpLabels[powerUpName] = nil
        labelToDestroy:Destroy()
        -- Adjust container size
        activeEffectsContainer.Size = activeEffectsContainer.Size - UDim2.new(0, 0, 0, 25 + activeEffectsLayout.Padding.Offset)
    end
end)

-- Listen for purchase feedback from server
purchaseFeedbackEvent.OnClientEvent:Connect(function(message)
    local shopGui = player.PlayerGui:FindFirstChild("PowerUpShopGui")
    if shopGui then
        local feedbackLabel = shopGui:FindFirstChild("FeedbackLabel")
        if feedbackLabel then
            feedbackLabel.Text = message
            feedbackLabel.Visible = true
            task.delay(GameConfig.FEEDBACK_DISPLAY_TIME, function()
                if feedbackLabel then
                    feedbackLabel.Visible = false
                end
            end)
        end
    end
end)


-- Keep track of whether the button is already connected
local speedBoostButtonConnected = false



local function connectSpeedBoostButton()
    if speedBoostButtonConnected then
        return -- Already connected, don't connect again
    end
    
    local playerGui = player:WaitForChild("PlayerGui")
    local function tryConnect()
        local mainUI = playerGui:FindFirstChild("MainUI")
        local speedBoostButton = mainUI and mainUI:FindFirstChild("SpeedBoost")
        if speedBoostButton and not speedBoostButtonConnected then
            speedBoostButton.MouseButton1Click:Connect(function()
                logDebug("Speed boost button clicked, firing shopEvent to server.")
                shopEvent:FireServer(1)
            end)
            speedBoostButtonConnected = true
        else
            -- Retry after a short delay if not found
            task.delay(0.2, tryConnect)
        end
    end
    tryConnect()
end

local function clearActiveEffectsDisplay()
    for _, label in pairs(activePowerUpLabels) do
        if label and label.Parent then
            label:Destroy()
        end
    end
    activePowerUpLabels = {}
    activeEffectsContainer.Size = ACTIVE_EFFECTS_SIZE
end

player.CharacterAdded:Connect(function(character)
    -- Always clear active effects on respawn
    clearActiveEffectsDisplay()
    -- Reset connection flag for new character
    speedBoostButtonConnected = false
    -- Wait for Humanoid to be ready
    local humanoid = character:WaitForChild("Humanoid")
    humanoid.Died:Connect(function()
        clearActiveEffectsDisplay()
        speedBoostButtonConnected = false
    end)
    -- Wait a short moment for PlayerGui/MainUI to be ready
    task.wait(0.1)
    connectSpeedBoostButton()
end)

if player.Character then
    connectSpeedBoostButton()
end 