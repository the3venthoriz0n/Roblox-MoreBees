local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEventsManager = {}

-- Store all remote events for easy access
local remoteEvents = {}

-- Create all remote events
function RemoteEventsManager.createRemoteEvents()
    -- Bee spawning event
    local spawnCubeEvent = Instance.new("RemoteEvent")
    spawnCubeEvent.Name = "SpawnCube"
    spawnCubeEvent.Parent = ReplicatedStorage
    remoteEvents.SpawnCube = spawnCubeEvent

    -- Player respawn request event
    local requestRespawnEvent = Instance.new("RemoteEvent")
    requestRespawnEvent.Name = "RequestRespawnEvent"
    requestRespawnEvent.Parent = ReplicatedStorage
    remoteEvents.RequestRespawn = requestRespawnEvent

    -- Power-up shop interaction event
    local shopEvent = Instance.new("RemoteEvent")
    shopEvent.Name = "PowerUpShopEvent"
    shopEvent.Parent = ReplicatedStorage
    remoteEvents.PowerUpShop = shopEvent

    -- Purchase feedback event
    local purchaseFeedbackEvent = Instance.new("RemoteEvent")
    purchaseFeedbackEvent.Name = "PurchaseFeedbackEvent"
    purchaseFeedbackEvent.Parent = ReplicatedStorage
    remoteEvents.PurchaseFeedback = purchaseFeedbackEvent

    -- Power-up active event
    local PowerUpActiveEvent = Instance.new("RemoteEvent")
    PowerUpActiveEvent.Name = "PowerUpActiveEvent"
    PowerUpActiveEvent.Parent = ReplicatedStorage
    remoteEvents.PowerUpActive = PowerUpActiveEvent

    -- Power-up ended event
    local PowerUpEndedEvent = Instance.new("RemoteEvent")
    PowerUpEndedEvent.Name = "PowerUpEndedEvent"
    PowerUpEndedEvent.Parent = ReplicatedStorage
    remoteEvents.PowerUpEnded = PowerUpEndedEvent

    -- Shop visibility toggle event
    local toggleShopEvent = Instance.new("RemoteEvent")
    toggleShopEvent.Name = "ToggleShopEvent"
    toggleShopEvent.Parent = ReplicatedStorage
    remoteEvents.ToggleShop = toggleShopEvent

    print("RemoteEventsManager: All remote events created successfully")
end

-- Get a specific remote event by name
function RemoteEventsManager.getRemoteEvent(eventName)
    return remoteEvents[eventName]
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