local ShopConfig = {}

ShopConfig.POWER_UPS_DATA = {
    {
        Name = "Speed Boost",
        Description = "Increases your movement speed by 50% for 30 seconds",
        Cost = 2,
        RobuxCost = 5,
        ProductId = 12345,
        Duration = 30,
    },
    {
        Name = "Health Boost",
        Description = "Increases your max health by 50 for 1 minute",
        Cost = 3,
        RobuxCost = 10,
        ProductId = 67890,
        Duration = 60,
    },
    {
        Name = "Bee Shield",
        Description = "Bees cannot sting you for 45 seconds",
        Cost = 4,
        RobuxCost = 20,
        ProductId = 11223,
        Duration = 45,
    },
    {
        Name = "Spawn Bees",
        Description = "Spawns 10 additional bees",
        Cost = 1, -- 1 HoneyDrip
        RobuxCost = 10, -- 10 Robux
        ProductId = 44556, -- REPLACE WITH YOUR ACTUAL DEVELOPER PRODUCT ID
        Duration = 0, -- Instant effect
    }
}

return ShopConfig 