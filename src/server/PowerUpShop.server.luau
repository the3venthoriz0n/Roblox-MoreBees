-- Variables defined at the top as per user preference
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

-- Require modules with redundancy
local ShopConfig = nil
local PowerUpEffects = nil
local GameConfig = nil
local PlayerDataManager = nil
local RemoteEventsManager = nil

local function loadModules()
    local success, result = pcall(function()
        return require(ReplicatedStorage.Shared.ShopConfig)
    end)
    if success then
        ShopConfig = result
    else
        warn("Failed to load ShopConfig:", result)
        ShopConfig = nil
    end
    
    success, result = pcall(function()
        return require(game.ServerScriptService.Server.PowerUpEffects)
    end)
    if success then
        PowerUpEffects = result
    else
        warn("Failed to load PowerUpEffects:", result)
        PowerUpEffects = nil
    end
    
    success, result = pcall(function()
        return require(ReplicatedStorage.Shared.GameConfig)
    end)
    if success then
        GameConfig = result
    else
        warn("Failed to load GameConfig:", result)
        GameConfig = nil
    end
    
    success, result = pcall(function()
        return require(game.ServerScriptService.Server.PlayerDataManager)
    end)
    if success then
        PlayerDataManager = result
    else
        warn("Failed to load PlayerDataManager:", result)
        PlayerDataManager = nil
    end
    
    success, result = pcall(function()
        return require(ReplicatedStorage.Shared.RemoteEventsManager)
    end)
    if success then
        RemoteEventsManager = result
    else
        warn("Failed to load RemoteEventsManager:", result)
        RemoteEventsManager = nil
    end
end

-- Load modules immediately
loadModules()

local function logDebug(...)
    if GameConfig and GameConfig.LOG_LEVEL == "debug" then
        print("[DEBUG][PowerUpShop.server]", ...)
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

-- Define server-side POWER_UPS with effects (durations will come from ShopConfig)
-- This table will combine the shared data with server-specific logic
local POWER_UPS = {}

local function initializePowerUps()
    if not ShopConfig then
        warn("ShopConfig not available for power-up initialization")
        return
    end
    if not ShopConfig.POWER_UPS_DATA then
        warn("ShopConfig.POWER_UPS_DATA not available for power-up initialization")
        return
    end
    
    safeExecute("initializePowerUps", function()
        for i, data in ipairs(ShopConfig.POWER_UPS_DATA) do
            POWER_UPS[i] = table.clone(data) -- Copy shared data including Duration
        end

        -- Add server-side effects to the copied power-up data
        if POWER_UPS[1] and PowerUpEffects and PowerUpEffects.SpeedBoost then
            POWER_UPS[1].Effect = function(character)
                safeExecute("SpeedBoost effect", PowerUpEffects.SpeedBoost, character, POWER_UPS[1].Duration)
            end
        end

        if POWER_UPS[2] and PowerUpEffects and PowerUpEffects.HealthBoost then
            POWER_UPS[2].Effect = function(character)
                safeExecute("HealthBoost effect", PowerUpEffects.HealthBoost, character, POWER_UPS[2].Duration)
            end
        end

        if POWER_UPS[3] and PowerUpEffects and PowerUpEffects.BeeShield then
            POWER_UPS[3].Effect = function(character)
                safeExecute("BeeShield effect", PowerUpEffects.BeeShield, character, POWER_UPS[3].Duration)
            end
        end

        if POWER_UPS[4] and PowerUpEffects and PowerUpEffects.MoreBees then
            POWER_UPS[4].Effect = function(character)
                safeExecute("MoreBees effect", PowerUpEffects.MoreBees, character, POWER_UPS[4].Duration)
            end
        end

        -- Add Honey Drip effect if present
        if POWER_UPS[5] and PowerUpEffects and PowerUpEffects.HoneyDrip then
            POWER_UPS[5].Effect = function(character)
                safeExecute("HoneyDrip effect", PowerUpEffects.HoneyDrip, character, POWER_UPS[5].Duration)
            end
        end
        
        logDebug("Power-ups initialized successfully")
    end)
end

-- Initialize power-ups
initializePowerUps()

-- Handle shop purchases (HoneyDrips) with redundancy
local function handleShopPurchase(player, powerUpIndex)
    if not player then
        warn("Invalid player for shop purchase")
        return
    end
    
    if not powerUpIndex or not POWER_UPS[powerUpIndex] then
        warn("Invalid powerUpIndex:", powerUpIndex)
        return
    end
    
    safeExecute("handleShopPurchase", function()
        local character = player.Character
        if not character then
            logDebug("No character for player", player.Name)
            return
        end

        local powerUp = POWER_UPS[powerUpIndex]
        if not powerUp then
            logDebug("Invalid powerUpIndex:", powerUpIndex)
            return
        end

        -- If Robux purchase is enabled for this item, instruct client to use Robux dialog
        if powerUp.EnableRobuxPurchase then
            logDebug("Robux purchase enabled for", powerUp.Name, "- instructing client to use Robux dialog.")
            RemoteEventsManager.fireToClient("PurchaseFeedback", player, "Please use Robux to purchase this power-up.")
            return
        end

        -- Otherwise, use HoneyDrips cost
        if not PlayerDataManager then
            warn("PlayerDataManager not available for HoneyDrips check")
            return
        end
        
        local currentHoneyDrips = PlayerDataManager.getPlayerHoneyDrips(player)
        logDebug("Player", player.Name, "has", currentHoneyDrips, "HoneyDrips. PowerUp cost:", powerUp.Cost)
        
        if currentHoneyDrips >= powerUp.Cost then
            -- Deduct HoneyDrips
            PlayerDataManager.updatePlayerHoneyDrips(player, currentHoneyDrips - powerUp.Cost)
            
            -- Apply power-up effect
            logDebug("Applying effect for powerUp:", powerUp.Name)
            if powerUp.Effect then
                powerUp.Effect(character)
            end
            
            -- Notify player (server log)
            print(player.Name .. " purchased " .. powerUp.Name .. " for " .. powerUp.Cost .. " HoneyDrips")
            
            -- Send success feedback to client
            logDebug("Firing PurchaseFeedback to client for success")
            RemoteEventsManager.fireToClient("PurchaseFeedback", player, "Purchased " .. powerUp.Name .. "!")
            
            -- Signal power-up active to client
            if powerUp.Duration and powerUp.Duration > 0 then
                logDebug("Firing PowerUpActiveEvent for", player.Name, powerUp.Name, powerUp.Duration)
                RemoteEventsManager.fireToClient("PowerUpActive", player, powerUp.Name, powerUp.Duration)
            end
        else
            -- Notify player (server log)
            print(player.Name .. " tried to purchase " .. powerUp.Name .. " with HoneyDrips but only has " .. currentHoneyDrips .. " HoneyDrips")
            
            -- Send insufficient funds feedback to client
            logDebug("Firing PurchaseFeedback to client for insufficient funds")
            RemoteEventsManager.fireToClient("PurchaseFeedback", player, "Not enough HoneyDrips!")
        end
    end)
end

-- Connect to remote event with redundancy
local connection = RemoteEventsManager.connectToEvent("PowerUpShopEvent", handleShopPurchase)
if connection then
    print("[DEBUG] Successfully connected to PowerUpShopEvent")
else
    warn("Failed to connect to PowerUpShopEvent")
end

-- Track processed receipts to prevent duplicate processing
local processedReceipts = {}

-- Handle Robux purchases with redundancy and duplicate prevention
local function processRobuxReceipt(receiptInfo)
    if not receiptInfo then
        warn("Invalid receipt info")
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end
    
    return safeExecute("processRobuxReceipt", function()
        -- Check if this receipt has already been processed
        local receiptKey = receiptInfo.PlayerId .. "_" .. receiptInfo.PurchaseId
        if processedReceipts[receiptKey] then
            logDebug("Receipt already processed for player:", receiptInfo.PlayerId, "purchase:", receiptInfo.PurchaseId)
            return Enum.ProductPurchaseDecision.PurchaseGranted -- Already processed, return success
        end
        
        local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
        if not player then
            return Enum.ProductPurchaseDecision.NotProcessedYet -- Player not in game
        end

        local character = player.Character
        if not character then
            return Enum.ProductPurchaseDecision.NotProcessedYet -- Character not loaded yet
        end

        -- Find the power-up associated with the product ID
        for _, powerUp in ipairs(POWER_UPS) do
            if powerUp.ProductId == receiptInfo.ProductId then
                -- Mark receipt as processed before applying effect
                processedReceipts[receiptKey] = true
                
                -- Apply power-up effect if defined
                if powerUp.Effect then
                    powerUp.Effect(character)
                    print(player.Name .. " successfully purchased " .. (powerUp.Name or "Unknown PowerUp") .. " with Robux!")
                else
                    warn("No Effect defined for power-up with ProductId:", powerUp.ProductId)
                end
                
                -- Signal power-up active to client if Duration is defined and > 0
                if powerUp.Duration and powerUp.Duration > 0 then
                    RemoteEventsManager.fireToClient("PowerUpActive", player, powerUp.Name or "Unknown PowerUp", powerUp.Duration)
                end
                return Enum.ProductPurchaseDecision.PurchaseGranted
            end
        end

        return Enum.ProductPurchaseDecision.NotProcessedYet -- Product ID not recognized
    end) or Enum.ProductPurchaseDecision.NotProcessedYet
end

-- Set up MarketplaceService with redundancy
MarketplaceService.ProcessReceipt = processRobuxReceipt

-- Recovery and monitoring system
local function monitorAndRecover()
    task.spawn(function()
        while true do
            task.wait(30) -- Check every 30 seconds
            
            -- Reload modules if they're missing
            if not ShopConfig or not PowerUpEffects or not GameConfig or not PlayerDataManager or not RemoteEventsManager then
                logDebug("Reloading missing modules...")
                loadModules()
                initializePowerUps()
            end
            
            -- Reconnect to remote events if needed
            if RemoteEventsManager and RemoteEventsManager.connectToEvent then
                -- This would need to be implemented in RemoteEventsManager to avoid duplicate connections
                logDebug("Checking remote event connections...")
            end
        end
    end)
end

-- Clean up player data when they leave
Players.PlayerRemoving:Connect(function(player)
    -- Clean up processed receipts for this player
    local playerId = player.UserId
    for receiptKey, _ in pairs(processedReceipts) do
        if receiptKey:find(tostring(playerId) .. "_") then
            processedReceipts[receiptKey] = nil
        end
    end
end)

-- Start monitoring
monitorAndRecover()

logDebug("PowerUpShop server initialized with redundancy")

