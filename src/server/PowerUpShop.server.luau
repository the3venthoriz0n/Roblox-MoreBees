local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

-- Require the shared shop configuration data
local ShopConfig = require(ReplicatedStorage.Shared.ShopConfig)

-- Define server-side POWER_UPS with effects (durations will come from ShopConfig)
-- This table will combine the shared data with server-specific logic
local POWER_UPS = {}
for i, data in ipairs(ShopConfig.POWER_UPS_DATA) do
    POWER_UPS[i] = table.clone(data) -- Copy shared data including Duration
end

-- Add server-side effects to the copied power-up data
POWER_UPS[1].Effect = function(character)
    local humanoid = character:FindFirstChild("Humanoid")
    if humanoid then
        local originalSpeed = humanoid.WalkSpeed
        humanoid.WalkSpeed = originalSpeed * 1.5
        task.delay(POWER_UPS[1].Duration, function()
            if humanoid and humanoid.Parent then
                humanoid.WalkSpeed = originalSpeed
            end
            PowerUpEndedEvent:FireClient(Players:GetPlayerFromCharacter(character), POWER_UPS[1].Name) -- Signal end of effect
        end)
    end
end

POWER_UPS[2].Effect = function(character)
    local humanoid = character:FindFirstChild("Humanoid")
    if humanoid then
        local originalMaxHealth = humanoid.MaxHealth
        humanoid.MaxHealth = originalMaxHealth + 50
        humanoid.Health = humanoid.Health + 50
        task.delay(POWER_UPS[2].Duration, function()
            if humanoid and humanoid.Parent then
                humanoid.MaxHealth = originalMaxHealth
                humanoid.Health = math.min(humanoid.Health, originalMaxHealth)
            end
            PowerUpEndedEvent:FireClient(Players:GetPlayerFromCharacter(character), POWER_UPS[2].Name) -- Signal end of effect
        end)
    end
end

POWER_UPS[3].Effect = function(character)
    local player = Players:GetPlayerFromCharacter(character)
    if player then
        player:SetAttribute("BeeShield", true)
        task.delay(POWER_UPS[3].Duration, function()
            if player then
                player:SetAttribute("BeeShield", false)
            end
            PowerUpEndedEvent:FireClient(player, POWER_UPS[3].Name) -- Signal end of effect
        end)
    end
end

POWER_UPS[4].Effect = function(character)
    -- Fire the BindableEvent to request bee spawning
    local spawnBeesRequestEvent = ReplicatedStorage:FindFirstChild("SpawnBeesRequestEvent")
    if spawnBeesRequestEvent then
        spawnBeesRequestEvent:Fire(10, BrickColor.new("Really red")) -- Request to spawn 10 red bees
    else
        warn("SpawnBeesRequestEvent not found in ReplicatedStorage!")
    end
end

-- Create RemoteEvent for shop interactions
local shopEvent = Instance.new("RemoteEvent")
shopEvent.Name = "PowerUpShopEvent"
shopEvent.Parent = ReplicatedStorage

-- New RemoteEvent for purchase feedback
local purchaseFeedbackEvent = Instance.new("RemoteEvent")
purchaseFeedbackEvent.Name = "PurchaseFeedbackEvent"
purchaseFeedbackEvent.Parent = ReplicatedStorage

-- New RemoteEvent for signaling active power-ups to the client
local PowerUpActiveEvent = Instance.new("RemoteEvent")
PowerUpActiveEvent.Name = "PowerUpActiveEvent"
PowerUpActiveEvent.Parent = ReplicatedStorage

-- New RemoteEvent for signaling power-up end to the client
local PowerUpEndedEvent = Instance.new("RemoteEvent")
PowerUpEndedEvent.Name = "PowerUpEndedEvent"
PowerUpEndedEvent.Parent = ReplicatedStorage

-- Function to get player's HoneyDrip count
local function getPlayerHoneyDrips(player)
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        local honeyDrips = leaderstats:FindFirstChild("HoneyDrips")
        return honeyDrips and honeyDrips.Value or 0
    end
    return 0
end

-- Function to update player's HoneyDrip count
local function updatePlayerHoneyDrips(player, newAmount)
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        local honeyDrips = leaderstats:FindFirstChild("HoneyDrips")
        if not honeyDrips then
            honeyDrips = Instance.new("IntValue")
            honeyDrips.Name = "HoneyDrips"
            honeyDrips.Parent = leaderstats
        end
        honeyDrips.Value = newAmount
    end
end

-- Handle shop purchases (HoneyDrips)
shopEvent.OnServerEvent:Connect(function(player, powerUpIndex)
    local character = player.Character
    if not character then return end

    local powerUp = POWER_UPS[powerUpIndex]
    if not powerUp then return end

    local currentHoneyDrips = getPlayerHoneyDrips(player)
    if currentHoneyDrips >= powerUp.Cost then
        -- Deduct HoneyDrips
        updatePlayerHoneyDrips(player, currentHoneyDrips - powerUp.Cost)
        
        -- Apply power-up effect
        powerUp.Effect(character)
        
        -- Notify player (server log)
        print(player.Name .. " purchased " .. powerUp.Name .. " for " .. powerUp.Cost .. " HoneyDrips")

        -- Send success feedback to client
        purchaseFeedbackEvent:FireClient(player, "Purchased " .. powerUp.Name .. "!")

        -- Signal power-up active to client
        if powerUp.Duration > 0 then
            PowerUpActiveEvent:FireClient(player, powerUp.Name, powerUp.Duration)
        end

    else
        -- Notify player (server log)
        print(player.Name .. " tried to purchase " .. powerUp.Name .. " with HoneyDrips but only has " .. currentHoneyDrips .. " HoneyDrips")
        
        -- Send insufficient funds feedback to client
        purchaseFeedbackEvent:FireClient(player, "Not enough HoneyDrips!")
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
                PowerUpActiveEvent:FireClient(player, powerUp.Name, powerUp.Duration)
            end

            return Enum.ProductPurchaseDecision.PurchaseGranted
        end
    end

    return Enum.ProductPurchaseDecision.NotProcessedYet -- Product ID not recognized
end

MarketplaceService.ProcessReceipt = processRobuxReceipt

-- Create RemoteEvent for toggling shop visibility
local toggleShopEvent = Instance.new("RemoteEvent")
toggleShopEvent.Name = "ToggleShopEvent"
toggleShopEvent.Parent = ReplicatedStorage

-- Handle shop visibility toggle
toggleShopEvent.OnServerEvent:Connect(function(player)
    print("ToggleShopEvent received on server for player: ", player.Name)
    -- Instead of trying to find the GUI on the server, fire the event back to the client
    toggleShopEvent:FireClient(player)
    print("Server fired ToggleShopEvent back to client for player: ", player.Name)
end) 