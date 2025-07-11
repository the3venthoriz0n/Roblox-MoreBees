local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local Logger = {}

-- Log levels in order of severity
local LOG_LEVELS = {
    debug = 1,
    info = 2,
    warn = 3,
    error = 4
}

-- Get current log level
local function getCurrentLogLevel()
    return LOG_LEVELS[GameConfig.LOG_LEVEL] or LOG_LEVELS.warn
end

-- Check if a log level should be printed
local function shouldLog(level)
    return LOG_LEVELS[level] >= getCurrentLogLevel()
end

-- Debug logging function
function Logger.debug(...)
    if shouldLog("debug") then
        print("[DEBUG]", ...)
    end
end

-- Info logging function
function Logger.info(...)
    if shouldLog("info") then
        print("[INFO]", ...)
    end
end

-- Warning logging function
function Logger.warn(...)
    if shouldLog("warn") then
        print("[WARN]", ...)
    end
end

-- Error logging function
function Logger.error(...)
    if shouldLog("error") then
        print("[ERROR]", ...)
    end
end

-- Legacy debug function for backward compatibility
function Logger.debugPrint(...)
    Logger.debug(...)
end

return Logger 