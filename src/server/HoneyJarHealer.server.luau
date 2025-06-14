-- HoneyJar Healing Script
-- Place this script inside your HoneyJar model (e.g., as a child of the 'Handle' part or the model itself)

local HoneyJar -- Will store the actual HoneyJar model
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Determine the HoneyJar model
if script.Parent:IsA("Model") then
    HoneyJar = script.Parent
else
    -- Assume script is in a part inside the model
    HoneyJar = script.Parent.Parent
    if not HoneyJar or not HoneyJar:IsA("Model") then
        warn("[HoneyJarHealer] Could not find HoneyJar model. Script parent is not a model, and its parent is also not a model.")
        script:Destroy()
        return
    end
end

-- Debug control (can be linked to a global debug setting if needed)
local Debug = true
local function debugPrint(...)
    if Debug then
        print("[HoneyJarHealer]", ...)
    end
end

debugPrint("HoneyJar Healing Script loaded for model: ", HoneyJar.Name)

-- Healing settings
local HEAL_COOLDOWN = 5 -- 5 seconds between heals
local HEAL_AMOUNT = 25 -- Amount of health to restore

local lastHealTime = 0

-- Ensure the HoneyJar has a PrimaryPart set for proper Adornee/Parenting of UI
local primaryPart = HoneyJar.PrimaryPart or HoneyJar:FindFirstChild("Handle") or HoneyJar:FindFirstChildWhichIsA("BasePart")

if not primaryPart then
    warn("[HoneyJarHealer] No suitable PrimaryPart found for HoneyJar. Healing functionality may be limited.")
    -- Attempt to find any BasePart as a fallback for prompt parenting
    for _, part in ipairs(HoneyJar:GetDescendants()) do
        if part:IsA("BasePart") then
            primaryPart = part
            HoneyJar.PrimaryPart = part -- Set it if not already set
            break
        end
    end
end

if not primaryPart then
    warn("[HoneyJarHealer] Critical: No BasePart found in HoneyJar model. Healing script cannot function.")
    script:Destroy()
    return
end

-- Add ProximityPrompt for healing
local healthPrompt = Instance.new("ProximityPrompt")
healthPrompt.Name = "HealthPackPrompt"
healthPrompt.ActionText = "Heal"
healthPrompt.ObjectText = "Honey Jar"
healthPrompt.HoldDuration = 0.5
healthPrompt.MaxActivationDistance = 10
healthPrompt.RequiresLineOfSight = true
healthPrompt.Parent = primaryPart -- Parent to the primary part
debugPrint("ProximityPrompt created and parented to ", primaryPart.Name, ", Enabled: ", healthPrompt.Enabled)

-- Create billboard GUI for cooldown timer
local billboardGui = Instance.new("BillboardGui")
billboardGui.Name = "CooldownTimer"
billboardGui.Size = UDim2.new(0, 100, 0, 50)
billboardGui.StudsOffset = Vector3.new(0, 1.5, 0) -- Position centered above the jar
billboardGui.Adornee = primaryPart -- Adorn to the primary part
billboardGui.Parent = primaryPart -- Parent to the primary part
debugPrint("BillboardGui created and parented to ", primaryPart.Name)

local timerText = Instance.new("TextLabel")
timerText.Name = "TimerText"
timerText.Size = UDim2.new(1, 0, 1, 0)
timerText.BackgroundTransparency = 0.5
timerText.BackgroundColor3 = Color3.new(0, 0, 0)
timerText.TextColor3 = Color3.new(1, 1, 1)
timerText.TextScaled = true
timerText.Font = Enum.Font.GothamBold
timerText.Text = "Health"
timerText.Parent = billboardGui

-- Function to update cooldown timer
local function updateCooldownTimer()
    if not primaryPart or not primaryPart.Parent then return end -- Safety check
    if not timerText or not timerText.Parent then return end -- Safety check

    local currentTime = tick()
    local timeSinceLastHeal = currentTime - lastHealTime
    local remainingCooldown = math.max(0, HEAL_COOLDOWN - timeSinceLastHeal)
    
    if remainingCooldown > 0 then
        timerText.Text = string.format("%.1f", remainingCooldown)
        timerText.TextColor3 = Color3.new(1, 0, 0)
        healthPrompt.Enabled = false
    else
        timerText.Text = "Health"
        timerText.TextColor3 = Color3.new(0, 1, 0)
        healthPrompt.Enabled = true
    end
end

-- Update timer every frame
local cooldownConnection
cooldownConnection = RunService.Heartbeat:Connect(function()
    if not primaryPart or not primaryPart.Parent then
        if cooldownConnection then
            cooldownConnection:Disconnect()
        end
        return
    end
    updateCooldownTimer()
end)

debugPrint("Connecting ProximityPrompt Triggered event...")
-- Handle health pack trigger
healthPrompt.Triggered:Connect(function(player)
    debugPrint("ProximityPrompt Triggered by player: ", player.Name)
    if not primaryPart or not primaryPart.Parent then 
        debugPrint("PrimaryPart or its parent is missing, cannot heal.")
        return 
    end -- Safety check
    
    local currentTime = tick()
    if currentTime - lastHealTime >= HEAL_COOLDOWN then
        debugPrint("Cooldown met. Attempting to heal.")
        lastHealTime = currentTime
        
        local character = player.Character
        if character then
            debugPrint("Player character found: ", character.Name)
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid then
                debugPrint("Humanoid found. Current health: ", humanoid.Health, " Max health: ", humanoid.MaxHealth)
                -- Only heal if player is damaged
                if humanoid.Health < humanoid.MaxHealth then
                    debugPrint("Player is damaged. Healing...")
                    local newHealth = math.min(humanoid.MaxHealth, humanoid.Health + HEAL_AMOUNT)
                    humanoid.Health = newHealth
                    
                    debugPrint("Healed player:", player.Name, "New health:", newHealth)
                    
                    -- Visual effect
                    for _, part in ipairs(HoneyJar:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.BrickColor = BrickColor.new("Bright green")
                            local originalMaterial = part.Material
                            part.Material = Enum.Material.Neon
                            task.delay(0.2, function()
                                if part.Parent then
                                    part.Material = originalMaterial
                                    part.BrickColor = BrickColor.new("Really red")
                                end
                            end)
                        end
                    end
                    
                    -- Play a healing sound
                    local healSound = HoneyJar:FindFirstChild("HealSound")
                    if not healSound then
                        healSound = Instance.new("Sound")
                        healSound.Name = "HealSound"
                        healSound.SoundId = "rbxassetid://9114827380"
                        healSound.Volume = 0.5
                        healSound.Parent = HoneyJar
                    end
                    healSound:Play()
                else
                    debugPrint("Player is at full health. Not healing.")
                    -- Player is at full health
                    timerText.Text = "Full Health"
                    timerText.TextColor3 = Color3.new(1, 1, 0)
                    task.delay(1, function()
                        if timerText.Parent then
                            updateCooldownTimer()
                        end
                    end)
                end
            else
                debugPrint("Humanoid not found in character: ", character.Name)
            end
        else
            debugPrint("Player character not found for: ", player.Name)
        end
    else
        debugPrint("Cooldown not met. Remaining: ", string.format("%.1f", HEAL_COOLDOWN - (currentTime - lastHealTime)))
    end
end) 