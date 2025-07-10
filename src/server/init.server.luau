print("Hello world, from Rojo Server OG!")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local PhysicsService = game:GetService("PhysicsService")
local ServerStorage = game:GetService("ServerStorage") -- Get ServerStorage

-- Require Modules
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local PlayerDataManager = require(game.ServerScriptService.Server.PlayerDataManager)
local RemoteEventsManager = require(game.ServerScriptService.Server.RemoteEventsManager)


-- Initialize 
PlayerDataManager.initialize()
RemoteEventsManager.createRemoteEvents()

local function logDebug(...)
    if GameConfig.LOG_LEVEL == "debug" then
        print("[DEBUG]", ...)
    end
end

-- Run unit tests (controlled by GameConfig.RUN_TESTS)
if GameConfig.RUN_TESTS then
    local RemoteEventsManagerTests = require(game.ServerScriptService.Server.tests.RemoteEventsManagerTests)
    local GameConfigTests = require(game.ServerScriptService.Server.tests.GameConfigTests)

    RemoteEventsManagerTests.runTests()
    GameConfigTests.runTests()
else
    print("🧪 Unit tests disabled (GameConfig.RUN_TESTS = false)")
end



local SoundsFolder = ServerStorage:FindFirstChild("Sounds")
if not SoundsFolder then
    warn("Sounds folder not found in ServerStorage. Please ensure your audio assets are placed in ServerStorage/Sounds.")
    -- Create a dummy folder or handle gracefully if sounds are missing
    SoundsFolder = Instance.new("Folder")
    SoundsFolder.Name = "Sounds"
    SoundsFolder.Parent = ServerStorage
end

print("Services initialized")

-- Audio Setup
local buzSounds = {}
for i = 1, GameConfig.BUZ_SOUND_COUNT do -- Assuming robloxMoreBeesAudio_buz, _buz2, _buz3
    local sound = SoundsFolder:FindFirstChild("robloxMoreBeesAudio_buz" .. (i > 1 and tostring(i) or ""))
    if sound then
        table.insert(buzSounds, sound)
    else
        warn("Buz sound not found: robloxMoreBeesAudio_buz" .. (i > 1 and tostring(i) or "") .. " in Sounds folder.")
    end
end
-- debugPrint("Found ", #buzSounds, " buz sounds.")

local stingSounds = {}
for i = 1, GameConfig.STING_SOUND_COUNT do -- Assuming robloxMoreBeesAudio_sting, _sting2, ..., _sting5
    local sound = SoundsFolder:FindFirstChild("robloxMoreBeesAudio_sting" .. (i > 1 and tostring(i) or ""))
    if sound then
        table.insert(stingSounds, sound)
    else
        warn("Sting sound not found: robloxMoreBeesAudio_sting" .. (i > 1 and tostring(i) or "") .. " in Sounds folder.")
    end
end
-- debugPrint("Found ", #stingSounds, " sting sounds.")

local honeyDripSounds = {}
for i = 1, GameConfig.HONEYDRIP_SOUND_COUNT do -- Assuming robloxMoreBeesAudio_drip, _drip2, _drip3
    local sound = SoundsFolder:FindFirstChild("robloxMoreBeesAudio_drip" .. (i > 1 and tostring(i) or ""))
    if sound then
        table.insert(honeyDripSounds, sound)
    else
        warn("HoneyDrip sound not found: robloxMoreBeesAudio_drip" .. (i > 1 and tostring(i) or "") .. " in Sounds folder.")
    end
end
-- debugPrint("Found ", #honeyDripSounds, " HoneyDrip sounds.")

if #buzSounds == 0 then warn("No buz sounds found in ServerStorage!") end
if #stingSounds == 0 then warn("No sting sounds found in ServerStorage!") end
if #honeyDripSounds == 0 then warn("No HoneyDrip sounds found in ServerStorage!") end

-- All spawn control and game constants are now in GameConfig

-- debugPrint("Before createHoneyDrip definition: createHoneyDrip is ", tostring(createHoneyDrip))
-- Function to create and spawn a HoneyDrip item near the BeeHive
local function createHoneyDrip(initialPosition)
    -- debugPrint("Attempting to create HoneyDrip...")
    
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
    newDrip.Transparency = GameConfig.HONEYDRIP_TRANSPARENCY -- Ensure it's visible

    local spawnPosition = initialPosition or Vector3.new(0, 0, 0) -- Default if no initialPosition

    if not initialPosition then -- Only use BeeHive logic if no specific position is provided
        local beeHive = workspace:FindFirstChild("BeeHive")
        if beeHive and beeHive.PrimaryPart then
            -- Spawn on the ground under the BeeHive with a small random offset
            spawnPosition = Vector3.new(
                beeHive.PrimaryPart.Position.X + math.random(-GameConfig.BEEHIVE_SPAWN_OFFSET_X, GameConfig.BEEHIVE_SPAWN_OFFSET_X), -- Small X offset
                GameConfig.BEEHIVE_SPAWN_Y, -- Ground level
                beeHive.PrimaryPart.Position.Z + math.random(-GameConfig.BEEHIVE_SPAWN_OFFSET_Z, GameConfig.BEEHIVE_SPAWN_OFFSET_Z)  -- Small Z offset
            )
        else
            warn("BeeHive or its PrimaryPart not found. Spawning HoneyDrip at default position.")
        end
    end

    newDrip.Position = spawnPosition -- Set position directly on the MeshPart
    newDrip.Parent = workspace
    -- debugPrint("HoneyDrip created at ", tostring(spawnPosition), " with size ", tostring(newDrip.Size))

    -- Get the existing ProximityPrompt from the cloned HoneyDrip
    local prompt = newDrip:FindFirstChildOfClass("ProximityPrompt")
    if prompt then
        -- debugPrint("Found existing ProximityPrompt on HoneyDrip (", newDrip.Name, ") with parent ", prompt.Parent.Name)
        -- Connect the Triggered event for the prompt
        prompt.Triggered:Connect(function(player)
            -- debugPrint("ProximityPrompt Triggered for HoneyDrip (", newDrip.Name, ") by ", player.Name, ". HoneyDrip parent: ", newDrip.Parent and newDrip.Parent.Name or "nil", ", Prompt parent: ", prompt.Parent and prompt.Parent.Name or "nil")
            local character = player.Character
            if character and character:FindFirstChildOfClass("Humanoid") then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid.Health < humanoid.MaxHealth then
                    humanoid.Health = math.min(humanoid.Health + GameConfig.HEAL_AMOUNT_HONEYDRIP, humanoid.MaxHealth)
                    -- debugPrint(player.Name, " healed by HoneyDrip. Current health:", humanoid.Health)
                    
                    -- Visual feedback: brief color flash
                    local originalColor = player.Character.HumanoidRootPart.BrickColor
                    player.Character.HumanoidRootPart.BrickColor = BrickColor.new(GameConfig.HEAL_FLASH_COLOR)
                    task.delay(GameConfig.HEAL_FLASH_DURATION, function() -- Flash for configured duration
                        if player.Character and player.Character.HumanoidRootPart then
                            player.Character.HumanoidRootPart.BrickColor = originalColor
                        end
                    end)
                end

                -- Play HoneyDrip pickup sound
                if #honeyDripSounds > 0 then
                    local chosenDripSound = honeyDripSounds[math.random(1, #honeyDripSounds)]:Clone()
                    chosenDripSound.Parent = newDrip -- Parent to the picked up drip
                    chosenDripSound.Volume = GameConfig.SOUND_VOLUME -- Set volume from config
                    -- debugPrint("Attempting to play HoneyDrip sound: ", chosenDripSound.Name)
                    chosenDripSound:Play()
                    game:GetService("Debris"):AddItem(chosenDripSound, chosenDripSound.TimeLength) -- Clean up sound after playing
                else
                    warn("No HoneyDrip sounds available to play!")
                end

                -- Use PlayerDataManager module
                local currentHoneyDrips = PlayerDataManager.getPlayerHoneyDrips(player)
                
                -- Get the value from the HoneyDrip model itself
                local honeyDripValueObject = newDrip:FindFirstChild("DripAmount") -- Now looking for "DripAmount"
                local amountToAdd = GameConfig.DEFAULT_HONEYDRIP_AMOUNT -- Default to config value if DripAmount object not found
                if honeyDripValueObject and honeyDripValueObject:IsA("NumberValue") then
                    amountToAdd = honeyDripValueObject.Value
                    -- debugPrint("HoneyDrip (", newDrip.Name, ") has value of ", amountToAdd)
                else
                    warn("HoneyDrip (", newDrip.Name, ") does not have a 'DripAmount' NumberValue child or it's not a NumberValue. Defaulting to 1.")
                end

                -- Use PlayerDataManager module
                PlayerDataManager.updatePlayerHoneyDrips(player, currentHoneyDrips + amountToAdd)
                
            else
                warn("Player character or Humanoid not found for healing.")
            end
            
            -- Destroy the HoneyDrip after pickup
            -- debugPrint("Destroying HoneyDrip (", newDrip.Name, ") after pickup. Waiting configured delay.")
            task.wait(GameConfig.HONEYDRIP_PICKUP_DELAY) -- Small delay to allow events to fully process
            newDrip:Destroy()
        end)
    else
        warn("No ProximityPrompt found on HoneyDrip template!")
    end

    return newDrip
end

-- Set up collision rules
-- Ensure groups exist, then disable collisions between them
local function setupCollisionGroups()
    -- Register groups if they don't exist
    PhysicsService:RegisterCollisionGroup(GameConfig.BEEHIVE_COLLISION_GROUP)
    PhysicsService:RegisterCollisionGroup(GameConfig.CUBE_COLLISION_GROUP)
    PhysicsService:RegisterCollisionGroup(GameConfig.PLAYER_COLLISION_GROUP)

    -- Disable collisions between BeeHiveGroup and FlyingGroup
    PhysicsService:CollisionGroupSetCollidable(GameConfig.BEEHIVE_COLLISION_GROUP, GameConfig.CUBE_COLLISION_GROUP, false)
    
    -- Disable collisions between FlyingGroup (bees) and PlayerGroup (players)
    PhysicsService:CollisionGroupSetCollidable(GameConfig.CUBE_COLLISION_GROUP, GameConfig.PLAYER_COLLISION_GROUP, false)
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
        if obj.Name == "FlyingCube" then
            local isAliveValue = obj:FindFirstChild("IsAlive")
            if isAliveValue and isAliveValue.Value == GameConfig.BEE_ALIVE_VALUE then
                count = count + 1
                -- debugPrint("getBeeCount: Counting alive bee ", obj.Name)
            else
                -- debugPrint("getBeeCount: Not counting bee ", obj.Name, ", IsAlive: ", isAliveValue and isAliveValue.Value or "nil")
            end
        else
            -- debugPrint("getBeeCount: Not a FlyingCube: ", obj.Name)
        end
    end
    -- debugPrint("getBeeCount: Final count ", count)
    return count
end

-- Function to update bee count display
local function updateBeeCount()
    local count = getBeeCount()
    beeCountDisplay.Value = "Bees: " .. count
    -- debugPrint("Updated bee count:", count)
end

-- Function to create and spawn a flying bee that follows the closest player
local function createFlyingCube(customColor)
    -- logDebug("Attempting to create flying bee...")
    
    -- Get the bee model from ReplicatedStorage, as per your model's new location
    local beeModel = ReplicatedStorage:FindFirstChild("Bee")
    if not beeModel then
        warn("Bee model not found in ReplicatedStorage! Please add a bee model named 'Bee' to ReplicatedStorage.")
        return nil
    end
    -- logDebug("Bee model found in ReplicatedStorage")
    
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

    -- Apply custom color if provided
    if customColor and typeof(customColor) == "BrickColor" then
        for _, part in ipairs(bee:GetDescendants()) do
            if part:IsA("BasePart") then
                part.BrickColor = customColor
            end
        end
    end

    -- Assign Bee to its collision group and ensure all parts are non-collidable and unanchored
    for _, part in ipairs(bee:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CollisionGroup = GameConfig.CUBE_COLLISION_GROUP
            part.Anchored = false -- Ensure bee parts are not anchored so BodyMovers can affect them
            -- debugPrint("Bee part ", part.Name, " initial CanCollide: ", tostring(part.CanCollide))
        end
    end

    -- Weld all parts of the bee model to its primary part to ensure it moves as a single unit
    -- debugPrint("PrimaryPart '", primaryPart.Name, "' found for welding.")
    for _, part in ipairs(bee:GetDescendants()) do
        if part:IsA("BasePart") and part ~= primaryPart then
            local weldConstraint = Instance.new("WeldConstraint")
            weldConstraint.Part0 = primaryPart
            weldConstraint.Part1 = part
            weldConstraint.Parent = part -- Parent to the child part
            -- debugPrint("WeldConstraint created between ", primaryPart.Name, " and ", part.Name)
        end
    end

    -- Add buz sound
    local buzSound = nil
    if #buzSounds > 0 then
        local chosenBuzSound = buzSounds[math.random(1, #buzSounds)]:Clone()
        chosenBuzSound.Parent = primaryPart -- Parent to primary part to ensure it moves with bee
        chosenBuzSound.Looped = true
        chosenBuzSound:Play()
        buzSound = chosenBuzSound
    else
        warn("No buz sounds available to play!")
    end

    -- Add IsAlive status
    local isAlive = Instance.new("IntValue")
    isAlive.Name = "IsAlive"
            isAlive.Value = GameConfig.BEE_ALIVE_VALUE -- 1 for alive, 0 for dead
    isAlive.Parent = bee

    -- Stamina tracking for this bee
    local chaseTime = GameConfig.MAX_CHASE_TIME -- How long this bee has been actively chasing a player

    -- Create BillboardGui for stamina display
    local staminaGui = Instance.new("BillboardGui")
    staminaGui.Name = "StaminaDisplay"
    staminaGui.Size = UDim2.new(2, 0, 1, 0) -- Size of the GUI (width 2 studs, height 1 stud)
    staminaGui.StudsOffset = Vector3.new(0, 5, 0) -- Offset above the bee
    staminaGui.AlwaysOnTop = true
    staminaGui.Parent = primaryPart -- Parent to the primary part so it moves with the bee

    local staminaText = Instance.new("TextLabel")
    staminaText.Name = "StaminaText"
    staminaText.Size = UDim2.new(1, 0, 1, 0)
            staminaText.BackgroundTransparency = GameConfig.STAMINA_TEXT_BACKGROUND_TRANSPARENCY
    staminaText.TextScaled = true
    staminaText.TextColor3 = Color3.new(1, 1, 0) -- Yellow color for stamina
    staminaText.TextStrokeColor3 = Color3.new(0, 0, 0)
            staminaText.TextStrokeTransparency = GameConfig.STAMINA_TEXT_STROKE_TRANSPARENCY
    staminaText.Font = Enum.Font.SourceSansBold
    staminaText.Text = "Stamina: 0.00"
    staminaText.Parent = staminaGui

    -- Aggravation Radius
            local aggravationRadius = GameConfig.AGRAVATION_RADIUS -- Bees will only attack if player is within configured radius

    -- BodyMover Multiplier, larger is "slower"
            local BODY_MOVER_MULTIPLIER = GameConfig.BODY_MOVER_MULTIPLIER -- Multiply P and D values by this to work with smaller numbers

    -- Find the BeeHive and set spawn position
    local spawnPosition = Vector3.new(0, 25, 0) -- Default spawn if BeeHive not found or no PrimaryPart
    local beeHive = workspace:FindFirstChild("BeeHive")
    if beeHive and beeHive:IsA("Model") then
        -- debugPrint("BeeHive model found.")
        -- Assign BeeHive to its collision group (if it has parts)
        for _, part in ipairs(beeHive:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CollisionGroup = GameConfig.BEEHIVE_COLLISION_GROUP
            end
        end
        if beeHive.PrimaryPart then
            -- debugPrint("BeeHive PrimaryPart found.")
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
    -- debugPrint("Flying bee created and parented to workspace at: " .. tostring(spawnPosition))

    -- Add BodyPosition and BodyGyro for flying
    local bodyPosition = Instance.new("BodyPosition")
    bodyPosition.MaxForce = Vector3.new(1e6, 1e6, 1e6)
            bodyPosition.P = GameConfig.BODY_POSITION_P * BODY_MOVER_MULTIPLIER
        bodyPosition.D = GameConfig.BODY_POSITION_D * BODY_MOVER_MULTIPLIER
    bodyPosition.Position = primaryPart.Position
    bodyPosition.Parent = primaryPart
    -- debugPrint("BodyPosition created and parented to ", primaryPart.Name)

    local bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
            bodyGyro.P = GameConfig.BODY_GYRO_P * BODY_MOVER_MULTIPLIER
        bodyGyro.D = GameConfig.BODY_GYRO_D * BODY_MOVER_MULTIPLIER
    bodyGyro.CFrame = primaryPart.CFrame
    bodyGyro.Parent = primaryPart
    -- debugPrint("BodyGyro created and parented to ", primaryPart.Name)

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
        local wanderRadius = GameConfig.WANDER_RADIUS -- How far bees can wander from the center
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

    -- New local variable for tracking drip drop time
    local lastDripDropAttemptTime = 0

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

        -- Determine if the bee should be chasing based on player proximity
        if targetPlayer and playerRootPart then
            distanceToPlayer = (primaryPart.Position - playerRootPart.Position).Magnitude
            if distanceToPlayer <= aggravationRadius then
                shouldAttackPlayer = true
            end
        end

        -- STAMINA LOGIC (COUNTING DOWN)
        if shouldAttackPlayer then
            chaseTime = math.max(0, chaseTime - dt) -- Stamina decreases when chasing
        else
            chaseTime = math.min(GameConfig.MAX_CHASE_TIME, chaseTime + dt) -- Stamina recovers when not chasing
        end

        local currentSpeedMultiplier = 1.0
        if chaseTime <= 0 then -- Bee is tired when stamina is 0 or less
            currentSpeedMultiplier = GameConfig.TIRED_SPEED_MULTIPLIER
            -- debugPrint("Bee " .. bee.Name .. " is tired! Speed multiplier: ", currentSpeedMultiplier)
        end

        -- Apply speed multiplier to body movers
        bodyPosition.P = (10 * BODY_MOVER_MULTIPLIER) * currentSpeedMultiplier
        bodyPosition.D = (1 * BODY_MOVER_MULTIPLIER) * currentSpeedMultiplier

        -- Update stamina display
        staminaText.Text = string.format("Stamina: %.2f / %d", chaseTime, GameConfig.MAX_CHASE_TIME)
        if chaseTime <= 0 then
            staminaText.TextColor3 = Color3.new(1, 0, 0) -- Red when tired
        else
            staminaText.TextColor3 = Color3.new(1, 1, 0) -- Yellow when not tired
        end

        if shouldAttackPlayer and playerRootPart then
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

        -- Check for HoneyDrip drop from flying bee
        local now = tick()
        if now - lastDripDropAttemptTime > GameConfig.FLYING_BEE_DRIP_CHECK_INTERVAL then
            lastDripDropAttemptTime = now
            if math.random(1, 100) <= GameConfig.FLYING_BEE_DRIP_CHANCE then
                -- debugPrint("HoneyDrip dropped from flying bee")
                createHoneyDrip(primaryPart.Position)
            end
        end
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
                    -- debugPrint("Player has Bee Shield, no damage applied")
                    return
                end

                -- debugPrint("Bee touched player:", player.Name)
                local now = tick()
                local lastSting = lastStingTimes[player] or 0
                if now - lastSting > 1 then
                    lastStingTimes[player] = now
                    local humanoid = character:FindFirstChild("Humanoid")
                    if humanoid and humanoid.Health > 0 then
                        -- debugPrint("Stinging player for 20 damage!")
                        humanoid:TakeDamage(20)

                        -- Play sting sound
                        if #stingSounds > 0 then
                            local chosenStingSound = stingSounds[math.random(1, #stingSounds)]:Clone()
                            chosenStingSound.Parent = primaryPart -- Play sound from bee's location
                            chosenStingSound.Playing = true -- Play immediately
                            game:GetService("Debris"):AddItem(chosenStingSound, chosenStingSound.TimeLength + 1) -- Clean up sound after playing
                        end

                        -- Stop buz sound if it exists
                        if buzSound then
                            buzSound:Stop()
                            buzSound:Destroy()
                            buzSound = nil
                        end

                        -- Mark bee as dead
                        isBeeDead = true
                        isAlive.Value = GameConfig.BEE_DEAD_VALUE
                        updateBeeCount()

                        -- Stop all movement and chasing
                        if connection then 
                            connection:Disconnect() 
                            connection = nil
                        end
                        if bodyPosition then 
                            bodyPosition:Destroy() 
                            bodyPosition = nil
                        end
                        if bodyGyro then 
                            bodyGyro:Destroy() 
                            bodyGyro = nil
                        end
                        if staminaGui then 
                            staminaGui:Destroy() 
                            staminaGui = nil
                        end

                        -- Make bee fall to ground and become transparent
                        for _, part in ipairs(bee:GetDescendants()) do
                            if part:IsA("BasePart") then
                                -- Make parts transparent
                                part.Transparency = GameConfig.BEE_DEATH_TRANSPARENCY
                                -- Keep collision enabled initially so it doesn't fall through
                                part.CanCollide = true
                                -- Add gravity to make it fall
                                local bodyForce = Instance.new("BodyForce")
                                bodyForce.Force = Vector3.new(0, -part:GetMass() * workspace.Gravity, 0)
                                bodyForce.Parent = part
                            end
                        end

                        -- Anchor the bee to the ground after it falls and then disable collision
                        task.delay(1, function()
                            if bee and bee.Parent then
                                for _, part in ipairs(bee:GetDescendants()) do
                                    if part:IsA("BasePart") then
                                        part.Anchored = true
                                        -- Now we can safely disable collision
                                        part.CanCollide = false
                                        -- Remove the body force since we don't need it anymore
                                        local bodyForce = part:FindFirstChild("BodyForce")
                                        if bodyForce then
                                            bodyForce:Destroy()
                                        end
                                    end
                                end
                            end
                        end)
                    end
                end
            end
        end
    end)

    return bee
end

-- Connect player events using PlayerDataManager
Players.PlayerAdded:Connect(function(player)
    PlayerDataManager.onPlayerAdded(player, GameConfig.DEFAULT_SPAWN_POSITION)
end)

-- Listen for spawn requests from client
RemoteEventsManager.connectToEvent("SpawnCube", function(player)
    createFlyingCube()
    updateBeeCount() -- Update count immediately after manual spawn
end)

-- Spawn the first cube when the game starts
print("Starting flying cube spawn...")
local firstBee = createFlyingCube()
if firstBee then
    print("First bee created successfully")
else
    warn("Failed to create first bee!")
end
updateBeeCount() -- Update count immediately after initial spawn

-- Function to get minimum required bees
local function getMinRequiredBees()
    local playerCount = 0
    for _, _ in ipairs(Players:GetPlayers()) do
        playerCount = playerCount + 1
    end
    return GameConfig.BASE_MIN_BEES + (playerCount * GameConfig.BEES_PER_PLAYER)
end

-- Automatic bee spawner
local function startAutoSpawner()
    while true do
        local currentBees = getBeeCount()
        local minRequiredBees = getMinRequiredBees()
        
        -- Determine spawn interval based on current bee count
        local spawnInterval = currentBees < minRequiredBees and GameConfig.MIN_SPAWN_INTERVAL or GameConfig.MAX_SPAWN_INTERVAL
        
        -- Always spawn if below minimum, otherwise spawn at max interval
        if currentBees < GameConfig.MAX_HONEYDRIPS then
            -- debugPrint("Auto-spawning bee. Current:", currentBees, "Minimum Required:", minRequiredBees, "Interval:", spawnInterval)
            createFlyingCube()
        else
            -- debugPrint("Maintaining minimum. Current:", currentBees, "Minimum Required:", minRequiredBees, "Spawning at:", spawnInterval, "seconds")
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
    print("Starting auto spawner task...")
    task.spawn(startAutoSpawner)
    print("Auto spawner started")
end)

-- Listen for bees being removed from the workspace to update the count immediately
workspace.ChildRemoved:Connect(function(child)
    if child.Name == "FlyingCube" then
        -- debugPrint("Bee removed from workspace, updating count")
        updateBeeCount()
    end
end)

-- New: BindableEvent for inter-script communication
local SpawnBeesRequestEvent = Instance.new("BindableEvent")
SpawnBeesRequestEvent.Name = "SpawnBeesRequestEvent"
SpawnBeesRequestEvent.Parent = ReplicatedStorage

-- Function to spawn multiple bees (called via BindableEvent)
local function spawnMultipleBees(count, color)
    for i = 1, count do
        task.spawn(function()
            createFlyingCube(color)
        end)
    end
    updateBeeCount()
    -- debugPrint("Spawned", count, "bees via request!")
end

-- Connect the BindableEvent to the spawning function
SpawnBeesRequestEvent.Event:Connect(spawnMultipleBees)
SpawnBeesRequestEvent.Event:Connect(spawnMultipleBees)

-- Handle client respawn requests
RemoteEventsManager.connectToEvent("RequestRespawn", function(player)
    if player and player:IsA("Player") then
        player:LoadCharacter()
    end
end)
