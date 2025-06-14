local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

-- Create shop button
local function createShopButton()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ShopButtonGui"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = player:WaitForChild("PlayerGui")
    
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 150, 0, 50)
    button.Position = UDim2.new(0.9, -160, 0.1, 10) -- Top right corner
    button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    button.Text = "Shop"
    button.TextColor3 = Color3.new(1, 1, 1)
    button.TextScaled = true
    button.Font = Enum.Font.GothamBold
    button.Parent = screenGui
    
    -- Add hover effect
    button.MouseEnter:Connect(function()
        button.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    end)
    
    button.MouseLeave:Connect(function()
        button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    end)
    
    -- Toggle shop visibility when clicked
    local toggleShopEvent = ReplicatedStorage:WaitForChild("ToggleShopEvent")
    button.MouseButton1Click:Connect(function()
        print("Shop button clicked, firing ToggleShopEvent!")
        toggleShopEvent:FireServer()
    end)
end

-- Create button for new players
Players.PlayerAdded:Connect(function(newPlayer)
    if newPlayer == player then
        createShopButton()
    end
end)

-- Create button for existing player
if player then
    createShopButton()
end 