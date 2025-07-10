local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Require the shared configurations
local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local ShopConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ShopConfig"))

-- Client-specific UI constants
local ACTIVE_EFFECTS_POSITION = UDim2.new(0, 10, 0, 70) -- Position of active effects display
local ACTIVE_EFFECTS_SIZE = UDim2.new(0, 200, 0, 0) -- Size of active effects container


local shopEvent = ReplicatedStorage:WaitForChild("PowerUpShopEvent")
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


-- Listen for PowerUpActiveEvent
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


local function clearActiveEffectsDisplay()
    for _, label in pairs(activePowerUpLabels) do
        if label and label.Parent then
            label:Destroy()
        end
    end
    activePowerUpLabels = {}
    activeEffectsContainer.Size = ACTIVE_EFFECTS_SIZE
end

-- Utility: Connect a button by name in MainUI to a handler, managing connection lifecycle
local buttonConnections = {}
local function connectMainUIButton(buttonName, handler)
    local playerGui = player:WaitForChild("PlayerGui")
    local function tryConnect()
        local mainUI = playerGui:FindFirstChild("MainUI")
        local button = mainUI and mainUI:FindFirstChild(buttonName)
        if button then
            -- Always disconnect previous connection for this button
            if buttonConnections[buttonName] then
                buttonConnections[buttonName]:Disconnect()
            end
            -- Connect the new handler
            buttonConnections[buttonName] = button.MouseButton1Click:Connect(handler)
            logDebug(buttonName .. " button connected! (instance: " .. tostring(button) .. ")")
        else
            logDebug(buttonName .. " button not found, retrying...")
            task.delay(0.2, tryConnect)
        end
    end
    tryConnect()
end

local function disconnectAllMainUIButtons()
    for name, conn in pairs(buttonConnections) do
        if conn then conn:Disconnect() end
        buttonConnections[name] = nil
    end
end

local function setupMainUIButtons()
    for i, powerUp in ipairs(ShopConfig.POWER_UPS_DATA) do
        local buttonName = powerUp.ButtonName or powerUp.Name:gsub(" ", "")
        connectMainUIButton(buttonName, function()
            if powerUp.ProductId and powerUp.EnableRobuxPurchase then
                logDebug(buttonName .. " button clicked, prompting Robux purchase.")
                local MarketplaceService = game:GetService("MarketplaceService")
                MarketplaceService:PromptProductPurchase(player, powerUp.ProductId)
            elseif powerUp.Cost then
                logDebug(buttonName .. " button clicked, purchasing with HoneyDrips.")
                shopEvent:FireServer(i)
            else
                logDebug(buttonName .. " button clicked, but no valid purchase method found in ShopConfig.")
            end
        end)
    end
end

player.CharacterAdded:Connect(function(character)
    clearActiveEffectsDisplay()
    disconnectAllMainUIButtons()
    local humanoid = character:WaitForChild("Humanoid")
    humanoid.Died:Connect(function()
        clearActiveEffectsDisplay()
        disconnectAllMainUIButtons()
    end)
    task.wait(0.1)
    setupMainUIButtons()
end)

if player.Character then
    setupMainUIButtons()
end 