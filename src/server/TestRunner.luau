-- Simple Test Runner
-- A basic testing framework for any module

local TestRunner = {}

local testsPassed = 0
local testsFailed = 0

-- Simple test function
function TestRunner.test(name, testFunction)
    local success, result = pcall(testFunction)
    if success and result then
        print("✅ PASS:", name)
        testsPassed = testsPassed + 1
    else
        print("❌ FAIL:", name)
        if not success then
            print("   Error:", result)
        end
        testsFailed = testsFailed + 1
    end
end

-- Assert functions
function TestRunner.assertEquals(expected, actual, message)
    if expected == actual then
        return true
    else
        error(message or ("Expected " .. tostring(expected) .. " but got " .. tostring(actual)))
    end
end

function TestRunner.assertNotNil(value, message)
    if value ~= nil then
        return true
    else
        error(message or "Expected non-nil value")
    end
end

function TestRunner.assertNil(value, message)
    if value == nil then
        return true
    else
        error(message or "Expected nil value")
    end
end

function TestRunner.assertTrue(value, message)
    if value == true then
        return true
    else
        error(message or "Expected true")
    end
end

function TestRunner.assertFalse(value, message)
    if value == false then
        return true
    else
        error(message or "Expected false")
    end
end

-- Start a test suite
function TestRunner.startSuite(suiteName)
    print("\n🧪 Starting Test Suite:", suiteName)
    print(string.rep("=", 50))
    testsPassed = 0
    testsFailed = 0
end

-- End a test suite and show results
function TestRunner.endSuite()
    print(string.rep("=", 50))
    print("📊 Test Results:")
    print("✅ Passed:", testsPassed)
    print("❌ Failed:", testsFailed)
    print("📈 Total:", testsPassed + testsFailed)
    
    if testsFailed == 0 then
        print("🎉 All tests passed!")
    else
        print("⚠️  Some tests failed!")
    end
    print(string.rep("=", 50))
    
    return testsFailed == 0
end

return TestRunner 