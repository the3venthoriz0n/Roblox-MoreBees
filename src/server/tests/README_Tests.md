# Simple Test Framework

A basic testing framework for Roblox modules.

## How to Use

### 1. Create Tests for a Module

```lua
-- MyModuleTests.luau
local TestRunner = require(game.ServerScriptService.Server.tests.TestRunner)
local MyModule = require(game.ServerScriptService.Server.MyModule)

local function runTests()
    TestRunner.startSuite("MyModule")
    
    TestRunner.test("My function works", function()
        local result = MyModule.myFunction()
        TestRunner.assertEquals(42, result, "Should return 42")
        return true
    end)
    
    TestRunner.test("My function handles errors", function()
        local result = MyModule.myFunction("invalid")
        TestRunner.assertNil(result, "Should return nil for invalid input")
        return true
    end)
    
    return TestRunner.endSuite()
end

local MyModuleTests = {}
MyModuleTests.runTests = runTests
return MyModuleTests
```

### 2. Run Tests

In your main script:
```lua
local MyModuleTests = require(game.ServerScriptService.Server.tests.MyModuleTests)
MyModuleTests.runTests()
```

## Available Assert Functions

- `TestRunner.assertEquals(expected, actual, message)` - Check if values are equal
- `TestRunner.assertNotNil(value, message)` - Check if value is not nil
- `TestRunner.assertNil(value, message)` - Check if value is nil
- `TestRunner.assertTrue(value, message)` - Check if value is true
- `TestRunner.assertFalse(value, message)` - Check if value is false

## Test Structure

1. `TestRunner.startSuite("SuiteName")` - Start a test suite
2. `TestRunner.test("Test Name", function() ... end)` - Run a test
3. `TestRunner.endSuite()` - End the suite and show results

## Example Output

```
🧪 Starting Test Suite: MyModule
==================================================
✅ PASS: My function works
✅ PASS: My function handles errors
==================================================
📊 Test Results:
✅ Passed: 2
❌ Failed: 0
📈 Total: 2
🎉 All tests passed!
==================================================
``` 