local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Require GameConfig for constants
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local RemoteEventsManager = require(game.ServerScriptService.Server.RemoteEventsManager)
local PowerUpEndedEvent = RemoteEventsManager.getRemoteEvent("PowerUpEnded")

local PowerUpEffects = {}

-- Helper function to fire power-up ended events
local function firePowerUpEndedEvent(character, powerUpName)
    local player = Players:GetPlayerFromCharacter(character)
    if player then
        PowerUpEndedEvent:FireClient(player, powerUpName)
    end
end

-- Speed Boost Effect
function PowerUpEffects.SpeedBoost(character, duration)
    local humanoid = character:FindFirstChild("Humanoid")
    if humanoid then
        local originalSpeed = humanoid.WalkSpeed
        humanoid.WalkSpeed = originalSpeed * GameConfig.SPEED_BOOST_MULTIPLIER
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
        humanoid.MaxHealth = originalMaxHealth + GameConfig.HEALTH_BOOST_AMOUNT
        humanoid.Health = humanoid.Health + GameConfig.HEALTH_BOOST_AMOUNT
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
        spawnBeesRequestEvent:Fire(GameConfig.BEE_SPAWN_COUNT, BrickColor.new(GameConfig.BEE_SPAWN_COLOR))
    else
        warn("SpawnBeesRequestEvent not found in ReplicatedStorage!")
    end
end

return PowerUpEffects 