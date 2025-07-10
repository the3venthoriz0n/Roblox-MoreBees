local ShopConfig = {}
local GameConfig = require(script.Parent.GameConfig)

ShopConfig.POWER_UPS_DATA = {
    {
        Name = "Speed Boost",
        Description = "Increases your movement speed by 50% for 30 seconds",
        Cost = 2,
        ProductId = 3307385345,
        Duration = 30,
        EnableRobuxPurchase = GameConfig.ENABLE_ROBUX_PURCHASES,
    },
    {
        Name = "Health Boost",
        Description = "Increases your max health by 50 for 1 minute",
        Cost = 4,
        ProductId = 3307385342,
        Duration = 60,
        EnableRobuxPurchase = GameConfig.ENABLE_ROBUX_PURCHASES,
    },
    {
        Name = "Bee Shield",
        Description = "Bees cannot sting you for 45 seconds",
        Cost = 5,
        ProductId = 3307385343,
        Duration = 45,
        EnableRobuxPurchase = GameConfig.ENABLE_ROBUX_PURCHASES,
    },
    {
        Name = "More Bees",
        Description = "Spawns 20 additional bees",
        Cost = 10, -- 1 HoneyDrip
        ProductId = 3307385346, -- REPLACE WITH YOUR ACTUAL DEVELOPER PRODUCT ID
        Duration = 0, -- Instant effect
        EnableRobuxPurchase = GameConfig.ENABLE_ROBUX_PURCHASES,
    },
    {
        Name = "Honey Drip",
        Description = "Purchase a Honey Drip with Robux",
        Value = 10,
        ProductId = 3330220271, -- 10robux
        EnableRobuxPurchase = true,
    }
}

return ShopConfig