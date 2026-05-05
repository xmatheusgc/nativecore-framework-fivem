--[[
    NativeCore — Client State Manager
    Read-only access to StateBags + local memory store.
    Server is authoritative for StateBag writes.
]]

NCState = NCState or {}
NCState.Memory = NCState.Memory or {}

local _memoryStore = {}

-- ============================================================
-- StateBag Layer (read from server-replicated state)
-- ============================================================

--- Get a global state value.
--- @param key string
--- @return any
function NCState.GetGlobal(key)
    return GlobalState[NC_STATE_PREFIX .. key]
end

--- Get local player state value.
--- @param key string
--- @return any
function NCState.GetPlayer(key)
    return LocalPlayer.state[NC_STATE_PREFIX .. key]
end

--- Get an entity state value.
--- @param entity number entity handle
--- @param key string
--- @return any
function NCState.GetEntity(entity, key)
    local ent = Entity(entity)
    if ent then
        return ent.state[NC_STATE_PREFIX .. key]
    end
    return nil
end

--- Register a StateBag change handler.
--- @param bagFilter string?
--- @param keyFilter string
--- @param handler function
--- @return number handlerId
function NCState.OnChange(bagFilter, keyFilter, handler)
    local watchKey = keyFilter
    if not string.find(keyFilter, '^' .. NC_STATE_PREFIX) then
        watchKey = NC_STATE_PREFIX .. keyFilter
    end

    return AddStateBagChangeHandler(watchKey, bagFilter, function(bagName, key, value, reserved, replicated)
        local ok, err = NCUtils.SafeCall(handler, bagName, key, value, reserved, replicated)
        if not ok then
            NCLogger.Error('state', 'Client StateBag handler error', {
                key = key,
                error = tostring(err),
            })
        end
    end)
end

-- ============================================================
-- Memory Layer (client-local, fast)
-- ============================================================

function NCState.Memory.Set(scope, key, value)
    if not _memoryStore[scope] then _memoryStore[scope] = {} end
    _memoryStore[scope][key] = value
end

function NCState.Memory.Get(scope, key)
    if not _memoryStore[scope] then return nil end
    return _memoryStore[scope][key]
end

function NCState.Memory.Delete(scope, key)
    if _memoryStore[scope] then _memoryStore[scope][key] = nil end
end

function NCState.Memory.GetAll(scope)
    if not _memoryStore[scope] then return {} end
    return NCUtils.DeepCopy(_memoryStore[scope])
end

function NCState.Memory.Clear(scope)
    _memoryStore[scope] = nil
end
