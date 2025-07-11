local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Logger = require(script.Parent.Logger)

local RemoteEventsManager = {}

local function logDebug(...)
    Logger.debug("[RemoteEventsManager]", ...)
end

-- Create all remote events
function RemoteEventsManager.createRemoteEvents()
    -- Helper to create or get existing event
    local function createOrGetEvent(eventName)
        local existing = ReplicatedStorage:FindFirstChild(eventName)
        if existing then
            logDebug("Event already exists:", eventName)
            return existing
        else
            local event = Instance.new("RemoteEvent")
            event.Name = eventName
            event.Parent = ReplicatedStorage
            logDebug("Created event:", eventName)
            return event
        end
    end

    createOrGetEvent("SpawnCube")
    createOrGetEvent("RequestRespawnEvent")
    createOrGetEvent("PowerUpShopEvent")
    createOrGetEvent("PurchaseFeedbackEvent")
    createOrGetEvent("PowerUpActiveEvent")
    createOrGetEvent("PowerUpEndedEvent")
    
    -- Bindable event for bee spawning
    local bindable = ReplicatedStorage:FindFirstChild("SpawnBeesRequestEvent")
    if not bindable then
        bindable = Instance.new("BindableEvent")
        bindable.Name = "SpawnBeesRequestEvent"
        bindable.Parent = ReplicatedStorage
        logDebug("Created bindable event: SpawnBeesRequestEvent")
    else
        logDebug("Bindable event already exists: SpawnBeesRequestEvent")
    end
    
    -- Add HoneyDripPickupEvent for client-side pickup sound
    createOrGetEvent("HoneyDripPickupEvent")
end

-- Get a specific remote event by name
function RemoteEventsManager.getRemoteEvent(eventName)
    local event = ReplicatedStorage:FindFirstChild(eventName)
    if event then
        logDebug("getRemoteEvent:", eventName, "->", event.Name)
    else
        logDebug("getRemoteEvent: No event found for name:", eventName)
    end
    return event
end

-- Fire a remote event to a specific client
function RemoteEventsManager.fireToClient(eventName, player, ...)
    local event = ReplicatedStorage:FindFirstChild(eventName .. "Event") or ReplicatedStorage:FindFirstChild(eventName)
    if event and player then
        event:FireClient(player, ...)
    else
        warn("RemoteEventsManager: Invalid event name or player for fireToClient:", eventName)
    end
end

-- Fire a remote event to all clients
function RemoteEventsManager.fireToAllClients(eventName, ...)
    local event = ReplicatedStorage:FindFirstChild(eventName .. "Event") or ReplicatedStorage:FindFirstChild(eventName)
    if event then
        event:FireAllClients(...)
    else
        warn("RemoteEventsManager: Invalid event name for fireToAllClients:", eventName)
    end
end

-- Connect a function to a remote event
function RemoteEventsManager.connectToEvent(eventName, callback)
    local event = ReplicatedStorage:FindFirstChild(eventName .. "Event") or ReplicatedStorage:FindFirstChild(eventName)
    if event then
        return event.OnServerEvent:Connect(callback)
    else
        warn("RemoteEventsManager: Invalid event name for connectToEvent:", eventName)
        return nil
    end
end

function RemoteEventsManager.firePowerUpEnded(character, powerUpName)
    local Players = game:GetService("Players")
    local player = Players:GetPlayerFromCharacter(character)
    if player then
        RemoteEventsManager.fireToClient("PowerUpEnded", player, powerUpName)
    end
end

return RemoteEventsManager