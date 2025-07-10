local ShopConfig = {}

ShopConfig.POWER_UPS_DATA = {
    {
        Name = "Speed Boost",
        Description = "Increases your movement speed by 50% for 30 seconds",
        Cost = 2,
        -- RobuxCost = 5,
        -- ProductId = 3307385345,
        Duration = 30,
    },
    {
        Name = "Health Boost",
        Description = "Increases your max health by 50 for 1 minute",
        Cost = 3,
        RobuxCost = 10,
        ProductId = 3307385342,
        Duration = 60,
    },
    {
        Name = "Bee Shield",
        Description = "Bees cannot sting you for 45 seconds",
        Cost = 4,
        RobuxCost = 20,
        ProductId = 3307385343,
        Duration = 45,
    },
    {
        Name = "Spawn Bees",
        Description = "Spawns 20 additional bees",
        Cost = 5, -- 1 HoneyDrip
        RobuxCost = 25, -- 10 Robux
        ProductId = 3307385346, -- REPLACE WITH YOUR ACTUAL DEVELOPER PRODUCT ID
        Duration = 0, -- Instant effect
    },
    {
        Name = "Honey Drip",
        Description = "Purchase a Honey Drip with Robux",
        RobuxCost = 1,
        ProductId = 3307384691,
    }
}

return ShopConfig