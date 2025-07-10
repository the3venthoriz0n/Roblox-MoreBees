-- Variable definitions
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local ShopConfig = require(ReplicatedStorage.Shared.ShopConfig)
local RemoteEventsManager = require(game.ServerScriptService.Server.RemoteEventsManager)
local PlayerDataManager = require(game.ServerScriptService.Server.PlayerDataManager)
local PowerUpEffects = {}
local activeEffects = {} -- [player][effectName] = {endTime = number, ...}

local function getPlayer(character)
    return Players:GetPlayerFromCharacter(character)
end

local function startOrExtendEffect(player, effectName, duration, onStart, onEnd)
    activeEffects[player] = activeEffects[player] or {}
    local now = os.clock()
    local effect = activeEffects[player][effectName]

    if effect then
        -- Extend effect time
        effect.endTime = math.max(effect.endTime, now) + duration
    else
        -- First-time application
        effect = {endTime = now + duration}
        activeEffects[player][effectName] = effect
    end

    -- Always run onStart in case it needs to re-apply
    if onStart then onStart(effect) end

    -- Start effect timer only once
    if not effect._timerRunning then
        effect._timerRunning = true
        coroutine.wrap(function()
            while os.clock() < effect.endTime do
                task.wait(0.2)
            end
            if onEnd then onEnd(effect) end
            RemoteEventsManager.firePowerUpEnded(player.Character, effectName)
            activeEffects[player][effectName] = nil
        end)()
    end
end

function PowerUpEffects.SpeedBoost(character, duration)
    local humanoid = character:FindFirstChild("Humanoid")
    local player = getPlayer(character)
    if humanoid and player then
        startOrExtendEffect(player, "Speed Boost", duration,
            function(effect)
                if not effect.originalSpeed then
                    effect.originalSpeed = humanoid.WalkSpeed
                    effect.stackCount = 0
                end

                -- Stack another boost
                effect.stackCount = effect.stackCount + 1

                -- Apply new speed
                local multiplier = GameConfig.SPEED_BOOST_MULTIPLIER ^ effect.stackCount
                humanoid.WalkSpeed = effect.originalSpeed * multiplier
            end,
            function(effect)
                -- Reset back to original speed
                if effect.originalSpeed then
                    humanoid.WalkSpeed = effect.originalSpeed
                end
            end
        )
    end
end


function PowerUpEffects.HealthBoost(character, duration)
    local humanoid = character:FindFirstChild("Humanoid")
    local player = getPlayer(character)
    if humanoid and player then
        startOrExtendEffect(player, "Health Boost", duration,
            function(effect)
                if not effect.originalMaxHealth then
                    effect.originalMaxHealth = humanoid.MaxHealth
                end
                humanoid.MaxHealth = effect.originalMaxHealth + GameConfig.HEALTH_BOOST_AMOUNT
                humanoid.Health = humanoid.Health + GameConfig.HEALTH_BOOST_AMOUNT
            end,
            function(effect)
                if humanoid and humanoid.Parent then
                    if effect.originalMaxHealth then
                        humanoid.MaxHealth = effect.originalMaxHealth
                        humanoid.Health = math.min(humanoid.Health, effect.originalMaxHealth)
                    end
                end
            end
        )
    end
end


-- Bee Shield Effect (unchanged)
function PowerUpEffects.BeeShield(character, duration)
    local player = getPlayer(character)
    if player then
        startOrExtendEffect(player, "Bee Shield", duration,
            function(effect)
                player:SetAttribute("BeeShield", true)
                if not character:FindFirstChildOfClass("ForceField") then
                    local forceField = Instance.new("ForceField")
                    forceField.Visible = true
                    forceField.Parent = character
                end
            end,
            function(effect)
                player:SetAttribute("BeeShield", false)
                local forceField = character:FindFirstChildOfClass("ForceField")
                if forceField then
                    forceField:Destroy()
                end
            end
        )
    end
end

-- More Bees Effect (unchanged)
function PowerUpEffects.MoreBees(character, duration)
    local spawnBeesRequestEvent = ReplicatedStorage:FindFirstChild("SpawnBeesRequestEvent")
    if spawnBeesRequestEvent then
        spawnBeesRequestEvent:Fire(GameConfig.BEE_SPAWN_COUNT, BrickColor.new(GameConfig.BEE_SPAWN_COLOR))
    else
        warn("SpawnBeesRequestEvent not found in ReplicatedStorage!")
    end
end

-- Honey Drip Effect (unchanged)
function PowerUpEffects.HoneyDrip(character, duration)
    local player = Players:GetPlayerFromCharacter(character)
    if player then
        local currentDrips = PlayerDataManager.getPlayerHoneyDrips(player)
        PlayerDataManager.updatePlayerHoneyDrips(player, currentDrips + ShopConfig.POWER_UPS_DATA[5].Value)
        print(player.Name .. " received 1 HoneyDrip from power-up effect!")
    end
end

return PowerUpEffects 