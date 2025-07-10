-- Variable definitions
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local ShopConfig = require(ReplicatedStorage.Shared.ShopConfig)
local RemoteEventsManager = require(game.ServerScriptService.Server.RemoteEventsManager)
local PlayerDataManager = require(game.ServerScriptService.Server.PlayerDataManager)
local PowerUpEffects = {}
local activeEffects = {} -- [player][effectName] = {endTime = number, running = bool}

local function getPlayer(character)
    return Players:GetPlayerFromCharacter(character)
end

local function startOrExtendEffect(player, effectName, duration, onStart, onEnd)
    activeEffects[player] = activeEffects[player] or {}
    local now = os.clock()
    local effect = activeEffects[player][effectName]
    if effect and effect.endTime and effect.endTime > now then
        effect.endTime = effect.endTime + duration
    else
        effect = {endTime = now + duration, running = false}
        activeEffects[player][effectName] = effect
    end
    if not effect.running then
        effect.running = true
        if onStart then onStart() end
        coroutine.wrap(function()
            while os.clock() < effect.endTime do
                task.wait(0.2)
            end
            -- End effect
            if onEnd then onEnd() end
            RemoteEventsManager.firePowerUpEnded(player.Character, effectName)
            activeEffects[player][effectName] = nil
        end)()
    end
end

-- Speed Boost Effect
function PowerUpEffects.SpeedBoost(character, duration)
    local humanoid = character:FindFirstChild("Humanoid")
    local player = getPlayer(character)
    if humanoid and player then
        startOrExtendEffect(player, "Speed Boost", duration,
            function()
                local effect = activeEffects[player]["Speed Boost"]
                if not effect.originalSpeed then
                    effect.originalSpeed = humanoid.WalkSpeed
                end
                humanoid.WalkSpeed = effect.originalSpeed * GameConfig.SPEED_BOOST_MULTIPLIER
            end,
            function()
                local effect = activeEffects[player] and activeEffects[player]["Speed Boost"]
                if humanoid and humanoid.Parent then
                    if effect and effect.originalSpeed then
                        humanoid.WalkSpeed = effect.originalSpeed
                    end
                end
            end
        )
    end
end

-- Health Boost Effect
function PowerUpEffects.HealthBoost(character, duration)
    local humanoid = character:FindFirstChild("Humanoid")
    local player = getPlayer(character)
    if humanoid and player then
        local originalMaxHealth = humanoid.MaxHealth
        startOrExtendEffect(player, "Health Boost", duration,
            function()
                humanoid.MaxHealth = originalMaxHealth + GameConfig.HEALTH_BOOST_AMOUNT
                humanoid.Health = humanoid.Health + GameConfig.HEALTH_BOOST_AMOUNT
            end,
            function()
                if humanoid and humanoid.Parent then
                    humanoid.MaxHealth = originalMaxHealth
                    humanoid.Health = math.min(humanoid.Health, originalMaxHealth)
                end
            end
        )
    end
end

-- Bee Shield Effect
function PowerUpEffects.BeeShield(character, duration)
    local player = getPlayer(character)
    if player then
        startOrExtendEffect(player, "Bee Shield", duration,
            function()
                player:SetAttribute("BeeShield", true)
                -- Create a ForceField for the duration
                if not character:FindFirstChildOfClass("ForceField") then
                    local forceField = Instance.new("ForceField")
                    forceField.Visible = true
                    forceField.Parent = character
                end
            end,
            function()
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