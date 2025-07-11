-- Variables defined at the top as per user preference
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

-- Require the shared configurations with redundancy
local GameConfig = nil
local ShopConfig = nil
local Logger = nil

local function loadConfigs()
    local success, result = pcall(function()
        return require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
    end)
    if success then
        GameConfig = result
    else
        warn("Failed to load GameConfig:", result)
        GameConfig = nil
    end
    
    success, result = pcall(function()
        return require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ShopConfig"))
    end)
    if success then
        ShopConfig = result
    else
        warn("Failed to load ShopConfig:", result)
        ShopConfig = nil
    end
    
    success, result = pcall(function()
        return require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Logger"))
    end)
    if success then
        Logger = result
    else
        warn("Failed to load Logger:", result)
        Logger = nil
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
        if Logger then Logger.debug("Successfully loaded PowerUpShopEvent") end
    else
        warn("Failed to load PowerUpShopEvent:", result)
    end
    
    success, result = pcall(function()
        return ReplicatedStorage:WaitForChild("PurchaseFeedbackEvent", 10)
    end)
    if success then
        purchaseFeedbackEvent = result
        if Logger then Logger.debug("Successfully loaded PurchaseFeedbackEvent") end
    else
        warn("Failed to load PurchaseFeedbackEvent:", result)
    end
    
    success, result = pcall(function()
        return ReplicatedStorage:WaitForChild("PowerUpActiveEvent", 10)
    end)
    if success then
        PowerUpActiveEvent = result
        if Logger then Logger.debug("Successfully loaded PowerUpActiveEvent") end
    else
        warn("Failed to load PowerUpActiveEvent:", result)
    end
    
    success, result = pcall(function()
        return ReplicatedStorage:WaitForChild("PowerUpEndedEvent", 10)
    end)
    if success then
        PowerUpEndedEvent = result
        if Logger then Logger.debug("Successfully loaded PowerUpEndedEvent") end
    else
        warn("Failed to load PowerUpEndedEvent:", result)
    end
    
    -- Return true if all events were loaded successfully
    return shopEvent and purchaseFeedbackEvent and PowerUpActiveEvent and PowerUpEndedEvent
end

-- Load remote events immediately
loadRemoteEvents()

-- Debug logging function with redundancy
local function logDebug(...)
    if Logger then
        Logger.debug("[PowerUpShop.client]", ...)
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
                -- Show NotEnoughDrips text if purchase failed
                if message == "Not enough HoneyDrips!" then
                    local counterGui = player.PlayerGui:FindFirstChild("CounterGui")
                    if counterGui then
                        local notEnoughDrips = counterGui:FindFirstChild("NotEnoughDrips")
                        if notEnoughDrips then
                            -- Center the text on screen
                            notEnoughDrips.AnchorPoint = Vector2.new(0.5, 0.5)
                            notEnoughDrips.Position = UDim2.new(0.5, 0, 0.5, 0)
                            notEnoughDrips.Visible = true
                            task.delay(1, function()
                                if notEnoughDrips then
                                    notEnoughDrips.Visible = false
                                end
                            end)
                        end
                    end
                end
            end)
        end)
    end
end

-- SIMPLIFIED Button connection management
local buttonConnections = {}

local function connectButton(buttonName, handler)
    if not buttonName or not handler then
        warn("Invalid parameters for connectButton:", buttonName, handler)
        return
    end
    
    if Logger then Logger.debug("Attempting to connect button:", buttonName) end
    
    -- Wait for PlayerGui and MainUI
    local playerGui = player:WaitForChild("PlayerGui", 10)
    if not playerGui then
        warn("PlayerGui not found")
        return
    end
    
    local mainUI = playerGui:WaitForChild("MainUI", 10)
    if not mainUI then
        warn("MainUI not found")
        return
    end
    
    -- Find the button
    local button = mainUI:FindFirstChild(buttonName)
    if not button then
        warn("Button not found:", buttonName)
        -- List available buttons for debugging
        if Logger then
            Logger.debug("Available buttons in MainUI:")
            for _, child in ipairs(mainUI:GetChildren()) do
                if child:IsA("GuiObject") then
                    Logger.debug("  - " .. child.Name)
                end
            end
        end
        return
    end
    
    -- Disconnect previous connection if exists
    if buttonConnections[button] then
        buttonConnections[button]:Disconnect()
    end
    
    -- Connect the new handler
    buttonConnections[button] = button.MouseButton1Click:Connect(handler)
    if Logger then Logger.debug("Successfully connected button:", buttonName) end
    return true
end

local function setupMainUIButtons()
    if not ShopConfig then
        warn("ShopConfig not available for button setup")
        return
    end
    if not ShopConfig.POWER_UPS_DATA then
        warn("ShopConfig.POWER_UPS_DATA not available for button setup")
        return
    end
    
    if Logger then Logger.debug("Setting up shop buttons...") end
    
    local connectedCount = 0
    for i, powerUp in ipairs(ShopConfig.POWER_UPS_DATA) do
        local buttonName = powerUp.Name:gsub(" ", "")
        if Logger then Logger.debug("Looking for button:", buttonName, "for power-up:", powerUp.Name) end
        
        if connectButton(buttonName, function()
            if Logger then Logger.debug("Button clicked:", buttonName) end
            
            if powerUp.ProductId and powerUp.EnableRobuxPurchase then
                logDebug(buttonName .. " button clicked, prompting Robux purchase.")
                local MarketplaceService = game:GetService("MarketplaceService")
                MarketplaceService:PromptProductPurchase(player, powerUp.ProductId)
            elseif powerUp.Cost and shopEvent then
                logDebug(buttonName .. " button clicked, purchasing with HoneyDrips.")
                if Logger then Logger.debug("Firing PowerUpShopEvent with index:", i) end
                shopEvent:FireServer(i)
            else
                logDebug(buttonName .. " button clicked, but no valid purchase method found.")
            end
        end) then
            connectedCount = connectedCount + 1
        end
    end
    
    if Logger then Logger.info("Connected " .. connectedCount .. " out of " .. #ShopConfig.POWER_UPS_DATA .. " shop buttons successfully!") end
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
    end)
end

local function setupGlobalTooltip()
    if not ShopConfig then
        warn("ShopConfig not available for tooltip setup")
        return
    end
    if not ShopConfig.POWER_UPS_DATA then
        warn("ShopConfig.POWER_UPS_DATA not available for tooltip setup")
        return
    end
    
    safeExecute("setupGlobalTooltip", function()
        local playerGui = player:WaitForChild("PlayerGui", 10)
        if not playerGui then return end
        
        local mainUI = playerGui:WaitForChild("MainUI", 10)
        if not mainUI then return end
        
        local globalTooltip = mainUI:FindFirstChild("GlobalToolTip")
        if not globalTooltip then return end

        -- Tooltip delay tracking
        local tooltipDelays = {}
        local tooltipDelay = GameConfig and GameConfig.TOOLTIP_DELAY or 0.5 -- Default to 0.5 seconds

        for i, powerUp in ipairs(ShopConfig.POWER_UPS_DATA) do
            local buttonName = powerUp.Name:gsub(" ", "")
            if buttonName then
                local button = mainUI:FindFirstChild(buttonName)
                if button then
                    local desc = powerUp.Description or ""
                    
                    local function show()
                        -- Cancel any existing delay for this button
                        if tooltipDelays[button] then
                            tooltipDelays[button] = false
                        end
                        
                        -- Set up delayed tooltip display
                        local shouldShow = true
                        tooltipDelays[button] = shouldShow
                        
                        task.delay(tooltipDelay, function()
                            -- Only show if the delay hasn't been cancelled
                            if tooltipDelays[button] == shouldShow then
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
                        end)
                    end
                    
                    local function hide()
                        -- Cancel the delayed tooltip if it hasn't shown yet
                        if tooltipDelays[button] then
                            tooltipDelays[button] = false
                        end
                        
                        -- Hide tooltip immediately
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

-- Simple initialization function
local function initializeShop()
    if Logger then Logger.debug("Initializing shop...") end
    
    -- Load configs if not loaded
    if not GameConfig then
        loadConfigs()
    end
    if not ShopConfig then
        loadConfigs()
    end
    
    -- Load remote events if not loaded
    if not shopEvent or not purchaseFeedbackEvent or not PowerUpActiveEvent or not PowerUpEndedEvent then
        if not loadRemoteEvents() then
            if Logger then Logger.debug("Failed to load all remote events") end
            return false
        end
    end
    
    -- Wait for all required components to be available
    if not GameConfig or not ShopConfig or not shopEvent or not purchaseFeedbackEvent or not PowerUpActiveEvent or not PowerUpEndedEvent then
        if Logger then Logger.debug("Waiting for required components to load...") end
        task.wait(0.5)
        return false -- Indicate initialization is not complete
    end
    
    -- Setup event connections
    setupEventConnections()
    
    -- Setup buttons
    setupMainUIButtons()
    
    -- Setup tooltips
    setupGlobalTooltip()
    
    if Logger then Logger.debug("Shop initialization completed") end
    return true -- Indicate initialization is complete
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
        
        -- Wait for UI to load, then setup buttons
        task.wait(0.5) -- Increased wait time to ensure UI is loaded
        setupMainUIButtons()
        setupGlobalTooltip()
    end)
end

-- Hook into player events with redundancy
player.CharacterAdded:Connect(setupCharacter)

-- Setup for existing character
if player.Character then
    task.wait(0.2) -- Increased wait time
    setupCharacter(player.Character)
end

-- Initialize shop with retry logic
local function initializeShopWithRetry()
    local maxRetries = 5
    local retryCount = 0
    
    while retryCount < maxRetries do
        if initializeShop() then
            if Logger then Logger.debug("Shop initialization successful on attempt", retryCount + 1) end
            break
        else
            retryCount = retryCount + 1
            if Logger then Logger.debug("Shop initialization failed, retrying... (", retryCount, "/", maxRetries, ")") end
            task.wait(1) -- Wait before retry
        end
    end
    
    if retryCount >= maxRetries then
        warn("[DEBUG] Failed to initialize shop after", maxRetries, "attempts")
    end
end

-- Initialize shop
initializeShopWithRetry()

-- Simple periodic re-initialization with retry logic
task.spawn(function()
    while true do
        task.wait(30) -- Re-initialize every 30 seconds
        initializeShopWithRetry()
    end
end) 