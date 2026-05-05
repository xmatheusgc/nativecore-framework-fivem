--[[
    NativeCore — Player Session Manager (Server)
    Manages connected player sessions with in-memory cache.
    Lifecycle: Connecting → Loading → Loaded → Disconnecting → Removed
]]

NCPlayer = {}

local _players    = {}   -- [source] = playerObj
local _uuidIndex  = {}   -- [uuid] = source (reverse lookup)
local _saveTimer  = nil

-- ============================================================
-- Player Object Factory
-- ============================================================

--- Create a new player object.
--- @param source number
--- @param identity table from NCIdentity.Resolve
--- @return table playerObj
local function createPlayerObject(source, identity)
    return {
        source      = source,
        uuid        = identity.uuid,
        name        = identity.name,
        identifiers = identity.identifiers,
        group       = NCConfig.Get('core.DefaultGroup', 'user'),
        position    = NCConfig.Get('core.DefaultSpawn'),
        metadata    = {},
        state       = NC_PLAYER_STATE.LOADING,
        connectedAt = NCUtils.Timestamp(),
        isNew       = identity.isNew,
    }
end

-- ============================================================
-- Session Management
-- ============================================================

--- Load a player session (called during connection).
--- @param source number
--- @return table|nil playerObj
function NCPlayer.Load(source)
    if _players[source] then
        NCLogger.Warn('player', 'Player already loaded', { source = source })
        return _players[source]
    end

    -- Resolve identity (creates user if new)
    local identity = NCIdentity.Resolve(source)
    if not identity or not identity.uuid then
        NCLogger.Error('player', 'Failed to resolve identity', { source = source })
        return nil
    end

    -- Create player object
    local playerObj = createPlayerObject(source, identity)

    -- Load persisted data from database
    local dbData = NCDB.Single(
        'SELECT `group`, position, metadata FROM nc_users WHERE uuid = ?',
        { identity.uuid }
    )

    if dbData then
        playerObj.group = dbData.group or playerObj.group

        -- Parse position
        if dbData.position then
            local ok, pos = pcall(json.decode, dbData.position)
            if ok and pos then
                playerObj.position = pos
            end
        end

        -- Parse metadata
        if dbData.metadata then
            local ok, meta = pcall(json.decode, dbData.metadata)
            if ok and meta then
                playerObj.metadata = meta
            end
        end
    end

    -- Store in cache
    _players[source] = playerObj
    _uuidIndex[identity.uuid] = source

    -- Set StateBag data for client
    NCState.SetPlayer(source, 'uuid', playerObj.uuid)
    NCState.SetPlayer(source, 'group', playerObj.group)
    NCState.SetPlayer(source, 'loaded', true)

    -- Mark as loaded
    playerObj.state = NC_PLAYER_STATE.LOADED

    NCLogger.Info('player', 'Player loaded', {
        source = source,
        uuid = playerObj.uuid,
        name = playerObj.name,
        isNew = playerObj.isNew,
    })

    -- Emit event for modules
    NCEvents.Emit('player:loaded', source, playerObj)

    return playerObj
end

--- Unload a player session (called on disconnect).
--- @param source number
--- @param reason string? disconnect reason
function NCPlayer.Unload(source, reason)
    local playerObj = _players[source]
    if not playerObj then return end

    playerObj.state = NC_PLAYER_STATE.DISCONNECTING

    -- Emit event before cleanup (modules can save their data)
    NCEvents.Emit('player:disconnecting', source, playerObj, reason)

    -- Save to database
    NCPlayer.Save(source)

    -- Clean up
    _uuidIndex[playerObj.uuid] = nil
    _players[source] = nil

    -- Clean up callback rate limits
    NCCallbacks.CleanupPlayer(source)

    NCLogger.Info('player', 'Player unloaded', {
        source = source,
        uuid = playerObj.uuid,
        reason = reason or 'unknown',
    })

    NCEvents.Emit('player:disconnected', source, playerObj.uuid)
end

-- ============================================================
-- Getters
-- ============================================================

--- Get a player object by source.
--- @param source number
--- @return table|nil playerObj
function NCPlayer.Get(source)
    return _players[source]
end

--- Get a player object by UUID.
--- @param uuid string
--- @return table|nil playerObj
function NCPlayer.GetByUUID(uuid)
    local source = _uuidIndex[uuid]
    if source then return _players[source] end
    return nil
end

--- Get all connected players.
--- @return table<number, table> [source] = playerObj
function NCPlayer.GetAll()
    return _players
end

--- Get connected player count.
--- @return number
function NCPlayer.Count()
    return NCUtils.TableCount(_players)
end

--- Check if a player is loaded.
--- @param source number
--- @return boolean
function NCPlayer.IsLoaded(source)
    local p = _players[source]
    return p ~= nil and p.state == NC_PLAYER_STATE.LOADED
end

-- ============================================================
-- Data Management
-- ============================================================

--- Set a custom data field on a player.
--- @param source number
--- @param key string
--- @param value any
--- @return boolean success
function NCPlayer.SetData(source, key, value)
    local p = _players[source]
    if not p then return false end
    p.metadata[key] = value
    return true
end

--- Get a custom data field from a player.
--- @param source number
--- @param key string
--- @return any
function NCPlayer.GetData(source, key)
    local p = _players[source]
    if not p then return nil end
    if key then return p.metadata[key] end
    return p.metadata
end

--- Set the player's group.
--- @param source number
--- @param group string
--- @return boolean
function NCPlayer.SetGroup(source, group)
    local p = _players[source]
    if not p then return false end
    p.group = group
    NCState.SetPlayer(source, 'group', group)
    NCEvents.Emit('player:groupChanged', source, group)
    return true
end

--- Update player position in cache.
--- @param source number
--- @param position table { x, y, z, heading }
function NCPlayer.SetPosition(source, position)
    local p = _players[source]
    if not p then return end
    p.position = position
end

-- ============================================================
-- Persistence
-- ============================================================

--- Save a player's data to the database.
--- @param source number
--- @return boolean success
function NCPlayer.Save(source)
    local p = _players[source]
    if not p then return false end

    local positionJson = json.encode(p.position or {})
    local metadataJson = json.encode(p.metadata or {})

    NCDB.Update(
        'UPDATE nc_users SET `group` = ?, position = ?, metadata = ?, updated_at = CURRENT_TIMESTAMP WHERE uuid = ?',
        { p.group, positionJson, metadataJson, p.uuid }
    )

    NCLogger.Debug('player', 'Player saved', { source = source, uuid = p.uuid })
    return true
end

--- Save all connected players (batch save for auto-save).
--- @return number count of players saved
function NCPlayer.SaveAll()
    local count = 0
    for source, _ in pairs(_players) do
        if NCPlayer.Save(source) then
            count = count + 1
        end
    end
    NCLogger.Debug('player', 'Batch save completed', { count = count })
    return count
end

--- Start the auto-save timer.
function NCPlayer.StartAutoSave()
    local interval = NCConfig.Get('core.AutoSaveInterval', 300) * 1000

    if _saveTimer then return end

    _saveTimer = true
    Citizen.CreateThread(function()
        while _saveTimer do
            Citizen.Wait(interval)
            if NCPlayer.Count() > 0 then
                NCPlayer.SaveAll()
            end
        end
    end)

    NCLogger.Info('player', 'Auto-save started', {
        intervalSec = interval / 1000,
    })
end

--- Stop the auto-save timer.
function NCPlayer.StopAutoSave()
    _saveTimer = nil
end
