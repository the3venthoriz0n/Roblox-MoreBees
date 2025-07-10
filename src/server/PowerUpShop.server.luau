local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

-- Require modules
local ShopConfig = require(ReplicatedStorage.Shared.ShopConfig)
local PowerUpEffects = require(game.ServerScriptService.Server.PowerUpEffects)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local PlayerDataManager = require(game.ServerScriptService.Server.PlayerDataManager)
local RemoteEventsManager = require(game.ServerScriptService.Server.RemoteEventsManager)

local function logDebug(...)
    if GameConfig.LOG_LEVEL == "debug" then
        print("[DEBUG][PowerUpShop.server]", ...)
    end
end


-- Define server-side POWER_UPS with effects (durations will come from ShopConfig)
-- This table will combine the shared data with server-specific logic
local POWER_UPS = {}
for i, data in ipairs(ShopConfig.POWER_UPS_DATA) do
    POWER_UPS[i] = table.clone(data) -- Copy shared data including Duration
end

-- Add server-side effects to the copied power-up data
POWER_UPS[1].Effect = function(character)
    PowerUpEffects.SpeedBoost(character, POWER_UPS[1].Duration)
end

POWER_UPS[2].Effect = function(character)
    PowerUpEffects.HealthBoost(character, POWER_UPS[2].Duration)
end

POWER_UPS[3].Effect = function(character)
    PowerUpEffects.BeeShield(character, POWER_UPS[3].Duration)
end

POWER_UPS[4].Effect = function(character)
    PowerUpEffects.SpawnBees(character, POWER_UPS[4].Duration)
end

-- Handle shop purchases (HoneyDrips)
RemoteEventsManager.connectToEvent("PowerUpShop", function(player, powerUpIndex)
    logDebug("shopEvent.OnServerEvent called for player:", player and player.Name or tostring(player), "powerUpIndex:", powerUpIndex)
    local character = player.Character
    if not character then
        logDebug("No character for player", player and player.Name or tostring(player))
        return
    end

    local powerUp = POWER_UPS[powerUpIndex]
    if not powerUp then
        logDebug("Invalid powerUpIndex:", powerUpIndex)
        return
    end

    local currentHoneyDrips = PlayerDataManager.getPlayerHoneyDrips(player)
    logDebug("Player", player.Name, "has", currentHoneyDrips, "HoneyDrips. PowerUp cost:", powerUp.Cost)
    if currentHoneyDrips >= powerUp.Cost then
        -- Deduct HoneyDrips
        PlayerDataManager.updatePlayerHoneyDrips(player, currentHoneyDrips - powerUp.Cost)
        
        -- Apply power-up effect
        logDebug("Applying effect for powerUp:", powerUp.Name)
        powerUp.Effect(character)
        
        -- Notify player (server log)
        print(player.Name .. " purchased " .. powerUp.Name .. " for " .. powerUp.Cost .. " HoneyDrips")

        -- Send success feedback to client
        logDebug("Firing PurchaseFeedback to client for success")
        RemoteEventsManager.fireToClient("PurchaseFeedback", player, "Purchased " .. powerUp.Name .. "!")

        -- Signal power-up active to client
        if powerUp.Duration > 0 then
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

-- Handle Robux purchases
local function processRobuxReceipt(receiptInfo)
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
            -- Apply power-up effect
            powerUp.Effect(character)
            print(player.Name .. " successfully purchased " .. powerUp.Name .. " with Robux!")
            
            -- Signal power-up active to client
            if powerUp.Duration > 0 then
                RemoteEventsManager.fireToClient("PowerUpActive", player, powerUp.Name, powerUp.Duration)
            end

            return Enum.ProductPurchaseDecision.PurchaseGranted
        end
    end

    return Enum.ProductPurchaseDecision.NotProcessedYet -- Product ID not recognized
end

MarketplaceService.ProcessReceipt = processRobuxReceipt

