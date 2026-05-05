--[[
    NativeCore — Database Adapter Layer (Server)
    Wraps oxmysql with a clean API. Adapter pattern for future driver swaps.
]]

NCDB = {}

local _adapter = nil
local _ready   = false

--- Initialize the database adapter.
--- @return boolean success
function NCDB.Init()
    local adapterName = NCConfig.Get('database.Adapter', 'oxmysql')

    if adapterName == 'oxmysql' then
        if GetResourceState('oxmysql') ~= 'started' then
            NCLogger.Error('db', 'oxmysql is not started')
            return false
        end

        -- Wait for oxmysql to be ready
        if MySQL and MySQL.ready then
            MySQL.ready.await()
        end

        _adapter = 'oxmysql'
        _ready = true
        NCLogger.Info('db', 'Database adapter initialized', { adapter = _adapter })
        return true
    end

    NCLogger.Error('db', 'Unknown database adapter', { adapter = adapterName })
    return false
end

--- Check if the database is ready.
--- @return boolean
function NCDB.Ready()
    return _ready
end

--- Execute a SELECT query returning multiple rows.
--- @param query string SQL query with ? placeholders
--- @param params table? parameter values
--- @return table rows
function NCDB.Query(query, params)
    if not _ready then
        NCLogger.Error('db', 'Database not ready')
        return {}
    end
    return MySQL.query.await(query, params or {}) or {}
end

--- Execute a SELECT query returning a single row.
--- @param query string
--- @param params table?
--- @return table|nil row
function NCDB.Single(query, params)
    if not _ready then
        NCLogger.Error('db', 'Database not ready')
        return nil
    end
    return MySQL.single.await(query, params or {})
end

--- Execute a SELECT query returning a single scalar value.
--- @param query string
--- @param params table?
--- @return any|nil value
function NCDB.Scalar(query, params)
    if not _ready then
        NCLogger.Error('db', 'Database not ready')
        return nil
    end
    return MySQL.scalar.await(query, params or {})
end

--- Execute an INSERT query returning the last insert ID.
--- @param query string
--- @param params table?
--- @return number|nil insertId
function NCDB.Insert(query, params)
    if not _ready then
        NCLogger.Error('db', 'Database not ready')
        return nil
    end
    return MySQL.insert.await(query, params or {})
end

--- Execute an UPDATE/DELETE query returning affected row count.
--- @param query string
--- @param params table?
--- @return number affectedRows
function NCDB.Update(query, params)
    if not _ready then
        NCLogger.Error('db', 'Database not ready')
        return 0
    end
    return MySQL.update.await(query, params or {}) or 0
end

--- Execute a raw query (for DDL, etc.).
--- @param query string
--- @param params table?
--- @return any result
function NCDB.Execute(query, params)
    if not _ready then
        NCLogger.Error('db', 'Database not ready')
        return nil
    end
    return MySQL.query.await(query, params or {})
end

--- Execute multiple queries in a transaction.
--- @param queries table array of { query = string, values = table? }
--- @return boolean success
function NCDB.Transaction(queries)
    if not _ready then
        NCLogger.Error('db', 'Database not ready')
        return false
    end

    local formatted = {}
    for _, q in ipairs(queries) do
        formatted[#formatted + 1] = {
            query  = q.query or q[1],
            values = q.values or q.params or q[2] or {},
        }
    end

    local result = MySQL.transaction.await(formatted)
    return result ~= nil and result ~= false
end
