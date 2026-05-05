--[[
    NativeCore — Client Callbacks
    Client-side of the RPC system. Sends requests to server callbacks.
    Supports both callback-style and await-style invocation.
]]

NCCallbacks = NCCallbacks or {}

local _pending   = {}  -- [requestId] = callback
local _requestId = 0

--- Trigger a server callback with a response handler.
--- @param name string callback name
--- @param cb function(result, error?)
--- @param ... any arguments to pass to server handler
function NCCallbacks.Trigger(name, cb, ...)
    _requestId = _requestId + 1
    local id = _requestId

    _pending[id] = {
        callback = cb,
        time     = GetGameTimer(),
    }

    TriggerServerEvent(NC_CALLBACK_PREFIX .. 'request', name, id, ...)

    -- Auto-cleanup after timeout
    local timeout = NCConfig.Get('core.MaxCallbackTimeout', 10000)
    Citizen.SetTimeout(timeout, function()
        if _pending[id] then
            NCLogger.Warn('callbacks', 'Callback timed out', { name = name, id = id })
            local entry = _pending[id]
            _pending[id] = nil
            if entry.callback then
                entry.callback(nil, 'timeout')
            end
        end
    end)
end

--- Trigger a server callback and await the result (coroutine-based).
--- @param name string callback name
--- @param ... any arguments
--- @return any result, string? error
function NCCallbacks.Await(name, ...)
    local p = promise.new()

    NCCallbacks.Trigger(name, function(result, err)
        if err then
            p:reject(err)
        else
            p:resolve(result)
        end
    end, ...)

    return Citizen.Await(p)
end

-- Response handler from server
RegisterNetEvent(NC_CALLBACK_RESPONSE)
AddEventHandler(NC_CALLBACK_RESPONSE, function(requestId, result, err)
    local entry = _pending[requestId]
    if not entry then return end

    _pending[requestId] = nil

    if entry.callback then
        local ok, callErr = NCUtils.SafeCall(entry.callback, result, err)
        if not ok then
            NCLogger.Error('callbacks', 'Callback response handler error', {
                requestId = requestId,
                error = tostring(callErr),
            })
        end
    end
end)
