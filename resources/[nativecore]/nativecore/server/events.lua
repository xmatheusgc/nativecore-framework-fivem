--[[
    NativeCore — Server Event Bus
    Internal pub/sub system using FiveM native events under the hood.
    Supports priority, wildcards, error isolation, and net events.
]]

NCEvents = {}

local _handlers  = {}  -- [event] = { {callback, priority, id} }
local _handlerId = 0

--- Register an event handler with optional priority.
--- @param event string event name (without nc: prefix)
--- @param callback function handler function
--- @param priority number? higher = runs first (default 0)
--- @return number handlerId for unregistration
function NCEvents.On(event, callback, priority)
    NCUtils.TypeCheck(event, 'string', 'event')
    NCUtils.TypeCheck(callback, 'function', 'callback')
    priority = priority or 0

    _handlerId = _handlerId + 1
    local id = _handlerId

    if not _handlers[event] then
        _handlers[event] = {}

        -- Register FiveM event handler (one per event name)
        AddEventHandler(NC_EVENT_PREFIX .. event, function(...)
            NCEvents._dispatch(event, ...)
        end)
    end

    local entry = { callback = callback, priority = priority, id = id }
    table.insert(_handlers[event], entry)

    -- Sort by priority descending (highest first)
    table.sort(_handlers[event], function(a, b)
        return a.priority > b.priority
    end)

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

--- Remove a specific handler by ID.
--- @param event string
--- @param handlerId number
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

--- Remove all handlers for an event, or a specific callback.
--- @param event string
--- @param callback function? if nil, removes all handlers for event
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

--- Emit an event locally (server-side only).
--- @param event string
--- @param ... any arguments
function NCEvents.Emit(event, ...)
    TriggerEvent(NC_EVENT_PREFIX .. event, ...)
end

--- Emit an event to a specific client or all clients.
--- @param event string
--- @param target number|number[] player source(s), or -1 for all
--- @param ... any arguments
function NCEvents.EmitNet(event, target, ...)
    TriggerClientEvent(NC_EVENT_PREFIX .. event, target, ...)
end

--- Emit to all clients.
--- @param event string
--- @param ... any arguments
function NCEvents.EmitNetAll(event, ...)
    TriggerClientEvent(NC_EVENT_PREFIX .. event, -1, ...)
end

--- Internal dispatcher with error isolation and wildcard support.
--- @param event string
--- @param ... any
function NCEvents._dispatch(event, ...)
    -- Direct handlers
    local handlers = _handlers[event]
    if handlers then
        for _, entry in ipairs(handlers) do
            local ok, err = NCUtils.SafeCall(entry.callback, ...)
            if not ok then
                NCLogger.Error('events', 'Handler error', {
                    event = event,
                    handlerId = entry.id,
                    error = tostring(err),
                })
            end
        end
    end

    -- Wildcard handlers: 'player:*' matches 'player:loaded', 'player:died'
    for pattern, patternHandlers in pairs(_handlers) do
        if pattern ~= event and string.sub(pattern, -1) == '*' then
            local prefix = string.sub(pattern, 1, -2)  -- remove '*'
            if string.sub(event, 1, #prefix) == prefix then
                for _, entry in ipairs(patternHandlers) do
                    local ok, err = NCUtils.SafeCall(entry.callback, event, ...)
                    if not ok then
                        NCLogger.Error('events', 'Wildcard handler error', {
                            pattern = pattern,
                            event = event,
                            error = tostring(err),
                        })
                    end
                end
            end
        end
    end
end

--- Get registered event count (for diagnostics).
--- @return number
function NCEvents.Count()
    return NCUtils.TableCount(_handlers)
end
