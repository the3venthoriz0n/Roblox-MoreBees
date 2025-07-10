local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PowerUpEffects = {}

-- Helper function to fire power-up ended events
local function firePowerUpEndedEvent(character, powerUpName)
    local player = Players:GetPlayerFromCharacter(character)
    if player then
        local PowerUpEndedEvent = ReplicatedStorage:FindFirstChild("PowerUpEndedEvent")
        if PowerUpEndedEvent then
            PowerUpEndedEvent:FireClient(player, powerUpName)
        end
    end
end

-- Speed Boost Effect
function PowerUpEffects.SpeedBoost(character, duration)
    local humanoid = character:FindFirstChild("Humanoid")
    if humanoid then
        local originalSpeed = humanoid.WalkSpeed
        humanoid.WalkSpeed = originalSpeed * 1.5
        task.delay(duration, function()
            if humanoid and humanoid.Parent then
                humanoid.WalkSpeed = originalSpeed
            end
            firePowerUpEndedEvent(character, "Speed Boost")
        end)
    end
end

-- Health Boost Effect
function PowerUpEffects.HealthBoost(character, duration)
    local humanoid = character:FindFirstChild("Humanoid")
    if humanoid then
        local originalMaxHealth = humanoid.MaxHealth
        humanoid.MaxHealth = originalMaxHealth + 50
        humanoid.Health = humanoid.Health + 50
        task.delay(duration, function()
            if humanoid and humanoid.Parent then
                humanoid.MaxHealth = originalMaxHealth
                humanoid.Health = math.min(humanoid.Health, originalMaxHealth)
            end
            firePowerUpEndedEvent(character, "Health Boost")
        end)
    end
end

-- Bee Shield Effect
function PowerUpEffects.BeeShield(character, duration)
    local player = Players:GetPlayerFromCharacter(character)
    if player then
        player:SetAttribute("BeeShield", true)
        task.delay(duration, function()
            if player then
                player:SetAttribute("BeeShield", false)
            end
            firePowerUpEndedEvent(character, "Bee Shield")
        end)
    end
end

-- Spawn Bees Effect
function PowerUpEffects.SpawnBees(character, duration)
    local spawnBeesRequestEvent = ReplicatedStorage:FindFirstChild("SpawnBeesRequestEvent")
    if spawnBeesRequestEvent then
        spawnBeesRequestEvent:Fire(10, BrickColor.new("Really red"))
    else
        warn("SpawnBeesRequestEvent not found in ReplicatedStorage!")
    end
end

return PowerUpEffects 