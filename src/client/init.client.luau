local StarterGui = game:GetService("StarterGui")
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, true)

print("Client script loaded Rojo OG!")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Respawn timer variables
local respawnTime = 5
local deaths = 0
local respawnGui
local respawnLabel
local respawnCountdown = 0
local respawnConnection

-- Create respawn timer GUI
local function createRespawnGui()
    if respawnGui then respawnGui:Destroy() end
    respawnGui = Instance.new("ScreenGui")
    respawnGui.Name = "RespawnGui"
    respawnGui.ResetOnSpawn = false
    respawnGui.Parent = player:WaitForChild("PlayerGui")

    respawnLabel = Instance.new("TextLabel")
    respawnLabel.Size = UDim2.new(0, 300, 0, 80)
    respawnLabel.Position = UDim2.new(0.5, -150, 0.4, 0)
    respawnLabel.BackgroundTransparency = 0.3
    respawnLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    respawnLabel.TextColor3 = Color3.new(1, 1, 1)
    respawnLabel.TextStrokeTransparency = 0.5
    respawnLabel.Font = Enum.Font.SourceSansBold
    respawnLabel.TextScaled = true
    respawnLabel.Text = ""
    respawnLabel.Parent = respawnGui
end

local function showRespawnTimer()
    createRespawnGui()
    if not respawnLabel then return end -- Safety check
    
    respawnCountdown = respawnTime
    respawnLabel.Text = "Respawning in " .. respawnCountdown .. "..."
    
    if respawnConnection then respawnConnection:Disconnect() end
    respawnConnection = game:GetService("RunService").RenderStepped:Connect(function(dt)
        if not respawnLabel or not respawnLabel.Parent then return end -- Safety check
        
        if respawnCountdown > 0 then
            respawnCountdown = respawnCountdown - dt
            local display = math.ceil(respawnCountdown)
            respawnLabel.Text = "Respawning in " .. display .. "..."
            if respawnCountdown <= 0 then
                respawnLabel.Text = "Respawning..."
                if respawnConnection then
                    respawnConnection:Disconnect()
                    respawnConnection = nil
                end
                -- Request respawn
                player:LoadCharacter()
                task.wait(0.5)
                if respawnGui then 
                    respawnGui:Destroy()
                    respawnGui = nil
                    respawnLabel = nil
                end
            end
        end
    end)
end

-- Listen for deaths and trigger respawn timer
player.CharacterAdded:Connect(function(character)
    -- Remove respawn GUI if it exists (player has respawned)
    if respawnGui then
        respawnGui:Destroy()
        respawnGui = nil
        respawnLabel = nil
    end
    
    local humanoid = character:WaitForChild("Humanoid")
    humanoid.Died:Connect(function()
        deaths = deaths + 1
        respawnTime = 5 * deaths -- Increase by 5 seconds per death
        task.spawn(showRespawnTimer) -- Spawn in a new thread to ensure proper initialization
    end)
end)

-- Create GUI
local function createCubeSpawnerGui()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CubeSpawnerGui"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = player:WaitForChild("PlayerGui")

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 200, 0, 50)
    button.Position = UDim2.new(0.5, -100, 0.9, -25)
    button.Text = "Spawn Flying Cube"
    button.Parent = screenGui

    -- Fire RemoteEvent when button is clicked
    local spawnEvent = ReplicatedStorage:WaitForChild("SpawnCube")
    button.MouseButton1Click:Connect(function()
        spawnEvent:FireServer()
    end)
end

-- Only create if not already present
if not player.PlayerGui:FindFirstChild("CubeSpawnerGui") then
    createCubeSpawnerGui()
end

-- Create GUI for bee count display
local function createBeeCountDisplayGui()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BeeCountDisplayGui"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = player:WaitForChild("PlayerGui")

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 200, 0, 50)
    label.Position = UDim2.new(0.5, -100, 0.1, 0) -- Position at top center
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1, 1, 1) -- White text
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Text = "Bees: 0"
    label.Parent = screenGui

    -- Listen for changes in the server's BeeCountDisplay value
    local beeCountDisplay = ReplicatedStorage:WaitForChild("BeeCountDisplay")
    beeCountDisplay.Changed:Connect(function(value)
        label.Text = value
    end)

    -- Set initial value
    label.Text = beeCountDisplay.Value
end

-- Only create if not already present
if not player.PlayerGui:FindFirstChild("BeeCountDisplayGui") then
    createBeeCountDisplayGui()
end

player.CharacterAdded:Connect(function()
    -- Re-parent the GUI if needed (in case PlayerGui is reset)
    local gui = player.PlayerGui:FindFirstChild("CubeSpawnerGui")
    if not gui then
        createCubeSpawnerGui()
    else
        gui.Parent = player.PlayerGui
    end

    local beeGui = player.PlayerGui:FindFirstChild("BeeCountDisplayGui")
    if not beeGui then
        createBeeCountDisplayGui()
    else
        beeGui.Parent = player.PlayerGui
    end
end)