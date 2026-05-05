--[[
    NativeCore — Identity Resolver (Server)
    Resolves FiveM identifiers to internal UUIDs.
    Manages the nc_users + nc_identifiers tables.
]]

NCIdentity = {}

--- Extract all identifiers from a player source.
--- @param source number
--- @return table identifiers { type = value, ... }
function NCIdentity.GetIdentifiers(source)
    local identifiers = {}
    local numIds = GetNumPlayerIdentifiers(source)

    for i = 0, numIds - 1 do
        local id = GetPlayerIdentifier(source, i)
        if id then
            local idType, idValue = string.match(id, '([^:]+):(.+)')
            if idType and idValue then
                identifiers[idType] = idValue
            end
        end
    end

    -- Also get player name
    identifiers._name = GetPlayerName(source) or 'Unknown'

    return identifiers
end

--- Find a UUID by a specific identifier.
--- @param idType string e.g. 'license', 'steam'
--- @param idValue string
--- @return string|nil uuid
function NCIdentity.FindByIdentifier(idType, idValue)
    return NCDB.Scalar(
        'SELECT uuid FROM nc_identifiers WHERE type = ? AND value = ?',
        { idType, idValue }
    )
end

--- Link an identifier to a UUID.
--- @param uuid string
--- @param idType string
--- @param idValue string
--- @return boolean success
function NCIdentity.LinkIdentifier(uuid, idType, idValue)
    local existing = NCDB.Scalar(
        'SELECT uuid FROM nc_identifiers WHERE type = ? AND value = ?',
        { idType, idValue }
    )

    if existing then
        if existing == uuid then return true end
        NCLogger.Warn('identity', 'Identifier already linked to different UUID', {
            type = idType,
            existingUUID = existing,
            requestedUUID = uuid,
        })
        return false
    end

    NCDB.Insert(
        'INSERT INTO nc_identifiers (uuid, type, value) VALUES (?, ?, ?)',
        { uuid, idType, idValue }
    )
    return true
end

--- Resolve a player source to a UUID. Creates a new user if not found.
--- @param source number
--- @return table { uuid = string, identifiers = table, isNew = boolean, name = string }
function NCIdentity.Resolve(source)
    local identifiers = NCIdentity.GetIdentifiers(source)
    local priority = NCConfig.Get('core.IdentityPriority', { 'license', 'fivem', 'steam', 'discord' })
    local name = identifiers._name

    -- Try to find existing UUID by priority order
    local uuid = nil
    for _, idType in ipairs(priority) do
        local idValue = identifiers[idType]
        if idValue then
            uuid = NCIdentity.FindByIdentifier(idType, idValue)
            if uuid then
                NCLogger.Debug('identity', 'UUID resolved', {
                    source = source,
                    via = idType,
                    uuid = uuid,
                })
                break
            end
        end
    end

    local isNew = false

    if not uuid then
        -- Generate new UUID and create user
        uuid = NCUtils.UUID()
        isNew = true

        NCDB.Execute(
            'INSERT INTO nc_users (uuid, name) VALUES (?, ?)',
            { uuid, name }
        )

        NCLogger.Info('identity', 'New user created', {
            source = source,
            uuid = uuid,
            name = name,
        })
    else
        -- Update last seen and name
        NCDB.Execute(
            'UPDATE nc_users SET last_seen = CURRENT_TIMESTAMP, name = ? WHERE uuid = ?',
            { name, uuid }
        )
    end

    -- Link all current identifiers to this UUID
    for idType, idValue in pairs(identifiers) do
        if idType ~= '_name' then
            NCIdentity.LinkIdentifier(uuid, idType, idValue)
        end
    end

    return {
        uuid = uuid,
        identifiers = identifiers,
        isNew = isNew,
        name = name,
    }
end

--- Get all identifiers linked to a UUID.
--- @param uuid string
--- @return table identifiers { { type, value }, ... }
function NCIdentity.GetLinkedIdentifiers(uuid)
    return NCDB.Query(
        'SELECT type, value FROM nc_identifiers WHERE uuid = ?',
        { uuid }
    )
end
