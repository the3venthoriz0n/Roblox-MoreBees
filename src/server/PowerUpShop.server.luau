local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Power-up definitions
local POWER_UPS = {
    {
        Name = "Speed Boost",
        Description = "Increases your movement speed by 50% for 30 seconds",
        Cost = 2, -- HoneyDrips
        Duration = 30, -- seconds
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
    }
}

-- Create RemoteEvent for shop interactions
local shopEvent = Instance.new("RemoteEvent")
shopEvent.Name = "PowerUpShopEvent"
shopEvent.Parent = ReplicatedStorage

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

-- Handle shop purchases
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
        
        -- Notify player
        print(player.Name .. " purchased " .. powerUp.Name .. " for " .. powerUp.Cost .. " HoneyDrips")
    else
        print(player.Name .. " tried to purchase " .. powerUp.Name .. " but only has " .. currentHoneyDrips .. " HoneyDrips")
    end
end)

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