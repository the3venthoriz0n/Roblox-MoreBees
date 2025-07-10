local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEventsManager = {}

-- Store all remote events for easy access
local remoteEvents = {}

local function logDebug(...)
    print("[DEBUG][RemoteEventsManager]", ...)
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

    -- Bee spawning event
    remoteEvents.SpawnCube = createOrGetEvent("SpawnCube")
    -- Player respawn request event
    remoteEvents.RequestRespawn = createOrGetEvent("RequestRespawnEvent")
    -- Power-up shop interaction event
    remoteEvents.PowerUpShop = createOrGetEvent("PowerUpShopEvent")
    -- Purchase feedback event
    remoteEvents.PurchaseFeedback = createOrGetEvent("PurchaseFeedbackEvent")
    -- Power-up active event
    remoteEvents.PowerUpActive = createOrGetEvent("PowerUpActiveEvent")
    -- Power-up ended event
    remoteEvents.PowerUpEnded = createOrGetEvent("PowerUpEndedEvent")
    -- Shop visibility toggle event
    remoteEvents.ToggleShop = createOrGetEvent("ToggleShopEvent")
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
end

-- Get a specific remote event by name
function RemoteEventsManager.getRemoteEvent(key)
    local event = remoteEvents[key]
    if event then
        logDebug("getRemoteEvent:", key, "->", event.Name)
    else
        logDebug("getRemoteEvent: No event found for key:", key)
    end
    return event
end

-- Get all remote events
function RemoteEventsManager.getAllRemoteEvents()
    return remoteEvents
end

-- Fire a remote event to a specific client
function RemoteEventsManager.fireToClient(eventName, player, ...)
    local event = remoteEvents[eventName]
    if event and player then
        event:FireClient(player, ...)
    else
        warn("RemoteEventsManager: Invalid event name or player for fireToClient:", eventName)
    end
end

-- Fire a remote event to all clients
function RemoteEventsManager.fireToAllClients(eventName, ...)
    local event = remoteEvents[eventName]
    if event then
        event:FireAllClients(...)
    else
        warn("RemoteEventsManager: Invalid event name for fireToAllClients:", eventName)
    end
end

-- Connect a function to a remote event
function RemoteEventsManager.connectToEvent(eventName, callback)
    local event = remoteEvents[eventName]
    if event then
        return event.OnServerEvent:Connect(callback)
    else
        warn("RemoteEventsManager: Invalid event name for connectToEvent:", eventName)
        return nil
    end
end

return RemoteEventsManager