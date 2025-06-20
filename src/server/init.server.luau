print("Hello world, from Rojo Server OG!")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local PhysicsService = game:GetService("PhysicsService")

print("Services initialized")

-- Debug control
local Debug = true -- Set to true to enable debug prints

-- Debug print function
local function debugPrint(...)
    if Debug then
        print(...)
    end
end

debugPrint("Debug mode enabled")

-- Spawn control
local swarm = false -- Set to true to enable bee swarming behavior
local AUTO_SPAWN_INTERVAL = 10 -- Spawn a bee every 10 seconds
local BASE_MIN_BEES = 10 -- Base minimum number of bees
local BEES_PER_PLAYER = 1 -- Additional bees per player
local MIN_SPAWN_INTERVAL = 1 -- Spawn every second when below minimum
local MAX_SPAWN_INTERVAL = 10 -- Normal spawn interval when at or above minimum

-- Define Collision Groups
local BEEHIVE_COLLISION_GROUP = "BeeHiveGroup"
local CUBE_COLLISION_GROUP = "FlyingGroup"

-- Set up collision rules
-- Ensure groups exist, then disable collisions between them
local function setupCollisionGroups()
    -- Register groups if they don't exist
    PhysicsService:RegisterCollisionGroup(BEEHIVE_COLLISION_GROUP)
    PhysicsService:RegisterCollisionGroup(CUBE_COLLISION_GROUP)

    -- Disable collisions between BeeHiveGroup and FlyingGroup
    PhysicsService:CollisionGroupSetCollidable(BEEHIVE_COLLISION_GROUP, CUBE_COLLISION_GROUP, false)
end

-- Call this once at server start
setupCollisionGroups()

print("Server script starting...")

-- Function to create and spawn a flying cube that follows the closest player
local function createFlyingCube()
    debugPrint("Attempting to create flying cube...")
    local cube = Instance.new("Part")
    cube.Name = "FlyingCube"
    cube.Size = Vector3.new(3, 3, 3)
    cube.Anchored = false
    cube.CanCollide = true -- Cubes still collide with players and other default parts

    -- Add IsAlive status
    local isAlive = Instance.new("IntValue")
    isAlive.Name = "IsAlive"
    isAlive.Value = 1 -- 1 for alive, 0 for dead
    isAlive.Parent = cube

    -- Aggravation Radius
    local aggravationRadius = 25 -- Cubes will only attack if player is within 50 studs

    -- BodyMover Multiplier
    local BODY_MOVER_MULTIPLIER = 1000 -- Multiply P and D values by this to work with smaller numbers

    -- Assign cube to its collision group
    cube.CollisionGroup = CUBE_COLLISION_GROUP

    -- Find the BeeHive and set spawn position
    local spawnPosition = Vector3.new(0, 25, 0) -- Default spawn if BeeHive not found or no PrimaryPart
    local beeHive = workspace:FindFirstChild("BeeHive")
    if beeHive and beeHive:IsA("Model") then
        debugPrint("BeeHive model found.")
        -- Assign BeeHive to its collision group (if it has parts)
        for _, part in ipairs(beeHive:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CollisionGroup = BEEHIVE_COLLISION_GROUP
            end
        end
        if beeHive.PrimaryPart then
            debugPrint("BeeHive PrimaryPart found.")
            -- Spawn at a random spot near the BeeHive PrimaryPart
            local randomOffset = Vector3.new(
                math.random(-10, 10), -- X offset
                math.random(0, 5),    -- Y offset (above BeeHive)
                math.random(-10, 10)  -- Z offset
            )
            spawnPosition = beeHive.PrimaryPart.Position + randomOffset
        else
            warn("BeeHive model found but no PrimaryPart set. Spawning at default position.")
        end
    else
        warn("BeeHive model not found. Spawning at default position.")
    end

    cube.Position = spawnPosition
    cube.Parent = workspace
    debugPrint("Flying cube created and parented to workspace at: " .. tostring(spawnPosition))

    local originalSpawnPosition = spawnPosition -- Store the initial spawn position

-- Add BodyPosition and BodyGyro for flying
local bodyPosition = Instance.new("BodyPosition")
bodyPosition.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    bodyPosition.P = 10 * BODY_MOVER_MULTIPLIER -- Increased P for more aggressive movement
    bodyPosition.D = 1 * BODY_MOVER_MULTIPLIER -- Reduced D to prevent slowing down
    bodyPosition.Position = cube.Position
    bodyPosition.Parent = cube

local bodyGyro = Instance.new("BodyGyro")
bodyGyro.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
    bodyGyro.P = 10 * BODY_MOVER_MULTIPLIER -- Increased P for faster turning
    bodyGyro.D = 1 * BODY_MOVER_MULTIPLIER -- Reduced D to prevent slowing down
    bodyGyro.CFrame = cube.CFrame
    bodyGyro.Parent = cube

-- Function to find the closest player
local function getClosestPlayer()
    local closest, closestDist
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local dist = (cube.Position - player.Character.HumanoidRootPart.Position).Magnitude
            if not closestDist or dist < closestDist then
                closest = player
                closestDist = dist
            end
        end
    end
    return closest
end

    local randomTargetPosition = Vector3.new(0, 0, 0)
    local function generateRandomTarget()
        local mapCenter = Vector3.new(0, 20, 0) -- A general center point for wandering
        local wanderRadius = 100 -- How far cubes can wander from the center
        randomTargetPosition = mapCenter + Vector3.new(
            math.random(-wanderRadius, wanderRadius),
            math.random(-5, 20), -- Varying height for more natural flight
            math.random(-wanderRadius, wanderRadius)
        )
    end
    generateRandomTarget() -- Initial random target

    -- Make the cube follow the closest player and avoid other cubes
    local isAttacking = false
    local connection
    local angerLevel = 0
    local isAngry = false

    connection = RunService.Heartbeat:Connect(function(dt) -- dt passed as argument
        if not cube.Parent then
            if connection then connection:Disconnect() end
            return
        end

        local targetPlayer = getClosestPlayer() -- Get closest player every frame
        local playerRootPart = nil
        if targetPlayer and targetPlayer.Character then
            playerRootPart = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
        end

        local currentTargetPos = cube.Position -- Default to current position (hover)
        local shouldAttackPlayer = false -- Final decision flag for attacking
        local distanceToPlayer = math.huge -- Initialize to a large number

        -- ANGER LOGIC & STATE UPDATE
        if targetPlayer and playerRootPart then -- Only process anger if a valid player target exists
            distanceToPlayer = (cube.Position - playerRootPart.Position).Magnitude
            if distanceToPlayer <= aggravationRadius then
                angerLevel = math.min(100, angerLevel + 50 * dt) -- Increased anger gain
                -- print("Anger (in range): " .. string.format("%.2f", angerLevel) .. ", isAngry: " .. tostring(isAngry))
            else
                angerLevel = math.max(0, angerLevel - 1 * dt) -- Slower anger decay
                -- print("Anger (out of range): " .. string.format("%.2f", angerLevel) .. ", isAngry: " .. tostring(isAngry))
            end

            if angerLevel >= 1 then -- User's change from 100 to 1 makes it instantly angry
                if not isAngry then 
                    debugPrint("Cube " .. cube.Name .. " is now ANGRY!")
                    -- Spawn an additional calm bee when this one becomes angry (only if swarm is enabled)
                    if swarm then
                        task.spawn(function()
                            local newBee = createFlyingCube()
                            if newBee then
                                debugPrint("Spawned additional calm bee due to anger!")
    end
end)
                    end
                end
                isAngry = true
            elseif angerLevel <= 0 then
                if isAngry then debugPrint("Cube " .. cube.Name .. " is no longer angry.") end -- Debug print only on transition
                isAngry = false
            end
        else -- No valid player target found
            angerLevel = math.max(0, angerLevel - 1 * dt) -- Slower anger decay
            if angerLevel <= 0 then
                isAngry = false
            end
            -- print("Anger (no player): " .. string.format("%.2f", angerLevel) .. ", isAngry: " .. tostring(isAngry))
        end

        -- DECIDE TARGETING BEHAVIOR
        if isAngry and targetPlayer and playerRootPart then
            shouldAttackPlayer = true
            -- print("Cube " .. cube.Name .. " force attacking due to anger!")
        elseif (targetPlayer and playerRootPart) and (not isAngry) and (distanceToPlayer <= aggravationRadius) then
            -- This condition is already implicitly handled by anger gain if player is in range
            -- and `angerLevel >= 1` is also implicitly making them angry and attack. No need for separate isCurrentlyAttackingPlayer flag here.
            -- Removing this branch makes the logic simpler as anger is the primary trigger for active pursuit.
            shouldAttackPlayer = true
        end

        if shouldAttackPlayer then
            -- Attack mode: move directly toward the player's body
            local baseTarget = playerRootPart.Position
            local attackOffset = Vector3.new(
                (math.random() - 0.5) * 2,
                (math.random() - 0.5) * 2,
                (math.random() - 0.5) * 2
            )
            currentTargetPos = baseTarget + attackOffset
        else
            -- Wander mode: move towards random target
            if (cube.Position - randomTargetPosition).Magnitude < 10 then
                generateRandomTarget()
            end
            currentTargetPos = randomTargetPosition
        end

        -- SEPARATION & LIVELINESS (always applies)
        local separation = Vector3.new(0, 0, 0)
        for _, other in ipairs(workspace:GetChildren()) do
            if other ~= cube and other.Name == "FlyingCube" and other:IsA("BasePart") then
                local offset = cube.Position - other.Position
                local dist = offset.Magnitude
                if dist < 4 and dist > 0 then
                    separation = separation + (offset.Unit * (4 - dist))
                end
            end
        end
        currentTargetPos = currentTargetPos + separation

        local randomOffset = Vector3.new(
            (math.random() - 0.5) * 2,
            (math.random() - 0.5) * 2,
            (math.random() - 0.5) * 2
        )
        currentTargetPos = currentTargetPos + randomOffset

        bodyPosition.Position = currentTargetPos
        bodyGyro.CFrame = CFrame.lookAt(cube.Position, currentTargetPos)
    end)

    -- Damage logic: sting player on touch
    local lastStingTimes = {}
    local isCubeDead = false -- Flag to ensure the cube only "dies" once after stinging

    cube.Touched:Connect(function(hit)
        if isCubeDead then return end -- Don't sting or die if already dead

        local character = hit.Parent
        if character and character:FindFirstChild("Humanoid") then
            local player = Players:GetPlayerFromCharacter(character)
            if player then
                debugPrint("Cube touched player:", player.Name)
                local now = tick()
                local lastSting = lastStingTimes[player] or 0
                if now - lastSting > 1 then
                    lastStingTimes[player] = now
                    local humanoid = character:FindFirstChild("Humanoid")
                    if humanoid and humanoid.Health > 0 then
                        debugPrint("Stinging player for 20 damage!")
                        humanoid:TakeDamage(20)

                        -- Cube "dies" after stinging
                        isCubeDead = true
                        isAlive.Value = 0 -- Mark as dead
                        if bodyPosition then bodyPosition:Destroy() end
                        if bodyGyro then bodyGyro:Destroy() end
                        if connection then connection:Disconnect() end -- Disconnect Heartbeat
                        cube.CanCollide = true -- Ensure it can collide with the ground
                        -- Optional: Change color to indicate it's dead
                        cube.BrickColor = BrickColor.new("Dark stone grey")
                        cube.Transparency = 0.5

                        -- Update the bee count display immediately after a bee "dies"
                        beeCountDisplay.Value = "Bees: " .. getBeeCount()

                        -- Chance to spawn a new cube when this one "dies" (only if swarm is enabled)
                        if swarm then
                            local spawnChance = 50 -- 50% chance
                            if math.random(1, 100) <= spawnChance then
                                createFlyingCube()
                            end
                        end
                    end
                end
            end
        end
    end)

    return cube
end

-- Create a folder in ReplicatedStorage for scores
local scoresFolder = Instance.new("Folder")
scoresFolder.Name = "PlayerScores"
scoresFolder.Parent = ReplicatedStorage

-- Function to get or create a player's score value
local function getPlayerScore(player)
    local scoreValue = scoresFolder:FindFirstChild(player.UserId)
    if not scoreValue then
        scoreValue = Instance.new("IntValue")
        scoreValue.Name = player.UserId
        scoreValue.Value = 0
        scoreValue.Parent = scoresFolder
        
        -- Create a StringValue for the leaderboard
        local leaderboardValue = Instance.new("StringValue")
        leaderboardValue.Name = "leaderstats"
        leaderboardValue.Parent = player
        
        local scoreStat = Instance.new("IntValue")
        scoreStat.Name = "Score"
        scoreStat.Value = 0
        scoreStat.Parent = leaderboardValue
    end
    return scoreValue
end

-- Function to update player's score
local function updatePlayerScore(player, newScore)
    local scoreValue = getPlayerScore(player)
    if newScore > scoreValue.Value then
        scoreValue.Value = newScore
        -- Update leaderboard
        local leaderstats = player:FindFirstChild("leaderstats")
        if leaderstats then
            local scoreStat = leaderstats:FindFirstChild("Score")
            if scoreStat then
                scoreStat.Value = newScore
            end
        end
        debugPrint("New high score for", player.Name, ":", newScore)
    end
end

-- Handle player scoring
local function onPlayerAdded(player)
    local currentScore = 0
    local lastUpdate = tick()
    
    -- Create leaderboard for new players
    local leaderboardValue = Instance.new("StringValue")
    leaderboardValue.Name = "leaderstats"
    leaderboardValue.Parent = player
    
    local scoreStat = Instance.new("IntValue")
    scoreStat.Name = "Score"
    scoreStat.Value = 0
    scoreStat.Parent = leaderboardValue
    
    -- Start scoring when character is added
    player.CharacterAdded:Connect(function(character)
        local humanoid = character:WaitForChild("Humanoid")
        currentScore = 0
        lastUpdate = tick()
        
        -- Update score every second while alive
        local connection
        connection = RunService.Heartbeat:Connect(function()
            if not character.Parent then
                connection:Disconnect()
                return
            end
            
            local now = tick()
            if now - lastUpdate >= 1 then
                currentScore = currentScore + 1
                lastUpdate = now
                updatePlayerScore(player, currentScore)
            end
        end)
        
        -- Reset score on death
        humanoid.Died:Connect(function()
            if connection then
                connection:Disconnect()
            end
        end)
    end)
    
    -- Set initial spawn position
    player.CharacterAdded:Connect(function(character)
        local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
        humanoidRootPart.CFrame = CFrame.new(0, 5, 0)
    end)
end

Players.PlayerAdded:Connect(onPlayerAdded)

-- Create a StringValue in ReplicatedStorage to display current bee count
local beeCountDisplay = Instance.new("StringValue")
beeCountDisplay.Name = "BeeCountDisplay"
beeCountDisplay.Value = "Bees: 0"
beeCountDisplay.Parent = ReplicatedStorage

-- Function to get current bee count
local function getBeeCount()
    local count = 0
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj.Name == "FlyingCube" and obj:FindFirstChild("IsAlive") and obj.IsAlive.Value == 1 then
            count = count + 1
        end
    end
    return count
end

-- Add RemoteEvent for spawning cubes from client
local spawnCubeEvent = Instance.new("RemoteEvent")
spawnCubeEvent.Name = "SpawnCube"
spawnCubeEvent.Parent = ReplicatedStorage

-- Listen for spawn requests from client
spawnCubeEvent.OnServerEvent:Connect(function(player)
    createFlyingCube()
    beeCountDisplay.Value = "Bees: " .. getBeeCount() -- Update count immediately after manual spawn
end)

-- Spawn the first cube when the game starts
print("Starting flying cube spawn...")
createFlyingCube()
beeCountDisplay.Value = "Bees: " .. getBeeCount() -- Update count immediately after initial spawn

-- Create a spawn button
print("Creating spawn button...")
local spawnButton = Instance.new("Part")
spawnButton.Name = "BeeSpawnButton"
spawnButton.Size = Vector3.new(4, 4, 4) -- Cube shape
spawnButton.Position = Vector3.new(10, 2, 0) -- Moved to the right
spawnButton.Anchored = true
spawnButton.CanCollide = true
spawnButton.BrickColor = BrickColor.new("New Yeller") -- Changed to yellow
spawnButton.Material = Enum.Material.Neon
spawnButton.Parent = workspace
print("Spawn button created and parented to workspace")

-- Add ProximityPrompt for interaction
local prompt = Instance.new("ProximityPrompt")
prompt.Name = "SpawnBeePrompt"
prompt.ActionText = "Spawn Bee"
prompt.ObjectText = "Bee Spawner"
prompt.HoldDuration = 0.5
prompt.MaxActivationDistance = 10
prompt.Parent = spawnButton

-- Create billboard GUI for spawn cooldown timer
local spawnBillboardGui = Instance.new("BillboardGui")
spawnBillboardGui.Name = "SpawnCooldownTimer"
spawnBillboardGui.Size = UDim2.new(0, 100, 0, 50)
spawnBillboardGui.StudsOffset = Vector3.new(0, 3, 0) -- Position above the spawn button
spawnBillboardGui.Adornee = spawnButton
spawnBillboardGui.Parent = spawnButton

local spawnTimerText = Instance.new("TextLabel")
spawnTimerText.Name = "SpawnTimerText"
spawnTimerText.Size = UDim2.new(1, 0, 1, 0)
spawnTimerText.BackgroundTransparency = 1
spawnTimerText.TextColor3 = Color3.new(1, 1, 1) -- White text
spawnTimerText.TextScaled = true
spawnTimerText.Font = Enum.Font.GothamBold
spawnTimerText.Text = "Spawn Bee"
spawnTimerText.Parent = spawnBillboardGui

-- Add a cooldown system
local lastSpawnTime = 0
local SPAWN_COOLDOWN = 2 -- 2 seconds between spawns

-- Function to update spawn cooldown timer
local function updateSpawnCooldownTimer()
    local currentTime = tick()
    local timeSinceLastSpawn = currentTime - lastSpawnTime
    local remainingCooldown = math.max(0, SPAWN_COOLDOWN - timeSinceLastSpawn)
    
    if remainingCooldown > 0 then
        spawnTimerText.Text = string.format("%.1f", remainingCooldown)
        spawnTimerText.TextColor3 = Color3.new(1, 0, 0) -- Red when on cooldown
    else
        spawnTimerText.Text = "Spawn Bee"
        spawnTimerText.TextColor3 = Color3.new(0, 1, 0) -- Green when ready
    end
end

-- Update spawn timer every frame
local spawnCooldownConnection
spawnCooldownConnection = RunService.Heartbeat:Connect(function()
    if not spawnButton.Parent then
        spawnCooldownConnection:Disconnect()
        return
    end
    updateSpawnCooldownTimer()
end)

-- Handle prompt trigger
prompt.Triggered:Connect(function(player)
    local currentTime = tick()
    if currentTime - lastSpawnTime >= SPAWN_COOLDOWN then
        lastSpawnTime = currentTime
        debugPrint("Spawn button triggered by player:", player.Name)
        
        -- Visual effect
        spawnButton.BrickColor = BrickColor.new("Really red")
        task.delay(0.2, function()
            spawnButton.BrickColor = BrickColor.new("New Yeller") -- Changed to yellow
        end)
        
        -- Spawn the bee
        createFlyingCube()
    end
end)

-- Create a health pack
print("Creating health pack...")
local healthPack = ReplicatedStorage:FindFirstChild("HoneyDipper")
if not healthPack then
    warn("HoneyDipper model not found in ReplicatedStorage! Please add the HoneyDipper model to ReplicatedStorage.")
    return
end

-- Clone the HoneyDipper model
healthPack = healthPack:Clone()
healthPack.Name = "HealthPack"
healthPack.Position = Vector3.new(-5, 5, 0) -- Raised height to 5
healthPack.Parent = workspace

-- Make all parts anchored and non-collidable
for _, part in ipairs(healthPack:GetDescendants()) do
    if part:IsA("BasePart") then
        part.Anchored = true
        part.CanCollide = false
    end
end

print("Health pack created")

-- Add ProximityPrompt for health pack
local healthPrompt = Instance.new("ProximityPrompt")
healthPrompt.Name = "HealthPackPrompt"
healthPrompt.ActionText = "Heal"
healthPrompt.ObjectText = "Honey Dipper"
healthPrompt.HoldDuration = 0.5
healthPrompt.MaxActivationDistance = 10
healthPrompt.Parent = healthPack.PrimaryPart or healthPack

-- Create billboard GUI for cooldown timer
local billboardGui = Instance.new("BillboardGui")
billboardGui.Name = "CooldownTimer"
billboardGui.Size = UDim2.new(0, 200, 0, 100) -- Increased size for better visibility
billboardGui.StudsOffset = Vector3.new(0, 4, 0) -- Raised higher above health pack
billboardGui.Adornee = healthPack.PrimaryPart or healthPack
billboardGui.Parent = healthPack.PrimaryPart or healthPack

local timerText = Instance.new("TextLabel")
timerText.Name = "TimerText"
timerText.Size = UDim2.new(1, 0, 1, 0)
timerText.BackgroundTransparency = 0.5 -- Semi-transparent background
timerText.BackgroundColor3 = Color3.new(0, 0, 0) -- Black background
timerText.TextColor3 = Color3.new(1, 1, 1) -- White text
timerText.TextScaled = true
timerText.Font = Enum.Font.GothamBold
timerText.Text = "Health"
timerText.Parent = billboardGui

-- Health pack cooldown
local lastHealTime = 0
local HEAL_COOLDOWN = 5 -- 5 seconds between heals
local HEAL_AMOUNT = 25 -- Amount of health to restore

-- Function to update cooldown timer
local function updateCooldownTimer()
    local currentTime = tick()
    local timeSinceLastHeal = currentTime - lastHealTime
    local remainingCooldown = math.max(0, HEAL_COOLDOWN - timeSinceLastHeal)
    
    if remainingCooldown > 0 then
        timerText.Text = string.format("%.1f", remainingCooldown)
        timerText.TextColor3 = Color3.new(1, 0, 0) -- Red when on cooldown
    else
        timerText.Text = "Health"
        timerText.TextColor3 = Color3.new(0, 1, 0) -- Green when ready
    end
end

-- Update timer every frame
local cooldownConnection
cooldownConnection = RunService.Heartbeat:Connect(function()
    if not healthPack.Parent then
        cooldownConnection:Disconnect()
        return
    end
    updateCooldownTimer()
end)

-- Handle health pack trigger
healthPrompt.Triggered:Connect(function(player)
    local currentTime = tick()
    if currentTime - lastHealTime >= HEAL_COOLDOWN then
        lastHealTime = currentTime
        
        local character = player.Character
        if character then
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid then
                -- Only heal if player is damaged
                if humanoid.Health < humanoid.MaxHealth then
                    -- Calculate new health (don't exceed max)
                    local newHealth = math.min(humanoid.MaxHealth, humanoid.Health + HEAL_AMOUNT)
                    humanoid.Health = newHealth
                    
                    debugPrint("Healed player:", player.Name, "New health:", newHealth)
                    
                    -- Visual effect
                    for _, part in ipairs(healthPack:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.BrickColor = BrickColor.new("Bright green")
                        end
                    end
                    task.delay(0.2, function()
                        for _, part in ipairs(healthPack:GetDescendants()) do
                            if part:IsA("BasePart") then
                                part.BrickColor = BrickColor.new("Really red")
                            end
                        end
                    end)
                end
            end
        end
    end
end)

-- Add global spawn state
-- local swarm = true -- Start with swarm enabled -- REMOVED due to re-declaration

-- Function to get minimum required bees
local function getMinRequiredBees()
    local playerCount = 0
    for _, _ in ipairs(Players:GetPlayers()) do
        playerCount = playerCount + 1
    end
    return BASE_MIN_BEES + (playerCount * BEES_PER_PLAYER)
end

-- Automatic bee spawner
local function startAutoSpawner()
    while true do
        local currentBees = getBeeCount()
        local minRequiredBees = getMinRequiredBees()
        
        -- Determine spawn interval based on current bee count
        local spawnInterval = currentBees < minRequiredBees and MIN_SPAWN_INTERVAL or MAX_SPAWN_INTERVAL
        
        -- Always spawn if below minimum, otherwise spawn at max interval
        if currentBees < minRequiredBees then
            debugPrint("Auto-spawning bee. Current:", currentBees, "Minimum Required:", minRequiredBees, "Interval:", spawnInterval)
            createFlyingCube()
        else
            debugPrint("Maintaining minimum. Current:", currentBees, "Minimum Required:", minRequiredBees, "Spawning at:", spawnInterval, "seconds")
            createFlyingCube()
        end
        
        -- Update the bee count display value
        beeCountDisplay.Value = "Bees: " .. currentBees
        
        task.wait(spawnInterval)
    end
end

-- Start the auto spawner only after a short delay to ensure Players service is ready
print("Starting auto spawner...")
task.delay(1, function()
    task.spawn(startAutoSpawner)
    print("Auto spawner started")
end)

-- Listen for bees being removed from the workspace to update the count immediately
workspace.ChildRemoved:Connect(function(child)
    if child.Name == "FlyingCube" then
        beeCountDisplay.Value = "Bees: " .. getBeeCount()
    end
end)