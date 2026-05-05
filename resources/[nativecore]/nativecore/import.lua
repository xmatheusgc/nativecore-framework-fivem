--[[
    NativeCore — Import Bridge
    Include this in any module's fxmanifest.lua:
        shared_script '@nativecore/import.lua'

    Creates the global NativeCore table with cached API bindings.
    Handles both server and client contexts.
]]

if NativeCore then return end  -- already imported

local core = exports.nativecore
local isServer = IsDuplicityVersion()

NativeCore = {}

-- ============================================================
-- Logger (works via exports)
-- ============================================================

NativeCore.Logger = {
    Debug = function(...) core:LogDebug(...)  end,
    Info  = function(...) core:LogInfo(...)   end,
    Warn  = function(...) core:LogWarn(...)   end,
    Error = function(...) core:LogError(...)  end,
}

-- ============================================================
-- Config (works via exports)
-- ============================================================

NativeCore.Config = {
    Get = function(...) return core:ConfigGet(...) end,
}

-- ============================================================
-- Events (uses FiveM native events — no exports needed)
-- ============================================================

NativeCore.Events = {}

function NativeCore.Events.On(event, handler, priority)
    priority = priority or 0

    -- Use FiveM native events with nc: prefix
    RegisterNetEvent('nc:' .. event)
    AddEventHandler('nc:' .. event, handler)
end

function NativeCore.Events.Once(event, handler)
    local wrapper
    wrapper = function(...)
        RemoveEventHandler(wrapper)
        handler(...)
    end
    RegisterNetEvent('nc:' .. event)
    AddEventHandler('nc:' .. event, wrapper)
end

function NativeCore.Events.Emit(event, ...)
    TriggerEvent('nc:' .. event, ...)
end

if isServer then
    function NativeCore.Events.EmitNet(event, target, ...)
        TriggerClientEvent('nc:' .. event, target, ...)
    end
    function NativeCore.Events.EmitNetAll(event, ...)
        TriggerClientEvent('nc:' .. event, -1, ...)
    end
else
    function NativeCore.Events.EmitNet(event, ...)
        TriggerServerEvent('nc:' .. event, ...)
    end
end

function NativeCore.Events.Off(event)
    RemoveEventHandler('nc:' .. event)
end

-- ============================================================
-- Callbacks (uses FiveM native events for function passing)
-- ============================================================

NativeCore.Callbacks = {}

if isServer then
    --- Register a server callback from a module.
    function NativeCore.Callbacks.Register(name, handler)
        -- Register on core via Export (more reliable than TriggerEvent)
        core:CallbacksRegister(name, 'bridge')
        
        -- Listen for execution requests from core
        AddEventHandler('nc:cb:exec:' .. name, function(requestId, source, ...)
            local result = handler(source, ...)
            -- Send response back to client (directly for speed)
            TriggerClientEvent('nc:cb:res', source, requestId, result)
        end)
    end

    --- Check if a callback exists.
    function NativeCore.Callbacks.Has(name)
        return core:CallbacksHas(name)
    end
else
    local _pendingCallbacks = {}
    local _cbId = 0

    --- Trigger a server callback (client-side).
    function NativeCore.Callbacks.Trigger(name, cb, ...)
        _cbId = _cbId + 1
        local id = _cbId
        _pendingCallbacks[id] = cb
        TriggerServerEvent('nc:cb:req:request', name, id, ...)

        -- Timeout cleanup
        Citizen.SetTimeout(10000, function()
            if _pendingCallbacks[id] then
                _pendingCallbacks[id] = nil
            end
        end)
    end

    --- Await a server callback result.
    function NativeCore.Callbacks.Await(name, ...)
        local p = promise.new()
        NativeCore.Callbacks.Trigger(name, function(result, err)
            if err then p:reject(err) else p:resolve(result) end
        end, ...)
        return Citizen.Await(p)
    end

    -- Response handler
    RegisterNetEvent('nc:cb:res')
    AddEventHandler('nc:cb:res', function(requestId, result, err)
        local cb = _pendingCallbacks[requestId]
        if cb then
            _pendingCallbacks[requestId] = nil
            cb(result, err)
        end
    end)
end

-- ============================================================
-- Database (server only, via exports)
-- ============================================================

if isServer then
    NativeCore.DB = {
        Query       = function(...) return core:DBQuery(...)       end,
        Single      = function(...) return core:DBSingle(...)      end,
        Scalar      = function(...) return core:DBScalar(...)      end,
        Insert      = function(...) return core:DBInsert(...)      end,
        Update      = function(...) return core:DBUpdate(...)      end,
        Execute     = function(...) return core:DBExecute(...)     end,
        Transaction = function(...) return core:DBTransaction(...) end,
        Ready       = function()    return core:DBReady()          end,
    }
end

-- ============================================================
-- Player (via exports, data returned as tables)
-- ============================================================

NativeCore.Player = {}

if isServer then
    NativeCore.Player.Get       = function(...) return core:PlayerGet(...)       end
    NativeCore.Player.GetByUUID = function(...) return core:PlayerGetByUUID(...) end
    NativeCore.Player.GetAll    = function()    return core:PlayerGetAll()       end
    NativeCore.Player.Count     = function()    return core:PlayerCount()        end
    NativeCore.Player.SetData   = function(...) return core:PlayerSetData(...)   end
    NativeCore.Player.GetData   = function(...) return core:PlayerGetData(...)   end
    NativeCore.Player.IsLoaded  = function(...) return core:PlayerIsLoaded(...)  end
    NativeCore.Player.Save      = function(...) return core:PlayerSave(...)      end
    NativeCore.Player.SetGroup  = function(...) return core:PlayerSetGroup(...)  end
end

-- ============================================================
-- Modules (registration via events, queries via exports)
-- ============================================================

NativeCore.Modules = {}

--- Register a module with the core.
--- @param manifest table { name, version, requires?, optional?, onLoad?, onReady?, onUnload? }
function NativeCore.Modules.Register(manifest)
    -- Attach lifecycle handlers via events (functions can't go through exports)
    if manifest.onLoad then
        AddEventHandler('nc:module:load:' .. manifest.name, manifest.onLoad)
    end
    if manifest.onReady then
        AddEventHandler('nc:module:ready:' .. manifest.name, manifest.onReady)
    end
    if manifest.onUnload then
        AddEventHandler('nc:module:unload:' .. manifest.name, manifest.onUnload)
    end

    -- Send data-only manifest to core via event
    TriggerEvent('nc:modules:register', {
        name     = manifest.name,
        version  = manifest.version,
        requires = manifest.requires,
        optional = manifest.optional,
    })
end

NativeCore.Modules.Has     = function(...) return core:ModulesHas(...)     end
NativeCore.Modules.Get     = function(...) return core:ModulesGet(...)     end
NativeCore.Modules.List    = function()    return core:ModulesList()       end
NativeCore.Modules.Stats   = function()    return core:ModulesStats()      end
NativeCore.Modules.WaitFor = function(...) return core:ModulesWaitFor(...) end

-- ============================================================
-- State (via exports)
-- ============================================================

NativeCore.State = {
    GetGlobal = function(...) return core:StateGetGlobal(...) end,
    Memory = {
        Get = function(...) return core:StateMemoryGet(...) end,
    },
}

if isServer then
    NativeCore.State.SetGlobal  = function(...) core:StateSetGlobal(...)  end
    NativeCore.State.SetPlayer  = function(...) core:StateSetPlayer(...)  end
    NativeCore.State.GetPlayer  = function(...) return core:StateGetPlayer(...)  end
    NativeCore.State.SetEntity  = function(...) core:StateSetEntity(...)  end
    NativeCore.State.GetEntity  = function(...) return core:StateGetEntity(...) end
    NativeCore.State.Memory.Set = function(...) core:StateMemorySet(...)  end
end

-- ============================================================
-- Tests (Safe wrapper for nc-tests)
-- ============================================================

NativeCore.Tests = {}

--- Register a test suite safely (works even if nc-tests is missing).
--- @param suiteName string
--- @param fn function
function NativeCore.Tests.Register(suiteName, fn)
    if isServer and GetResourceState('nc-tests') == 'started' then
        exports['nc-tests']:RegisterSuite(suiteName, fn)
    end
end

-- ============================================================
-- Identity (server only, via exports)
-- ============================================================

if isServer then
    NativeCore.Identity = {
        GetIdentifiers    = function(...) return core:IdentityGetIdentifiers(...)    end,
        FindByIdentifier  = function(...) return core:IdentityFindByIdentifier(...)  end,
    }
end

print('[^2NC^0] NativeCore API imported (' .. (isServer and 'server' or 'client') .. ')')
