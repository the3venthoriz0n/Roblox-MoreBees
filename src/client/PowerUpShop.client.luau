local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Power-up definitions (must be consistent with server)
local POWER_UPS = {
    {
        Name = "Speed Boost",
        Description = "Increases your movement speed by 50% for 30 seconds",
        Cost = 2,
    },
    {
        Name = "Health Boost",
        Description = "Increases your max health by 50 for 1 minute",
        Cost = 3,
    },
    {
        Name = "Bee Shield",
        Description = "Bees cannot sting you for 45 seconds",
        Cost = 4,
    }
}

-- Get RemoteEvents
local shopEvent = ReplicatedStorage:WaitForChild("PowerUpShopEvent")
local toggleShopEvent = ReplicatedStorage:WaitForChild("ToggleShopEvent")

-- Create shop GUI
local function createShopGui()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "PowerUpShopGui"
    screenGui.ResetOnSpawn = false
    screenGui.Enabled = false -- Start with GUI hidden
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 400)
    frame.Position = UDim2.new(0.5, -150, 0.5, -200)
    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    frame.BorderSizePixel = 0
    frame.Parent = screenGui
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 50)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    title.Text = "Power-Up Shop"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.TextScaled = true
    title.Parent = frame
    
    local honeyDripCount = Instance.new("TextLabel")
    honeyDripCount.Name = "HoneyDripCountLabel"
    honeyDripCount.Size = UDim2.new(1, 0, 0, 30)
    honeyDripCount.Position = UDim2.new(0, 0, 0, 50)
    honeyDripCount.BackgroundTransparency = 1
    honeyDripCount.Text = "HoneyDrips: 0"
    honeyDripCount.TextColor3 = Color3.new(1, 1, 1)
    honeyDripCount.TextScaled = true
    honeyDripCount.Parent = frame
    
    -- Update HoneyDrip count when it changes
    local function updateHoneyDripDisplay()
        local leaderstats = player:FindFirstChild("leaderstats")
        if leaderstats then
            local honeyDrips = leaderstats:FindFirstChild("HoneyDrips")
            if honeyDrips then
                honeyDripCount.Text = "HoneyDrips: " .. honeyDrips.Value
            else
                honeyDripCount.Text = "HoneyDrips: 0"
            end
        else
            honeyDripCount.Text = "HoneyDrips: 0"
        end
    end

    -- Initial update
    updateHoneyDripDisplay()

    -- Listen for changes in HoneyDrips value
    player.CharacterAdded:Connect(function()
        -- Reconnect on character added if leaderstats object changes
        local leaderstats = player:WaitForChild("leaderstats")
        local honeyDrips = leaderstats:WaitForChild("HoneyDrips")
        honeyDrips.Changed:Connect(updateHoneyDripDisplay)
        updateHoneyDripDisplay() -- Initial update after character added
    end)

    -- Also listen for initial leaderstats creation
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        local honeyDrips = leaderstats:FindFirstChild("HoneyDrips")
        if honeyDrips then
            honeyDrips.Changed:Connect(updateHoneyDripDisplay)
        else
            -- Wait for HoneyDrips to be created if it doesn't exist yet
            leaderstats.ChildAdded:Connect(function(child)
                if child.Name == "HoneyDrips" then
                    child.Changed:Connect(updateHoneyDripDisplay)
                    updateHoneyDripDisplay()
                end
            end)
        end
    else
        player.ChildAdded:Connect(function(child)
            if child.Name == "leaderstats" then
                child.ChildAdded:Connect(function(grandchild)
                    if grandchild.Name == "HoneyDrips" then
                        grandchild.Changed:Connect(updateHoneyDripDisplay)
                        updateHoneyDripDisplay()
                    end
                end)
            end
        end)
    end

    -- Create buttons for each power-up
    local buttonHeight = 80
    local spacing = 10
    local startY = 90
    
    for i, powerUp in ipairs(POWER_UPS) do
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, -20, 0, buttonHeight)
        button.Position = UDim2.new(0, 10, 0, startY + (i-1) * (buttonHeight + spacing))
        button.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
        button.Text = powerUp.Name .. "\n" .. powerUp.Description .. "\nCost: " .. powerUp.Cost .. " HoneyDrips"
        button.TextColor3 = Color3.new(1, 1, 1)
        button.TextScaled = true
        button.Parent = frame
        
        button.MouseButton1Click:Connect(function()
            shopEvent:FireServer(i)
        end)
    end
    
    screenGui.Parent = player:WaitForChild("PlayerGui")
end

-- Listen for toggle event from server
toggleShopEvent.OnClientEvent:Connect(function()
    print("ToggleShopEvent received on client!")
    local shopGui = player.PlayerGui:FindFirstChild("PowerUpShopGui")
    if shopGui then
        shopGui.Enabled = not shopGui.Enabled
        print("Shop GUI Enabled status set to: ", shopGui.Enabled)
    else
        -- If GUI doesn't exist, create it and then enable/disable
        print("Shop GUI not found, creating it...")
        createShopGui()
        shopGui = player.PlayerGui:FindFirstChild("PowerUpShopGui")
        if shopGui then
            shopGui.Enabled = true -- Enable it after creation, as the server expects it to be toggled
            print("Shop GUI created and enabled to: ", shopGui.Enabled)
        else
            warn("Failed to create shop GUI.")
        end
    end
end)

-- Initial GUI creation (for players already in game)
if player and not player.PlayerGui:FindFirstChild("PowerUpShopGui") then
    print("Initial shop GUI creation for existing player.")
    createShopGui()
end 