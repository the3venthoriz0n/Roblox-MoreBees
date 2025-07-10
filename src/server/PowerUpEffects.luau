local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Require GameConfig for constants
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local RemoteEventsManager = require(game.ServerScriptService.Server.RemoteEventsManager)
local PowerUpEndedEvent = RemoteEventsManager.getRemoteEvent("PowerUpEnded")
local PlayerDataManager = require(game.ServerScriptService.Server.PlayerDataManager)

local PowerUpEffects = {}

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
            RemoteEventsManager.firePowerUpEnded(character, "Speed Boost")
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
            RemoteEventsManager.firePowerUpEnded(character, "Health Boost")
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
            RemoteEventsManager.firePowerUpEnded(character, "Bee Shield")
        end)
    end
end

-- More Bees Effect (was SpawnBees)
function PowerUpEffects.MoreBees(character, duration)
    local spawnBeesRequestEvent = ReplicatedStorage:FindFirstChild("SpawnBeesRequestEvent")
    if spawnBeesRequestEvent then
        spawnBeesRequestEvent:Fire(GameConfig.BEE_SPAWN_COUNT, BrickColor.new(GameConfig.BEE_SPAWN_COLOR))
    else
        warn("SpawnBeesRequestEvent not found in ReplicatedStorage!")
    end
end

-- Honey Drip Effect
function PowerUpEffects.HoneyDrip(character, duration)
    local player = Players:GetPlayerFromCharacter(character)
    if player then
        local currentDrips = PlayerDataManager.getPlayerHoneyDrips(player)
        PlayerDataManager.updatePlayerHoneyDrips(player, currentDrips + 1)
        print(player.Name .. " received 1 HoneyDrip from power-up effect!")
    end
end

return PowerUpEffects 