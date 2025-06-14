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
local AUTO_SPAWN_INTERVAL = 1 -- Spawn a bee every 10 seconds
local BASE_MIN_BEES = 10 -- Base minimum number of bees
local BEES_PER_PLAYER = 1 -- Additional bees per player
local MIN_SPAWN_INTERVAL = 1 -- Spawn every second when below minimum
local MAX_SPAWN_INTERVAL = 10 -- Normal spawn interval when at or above minimum

-- Constants for HoneyDrip spawning
local MAX_HONEYDRIPS = 10 -- Maximum number of HoneyDrips allowed in workspace
local BASE_DRIP_SPAWN_INTERVAL = 10 -- Base interval in seconds for drips to spawn
local DRIP_SPAWN_DECREASE_PER_BEE = 0.5 -- How much interval decreases per alive bee

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

-- Function to update bee count display
local function updateBeeCount()
    local count = getBeeCount()
    beeCountDisplay.Value = "Bees: " .. count
    debugPrint("Updated bee count:", count)
end

-- Function to create and spawn a flying bee that follows the closest player
local function createFlyingCube()
    debugPrint("Attempting to create flying bee...")
    
    -- Get the bee model from ReplicatedStorage, as per your model's new location
    local beeModel = ReplicatedStorage:FindFirstChild("Bee")
    if not beeModel then
        warn("Bee model not found in ReplicatedStorage! Please add a bee model named 'Bee' to ReplicatedStorage.")
        return nil
    end
    
    -- Clone the bee model
    local bee = beeModel:Clone()
    bee.Name = "FlyingCube" -- Keep the name for compatibility with existing code
    bee.Parent = workspace -- Parent to workspace early to ensure welds activate

    -- Identify the primary part (should be 'wing' as per your model)
    local primaryPart = bee:FindFirstChild("wing")
    if not primaryPart then
        warn("No 'wing' part found in Bee model! Falling back to model's PrimaryPart or first BasePart.")
        primaryPart = bee.PrimaryPart or bee:FindFirstChildWhichIsA("BasePart")
        if not primaryPart then
            warn("No BasePart found in Bee model! Cannot proceed with movement.")
            bee:Destroy() -- Clean up partial model
            return nil
        end
    end
    bee.PrimaryPart = primaryPart -- Ensure the model's PrimaryPart is set

    -- Assign Bee to its collision group and ensure all parts are non-collidable and unanchored
    for _, part in ipairs(bee:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CollisionGroup = CUBE_COLLISION_GROUP
            part.CanCollide = false -- Ensure bee parts are not collidable initially
            part.Anchored = false -- Ensure bee parts are not anchored so BodyMovers can affect them
        end
    end

    -- Weld all parts of the bee model to its primary part to ensure it moves as a single unit
    debugPrint("PrimaryPart '", primaryPart.Name, "' found for welding.")
    for _, part in ipairs(bee:GetDescendants()) do
        if part:IsA("BasePart") and part ~= primaryPart then
            local weldConstraint = Instance.new("WeldConstraint")
            weldConstraint.Part0 = primaryPart
            weldConstraint.Part1 = part
            weldConstraint.Parent = part -- Parent to the child part
            debugPrint("WeldConstraint created between ", primaryPart.Name, " and ", part.Name)
        end
    end

    -- Add IsAlive status
    local isAlive = Instance.new("IntValue")
    isAlive.Name = "IsAlive"
    isAlive.Value = 1 -- 1 for alive, 0 for dead
    isAlive.Parent = bee

    -- Aggravation Radius
    local aggravationRadius = 25 -- Bees will only attack if player is within 25 studs

    -- BodyMover Multiplier
    local BODY_MOVER_MULTIPLIER = 1000 -- Multiply P and D values by this to work with smaller numbers

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

    -- Set the position of the entire model via its PrimaryPart
    bee:SetPrimaryPartCFrame(CFrame.new(spawnPosition))
    debugPrint("Flying bee created and parented to workspace at: " .. tostring(spawnPosition))

    -- Add BodyPosition and BodyGyro for flying
    local bodyPosition = Instance.new("BodyPosition")
    bodyPosition.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    bodyPosition.P = 10 * BODY_MOVER_MULTIPLIER
    bodyPosition.D = 1 * BODY_MOVER_MULTIPLIER
    bodyPosition.Position = primaryPart.Position
    bodyPosition.Parent = primaryPart
    debugPrint("BodyPosition created and parented to ", primaryPart.Name)

    local bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
    bodyGyro.P = 10 * BODY_MOVER_MULTIPLIER
    bodyGyro.D = 1 * BODY_MOVER_MULTIPLIER
    bodyGyro.CFrame = primaryPart.CFrame
    bodyGyro.Parent = primaryPart
    debugPrint("BodyGyro created and parented to ", primaryPart.Name)

    -- Function to find the closest player
    local function getClosestPlayer()
        local closest, closestDist
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local dist = (primaryPart.Position - player.Character.HumanoidRootPart.Position).Magnitude
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
        local wanderRadius = 100 -- How far bees can wander from the center
        randomTargetPosition = mapCenter + Vector3.new(
            math.random(-wanderRadius, wanderRadius),
            math.random(-5, 20), -- Varying height for more natural flight
            math.random(-wanderRadius, wanderRadius)
        )
    end
    generateRandomTarget() -- Initial random target

    -- Make the bee follow the closest player and avoid other bees
    local isAttacking = false
    local connection
    local angerLevel = 0
    local isAngry = false

    connection = RunService.Heartbeat:Connect(function(dt)
        if not bee.Parent then
            if connection then connection:Disconnect() end
            return
        end

        local targetPlayer = getClosestPlayer()
        local playerRootPart = nil
        if targetPlayer and targetPlayer.Character then
            playerRootPart = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
        end

        local currentTargetPos = primaryPart.Position
        local shouldAttackPlayer = false
        local distanceToPlayer = math.huge

        -- ANGER LOGIC & STATE UPDATE
        if targetPlayer and playerRootPart then
            distanceToPlayer = (primaryPart.Position - playerRootPart.Position).Magnitude
            if distanceToPlayer <= aggravationRadius then
                angerLevel = math.min(100, angerLevel + 50 * dt)
            else
                angerLevel = math.max(0, angerLevel - 1 * dt)
            end

            if angerLevel >= 1 then
                if not isAngry then 
                    debugPrint("Bee " .. bee.Name .. " is now ANGRY!")
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
                if isAngry then debugPrint("Bee " .. bee.Name .. " is no longer angry.") end
                isAngry = false
            end
        else
            angerLevel = math.max(0, angerLevel - 1 * dt)
            if angerLevel <= 0 then
                isAngry = false
            end
        end

        -- DECIDE TARGETING BEHAVIOR
        if isAngry and targetPlayer and playerRootPart then
            shouldAttackPlayer = true
        elseif (targetPlayer and playerRootPart) and (not isAngry) and (distanceToPlayer <= aggravationRadius) then
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
            if (primaryPart.Position - randomTargetPosition).Magnitude < 10 then
                generateRandomTarget()
            end
            currentTargetPos = randomTargetPosition
        end

        -- SEPARATION & LIVELINESS
        local separation = Vector3.new(0, 0, 0)
        for _, other in ipairs(workspace:GetChildren()) do
            if other ~= bee and other.Name == "FlyingCube" and other:IsA("Model") then
                local otherPrimary = other.PrimaryPart or other:FindFirstChildWhichIsA("BasePart")
                if otherPrimary then
                    local offset = primaryPart.Position - otherPrimary.Position
                    local dist = offset.Magnitude
                    if dist < 4 and dist > 0 then
                        separation = separation + (offset.Unit * (4 - dist))
                    end
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
        bodyGyro.CFrame = CFrame.lookAt(primaryPart.Position, currentTargetPos)
    end)

    -- Damage logic: sting player on touch
    local lastStingTimes = {}
    local isBeeDead = false

    primaryPart.Touched:Connect(function(hit)
        if isBeeDead then return end

        local character = hit.Parent
        if character and character:FindFirstChild("Humanoid") then
            local player = Players:GetPlayerFromCharacter(character)
            if player then
                -- Check if player has Bee Shield power-up
                if player:GetAttribute("BeeShield") then
                    debugPrint("Player has Bee Shield, no damage applied")
                    return
                end

                debugPrint("Bee touched player:", player.Name)
                local now = tick()
                local lastSting = lastStingTimes[player] or 0
                if now - lastSting > 1 then
                    lastStingTimes[player] = now
                    local humanoid = character:FindFirstChild("Humanoid")
                    if humanoid and humanoid.Health > 0 then
                        debugPrint("Stinging player for 10 damage!")
                        humanoid:TakeDamage(10)

                        -- Bee "dies" after stinging
                        isBeeDead = true
                        isAlive.Value = 0
                        if bodyPosition then bodyPosition:Destroy() end
                        if bodyGyro then bodyGyro:Destroy() end
                        if connection then connection:Disconnect() end
                        
                        -- Make the bee fall to the ground and become solid
                        for _, part in ipairs(bee:GetDescendants()) do
                            if part:IsA("BasePart") then
                                part.CanCollide = true
                                part.Material = Enum.Material.SmoothPlastic
                                part.Transparency = 0.5
                                part.Anchored = false -- Ensure it can fall
                            end
                        end

                        -- Update the bee count display immediately after a bee "dies"
                        updateBeeCount()

                        -- Chance to spawn a new bee when this one "dies" (only if swarm is enabled)
                        if swarm then
                            local spawnChance = 50 -- 50% chance
                            if math.random(1, 100) <= spawnChance then
                                task.spawn(function()
                                    createFlyingCube()
                                    updateBeeCount()
                                end)
                            end
                        end
                    end
                end
            end
        end
    end)

    return bee
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
        
        local scoreStat = Instance.new("StringValue")
        scoreStat.Name = "Survived"
        scoreStat.Value = "0s"
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
            local scoreStat = leaderstats:FindFirstChild("Survived")
            if scoreStat and scoreStat:IsA("StringValue") then
                scoreStat.Value = tostring(newScore) .. "s"
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
    
    local scoreStat = Instance.new("StringValue")
    scoreStat.Name = "Survived"
    scoreStat.Value = "0s"
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

-- Add RemoteEvent for spawning cubes from client
local spawnCubeEvent = Instance.new("RemoteEvent")
spawnCubeEvent.Name = "SpawnCube"
spawnCubeEvent.Parent = ReplicatedStorage

-- Listen for spawn requests from client
spawnCubeEvent.OnServerEvent:Connect(function(player)
    createFlyingCube()
    updateBeeCount() -- Update count immediately after manual spawn
end)

-- Spawn the first cube when the game starts
print("Starting flying cube spawn...")
createFlyingCube()
updateBeeCount() -- Update count immediately after initial spawn

-- HoneyDrip Item Interaction
local honeyDripItem = workspace:FindFirstChild("HoneyDrip")

local HEAL_AMOUNT_HONEYDRIP = 25 -- Amount of health to restore when picking up HoneyDrip

if honeyDripItem then
    debugPrint("Found HoneyDrip item.")
    local honeyDripPrompt = honeyDripItem:FindFirstChildOfClass("ProximityPrompt")
    if honeyDripPrompt then
        debugPrint("Found ProximityPrompt on HoneyDrip.")
        honeyDripPrompt.ActionText = "Collect"
        honeyDripPrompt.ObjectText = "Honey Drip"

        honeyDripPrompt.Triggered:Connect(function(player)
            debugPrint("Player ", player.Name, " triggered HoneyDrip prompt.")
            
            -- Give HoneyDrip to player's inventory (using leaderstats for simplicity)
            local leaderstats = player:FindFirstChild("leaderstats")
            if leaderstats then
                local honeyDrips = leaderstats:FindFirstChild("HoneyDrips")
                if not honeyDrips then
                    honeyDrips = Instance.new("IntValue")
                    honeyDrips.Name = "HoneyDrips"
                    honeyDrips.Value = 0
                    honeyDrips.Parent = leaderstats
                    debugPrint("Created new HoneyDrips IntValue for ", player.Name)
                end
                honeyDrips.Value = honeyDrips.Value + 1
                debugPrint(player.Name, " collected a HoneyDrip. Total: ", honeyDrips.Value)

                -- Give health bump to the player
                local character = player.Character
                if character then
                    local humanoid = character:FindFirstChild("Humanoid")
                    if humanoid then
                        if humanoid.Health < humanoid.MaxHealth then
                            local newHealth = math.min(humanoid.MaxHealth, humanoid.Health + HEAL_AMOUNT_HONEYDRIP)
                            humanoid.Health = newHealth
                            debugPrint("Healed player:", player.Name, " by ", HEAL_AMOUNT_HONEYDRIP, " health. New health:", newHealth)
                        else
                            debugPrint(player.Name, " is already at full health. No healing applied.")
                        end
                    end
                end

                -- Visual effect for pickup
                local originalBrickColor = honeyDripItem.BrickColor
                honeyDripItem.BrickColor = BrickColor.new("Really yellow") -- Bright color on pickup
                task.delay(0.1, function()
                    if honeyDripItem then -- Check if item still exists
                        honeyDripItem.BrickColor = originalBrickColor
                    end
                end)

                -- Play a pickup sound
                local pickupSound = honeyDripItem:FindFirstChild("PickupSound")
                if not pickupSound then
                    pickupSound = Instance.new("Sound")
                    pickupSound.Name = "PickupSound"
                    pickupSound.SoundId = "rbxassetid://9114827380" -- Reusing existing heal sound, or you can provide a new one
                    pickupSound.Volume = 0.5
                    pickupSound.Parent = honeyDripItem
                end
                pickupSound:Play()

                -- Destroy the HoneyDrip from the workspace
                honeyDripItem:Destroy()
                debugPrint("HoneyDrip item destroyed.")
            else
                warn("Leaderstats not found for player ", player.Name, ". Cannot add HoneyDrip or heal.")
            end
        end)
    else
        warn("No ProximityPrompt found on HoneyDrip item. Please add one.")
    end
else
    warn("HoneyDrip item not found in workspace.")
end

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
        updateBeeCount()
        
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
        debugPrint("Bee removed from workspace, updating count")
        updateBeeCount()
    end
end)

-- Function to get current HoneyDrip count in workspace
local function getHoneyDripCount()
    local count = 0
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj.Name == "HoneyDrip" then -- Assuming HoneyDrip model is named "HoneyDrip"
            count = count + 1
        end
    end
    return count
end

-- Function to create and spawn a HoneyDrip item near the BeeHive
local function createHoneyDrip()
    debugPrint("Attempting to create HoneyDrip...")
    
    -- Get the HoneyDrip template from ReplicatedStorage
    local honeyDripTemplate = ReplicatedStorage:FindFirstChild("HoneyDrip")
    if not honeyDripTemplate or not honeyDripTemplate:IsA("MeshPart") then
        warn("HoneyDrip template not found in ReplicatedStorage! Please add a HoneyDrip MeshPart to ReplicatedStorage.")
        return nil
    end

    local newDrip = honeyDripTemplate:Clone()
    newDrip.Name = "HoneyDrip"
    
    -- Ensure the new drip is unanchored and collidable so it falls
    newDrip.Anchored = false
    newDrip.CanCollide = true -- So it can land on the ground
    newDrip.Transparency = 0 -- Ensure it's visible

    -- Position the drip near the BeeHive's primary part
    local beeHive = workspace:FindFirstChild("BeeHive")
    local spawnPosition = Vector3.new(0, 0, 0) -- Default spawn if BeeHive not found

    if beeHive and beeHive.PrimaryPart then
        -- Spawn on the ground under the BeeHive with a small random offset
        spawnPosition = Vector3.new(
            beeHive.PrimaryPart.Position.X + math.random(-2, 2), -- Small X offset
            0, -- Ground level
            beeHive.PrimaryPart.Position.Z + math.random(-2, 2)  -- Small Z offset
        )
    else
        warn("BeeHive or its PrimaryPart not found. Spawning HoneyDrip at default position.")
    end

    newDrip.Position = spawnPosition -- Set position directly on the MeshPart
    newDrip.Parent = workspace
    debugPrint("HoneyDrip created at ", tostring(spawnPosition), " with size ", tostring(newDrip.Size))

    -- Get the existing ProximityPrompt from the cloned HoneyDrip
    local prompt = newDrip:FindFirstChildOfClass("ProximityPrompt")
    if prompt then
        debugPrint("Found existing ProximityPrompt on HoneyDrip")
        -- Connect the Triggered event for the prompt
        prompt.Triggered:Connect(function(player)
            debugPrint("HoneyDrip Triggered event fired for player:", player.Name)
            -- Give HoneyDrip to player's inventory (using leaderstats for simplicity)
            local leaderstats = player:FindFirstChild("leaderstats")
            if leaderstats then
                local honeyDrips = leaderstats:FindFirstChild("HoneyDrips")
                if not honeyDrips then
                    honeyDrips = Instance.new("IntValue")
                    honeyDrips.Name = "HoneyDrips"
                    honeyDrips.Value = 0
                    honeyDrips.Parent = leaderstats
                    debugPrint("Created new HoneyDrips IntValue for ", player.Name)
                end
                honeyDrips.Value = honeyDrips.Value + 1
                debugPrint(player.Name, " collected a HoneyDrip. Total: ", honeyDrips.Value)

                -- Give health bump to the player
                local character = player.Character
                if character then
                    local humanoid = character:FindFirstChild("Humanoid")
                    if humanoid then
                        if humanoid.Health < humanoid.MaxHealth then
                            local newHealth = math.min(humanoid.MaxHealth, humanoid.Health + HEAL_AMOUNT_HONEYDRIP)
                            humanoid.Health = newHealth
                            debugPrint("Healed player:", player.Name, " by ", HEAL_AMOUNT_HONEYDRIP, " health. New health:", newHealth)
                        else
                            debugPrint(player.Name, " is already at full health. No healing applied.")
                        end
                    end
                end

                -- Visual effect for pickup
                local originalBrickColor = newDrip.BrickColor
                newDrip.BrickColor = BrickColor.new("Really yellow")
                task.delay(0.1, function()
                    if newDrip then
                        newDrip.BrickColor = originalBrickColor
                    end
                end)

                -- Play a pickup sound
                local pickupSound = newDrip:FindFirstChild("PickupSound")
                if not pickupSound then
                    pickupSound = Instance.new("Sound")
                    pickupSound.Name = "PickupSound"
                    pickupSound.SoundId = "rbxassetid://9114827380"
                    pickupSound.Volume = 0.5
                    pickupSound.Parent = newDrip
                end
                pickupSound:Play()

                -- Destroy the HoneyDrip from the workspace
                newDrip:Destroy()
                debugPrint("HoneyDrip item destroyed.")
            else
                warn("Leaderstats not found for player ", player.Name, ". Cannot add HoneyDrip or heal.")
            end
        end)
    else
        warn("No ProximityPrompt found on HoneyDrip template!")
    end

    return newDrip
end

-- Automatic HoneyDrip spawner
local function startHoneyDripSpawner()
    while true do
        local currentDrips = getHoneyDripCount()
        local aliveBees = getBeeCount() -- Reusing getBeeCount for dynamic interval

        local spawnInterval = BASE_DRIP_SPAWN_INTERVAL
        if aliveBees > 0 then
            -- Decrease spawn interval based on alive bees, but not below 1 second to prevent spam
            spawnInterval = math.max(1, BASE_DRIP_SPAWN_INTERVAL - (aliveBees * DRIP_SPAWN_DECREASE_PER_BEE))
        end

        debugPrint("Current HoneyDrips:", currentDrips, " Alive Bees:", aliveBees, " Calculated Drip Spawn Interval:", spawnInterval)

        if currentDrips < MAX_HONEYDRIPS then
            createHoneyDrip()
        else
            debugPrint("Max HoneyDrips reached (", MAX_HONEYDRIPS, "). Not spawning.")
        end

        task.wait(spawnInterval)
    end
end

-- Start the HoneyDrip spawner after a short delay
print("Starting HoneyDrip spawner...")
task.delay(2, function()
    task.spawn(startHoneyDripSpawner)
    print("HoneyDrip spawner started")
end)

-- New: BindableEvent for inter-script communication
local SpawnBeesRequestEvent = Instance.new("BindableEvent")
SpawnBeesRequestEvent.Name = "SpawnBeesRequestEvent"
SpawnBeesRequestEvent.Parent = ReplicatedStorage

-- Function to spawn multiple bees (called via BindableEvent)
local function spawnMultipleBees(count)
    for i = 1, count do
        task.spawn(function()
            createFlyingCube()
        end)
    end
    updateBeeCount()
    debugPrint("Spawned", count, "bees via request!")
end

-- Connect the BindableEvent to the spawning function
SpawnBeesRequestEvent.Event:Connect(spawnMultipleBees)