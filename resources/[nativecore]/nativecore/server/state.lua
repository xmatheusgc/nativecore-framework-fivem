--[[
    NativeCore — Unified State Manager (Server)
    Combines FiveM StateBags (network-replicated) with in-memory Lua store.
    StateBag keys are namespaced with 'nc:' to avoid collisions.
]]

NCState = {}
NCState.Memory = {}

local _memoryStore = {}  -- [scope] = { [key] = value }

-- ============================================================
-- StateBag Layer (network-replicated)
-- ============================================================

--- Set a global state value (replicated to all clients).
--- @param key string
--- @param value any (must be serializable)
function NCState.SetGlobal(key, value)
    GlobalState[NC_STATE_PREFIX .. key] = value
end

--- Get a global state value.
--- @param key string
--- @return any
function NCState.GetGlobal(key)
    return GlobalState[NC_STATE_PREFIX .. key]
end

--- Set a player state value (replicated to the player's client).
--- @param source number player source
--- @param key string
--- @param value any
function NCState.SetPlayer(source, key, value)
    local player = Player(source)
    if player then
        player.state:set(NC_STATE_PREFIX .. key, value, true)
    end
end

--- Get a player state value.
--- @param source number
--- @param key string
--- @return any
function NCState.GetPlayer(source, key)
    local player = Player(source)
    if player then
        return player.state[NC_STATE_PREFIX .. key]
    end
    return nil
end

--- Set an entity state value.
--- @param entity number entity handle
--- @param key string
--- @param value any
function NCState.SetEntity(entity, key, value)
    local ent = Entity(entity)
    if ent then
        ent.state:set(NC_STATE_PREFIX .. key, value, true)
    end
end

--- Get an entity state value.
--- @param entity number
--- @param key string
--- @return any
function NCState.GetEntity(entity, key)
    local ent = Entity(entity)
    if ent then
        return ent.state[NC_STATE_PREFIX .. key]
    end
    return nil
end

--- Register a StateBag change handler with error isolation.
--- @param bagFilter string? filter for bag name (nil = all bags)
--- @param keyFilter string state key to watch (with or without nc: prefix)
--- @param handler function(bagName, key, value, reserved, replicated)
--- @return number handlerId
function NCState.OnChange(bagFilter, keyFilter, handler)
    -- Auto-prefix key if not already prefixed
    local watchKey = keyFilter
    if not string.find(keyFilter, '^' .. NC_STATE_PREFIX) then
        watchKey = NC_STATE_PREFIX .. keyFilter
    end

    return AddStateBagChangeHandler(watchKey, bagFilter, function(bagName, key, value, reserved, replicated)
        local ok, err = NCUtils.SafeCall(handler, bagName, key, value, reserved, replicated)
        if not ok then
            NCLogger.Error('state', 'StateBag handler error', {
                bag = bagName,
                key = key,
                error = tostring(err),
            })
        end
    end)
end

-- ============================================================
-- Memory Layer (server-only, fast, not replicated)
-- ============================================================

--- Set a value in the memory store.
--- @param scope string namespace/scope name
--- @param key string
--- @param value any
function NCState.Memory.Set(scope, key, value)
    if not _memoryStore[scope] then
        _memoryStore[scope] = {}
    end
    _memoryStore[scope][key] = value
end

--- Get a value from the memory store.
--- @param scope string
--- @param key string
--- @return any
function NCState.Memory.Get(scope, key)
    if not _memoryStore[scope] then return nil end
    return _memoryStore[scope][key]
end

--- Delete a value from the memory store.
--- @param scope string
--- @param key string
function NCState.Memory.Delete(scope, key)
    if _memoryStore[scope] then
        _memoryStore[scope][key] = nil
    end
end

--- Get all values in a scope (returns a copy).
--- @param scope string
--- @return table
function NCState.Memory.GetAll(scope)
    if not _memoryStore[scope] then return {} end
    return NCUtils.DeepCopy(_memoryStore[scope])
end

--- Clear an entire scope.
--- @param scope string
function NCState.Memory.Clear(scope)
    _memoryStore[scope] = nil
end

--- Check if a scope exists.
--- @param scope string
--- @return boolean
function NCState.Memory.HasScope(scope)
    return _memoryStore[scope] ~= nil
end
