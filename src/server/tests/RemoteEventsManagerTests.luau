-- RemoteEventsManager Tests
-- Tests for the RemoteEventsManager module

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestRunner = require(game.ServerScriptService.Server.tests.TestRunner)
local RemoteEventsManager = require(game.ServerScriptService.Server.RemoteEventsManager)

local function runTests()
    TestRunner.startSuite("RemoteEventsManager")
    
    -- Test 1: Create remote events
    TestRunner.test("Create remote events", function()
        RemoteEventsManager.createRemoteEvents()
        local allEvents = RemoteEventsManager.getAllRemoteEvents()
        TestRunner.assertNotNil(allEvents, "getAllRemoteEvents should return a table")
        return true
    end)
    
    -- Test 2: Check if all expected events exist
    TestRunner.test("All expected events exist", function()
        local expectedEvents = {
            "SpawnCube",
            "RequestRespawn", 
            "PowerUpShop",
            "PurchaseFeedback",
            "PowerUpActive",
            "PowerUpEnded",
            "ToggleShop"
        }
        
        for _, eventName in ipairs(expectedEvents) do
            local event = RemoteEventsManager.getRemoteEvent(eventName)
            TestRunner.assertNotNil(event, "Event " .. eventName .. " should exist")
        end
        return true
    end)
    
    -- Test 3: Invalid event returns nil
    TestRunner.test("Invalid event returns nil", function()
        local invalidEvent = RemoteEventsManager.getRemoteEvent("NonExistentEvent")
        TestRunner.assertNil(invalidEvent, "Invalid event should return nil")
        return true
    end)
    
    -- Test 4: Events are proper RemoteEvent instances
    TestRunner.test("Events are RemoteEvent instances", function()
        local testEvent = RemoteEventsManager.getRemoteEvent("SpawnCube")
        TestRunner.assertTrue(testEvent:IsA("RemoteEvent"), "Event should be a RemoteEvent")
        return true
    end)
    
    -- Test 5: Events are parented to ReplicatedStorage
    TestRunner.test("Events are parented to ReplicatedStorage", function()
        local testEvent = RemoteEventsManager.getRemoteEvent("SpawnCube")
        TestRunner.assertEquals(ReplicatedStorage, testEvent.Parent, "Event should be parented to ReplicatedStorage")
        return true
    end)
    
    -- Test 6: connectToEvent works with valid event
    TestRunner.test("connectToEvent works with valid event", function()
        local connection = RemoteEventsManager.connectToEvent("SpawnCube", function() end)
        TestRunner.assertNotNil(connection, "connectToEvent should return a connection")
        connection:Disconnect() -- Clean up
        return true
    end)
    
    -- Test 7: connectToEvent returns nil for invalid event
    TestRunner.test("connectToEvent returns nil for invalid event", function()
        local connection = RemoteEventsManager.connectToEvent("NonExistentEvent", function() end)
        TestRunner.assertNil(connection, "connectToEvent should return nil for invalid event")
        return true
    end)
    
    return TestRunner.endSuite()
end

-- Export the test function
local RemoteEventsManagerTests = {}
RemoteEventsManagerTests.runTests = runTests

return RemoteEventsManagerTests 