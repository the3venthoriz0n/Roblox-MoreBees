local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

-- Power-up definitions
local POWER_UPS = {
    {
        Name = "Speed Boost",
        Description = "Increases your movement speed by 50% for 30 seconds",
        Cost = 2,
        RobuxCost = 5, -- New Robux cost
        ProductId = 12345, -- REPLACE WITH YOUR ACTUAL DEVELOPER PRODUCT ID
        Duration = 30,
        Effect = function(character)
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid then
                local originalSpeed = humanoid.WalkSpeed
                humanoid.WalkSpeed = originalSpeed * 1.5
                task.delay(30, function()
                    if humanoid and humanoid.Parent then
                        humanoid.WalkSpeed = originalSpeed
                    end
                end)
            end
        end
    },
    {
        Name = "Health Boost",
        Description = "Increases your max health by 50 for 1 minute",
        Cost = 3,
        RobuxCost = 10, -- New Robux cost
        ProductId = 67890, -- REPLACE WITH YOUR ACTUAL DEVELOPER PRODUCT ID
        Duration = 60,
        Effect = function(character)
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid then
                local originalMaxHealth = humanoid.MaxHealth
                humanoid.MaxHealth = originalMaxHealth + 50
                humanoid.Health = humanoid.Health + 50
                task.delay(60, function()
                    if humanoid and humanoid.Parent then
                        humanoid.MaxHealth = originalMaxHealth
                        humanoid.Health = math.min(humanoid.Health, originalMaxHealth)
                    end
                end)
            end
        end
    },
    {
        Name = "Bee Shield",
        Description = "Bees cannot sting you for 45 seconds",
        Cost = 4,
        RobuxCost = 20, -- New Robux cost
        ProductId = 11223, -- REPLACE WITH YOUR ACTUAL DEVELOPER PRODUCT ID
        Duration = 45,
        Effect = function(character)
            local player = Players:GetPlayerFromCharacter(character)
            if player then
                player:SetAttribute("BeeShield", true)
                task.delay(45, function()
                    if player then
                        player:SetAttribute("BeeShield", false)
                    end
                end)
            end
        end
    },
    -- New Power-Up: Spawn 10 Bees
    {
        Name = "Spawn Bees",
        Description = "Spawns 10 additional bees",
        Cost = 1, -- 1 HoneyDrip
        RobuxCost = 10, -- 10 Robux
        ProductId = 44556, -- REPLACE WITH YOUR ACTUAL DEVELOPER PRODUCT ID
        Duration = 0, -- Instant effect
        Effect = function(character)
            -- Fire the BindableEvent to request bee spawning
            local spawnBeesRequestEvent = ReplicatedStorage:FindFirstChild("SpawnBeesRequestEvent")
            if spawnBeesRequestEvent then
                spawnBeesRequestEvent:Fire(10) -- Request to spawn 10 bees
            else
                warn("SpawnBeesRequestEvent not found in ReplicatedStorage!")
            end
        end
    }
}

-- Create RemoteEvent for shop interactions
local shopEvent = Instance.new("RemoteEvent")
shopEvent.Name = "PowerUpShopEvent"
shopEvent.Parent = ReplicatedStorage

-- New RemoteEvent for purchase feedback
local purchaseFeedbackEvent = Instance.new("RemoteEvent")
purchaseFeedbackEvent.Name = "PurchaseFeedbackEvent"
purchaseFeedbackEvent.Parent = ReplicatedStorage

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

        -- Optionally, send success feedback to client
        purchaseFeedbackEvent:FireClient(player, "Purchased " .. powerUp.Name .. "!")
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