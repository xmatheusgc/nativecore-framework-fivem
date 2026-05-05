--[[
    NativeCore — Client Event Bus
    Client-side pub/sub using FiveM native events.
    Same API pattern as server events for consistency.
]]

NCEvents = NCEvents or {}

local _handlers  = {}
local _handlerId = 0

--- Register an event handler.
--- @param event string
--- @param callback function
--- @param priority number? (default 0)
--- @return number handlerId
function NCEvents.On(event, callback, priority)
    priority = priority or 0
    _handlerId = _handlerId + 1
    local id = _handlerId

    if not _handlers[event] then
        _handlers[event] = {}
        AddEventHandler(NC_EVENT_PREFIX .. event, function(...)
            NCEvents._dispatchClient(event, ...)
        end)
    end

    table.insert(_handlers[event], { callback = callback, priority = priority, id = id })
    table.sort(_handlers[event], function(a, b) return a.priority > b.priority end)

    return id
end

--- Register a one-time event handler.
--- @param event string
--- @param callback function
--- @return number handlerId
function NCEvents.Once(event, callback)
    local id
    id = NCEvents.On(event, function(...)
        NCEvents.OffById(event, id)
        callback(...)
    end)
    return id
end

--- Remove handler by ID.
function NCEvents.OffById(event, handlerId)
    local handlers = _handlers[event]
    if not handlers then return end
    for i = #handlers, 1, -1 do
        if handlers[i].id == handlerId then
            table.remove(handlers, i)
            break
        end
    end
end

--- Remove handlers for an event.
function NCEvents.Off(event, callback)
    if not callback then
        _handlers[event] = nil
        return
    end
    local handlers = _handlers[event]
    if not handlers then return end
    for i = #handlers, 1, -1 do
        if handlers[i].callback == callback then
            table.remove(handlers, i)
        end
    end
end

--- Emit a local client event.
function NCEvents.Emit(event, ...)
    TriggerEvent(NC_EVENT_PREFIX .. event, ...)
end

--- Emit an event to the server.
function NCEvents.EmitNet(event, ...)
    TriggerServerEvent(NC_EVENT_PREFIX .. event, ...)
end

--- Internal dispatcher with error isolation.
function NCEvents._dispatchClient(event, ...)
    local handlers = _handlers[event]
    if not handlers then return end
    for _, entry in ipairs(handlers) do
        local ok, err = NCUtils.SafeCall(entry.callback, ...)
        if not ok then
            NCLogger.Error('events', 'Client handler error', {
                event = event,
                error = tostring(err),
            })
        end
    end
end
