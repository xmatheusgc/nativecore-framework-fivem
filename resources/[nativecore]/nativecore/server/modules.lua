--[[
    NativeCore — Module Registry & Loader (Server)
    Manages module registration, dependency validation, and lifecycle.
    Modules register via TriggerEvent('nc:modules:register', data).
]]

NCModules = {}

local _modules      = {}   -- [name] = moduleInfo
local _coreReady    = false
local _pendingQueue = {}   -- modules registered before core ready

-- ============================================================
-- Module Registration
-- ============================================================

--- Process a module registration.
--- @param data table { name, version, requires?, optional? }
local function processModule(data)
    local resourceName = data._resource or 'unknown'

    -- Validate required dependencies
    if data.requires then
        for _, dep in ipairs(data.requires) do
            if dep ~= 'nativecore' and not _modules[dep] then
                NCLogger.Error('modules', 'Missing required dependency', {
                    module = data.name,
                    dependency = dep,
                })
                _modules[data.name] = {
                    name     = data.name,
                    version  = data.version or '0.0.0',
                    resource = resourceName,
                    state    = NC_MODULE_STATE.ERROR,
                    error    = 'Missing dependency: ' .. dep,
                }
                TriggerEvent(NC_EVENT_PREFIX .. 'module:error:' .. data.name, 'Missing dependency: ' .. dep)
                return
            end
        end
    end

    -- Register the module
    _modules[data.name] = {
        name     = data.name,
        version  = data.version or '0.0.0',
        requires = data.requires or {},
        optional = data.optional or {},
        resource = resourceName,
        state    = NC_MODULE_STATE.LOADING,
        loadedAt = NCUtils.Timestamp(),
    }

    NCLogger.Info('modules', 'Module registered', {
        name = data.name,
        version = data.version or '0.0.0',
        resource = resourceName,
    })

    -- Trigger lifecycle events
    TriggerEvent(NC_EVENT_PREFIX .. 'module:load:' .. data.name)

    -- Small delay to allow onLoad to execute, then mark ready
    Citizen.CreateThread(function()
        Citizen.Wait(0)
        if _modules[data.name] and _modules[data.name].state == NC_MODULE_STATE.LOADING then
            _modules[data.name].state = NC_MODULE_STATE.READY
            TriggerEvent(NC_EVENT_PREFIX .. 'module:ready:' .. data.name)
            NCLogger.Info('modules', 'Module ready', { name = data.name })
        end
    end)
end

-- Listen for module registration events
AddEventHandler(NC_EVENT_PREFIX .. 'modules:register', function(data)
    -- Track which resource is registering
    data._resource = GetInvokingResource() or GetCurrentResourceName()

    if _coreReady then
        processModule(data)
    else
        table.insert(_pendingQueue, data)
        NCLogger.Debug('modules', 'Module queued (core not ready)', { name = data.name })
    end
end)

-- ============================================================
-- Core Ready Handler
-- ============================================================

--- Called by main.lua when core initialization is complete.
function NCModules.SetCoreReady()
    _coreReady = true

    -- Process all pending module registrations
    for _, data in ipairs(_pendingQueue) do
        processModule(data)
    end
    _pendingQueue = {}

    NCLogger.Info('modules', 'Module loader ready, pending queue processed')
end

-- ============================================================
-- Public API
-- ============================================================

--- Check if a module is registered and ready.
--- @param name string
--- @return boolean
function NCModules.Has(name)
    local m = _modules[name]
    return m ~= nil and m.state == NC_MODULE_STATE.READY
end

--- Get module info.
--- @param name string
--- @return table|nil moduleInfo
function NCModules.Get(name)
    local m = _modules[name]
    if not m then return nil end
    -- Return a copy without internal fields
    return {
        name     = m.name,
        version  = m.version,
        state    = m.state,
        resource = m.resource,
        requires = m.requires,
        optional = m.optional,
        loadedAt = m.loadedAt,
    }
end

--- List all registered modules.
--- @return table modules { { name, version, state, resource }, ... }
function NCModules.List()
    local list = {}
    for _, m in pairs(_modules) do
        list[#list + 1] = {
            name     = m.name,
            version  = m.version,
            state    = m.state,
            resource = m.resource,
        }
    end
    return list
end

--- Get count of modules by state.
--- @return table { ready = n, loading = n, error = n, total = n }
function NCModules.Stats()
    local stats = { ready = 0, loading = 0, error = 0, stopped = 0, total = 0 }
    for _, m in pairs(_modules) do
        stats.total = stats.total + 1
        if stats[m.state] then
            stats[m.state] = stats[m.state] + 1
        end
    end
    return stats
end

--- Wait for a module to be ready (blocking coroutine).
--- @param name string
--- @param timeout number? milliseconds (default from config)
--- @return boolean ready
function NCModules.WaitFor(name, timeout)
    if NCModules.Has(name) then return true end

    timeout = timeout or NCConfig.Get('core.ModuleLoadTimeout', 15000)
    local start = GetGameTimer()

    while not NCModules.Has(name) do
        if GetGameTimer() - start > timeout then
            NCLogger.Warn('modules', 'WaitFor timed out', {
                module = name,
                timeout = timeout,
            })
            return false
        end
        Citizen.Wait(100)
    end

    return true
end

-- ============================================================
-- Resource Stop Handler (auto-unregister)
-- ============================================================

AddEventHandler('onResourceStop', function(resourceName)
    for name, m in pairs(_modules) do
        if m.resource == resourceName then
            m.state = NC_MODULE_STATE.STOPPED
            TriggerEvent(NC_EVENT_PREFIX .. 'module:unload:' .. name)
            NCLogger.Info('modules', 'Module stopped', {
                name = name,
                resource = resourceName,
            })
        end
    end
end)
