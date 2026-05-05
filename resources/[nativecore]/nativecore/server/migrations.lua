--[[
    NativeCore — Migration Runner (Server)
    Executes versioned database migrations on boot.
    Migrations live in migrations/*.lua and are run in numeric order.
]]

NCMigrations = {}

local _migrations = {}

--- Register a migration definition.
--- @param migration table { version = string, name = string, up = function }
function NCMigrations.Add(migration)
    _migrations[#_migrations + 1] = migration
end

--- Ensure the migrations tracking table exists.
local function ensureMigrationTable()
    NCDB.Execute([[
        CREATE TABLE IF NOT EXISTS nc_migrations (
            version     VARCHAR(10) PRIMARY KEY,
            name        VARCHAR(100) NOT NULL,
            executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ]])
end

--- Get all already-executed migration versions.
--- @return table<string, boolean> set of executed versions
local function getExecutedVersions()
    local rows = NCDB.Query('SELECT version FROM nc_migrations')
    local set = {}
    for _, row in ipairs(rows) do
        set[row.version] = true
    end
    return set
end

--- Load migration files from the resource.
local function loadMigrationFiles()
    local resourceName = GetCurrentResourceName()

    -- Scan known migration files (FiveM doesn't support directory listing)
    -- Migrations must be registered via NCMigrations.Add() or loaded here
    local i = 1
    while true do
        local filename = ('migrations/%03d_'):format(i)
        -- Try to find migration files by index
        -- Since we can't list directory, we try common patterns
        local found = false
        for _, suffix in ipairs({ 'initial', 'update', 'add_characters', 'schema' }) do
            local path = filename .. suffix .. '.lua'
            local content = LoadResourceFile(resourceName, path)
            if content then
                local chunk, err = load(content, path)
                if chunk then
                    local ok, migration = pcall(chunk)
                    if ok and type(migration) == 'table' and migration.up then
                        NCMigrations.Add(migration)
                        found = true
                        break
                    end
                end
            end
        end

        -- Also try the exact numbered format
        if not found then
            for _, name in ipairs(NCMigrations._knownFiles or {}) do
                local path = 'migrations/' .. name .. '.lua'
                local content = LoadResourceFile(resourceName, path)
                if content then
                    local chunk, err = load(content, path)
                    if chunk then
                        local ok, migration = pcall(chunk)
                        if ok and type(migration) == 'table' then
                            NCMigrations.Add(migration)
                            found = true
                        end
                    end
                end
            end
        end

        if not found then break end
        i = i + 1
    end
end

--- Run all pending migrations in order.
--- @return number count of migrations executed
function NCMigrations.Run()
    if not NCDB.Ready() then
        NCLogger.Error('migrations', 'Database not ready, cannot run migrations')
        return 0
    end

    if not NCConfig.Get('database.MigrationsEnabled', true) then
        NCLogger.Info('migrations', 'Migrations disabled by config')
        return 0
    end

    ensureMigrationTable()

    -- Load the initial migration directly (known file)
    local resourceName = GetCurrentResourceName()
    local content = LoadResourceFile(resourceName, 'migrations/001_initial.lua')
    if content and #_migrations == 0 then
        local chunk = load(content, '001_initial.lua')
        if chunk then
            local ok, migration = pcall(chunk)
            if ok and type(migration) == 'table' then
                NCMigrations.Add(migration)
            end
        end
    end

    local executed = getExecutedVersions()
    local count = 0

    -- Sort migrations by version
    table.sort(_migrations, function(a, b)
        return a.version < b.version
    end)

    for _, migration in ipairs(_migrations) do
        if not executed[migration.version] then
            NCLogger.Info('migrations', 'Running migration', {
                version = migration.version,
                name = migration.name,
            })

            local ok, err = NCUtils.SafeCall(migration.up, NCDB)
            if ok then
                NCDB.Execute(
                    'INSERT INTO nc_migrations (version, name) VALUES (?, ?)',
                    { migration.version, migration.name }
                )
                count = count + 1
                NCLogger.Info('migrations', 'Migration completed', {
                    version = migration.version,
                })
            else
                NCLogger.Error('migrations', 'Migration failed', {
                    version = migration.version,
                    error = tostring(err),
                })
                break  -- stop on first failure
            end
        end
    end

    if count > 0 then
        NCLogger.Info('migrations', 'Migrations finished', { executed = count })
    else
        NCLogger.Debug('migrations', 'No pending migrations')
    end

    return count
end

--- Get the current migration version.
--- @return string|nil version
function NCMigrations.GetVersion()
    if not NCDB.Ready() then return nil end
    return NCDB.Scalar('SELECT MAX(version) FROM nc_migrations')
end
