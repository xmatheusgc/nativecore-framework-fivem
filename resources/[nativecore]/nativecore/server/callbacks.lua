--[[
    NativeCore — Server Callbacks (Server)
    RPC system for client→server requests with rate limiting and timeouts.
]]

NCCallbacks = {}

local _registered = {}  -- [name] = { handler, owner }
local _rateLimits = {}  -- [source] = { count, lastReset }

--- Register a new server callback.
--- @param name string
--- @param handler function|string
function NCCallbacks.Register(name, handler)
    NCUtils.TypeCheck(name, 'string', 'name')
    
    local owner = GetInvokingResource() or GetCurrentResourceName()
    
    _registered[name] = {
        handler = handler,
        owner   = owner
    }
    
    NCLogger.Debug('callbacks', 'Callback registered', { name = name, owner = owner })
end

--- Unregister a callback.
function NCCallbacks.Unregister(name)
    _registered[name] = nil
end

-- Event handler for cross-resource registration (backward compatibility)
AddEventHandler(NC_EVENT_PREFIX .. 'callbacks:register', function(name)
    NCCallbacks.Register(name, 'bridge')
end)

--- Check if a callback is registered.
function NCCallbacks.Has(name)
    return _registered[name] ~= nil
end

--- Execute a registered callback.
--- Internal use only (called by net event).
function NCCallbacks.Execute(name, requestId, source, ...)
    local cb = _registered[name]
    if not cb then
        TriggerClientEvent(NC_CALLBACK_RESPONSE, source, requestId, nil, 'not_found')
        return
    end

    if type(cb.handler) == 'function' then
        local ok, result = NCUtils.SafeCall(cb.handler, source, ...)
        if ok then
            TriggerClientEvent(NC_CALLBACK_RESPONSE, source, requestId, result)
        else
            TriggerClientEvent(NC_CALLBACK_RESPONSE, source, requestId, nil, tostring(result))
        end
    else
        -- If it's a bridge callback, trigger event to the owner resource
        TriggerEvent(NC_EVENT_PREFIX .. 'cb:exec:' .. name, requestId, source, ...)
    end
end

--- Rate limit check for a source.
--- @param src number player source
--- @return boolean allowed
local function checkRateLimit(src)
    local maxRate = NCConfig.Get('core.CallbackRateLimit', 20)
    local now = GetGameTimer()

    if not _rateLimits[src] then
        _rateLimits[src] = { count = 0, lastReset = now }
    end

    local rl = _rateLimits[src]
    if now - rl.lastReset > 1000 then
        rl.count = 0
        rl.lastReset = now
    end

    rl.count = rl.count + 1
    return rl.count <= maxRate
end

--- Clean up rate limit data for a disconnected player.
--- @param src number
function NCCallbacks.CleanupPlayer(src)
    _rateLimits[src] = nil
end

-- Net event handler: client requests a callback
RegisterNetEvent(NC_CALLBACK_PREFIX .. 'request')
AddEventHandler(NC_CALLBACK_PREFIX .. 'request', function(name, requestId, ...)
    local src = source

    -- Rate limit check
    if not checkRateLimit(src) then
        NCLogger.Warn('callbacks', 'Rate limited', { source = src, callback = name })
        TriggerClientEvent(NC_CALLBACK_RESPONSE, src, requestId, nil, 'rate_limited')
        return
    end

    NCCallbacks.Execute(name, requestId, src, ...)
end)
