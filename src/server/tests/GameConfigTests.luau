-- GameConfig Tests
-- Example tests for the GameConfig module

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestRunner = require(game.ServerScriptService.Server.tests.TestRunner)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local function runTests()
    TestRunner.startSuite("GameConfig")
    
    -- Test 1: GameConfig exists and is a table
    TestRunner.test("GameConfig exists and is a table", function()
        TestRunner.assertNotNil(GameConfig, "GameConfig should exist")
        TestRunner.assertTrue(type(GameConfig) == "table", "GameConfig should be a table")
        return true
    end)
    
    -- Test 2: Check some important config values exist
    TestRunner.test("Important config values exist", function()
        TestRunner.assertNotNil(GameConfig.DEFAULT_SPAWN_POSITION, "DEFAULT_SPAWN_POSITION should exist")
        TestRunner.assertNotNil(GameConfig.BASE_MIN_BEES, "BASE_MIN_BEES should exist")
        TestRunner.assertNotNil(GameConfig.BEES_PER_PLAYER, "BEES_PER_PLAYER should exist")
        return true
    end)
    
    -- Test 3: Check config values are reasonable
    TestRunner.test("Config values are reasonable", function()
        TestRunner.assertTrue(GameConfig.BASE_MIN_BEES > 0, "BASE_MIN_BEES should be positive")
        TestRunner.assertTrue(GameConfig.BEES_PER_PLAYER >= 0, "BEES_PER_PLAYER should be non-negative")
        return true
    end)
    
    return TestRunner.endSuite()
end

-- Export the test function
local GameConfigTests = {}
GameConfigTests.runTests = runTests

return GameConfigTests 