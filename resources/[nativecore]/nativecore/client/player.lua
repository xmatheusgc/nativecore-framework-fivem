--[[
    NativeCore — Client Player Data
    Local cache of player data synced from server via StateBags.
]]

NCPlayer = NCPlayer or {}

local _playerData = nil
local _loaded     = false

--- Check if local player data is loaded.
--- @return boolean
function NCPlayer.IsLoaded()
    return _loaded
end

--- Get the local player UUID.
--- @return string|nil
function NCPlayer.GetUUID()
    return NCState.GetPlayer('uuid')
end

--- Get the local player group.
--- @return string
function NCPlayer.GetGroup()
    return NCState.GetPlayer('group') or 'user'
end

--- Get cached player data.
--- @param key string? specific key, or nil for all data
--- @return any
function NCPlayer.GetData(key)
    if not _playerData then return nil end
    if key then return _playerData[key] end
    return _playerData
end

--- Set local cache data (not persisted, use callbacks to update server).
--- @param key string
--- @param value any
function NCPlayer.SetLocalData(key, value)
    if not _playerData then _playerData = {} end
    _playerData[key] = value
end

--- Wait for player to be loaded (coroutine-based).
--- @param timeout number? milliseconds (default 30000)
--- @return boolean loaded
function NCPlayer.WaitForLoad(timeout)
    if _loaded then return true end

    timeout = timeout or 30000
    local start = GetGameTimer()

    while not _loaded do
        if GetGameTimer() - start > timeout then
            NCLogger.Warn('player', 'Client player load timed out')
            return false
        end
        Citizen.Wait(100)
    end

    return true
end

-- Listen for the loaded StateBag change
NCState.OnChange(nil, 'loaded', function(bagName, key, value)
    -- Only react to our own player's state
    if bagName == ('player:%d'):format(GetPlayerServerId(PlayerId())) then
        if value == true then
            _loaded = true
            NCLogger.Debug('player', 'Client player marked as loaded')
            NCEvents.Emit('player:loaded')
        end
    end
end)
