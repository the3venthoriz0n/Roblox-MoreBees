-- Variables defined at the top as per user preference
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

-- Require the shared configurations with redundancy
local GameConfig = nil
local ShopConfig = nil
local function loadConfigs()
    local success, result = pcall(function()
        return require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
    end)
    if success then
        GameConfig = result
    else
        warn("Failed to load GameConfig:", result)
        -- Fallback config
        GameConfig = {
            LOG_LEVEL = "debug",
            FEEDBACK_DISPLAY_TIME = 3,
            SPEED_BOOST_MULTIPLIER = 1.5,
            HEALTH_BOOST_AMOUNT = 50,
            BEE_SPAWN_COUNT = 5,
            ENABLE_ROBUX_PURCHASES = true
        }
    end
    
    success, result = pcall(function()
        return require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ShopConfig"))
    end)
    if success then
        ShopConfig = result
    else
        warn("Failed to load ShopConfig:", result)
        -- Fallback config
        ShopConfig = {
            POWER_UPS_DATA = {
                {Name = "Speed Boost", ButtonName = "SpeedBoost", Cost = 2, Duration = 20},
                {Name = "Health Boost", ButtonName = "HealthBoost", Cost = 4, Duration = 20},
                {Name = "Bee Shield", ButtonName = "BeeShield", Cost = 5, Duration = 30},
                {Name = "More Bees", ButtonName = "MoreBees", Cost = 10, Duration = 0}
            }
        }
    end
end

-- Load configs immediately and retry if needed
loadConfigs()

-- Remote events with redundancy
local shopEvent = nil
local purchaseFeedbackEvent = nil
local PowerUpActiveEvent = nil
local PowerUpEndedEvent = nil

local function loadRemoteEvents()
    local success, result = pcall(function()
        return ReplicatedStorage:WaitForChild("PowerUpShopEvent", 10)
    end)
    if success then
        shopEvent = result
    else
        warn("Failed to load PowerUpShopEvent:", result)
    end
    
    success, result = pcall(function()
        return ReplicatedStorage:WaitForChild("PurchaseFeedbackEvent", 10)
    end)
    if success then
        purchaseFeedbackEvent = result
    else
        warn("Failed to load PurchaseFeedbackEvent:", result)
    end
    
    success, result = pcall(function()
        return ReplicatedStorage:WaitForChild("PowerUpActiveEvent", 10)
    end)
    if success then
        PowerUpActiveEvent = result
    else
        warn("Failed to load PowerUpActiveEvent:", result)
    end
    
    success, result = pcall(function()
        return ReplicatedStorage:WaitForChild("PowerUpEndedEvent", 10)
    end)
    if success then
        PowerUpEndedEvent = result
    else
        warn("Failed to load PowerUpEndedEvent:", result)
    end
end

-- Load remote events immediately
loadRemoteEvents()

-- Client-specific UI constants
local ACTIVE_EFFECTS_POSITION = UDim2.new(0, 10, 0, 70)
local ACTIVE_EFFECTS_SIZE = UDim2.new(0, 200, 0, 0)

-- Debug logging function with redundancy
local function logDebug(...)
    if GameConfig and GameConfig.LOG_LEVEL == "debug" then
        print("[DEBUG][PowerUpShop.client]", ...)
    end
end

-- Enhanced error handling wrapper
local function safeExecute(name, func, ...)
    local success, result = pcall(func, ...)
    if not success then
        warn("Error in " .. name .. ":", result)
        return false
    end
    return true
end

-- Timer management with redundancy
local activeTimerConnections = {}
local activeTimerEndTimes = {}
local timerRetryCount = {}

local function showPowerUpTimer(buttonName, duration)
    if not buttonName or not duration then
        warn("Invalid parameters for showPowerUpTimer:", buttonName, duration)
        return
    end
    
    safeExecute("showPowerUpTimer", function()
        local playerGui = player:WaitForChild("PlayerGui", 10)
        if not playerGui then
            warn("PlayerGui not found for timer")
            return
        end
        
        local mainUI = playerGui:FindFirstChild("MainUI")
        if not mainUI then
            warn("MainUI not found for timer")
            return
        end
        
        local button = mainUI:FindFirstChild(buttonName)
        if not button then
            warn("Button not found for timer:", buttonName)
            return
        end
        
        local timerLabel = button:FindFirstChild("ActiveTimer")
        if not timerLabel then
            warn("ActiveTimer not found for button:", buttonName)
            return
        end
        
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
        connection = RunService.RenderStepped:Connect(function()
            if not activeTimerEndTimes[buttonName] then
                if connection then connection:Disconnect() end
                return
            end
            
            local remaining = math.max(0, activeTimerEndTimes[buttonName] - tick())
            if timerLabel and timerLabel.Parent then
                timerLabel.Text = tostring(math.ceil(remaining))
            end
            
            if remaining <= 0 then
                if timerLabel and timerLabel.Parent then
                    timerLabel.Visible = false
                    timerLabel.Text = ""
                end
                if connection then connection:Disconnect() end
                activeTimerConnections[buttonName] = nil
                activeTimerEndTimes[buttonName] = nil
                timerRetryCount[buttonName] = nil
            end
        end)
        activeTimerConnections[buttonName] = connection
    end)
end

local function hidePowerUpTimer(buttonName)
    if not buttonName then return end
    
    safeExecute("hidePowerUpTimer", function()
        local playerGui = player:FindFirstChild("PlayerGui")
        if not playerGui then return end
        
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
        timerRetryCount[buttonName] = nil
    end)
end

-- Event connections with redundancy
local eventConnections = {}

local function setupEventConnections()
    -- PowerUpActiveEvent
    if PowerUpActiveEvent then
        if eventConnections.PowerUpActive then
            eventConnections.PowerUpActive:Disconnect()
        end
        eventConnections.PowerUpActive = PowerUpActiveEvent.OnClientEvent:Connect(function(powerUpName, duration)
            if not powerUpName then return end
            local buttonName = powerUpName:gsub(" ", "")
            showPowerUpTimer(buttonName, duration)
        end)
    end
    
    -- PowerUpEndedEvent
    if PowerUpEndedEvent then
        if eventConnections.PowerUpEnded then
            eventConnections.PowerUpEnded:Disconnect()
        end
        eventConnections.PowerUpEnded = PowerUpEndedEvent.OnClientEvent:Connect(function(powerUpName)
            if not powerUpName then return end
            local buttonName = powerUpName:gsub(" ", "")
            hidePowerUpTimer(buttonName)
        end)
    end
    
    -- PurchaseFeedbackEvent
    if purchaseFeedbackEvent then
        if eventConnections.PurchaseFeedback then
            eventConnections.PurchaseFeedback:Disconnect()
        end
        eventConnections.PurchaseFeedback = purchaseFeedbackEvent.OnClientEvent:Connect(function(message)
            safeExecute("purchaseFeedback", function()
                local shopGui = player.PlayerGui:FindFirstChild("PowerUpShopGui")
                if shopGui then
                    local feedbackLabel = shopGui:FindFirstChild("FeedbackLabel")
                    if feedbackLabel then
                        feedbackLabel.Text = message or "Purchase processed"
                        feedbackLabel.Visible = true
                        task.delay(GameConfig and GameConfig.FEEDBACK_DISPLAY_TIME or 3, function()
                            if feedbackLabel and feedbackLabel.Parent then
                                feedbackLabel.Visible = false
                            end
                        end)
                    end
                end
            end)
        end)
    end
end

-- Button connection management with extensive redundancy
local buttonConnections = {}
local buttonRetryCount = {}
local MAX_RETRY_COUNT = 10
local RETRY_DELAY = 0.5

local function connectMainUIButton(buttonName, handler)
    if not buttonName or not handler then
        warn("Invalid parameters for connectMainUIButton:", buttonName, handler)
        return
    end
    
    buttonRetryCount[buttonName] = buttonRetryCount[buttonName] or 0
    
    local function tryConnect()
        safeExecute("connectMainUIButton", function()
            local playerGui = player:WaitForChild("PlayerGui", 10)
            if not playerGui then
                warn("PlayerGui not found for button connection")
                return false
            end
            
            local mainUI = playerGui:WaitForChild("MainUI", 10)
            if not mainUI then
                warn("MainUI not found for button connection")
                return false
            end
            
            local button = mainUI:FindFirstChild(buttonName)
            if not button then
                warn("Button not found:", buttonName)
                return false
            end
            
            -- Always disconnect previous connection for this button
            if buttonConnections[button] then
                buttonConnections[button]:Disconnect()
                buttonConnections[button] = nil
            end
            
            -- Connect the new handler with error protection
            local connection = button.MouseButton1Click:Connect(function()
                safeExecute("buttonClickHandler", handler)
            end)
            
            buttonConnections[button] = connection
            buttonRetryCount[buttonName] = 0 -- Reset retry count on success
            logDebug(buttonName .. " button connected successfully!")
            return true
        end)
        return false
    end
    
    -- Initial connection attempt
    if not tryConnect() then
        -- Retry mechanism
        local function retryConnection()
            if buttonRetryCount[buttonName] >= MAX_RETRY_COUNT then
                warn("Max retry count reached for button:", buttonName)
                return
            end
            
            buttonRetryCount[buttonName] = buttonRetryCount[buttonName] + 1
            logDebug("Retrying connection for", buttonName, "attempt", buttonRetryCount[buttonName])
            
            if not tryConnect() then
                task.delay(RETRY_DELAY, retryConnection)
            end
        end
        
        task.delay(RETRY_DELAY, retryConnection)
    end
end

local function setupMainUIButtons()
    if not ShopConfig or not ShopConfig.POWER_UPS_DATA then
        warn("ShopConfig not available for button setup")
        return
    end
    
    safeExecute("setupMainUIButtons", function()
        for i, powerUp in ipairs(ShopConfig.POWER_UPS_DATA) do
            local buttonName = powerUp.ButtonName or powerUp.Name:gsub(" ", "")
            if buttonName then
                connectMainUIButton(buttonName, function()
                    safeExecute("buttonClickHandler", function()
                        if powerUp.ProductId and powerUp.EnableRobuxPurchase then
                            logDebug(buttonName .. " button clicked, prompting Robux purchase.")
                            local MarketplaceService = game:GetService("MarketplaceService")
                            MarketplaceService:PromptProductPurchase(player, powerUp.ProductId)
                        elseif powerUp.Cost and shopEvent then
                            logDebug(buttonName .. " button clicked, purchasing with HoneyDrips.")
                            shopEvent:FireServer(i)
                        else
                            logDebug(buttonName .. " button clicked, but no valid purchase method found.")
                        end
                    end)
                end)
            end
        end
    end)
end

local function clearAllPowerUpTimers()
    safeExecute("clearAllPowerUpTimers", function()
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
        for k, _ in pairs(timerRetryCount) do
            timerRetryCount[k] = nil
        end
    end)
end

local function setupGlobalTooltip()
    if not ShopConfig or not ShopConfig.POWER_UPS_DATA then
        warn("ShopConfig not available for tooltip setup")
        return
    end
    
    safeExecute("setupGlobalTooltip", function()
        local playerGui = player:WaitForChild("PlayerGui", 10)
        if not playerGui then return end
        
        local mainUI = playerGui:WaitForChild("MainUI", 10)
        if not mainUI then return end
        
        local globalTooltip = mainUI:FindFirstChild("GlobalToolTip")
        if not globalTooltip then return end

        for i, powerUp in ipairs(ShopConfig.POWER_UPS_DATA) do
            local buttonName = powerUp.ButtonName or powerUp.Name:gsub(" ", "")
            if buttonName then
                local button = mainUI:FindFirstChild(buttonName)
                if button then
                    local desc = powerUp.Description or ""
                    local function show()
                        if globalTooltip and globalTooltip.Parent then
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
                    end
                    local function hide()
                        if globalTooltip and globalTooltip.Parent then
                            globalTooltip.Visible = false
                        end
                    end
                    
                    -- Connect tooltip events with error protection
                    button.MouseEnter:Connect(show)
                    button.MouseLeave:Connect(hide)
                    button.SelectionGained:Connect(show)
                    button.SelectionLost:Connect(hide)
                end
            end
        end
    end)
end

-- Recovery and monitoring system
local function monitorAndRecover()
    -- Monitor for missing buttons and reconnect
    task.spawn(function()
        while true do
            task.wait(5) -- Check every 5 seconds
            
            if not ShopConfig or not ShopConfig.POWER_UPS_DATA then
                loadConfigs() -- Try to reload configs
            else
                local playerGui = player:FindFirstChild("PlayerGui")
                if playerGui then
                    local mainUI = playerGui:FindFirstChild("MainUI")
                    if mainUI then
                        -- Check if any buttons are missing connections
                        for i, powerUp in ipairs(ShopConfig.POWER_UPS_DATA) do
                            local buttonName = powerUp.ButtonName or powerUp.Name:gsub(" ", "")
                            if buttonName then
                                local button = mainUI:FindFirstChild(buttonName)
                                if button and not buttonConnections[button] then
                                    logDebug("Button missing connection, reconnecting:", buttonName)
                                    connectMainUIButton(buttonName, function()
                                        safeExecute("recoveredButtonClickHandler", function()
                                            if powerUp.ProductId and powerUp.EnableRobuxPurchase then
                                                local MarketplaceService = game:GetService("MarketplaceService")
                                                MarketplaceService:PromptProductPurchase(player, powerUp.ProductId)
                                            elseif powerUp.Cost and shopEvent then
                                                shopEvent:FireServer(i)
                                            end
                                        end)
                                    end)
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
end

-- Initialize everything with redundancy
local function initializeShop()
    -- Load configs if not loaded
    if not GameConfig or not ShopConfig then
        loadConfigs()
    end
    
    -- Load remote events if not loaded
    if not shopEvent or not purchaseFeedbackEvent or not PowerUpActiveEvent or not PowerUpEndedEvent then
        loadRemoteEvents()
    end
    
    -- Setup event connections
    setupEventConnections()
    
    -- Setup buttons
    setupMainUIButtons()
    
    -- Setup tooltips
    setupGlobalTooltip()
    
    -- Start monitoring
    monitorAndRecover()
    
    logDebug("Shop initialization completed")
end

-- Character management with redundancy
local function setupCharacter(character)
    if not character then return end
    
    safeExecute("setupCharacter", function()
        local humanoid = character:WaitForChild("Humanoid", 10)
        if humanoid then
            humanoid.Died:Connect(function()
                clearAllPowerUpTimers()
            end)
        end
        
        -- Wait a bit for UI to load, then setup buttons
        task.wait(0.2)
        setupMainUIButtons()
        setupGlobalTooltip()
    end)
end

-- Hook into player events with redundancy
player.CharacterAdded:Connect(setupCharacter)

-- Setup for existing character
if player.Character then
    task.wait(0.1)
    setupCharacter(player.Character)
end

-- Initialize shop
initializeShop()

-- Periodic re-initialization for maximum redundancy
task.spawn(function()
    while true do
        task.wait(30) -- Re-initialize every 30 seconds
        initializeShop()
    end
end) 