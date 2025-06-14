local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local MarketplaceService = game:GetService("MarketplaceService")

-- Power-up definitions (must be consistent with server)
local POWER_UPS = {
    {
        Name = "Speed Boost",
        Description = "Increases your movement speed by 50% for 30 seconds",
        Cost = 2,
        RobuxCost = 5,
        ProductId = 12345,
    },
    {
        Name = "Health Boost",
        Description = "Increases your max health by 50 for 1 minute",
        Cost = 3,
        RobuxCost = 10,
        ProductId = 67890,
    },
    {
        Name = "Bee Shield",
        Description = "Bees cannot sting you for 45 seconds",
        Cost = 4,
        RobuxCost = 20,
        ProductId = 11223,
    },
    -- New Power-Up: Spawn 10 Bees
    {
        Name = "Spawn Bees",
        Description = "Spawns 10 additional bees",
        Cost = 1, -- 1 HoneyDrip
        RobuxCost = 10, -- 10 Robux
        ProductId = 44556, -- Must match server ProductId
    }
}

-- Get RemoteEvents
local shopEvent = ReplicatedStorage:WaitForChild("PowerUpShopEvent")
local toggleShopEvent = ReplicatedStorage:WaitForChild("ToggleShopEvent")
local purchaseFeedbackEvent = ReplicatedStorage:WaitForChild("PurchaseFeedbackEvent") -- New: Get feedback event

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
    title.Font = Enum.Font.GothamBold
    title.Parent = frame
    
    local honeyDripCount = Instance.new("TextLabel")
    honeyDripCount.Name = "HoneyDripCountLabel"
    honeyDripCount.Size = UDim2.new(1, 0, 0, 30)
    honeyDripCount.Position = UDim2.new(0, 0, 0, 50)
    honeyDripCount.BackgroundTransparency = 1
    honeyDripCount.Text = "HoneyDrips: 0"
    honeyDripCount.TextColor3 = Color3.new(1, 1, 1)
    honeyDripCount.TextScaled = true
    honeyDripCount.Font = Enum.Font.GothamBold
    honeyDripCount.Parent = frame
    
    -- Feedback TextLabel
    local feedbackLabel = Instance.new("TextLabel")
    feedbackLabel.Name = "FeedbackLabel"
    feedbackLabel.Size = UDim2.new(0, 200, 0, 40)
    feedbackLabel.Position = UDim2.new(0.5, -100, 0.05, 0) -- Top center
    feedbackLabel.BackgroundTransparency = 0.5
    feedbackLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    feedbackLabel.TextColor3 = Color3.new(1, 1, 1)
    feedbackLabel.TextScaled = true
    feedbackLabel.Font = Enum.Font.GothamBold
    feedbackLabel.Text = ""
    feedbackLabel.ZIndex = 2 -- Ensure it's on top
    feedbackLabel.Visible = false
    feedbackLabel.Parent = screenGui -- Parent to screenGui, not frame

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
        -- HoneyDrip Purchase Button
        local honeyDripButton = Instance.new("TextButton")
        honeyDripButton.Size = UDim2.new(0.45, -5, 0, buttonHeight)
        honeyDripButton.Position = UDim2.new(0, 10, 0, startY + (i-1) * (buttonHeight + spacing))
        honeyDripButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
        honeyDripButton.Text = powerUp.Name .. "\n" .. powerUp.Description .. "\nCost: " .. powerUp.Cost .. " HoneyDrips"
        honeyDripButton.TextColor3 = Color3.new(1, 1, 1)
        honeyDripButton.TextScaled = true
        honeyDripButton.Font = Enum.Font.GothamBold
        honeyDripButton.Parent = frame
        
        honeyDripButton.MouseButton1Click:Connect(function()
            shopEvent:FireServer(i)
        end)

        -- Robux Purchase Button
        local robuxButton = Instance.new("TextButton")
        robuxButton.Size = UDim2.new(0.45, -5, 0, buttonHeight)
        robuxButton.Position = UDim2.new(0.55, 0, 0, startY + (i-1) * (buttonHeight + spacing))
        robuxButton.BackgroundColor3 = Color3.fromRGB(100, 40, 100) -- Purple color for Robux
        robuxButton.Text = "Buy with Robux\n" .. powerUp.RobuxCost .. " R$"
        robuxButton.TextColor3 = Color3.new(1, 1, 1)
        robuxButton.TextScaled = true
        robuxButton.Font = Enum.Font.GothamBold
        robuxButton.Parent = frame

        robuxButton.MouseButton1Click:Connect(function()
            MarketplaceService:PromptProductPurchase(player, powerUp.ProductId)
        end)
    end
    
    screenGui.Parent = player:WaitForChild("PlayerGui")
    return screenGui -- Return the screenGui so it can be enabled/disabled
end

local currentShopGui = nil -- Store reference to the created GUI

-- Listen for toggle event from server
toggleShopEvent.OnClientEvent:Connect(function()
    if not currentShopGui then
        currentShopGui = createShopGui()
    end
    currentShopGui.Enabled = not currentShopGui.Enabled
end)

-- Listen for purchase feedback from server
purchaseFeedbackEvent.OnClientEvent:Connect(function(message)
    local shopGui = player.PlayerGui:FindFirstChild("PowerUpShopGui")
    if shopGui then
        local feedbackLabel = shopGui:FindFirstChild("FeedbackLabel")
        if feedbackLabel then
            feedbackLabel.Text = message
            feedbackLabel.Visible = true
            task.delay(3, function()
                if feedbackLabel then
                    feedbackLabel.Visible = false
                end
            end)
        end
    end
end)

-- Initial GUI creation (for players already in game)
if player and not player.PlayerGui:FindFirstChild("PowerUpShopGui") then
    currentShopGui = createShopGui()
end 