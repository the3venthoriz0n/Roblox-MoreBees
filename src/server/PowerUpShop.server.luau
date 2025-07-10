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
        -- Fallback config
        ShopConfig = {
            POWER_UPS_DATA = {
                {Name = "Speed Boost", Cost = 2, Duration = 20, EnableRobuxPurchase = true},
                {Name = "Health Boost", Cost = 4, Duration = 20, EnableRobuxPurchase = true},
                {Name = "Bee Shield", Cost = 5, Duration = 30, EnableRobuxPurchase = true},
                {Name = "More Bees", Cost = 10, Duration = 0, EnableRobuxPurchase = true}
            }
        }
    end
    
    success, result = pcall(function()
        return require(game.ServerScriptService.Server.PowerUpEffects)
    end)
    if success then
        PowerUpEffects = result
    else
        warn("Failed to load PowerUpEffects:", result)
        -- Fallback effects
        PowerUpEffects = {
            SpeedBoost = function(character) warn("SpeedBoost effect not available") end,
            HealthBoost = function(character) warn("HealthBoost effect not available") end,
            BeeShield = function(character) warn("BeeShield effect not available") end,
            MoreBees = function(character) warn("MoreBees effect not available") end,
            HoneyDrip = function(character) warn("HoneyDrip effect not available") end
        }
    end
    
    success, result = pcall(function()
        return require(ReplicatedStorage.Shared.GameConfig)
    end)
    if success then
        GameConfig = result
    else
        warn("Failed to load GameConfig:", result)
        -- Fallback config
        GameConfig = {
            LOG_LEVEL = "debug",
            ENABLE_ROBUX_PURCHASES = true
        }
    end
    
    success, result = pcall(function()
        return require(game.ServerScriptService.Server.PlayerDataManager)
    end)
    if success then
        PlayerDataManager = result
    else
        warn("Failed to load PlayerDataManager:", result)
        -- Fallback manager
        PlayerDataManager = {
            getPlayerHoneyDrips = function(player) return 0 end,
            updatePlayerHoneyDrips = function(player, amount) warn("PlayerDataManager not available") end
        }
    end
    
    success, result = pcall(function()
        return require(ReplicatedStorage.Shared.RemoteEventsManager)
    end)
    if success then
        RemoteEventsManager = result
    else
        warn("Failed to load RemoteEventsManager:", result)
        -- Fallback manager
        RemoteEventsManager = {
            connectToEvent = function(eventName, handler) warn("RemoteEventsManager not available") end,
            fireToClient = function(eventName, player, ...) warn("RemoteEventsManager not available") end
        }
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
    if not ShopConfig or not ShopConfig.POWER_UPS_DATA then
        warn("ShopConfig not available for power-up initialization")
        return
    end
    
    safeExecute("initializePowerUps", function()
        for i, data in ipairs(ShopConfig.POWER_UPS_DATA) do
            POWER_UPS[i] = table.clone(data) -- Copy shared data including Duration
        end

        -- Add server-side effects to the copied power-up data
        if POWER_UPS[1] and PowerUpEffects.SpeedBoost then
            POWER_UPS[1].Effect = function(character)
                safeExecute("SpeedBoost effect", PowerUpEffects.SpeedBoost, character, POWER_UPS[1].Duration)
            end
        end

        if POWER_UPS[2] and PowerUpEffects.HealthBoost then
            POWER_UPS[2].Effect = function(character)
                safeExecute("HealthBoost effect", PowerUpEffects.HealthBoost, character, POWER_UPS[2].Duration)
            end
        end

        if POWER_UPS[3] and PowerUpEffects.BeeShield then
            POWER_UPS[3].Effect = function(character)
                safeExecute("BeeShield effect", PowerUpEffects.BeeShield, character, POWER_UPS[3].Duration)
            end
        end

        if POWER_UPS[4] and PowerUpEffects.MoreBees then
            POWER_UPS[4].Effect = function(character)
                safeExecute("MoreBees effect", PowerUpEffects.MoreBees, character, POWER_UPS[4].Duration)
            end
        end

        -- Add Honey Drip effect if present
        if POWER_UPS[5] and PowerUpEffects.HoneyDrip then
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
            if RemoteEventsManager and RemoteEventsManager.fireToClient then
                RemoteEventsManager.fireToClient("PurchaseFeedback", player, "Please use Robux to purchase this power-up.")
            end
            return
        end

        -- Otherwise, use HoneyDrips cost
        if not PlayerDataManager or not PlayerDataManager.getPlayerHoneyDrips then
            warn("PlayerDataManager not available for HoneyDrips check")
            return
        end
        
        local currentHoneyDrips = PlayerDataManager.getPlayerHoneyDrips(player)
        logDebug("Player", player.Name, "has", currentHoneyDrips, "HoneyDrips. PowerUp cost:", powerUp.Cost)
        
        if currentHoneyDrips >= powerUp.Cost then
            -- Deduct HoneyDrips
            if PlayerDataManager.updatePlayerHoneyDrips then
                PlayerDataManager.updatePlayerHoneyDrips(player, currentHoneyDrips - powerUp.Cost)
            end
            
            -- Apply power-up effect
            logDebug("Applying effect for powerUp:", powerUp.Name)
            if powerUp.Effect then
                powerUp.Effect(character)
            end
            
            -- Notify player (server log)
            print(player.Name .. " purchased " .. powerUp.Name .. " for " .. powerUp.Cost .. " HoneyDrips")
            
            -- Send success feedback to client
            logDebug("Firing PurchaseFeedback to client for success")
            if RemoteEventsManager and RemoteEventsManager.fireToClient then
                RemoteEventsManager.fireToClient("PurchaseFeedback", player, "Purchased " .. powerUp.Name .. "!")
            end
            
            -- Signal power-up active to client
            if powerUp.Duration and powerUp.Duration > 0 then
                logDebug("Firing PowerUpActiveEvent for", player.Name, powerUp.Name, powerUp.Duration)
                if RemoteEventsManager and RemoteEventsManager.fireToClient then
                    RemoteEventsManager.fireToClient("PowerUpActive", player, powerUp.Name, powerUp.Duration)
                end
            end
        else
            -- Notify player (server log)
            print(player.Name .. " tried to purchase " .. powerUp.Name .. " with HoneyDrips but only has " .. currentHoneyDrips .. " HoneyDrips")
            
            -- Send insufficient funds feedback to client
            logDebug("Firing PurchaseFeedback to client for insufficient funds")
            if RemoteEventsManager and RemoteEventsManager.fireToClient then
                RemoteEventsManager.fireToClient("PurchaseFeedback", player, "Not enough HoneyDrips!")
            end
        end
    end)
end

-- Connect to remote event with redundancy
if RemoteEventsManager and RemoteEventsManager.connectToEvent then
    RemoteEventsManager.connectToEvent("PowerUpShopEvent", handleShopPurchase)
else
    warn("RemoteEventsManager not available for PowerUpShopEvent connection")
end

-- Handle Robux purchases with redundancy
local function processRobuxReceipt(receiptInfo)
    if not receiptInfo then
        warn("Invalid receipt info")
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end
    
    return safeExecute("processRobuxReceipt", function()
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
                -- Apply power-up effect if defined
                if powerUp.Effect then
                    powerUp.Effect(character)
                    print(player.Name .. " successfully purchased " .. (powerUp.Name or "Unknown PowerUp") .. " with Robux!")
                else
                    warn("No Effect defined for power-up with ProductId:", powerUp.ProductId)
                end
                
                -- Signal power-up active to client if Duration is defined and > 0
                if powerUp.Duration and powerUp.Duration > 0 then
                    if RemoteEventsManager and RemoteEventsManager.fireToClient then
                        RemoteEventsManager.fireToClient("PowerUpActive", player, powerUp.Name or "Unknown PowerUp", powerUp.Duration)
                    end
                end
                return Enum.ProductPurchaseDecision.PurchaseGranted
            end
        end

        return Enum.ProductPurchaseDecision.NotProcessedYet -- Product ID not recognized
    end) or Enum.ProductPurchaseDecision.NotProcessedYet
end

-- Set up MarketplaceService with redundancy
if MarketplaceService then
    MarketplaceService.ProcessReceipt = processRobuxReceipt
else
    warn("MarketplaceService not available")
end

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

-- Start monitoring
monitorAndRecover()

logDebug("PowerUpShop server initialized with redundancy")

