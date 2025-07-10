local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Require GameConfig for constants
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local PlayerDataManager = {}

-- Create a folder in ReplicatedStorage for scores
local scoresFolder = Instance.new("Folder")
scoresFolder.Name = "PlayerScores"
scoresFolder.Parent = ReplicatedStorage

-- ============================================================================
-- PLAYER STATS MANAGEMENT
-- ============================================================================

-- Initialize player stats when they join
-- Inline their logic into onPlayerAdded if only used there
-- function PlayerDataManager.initializePlayerStats(player)
--     -- Create leaderstats folder if it doesn't exist
--     local leaderstats = player:FindFirstChild("leaderstats")
--     if not leaderstats then
--         leaderstats = Instance.new("Folder")
--         leaderstats.Name = "leaderstats"
--         leaderstats.Parent = player
--     end
    
--     -- Create HoneyDrips stat if it doesn't exist
--     local honeyDrips = leaderstats:FindFirstChild("HoneyDrips")
--     if not honeyDrips then
--         honeyDrips = Instance.new("IntValue")
--         honeyDrips.Name = "HoneyDrips"
--         honeyDrips.Value = 0
--         honeyDrips.Parent = leaderstats
--     end
--     return leaderstats
-- end

-- function PlayerDataManager.setDebugHoneyDrips(player)
--     local leaderstats = player:FindFirstChild("leaderstats") or player:WaitForChild("leaderstats")
--     local honeyDrips = leaderstats:FindFirstChild("HoneyDrips") or leaderstats:WaitForChild("HoneyDrips")
--     honeyDrips.Value = GameConfig.DEBUG_HONEY_DRIPS_VALUE
-- end

-- ============================================================================
-- HONEYDRIPS MANAGEMENT
-- ============================================================================

-- Helper functions for HoneyDrips
function PlayerDataManager.getPlayerHoneyDrips(player)
    local leaderstats = player:WaitForChild("leaderstats")
    if not leaderstats then
        warn("getPlayerHoneyDrips: CRITICAL - leaderstats still nil after initialization for player: ", player.Name)
        return 0 -- Prevent further errors by returning a default value
    end
    
    local honeyDrips = leaderstats:FindFirstChild("HoneyDrips")
    if not honeyDrips then
        warn("getPlayerHoneyDrips: HoneyDrips not found for player: ", player.Name)
        honeyDrips = Instance.new("IntValue")
        honeyDrips.Name = "HoneyDrips"
        honeyDrips.Value = 0
        honeyDrips.Parent = leaderstats
    end
    return honeyDrips.Value
end

function PlayerDataManager.updatePlayerHoneyDrips(player, newAmount)
    local leaderstats = player:WaitForChild("leaderstats")
    if not leaderstats then
        warn("updatePlayerHoneyDrips: CRITICAL - leaderstats still nil after initialization for player: ", player.Name)
        return -- Cannot proceed without leaderstats
    end
    
    local honeyDrips = leaderstats:FindFirstChild("HoneyDrips")
    if not honeyDrips then
        -- Create HoneyDrips stat if it doesn't exist
        honeyDrips = Instance.new("IntValue")
        honeyDrips.Name = "HoneyDrips"
        honeyDrips.Value = 0
        honeyDrips.Parent = leaderstats
    end
    honeyDrips.Value = newAmount
end

-- ============================================================================
-- SCORING MANAGEMENT
-- ============================================================================

-- Function to get or create a player's score value
function PlayerDataManager.getPlayerScore(player)
    local scoreValue = scoresFolder:FindFirstChild(player.UserId)
    if not scoreValue then
        scoreValue = Instance.new("IntValue")
        scoreValue.Name = player.UserId
        scoreValue.Value = 0
        scoreValue.Parent = scoresFolder
        
        -- Create a StringValue for the leaderboard
        local leaderboardValue = Instance.new("Folder")
        leaderboardValue.Name = "leaderstats"
        leaderboardValue.Parent = player
        
        local scoreStat = Instance.new("StringValue")
        scoreStat.Name = "Survived"
        scoreStat.Value = "0s"
        scoreStat.Parent = leaderboardValue
    end
    return scoreValue
end

-- Function to update player's score
function PlayerDataManager.updatePlayerScore(player, newScore)
    local scoreValue = PlayerDataManager.getPlayerScore(player)
    if newScore > scoreValue.Value then
        scoreValue.Value = newScore
        -- Update leaderboard
        local leaderstats = player:FindFirstChild("leaderstats")
        if leaderstats then
            local scoreStat = leaderstats:FindFirstChild("Survived")
            if scoreStat and scoreStat:IsA("StringValue") then
                scoreStat.Value = tostring(newScore) .. "s"
            end
        end
    end
end

-- ============================================================================
-- PLAYER SETUP AND EVENT HANDLING
-- ============================================================================

-- Handle player scoring and setup
function PlayerDataManager.onPlayerAdded(player, DEFAULT_SPAWN_POSITION)
    local currentScore = 0
    local lastUpdate = tick()
    
    -- Create leaderboard for new players
    local leaderboardValue = Instance.new("Folder")
    leaderboardValue.Name = "leaderstats"
    leaderboardValue.Parent = player
    
    local scoreStat = Instance.new("StringValue")
    scoreStat.Name = "Survived"
    scoreStat.Value = "0s"
    scoreStat.Parent = leaderboardValue

    -- Create HoneyDrips stat (ensured to be created only once here)
    local honeyDripsStat = Instance.new("IntValue")
    honeyDripsStat.Name = "HoneyDrips"
    honeyDripsStat.Value = 0
    honeyDripsStat.Parent = leaderboardValue
    
    -- Start scoring when character is added
    player.CharacterAdded:Connect(function(character)
        local humanoid = character:WaitForChild("Humanoid")
        currentScore = 0
        lastUpdate = tick()
        if GameConfig.DEBUG then
            -- Inline setDebugHoneyDrips logic
            local leaderstats = player:FindFirstChild("leaderstats") or player:WaitForChild("leaderstats")
            local honeyDrips = leaderstats:FindFirstChild("HoneyDrips") or leaderstats:WaitForChild("HoneyDrips")
            honeyDrips.Value = GameConfig.DEBUG_HONEY_DRIPS_VALUE
        end
        
        -- Set player character parts to the PlayerGroup collision group
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CollisionGroup = GameConfig.PLAYER_COLLISION_GROUP
            end
        end

        -- Update score every second while alive
        local connection
        connection = RunService.Heartbeat:Connect(function()
            if not character.Parent then
                connection:Disconnect()
                return
            end
            
            local now = tick()
            if now - lastUpdate >= GameConfig.SCORE_UPDATE_INTERVAL then
                currentScore = currentScore + 1
                lastUpdate = now
                PlayerDataManager.updatePlayerScore(player, currentScore)
            end
        end)
        
        -- Reset score on death
        humanoid.Died:Connect(function()
            if connection then
                connection:Disconnect()
            end
            -- Reset HoneyDrips
            PlayerDataManager.updatePlayerHoneyDrips(player, 0)
            -- Note: Active effects are now handled by PowerUpEffects.clearAllEffects()
        end)
    end)
    
    -- Set initial spawn position
    player.CharacterAdded:Connect(function(character)
        local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
        humanoidRootPart.CFrame = CFrame.new(DEFAULT_SPAWN_POSITION)
    end)
end

-- ============================================================================
-- PUBLIC INTERFACE
-- ============================================================================

-- Connect player joining events
function PlayerDataManager.initialize()
    -- Note: PlayerAdded connection is now handled in main server script
    -- This function is kept for compatibility but does nothing
end

return PlayerDataManager 