local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Require the shared configurations
local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local ShopConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ShopConfig"))

-- Client-specific UI constants
local ACTIVE_EFFECTS_POSITION = UDim2.new(0, 10, 0, 70) -- Position of active effects display
local ACTIVE_EFFECTS_SIZE = UDim2.new(0, 200, 0, 0) -- Size of active effects container

-- Use :WaitForChild() for all remote events
local shopEvent = ReplicatedStorage:WaitForChild("PowerUpShopEvent")
local purchaseFeedbackEvent = ReplicatedStorage:WaitForChild("PurchaseFeedbackEvent")
local PowerUpActiveEvent = ReplicatedStorage:WaitForChild("PowerUpActiveEvent")
local PowerUpEndedEvent = ReplicatedStorage:WaitForChild("PowerUpEndedEvent")


-- Debug logging function
local function logDebug(...)
    if GameConfig and GameConfig.LOG_LEVEL == "debug" then
        print("[DEBUG]", ...)
    end
end


-- Generic function to show countdown timer above any power-up button
local activeTimerConnections = {}
local activeTimerEndTimes = {}
local function showPowerUpTimer(buttonName, duration)
    local playerGui = player:WaitForChild("PlayerGui")
    local mainUI = playerGui:FindFirstChild("MainUI")
    if not mainUI then return end
    local button = mainUI:FindFirstChild(buttonName)
    if not button then return end
    local timerLabel = button:FindFirstChild("ActiveTimer")
    if not timerLabel then return end
    timerLabel.Visible = true
    -- If already active, add to the remaining time
    local now = tick()
    local newEndTime = now + duration
    if activeTimerEndTimes[buttonName] and activeTimerEndTimes[buttonName] > now then
        newEndTime = activeTimerEndTimes[buttonName] + duration
    end
    activeTimerEndTimes[buttonName] = newEndTime
    -- Disconnect any previous timer for this button
    if activeTimerConnections[buttonName] then
        activeTimerConnections[buttonName]:Disconnect()
    end
    local connection
    connection = game:GetService("RunService").RenderStepped:Connect(function()
        local remaining = math.max(0, activeTimerEndTimes[buttonName] - tick())
        timerLabel.Text = tostring(math.ceil(remaining))
        if remaining <= 0 then
            timerLabel.Visible = false
            timerLabel.Text = ""
            if connection then connection:Disconnect() end
            activeTimerConnections[buttonName] = nil
            activeTimerEndTimes[buttonName] = nil
        end
    end)
    activeTimerConnections[buttonName] = connection
end

local function hidePowerUpTimer(buttonName)
    local playerGui = player:WaitForChild("PlayerGui")
    local mainUI = playerGui:FindFirstChild("MainUI")
    if not mainUI then return end
    local button = mainUI:FindFirstChild(buttonName)
    if not button then return end
    local timerLabel = button:FindFirstChild("ActiveTimer")
    if timerLabel then
        timerLabel.Visible = false
        timerLabel.Text = ""
    end
    if activeTimerConnections[buttonName] then
        activeTimerConnections[buttonName]:Disconnect()
        activeTimerConnections[buttonName] = nil
    end
    activeTimerEndTimes[buttonName] = nil
end

PowerUpActiveEvent.OnClientEvent:Connect(function(powerUpName, duration)
    local buttonName = powerUpName:gsub(" ", "")
    showPowerUpTimer(buttonName, duration)
end)

PowerUpEndedEvent.OnClientEvent:Connect(function(powerUpName)
    local buttonName = powerUpName:gsub(" ", "")
    hidePowerUpTimer(buttonName)
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


-- Utility: Connect a button by name in MainUI to a handler, managing connection lifecycle
local buttonConnections = {}
local function connectMainUIButton(buttonName, handler)
    local playerGui = player:WaitForChild("PlayerGui")
    local function tryConnect()
        local mainUI = playerGui:WaitForChild("MainUI")
        local button = mainUI and mainUI:FindFirstChild(buttonName)
        if button then
            -- Always disconnect previous connection for this button
            if buttonConnections[button] then
                buttonConnections[button]:Disconnect()
            end
            -- Connect the new handler
            buttonConnections[button] = button.MouseButton1Click:Connect(handler)
            logDebug(buttonName .. " button connected! (instance: " .. tostring(button) .. ")")
            return true -- Success
        else
            logDebug(buttonName .. " button not found, retrying...")
            return false -- Not found
        end
    end
    
    -- Try to connect immediately
    if not tryConnect() then
        -- If not found, retry with exponential backoff
        local retryCount = 0
        local maxRetries = 10
        local function retry()
            retryCount = retryCount + 1
            if retryCount > maxRetries then
                warn("Failed to connect button " .. buttonName .. " after " .. maxRetries .. " attempts")
                return
            end
            if not tryConnect() then
                task.delay(0.5 * retryCount, retry) -- Exponential backoff
            end
        end
        task.delay(0.2, retry)
    end
end

local function setupMainUIButtons()
    local playerGui = player:WaitForChild("PlayerGui")
    local mainUI = playerGui:WaitForChild("MainUI") -- Use WaitForChild for robustness
    
    -- Ensure we have valid ShopConfig data
    if not ShopConfig or not ShopConfig.POWER_UPS_DATA then
        warn("ShopConfig or POWER_UPS_DATA not found!")
        return
    end
    
    for i, powerUp in ipairs(ShopConfig.POWER_UPS_DATA) do
        if not powerUp.Name then
            warn("PowerUp at index " .. i .. " missing Name property")
            goto continue
        end
        
        local buttonName = powerUp.ButtonName or powerUp.Name:gsub(" ", "")
        connectMainUIButton(buttonName, function()
            -- Validate powerUp data before processing
            if not powerUp then
                warn("Invalid powerUp data for button: " .. buttonName)
                return
            end
            
            if powerUp.ProductId and powerUp.EnableRobuxPurchase then
                logDebug(buttonName .. " button clicked, prompting Robux purchase.")
                local MarketplaceService = game:GetService("MarketplaceService")
                MarketplaceService:PromptProductPurchase(player, powerUp.ProductId)
            elseif powerUp.Cost then
                logDebug(buttonName .. " button clicked, purchasing with HoneyDrips.")
                shopEvent:FireServer(i)
            else
                logDebug(buttonName .. " button clicked, but no valid purchase method found in ShopConfig.")
                -- Provide user feedback for invalid configuration
                local feedbackMessage = "This power-up is not available for purchase."
                -- Try to show feedback if possible
                local shopGui = player.PlayerGui:FindFirstChild("PowerUpShopGui")
                if shopGui then
                    local feedbackLabel = shopGui:FindFirstChild("FeedbackLabel")
                    if feedbackLabel then
                        feedbackLabel.Text = feedbackMessage
                        feedbackLabel.Visible = true
                        task.delay(GameConfig.FEEDBACK_DISPLAY_TIME, function()
                            if feedbackLabel then
                                feedbackLabel.Visible = false
                            end
                        end)
                    end
                end
            end
        end)
        
        ::continue::
    end
end


local function clearAllPowerUpTimers()
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then return end
    local mainUI = playerGui:FindFirstChild("MainUI")
    if not mainUI then return end
    for _, button in ipairs(mainUI:GetChildren()) do
        if button:IsA("GuiObject") then
            local timerLabel = button:FindFirstChild("ActiveTimer")
            if timerLabel then
                timerLabel.Visible = false
                timerLabel.Text = ""
            end
        end
    end
    -- Disconnect all timer connections and clear end times
    for k, conn in pairs(activeTimerConnections) do
        if conn then conn:Disconnect() end
        activeTimerConnections[k] = nil
    end
    for k, _ in pairs(activeTimerEndTimes) do
        activeTimerEndTimes[k] = nil
    end
end

local function setupGlobalTooltip()
    local playerGui = player:WaitForChild("PlayerGui")
    local mainUI = playerGui:WaitForChild("MainUI")
    local globalTooltip = mainUI:FindFirstChild("GlobalToolTip")
    if not globalTooltip then return end

    for i, powerUp in ipairs(ShopConfig.POWER_UPS_DATA) do
        local buttonName = powerUp.ButtonName or powerUp.Name:gsub(" ", "")
        local button = mainUI:FindFirstChild(buttonName)
        if button then
            local desc = powerUp.Description or ""
            local function show()
                globalTooltip.Text = desc
                globalTooltip.Visible = true
                -- Center of the screen
                local camera = workspace.CurrentCamera
                if camera then
                    local viewportSize = camera.ViewportSize
                    globalTooltip.Position = UDim2.new(
                        0, (viewportSize.X - globalTooltip.AbsoluteSize.X) / 2,
                        0, (viewportSize.Y - globalTooltip.AbsoluteSize.Y) / 2
                    )
                end
            end
            local function hide()
                globalTooltip.Visible = false
            end
            button.MouseEnter:Connect(show)
            button.MouseLeave:Connect(hide)
            button.SelectionGained:Connect(show)
            button.SelectionLost:Connect(hide)
        end
    end
end

-- Hook into player death to clear timers and effects
player.CharacterAdded:Connect(function(character)
    local humanoid = character:WaitForChild("Humanoid")
    humanoid.Died:Connect(function()
        clearAllPowerUpTimers()
    end)
    task.wait(0.1)
    setupMainUIButtons()
    setupGlobalTooltip()
end)

-- Remove the buttonsSetup logic and only set up tooltips for existing character on join
if player.Character then
    task.wait(0.1)
    setupMainUIButtons()
    setupGlobalTooltip()
end 