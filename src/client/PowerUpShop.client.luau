-- Variables defined at the top as per user preference
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

-- Simple config loading
local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local ShopConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ShopConfig"))

-- Simple remote event loading
local shopEvent = ReplicatedStorage:WaitForChild("PowerUpShopEvent")
local purchaseFeedbackEvent = ReplicatedStorage:WaitForChild("PurchaseFeedbackEvent")
local PowerUpActiveEvent = ReplicatedStorage:WaitForChild("PowerUpActiveEvent")
local PowerUpEndedEvent = ReplicatedStorage:WaitForChild("PowerUpEndedEvent")

-- Simple timer management
local activeTimers = {}

local function showPowerUpTimer(buttonName, duration)
    local playerGui = player:WaitForChild("PlayerGui")
    local mainUI = playerGui:WaitForChild("MainUI")
    local button = mainUI:FindFirstChild(buttonName)
    if not button then return end
    
    local timerLabel = button:FindFirstChild("ActiveTimer")
    if not timerLabel then return end
    
    timerLabel.Visible = true
    
    -- Calculate end time
    local endTime = tick() + duration
    if activeTimers[buttonName] and activeTimers[buttonName] > tick() then
        endTime = activeTimers[buttonName] + duration
    end
    activeTimers[buttonName] = endTime
    
    -- Update timer display
    local connection
    connection = RunService.RenderStepped:Connect(function()
        local remaining = math.max(0, endTime - tick())
        if timerLabel and timerLabel.Parent then
            timerLabel.Text = tostring(math.ceil(remaining))
        end
        
        if remaining <= 0 then
            if timerLabel and timerLabel.Parent then
                timerLabel.Visible = false
                timerLabel.Text = ""
            end
            if connection then connection:Disconnect() end
            activeTimers[buttonName] = nil
        end
    end)
end

local function hidePowerUpTimer(buttonName)
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then return end
    
    local mainUI = playerGui:FindFirstChild("MainUI")
    if not mainUI then return end
    
    local button = mainUI:FindFirstChild(buttonName)
    if not button then return end
    
    local timerLabel = button:FindFirstChild("ActiveTimer")
    if timerLabel then
        timerLabel.Visible = false
        timerLabel.Text = ""
    end
    
    activeTimers[buttonName] = nil
end

-- Simple event connections
PowerUpActiveEvent.OnClientEvent:Connect(function(powerUpName, duration)
    if powerUpName then
        local buttonName = powerUpName:gsub(" ", "")
        showPowerUpTimer(buttonName, duration)
    end
end)

PowerUpEndedEvent.OnClientEvent:Connect(function(powerUpName)
    if powerUpName then
        local buttonName = powerUpName:gsub(" ", "")
        hidePowerUpTimer(buttonName)
    end
end)

purchaseFeedbackEvent.OnClientEvent:Connect(function(message)
    if message == "Not enough HoneyDrips!" then
        local counterGui = player.PlayerGui:FindFirstChild("CounterGui")
        if counterGui then
            local notEnoughDrips = counterGui:FindFirstChild("NotEnoughDrips")
            if notEnoughDrips then
                notEnoughDrips.AnchorPoint = Vector2.new(0.5, 0.5)
                notEnoughDrips.Position = UDim2.new(0.5, 0, 0.5, 0)
                notEnoughDrips.Visible = true
                task.delay(1, function()
                    if notEnoughDrips then
                        notEnoughDrips.Visible = false
                    end
                end)
            end
        end
    end
end)

-- Simple button connection function
local function connectShopButtons()
    print("[DEBUG] Connecting shop buttons...")
    
    local playerGui = player:WaitForChild("PlayerGui")
    local mainUI = playerGui:WaitForChild("MainUI")
    
    -- List available buttons for debugging
    print("[DEBUG] Available buttons in MainUI:")
    for _, child in ipairs(mainUI:GetChildren()) do
        if child:IsA("GuiObject") then
            print("  - " .. child.Name)
        end
    end
    
    local connectedCount = 0
    
    for i, powerUp in ipairs(ShopConfig.POWER_UPS_DATA) do
        local buttonName = powerUp.Name:gsub(" ", "")
        print("[DEBUG] Looking for button:", buttonName)
        
        local button = mainUI:FindFirstChild(buttonName)
        if button then
            print("[DEBUG] Found button:", buttonName, "connecting...")
            
            button.MouseButton1Click:Connect(function()
                print("[DEBUG] Button clicked:", buttonName)
                
                if powerUp.ProductId and powerUp.EnableRobuxPurchase then
                    print("[DEBUG] Prompting Robux purchase for:", buttonName)
                    local MarketplaceService = game:GetService("MarketplaceService")
                    MarketplaceService:PromptProductPurchase(player, powerUp.ProductId)
                elseif powerUp.Cost then
                    print("[DEBUG] Purchasing with HoneyDrips:", buttonName, "index:", i)
                    shopEvent:FireServer(i)
                else
                    print("[DEBUG] No valid purchase method for:", buttonName)
                end
            end)
            
            connectedCount = connectedCount + 1
            print("[DEBUG] Successfully connected button:", buttonName)
        else
            print("[DEBUG] Button not found:", buttonName)
        end
    end
    
    print("[SUCCESS] Connected " .. connectedCount .. " out of " .. #ShopConfig.POWER_UPS_DATA .. " shop buttons!")
end

-- Simple tooltip setup
local function setupTooltips()
    local playerGui = player:WaitForChild("PlayerGui")
    local mainUI = playerGui:WaitForChild("MainUI")
    local globalTooltip = mainUI:FindFirstChild("GlobalToolTip")
    if not globalTooltip then return end
    
    local tooltipDelay = GameConfig.TOOLTIP_DELAY or 0.5
    local tooltipDelays = {}
    
    for _, powerUp in ipairs(ShopConfig.POWER_UPS_DATA) do
        local buttonName = powerUp.Name:gsub(" ", "")
        local button = mainUI:FindFirstChild(buttonName)
        if button then
            local desc = powerUp.Description or ""
            
            button.MouseEnter:Connect(function()
                -- Cancel existing delay
                if tooltipDelays[button] then
                    tooltipDelays[button] = false
                end
                
                local shouldShow = true
                tooltipDelays[button] = shouldShow
                
                task.delay(tooltipDelay, function()
                    if tooltipDelays[button] == shouldShow then
                        if globalTooltip and globalTooltip.Parent then
                            globalTooltip.Text = desc
                            globalTooltip.Visible = true
                            
                            local camera = workspace.CurrentCamera
                            if camera then
                                local viewportSize = camera.ViewportSize
                                globalTooltip.Position = UDim2.new(
                                    0, (viewportSize.X - globalTooltip.AbsoluteSize.X) / 2,
                                    0, (viewportSize.Y - globalTooltip.AbsoluteSize.Y) / 2
                                )
                            end
                        end
                    end
                end)
            end)
            
            button.MouseLeave:Connect(function()
                if tooltipDelays[button] then
                    tooltipDelays[button] = false
                end
                
                if globalTooltip and globalTooltip.Parent then
                    globalTooltip.Visible = false
                end
            end)
        end
    end
end

-- Simple initialization
local function initialize()
    print("[DEBUG] Initializing shop...")
    
    -- Wait for UI to load
    task.wait(0.5)
    
    -- Connect buttons
    connectShopButtons()
    
    -- Setup tooltips
    setupTooltips()
    
    print("[DEBUG] Shop initialization completed")
end

-- Setup for character
local function setupCharacter(character)
    if character then
        task.wait(0.5)
        initialize()
    end
end

player.CharacterAdded:Connect(setupCharacter)

if player.Character then
    setupCharacter(player.Character)
end

-- Initial setup
initialize() 