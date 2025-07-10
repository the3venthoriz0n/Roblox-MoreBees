local ShopConfig = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))

ShopConfig.POWER_UPS_DATA = {
    {
        Name = "Speed Boost",
        Description = "Increases your movement speed by " .. math.floor((GameConfig.SPEED_BOOST_MULTIPLIER - 1) * 100) .. "%",
        Cost = 2,
        ProductId = 3307385345,
        Duration = 20,
        EnableRobuxPurchase = GameConfig.ENABLE_ROBUX_PURCHASES,
    },
    {
        Name = "Health Boost",
        Description = "Increases your max health by " .. GameConfig.HEALTH_BOOST_AMOUNT,
        Cost = 4,
        ProductId = 3307385342,
        Duration = 20,
        EnableRobuxPurchase = GameConfig.ENABLE_ROBUX_PURCHASES,
    },
    {
        Name = "Bee Shield",
        Description = "Bees cannot sting you for 30 seconds", -- hardcoded duration
        Cost = 5,
        ProductId = 3307385343,
        Duration = 30,
        EnableRobuxPurchase = GameConfig.ENABLE_ROBUX_PURCHASES,
    },
    {
        Name = "More Bees",
        Description = "Spawns " .. GameConfig.BEE_SPAWN_COUNT .. " additional bees",
        Cost = 10,
        ProductId = 3307385346,
        Duration = 0,
        EnableRobuxPurchase = GameConfig.ENABLE_ROBUX_PURCHASES,
    },
    {
        Name = "Honey Drip",
        Description = "Purchase " .. tostring(10) .. " Honey Drips with Robux",
        Value = 10,
        ProductId = 3330220271,
        EnableRobuxPurchase = true,
    }
}

return ShopConfig