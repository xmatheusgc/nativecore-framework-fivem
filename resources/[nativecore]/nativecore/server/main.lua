--[[
    NativeCore — Server Main Entry Point
    Orchestrates boot sequence, registers exports, and FiveM lifecycle handlers.
]]

-- ============================================================
-- Boot Sequence
-- ============================================================

Citizen.CreateThread(function()
    -- 1. Load configuration
    NCConfig.LoadAll()
    NCLogger.Info('core', 'Configuration loaded')

    -- 2. Initialize database
    local dbOk = NCDB.Init()
    if not dbOk then
        NCLogger.Error('core', 'FATAL: Database initialization failed — aborting boot')
        return
    end

    -- 3. Run migrations
    NCMigrations.Run()

    -- 4. Start player auto-save
    NCPlayer.StartAutoSave()

    -- 5. Mark core as ready
    NCModules.SetCoreReady()

    -- 6. Freeze config after boot
    NCConfig.Freeze()

    -- 7. Emit core ready event
    NCEvents.Emit('core:ready')

    -- 8. Print boot banner
    local stats = NCModules.Stats()
    print('')
    print('^2============================================^0')
    print('^2  ' .. NC_NAME .. ' v' .. NC_VERSION .. ' — Server Started^0')
    print('^2============================================^0')
    print(('  ^3Database:^0   %s'):format(NCDB.Ready() and '^2Connected^0' or '^1Disconnected^0'))
    print(('  ^3Modules:^0    %d loaded'):format(stats.total))
    print(('  ^3Migration:^0  v%s'):format(NCMigrations.GetVersion() or 'none'))
    print('^2============================================^0')
    print('')
end)

-- ============================================================
-- FiveM Lifecycle Handlers
-- ============================================================

--- Player connecting — resolve identity, load session.
AddEventHandler('playerConnecting', function(playerName, setKickReason, deferrals)
    local src = source

    deferrals.defer()
    Citizen.Wait(0)

    deferrals.update(('Welcome %s! Loading your data...'):format(playerName))

    -- Wait for core to be ready
    local timeout = 15000
    local start = GetGameTimer()
    while not NCDB.Ready() do
        if GetGameTimer() - start > timeout then
            deferrals.done('Server is still starting up. Please try again in a moment.')
            return
        end
        Citizen.Wait(100)
    end

    -- Load player session
    local ok, result = NCUtils.SafeCall(NCPlayer.Load, src)
    if not ok or not result then
        NCLogger.Error('core', 'Failed to load player on connect', {
            source = src,
            name = playerName,
            error = tostring(result),
        })
        deferrals.done('Failed to load your data. Please try again.')
        return
    end

    deferrals.done()
end)

--- Player fully joined the server.
RegisterNetEvent('nc:client:playerJoined')
AddEventHandler('nc:client:playerJoined', function()
    local src = source
    local playerObj = NCPlayer.Get(src)
    if playerObj then
        NCEvents.Emit('player:joined', src, playerObj)
        NCLogger.Debug('core', 'Player fully joined', {
            source = src,
            uuid = playerObj.uuid,
        })
    end
end)

--- Player disconnected.
AddEventHandler('playerDropped', function(reason)
    local src = source
    NCPlayer.Unload(src, reason)
end)

--- Resource stopping — save all players.
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        NCLogger.Info('core', 'Core stopping — saving all players')
        NCPlayer.StopAutoSave()
        NCPlayer.SaveAll()
    end
end)

-- ============================================================
-- Exports Registration
-- ============================================================

-- Logger
exports('LogDebug', function(...) NCLogger.Debug(...) end)
exports('LogInfo',  function(...) NCLogger.Info(...)  end)
exports('LogWarn',  function(...) NCLogger.Warn(...)  end)
exports('LogError', function(...) NCLogger.Error(...) end)

-- Config
exports('ConfigGet', function(...) return NCConfig.Get(...) end)

-- DB
exports('DBQuery',       function(...) return NCDB.Query(...)       end)
exports('DBSingle',      function(...) return NCDB.Single(...)      end)
exports('DBScalar',      function(...) return NCDB.Scalar(...)      end)
exports('DBInsert',      function(...) return NCDB.Insert(...)      end)
exports('DBUpdate',      function(...) return NCDB.Update(...)      end)
exports('DBExecute',     function(...) return NCDB.Execute(...)     end)
exports('DBTransaction', function(...) return NCDB.Transaction(...) end)
exports('DBReady',       function()    return NCDB.Ready()          end)

-- Player
exports('PlayerGet',       function(...) return NCPlayer.Get(...)       end)
exports('PlayerGetByUUID', function(...) return NCPlayer.GetByUUID(...) end)
exports('PlayerGetAll',    function()    return NCPlayer.GetAll()       end)
exports('PlayerCount',     function()    return NCPlayer.Count()        end)
exports('PlayerSetData',   function(...) return NCPlayer.SetData(...)   end)
exports('PlayerGetData',   function(...) return NCPlayer.GetData(...)   end)
exports('PlayerIsLoaded',  function(...) return NCPlayer.IsLoaded(...)  end)
exports('PlayerSave',      function(...) return NCPlayer.Save(...)      end)
exports('PlayerSetGroup',  function(...) return NCPlayer.SetGroup(...)  end)

-- Modules
exports('ModulesHas',     function(...) return NCModules.Has(...)     end)
exports('ModulesGet',     function(...) return NCModules.Get(...)     end)
exports('ModulesList',    function()    return NCModules.List()       end)
exports('ModulesStats',   function()    return NCModules.Stats()      end)
exports('ModulesWaitFor', function(...) return NCModules.WaitFor(...) end)

-- State
exports('StateSetGlobal',  function(...) NCState.SetGlobal(...)     end)
exports('StateGetGlobal',  function(...) return NCState.GetGlobal(...) end)
exports('StateSetPlayer',  function(...) NCState.SetPlayer(...)     end)
exports('StateGetPlayer',  function(...) return NCState.GetPlayer(...) end)
exports('StateSetEntity',  function(...) NCState.SetEntity(...)     end)
exports('StateGetEntity',  function(...) return NCState.GetEntity(...) end)
exports('StateMemorySet',  function(...) NCState.Memory.Set(...)    end)
exports('StateMemoryGet',  function(...) return NCState.Memory.Get(...) end)

-- Identity
exports('IdentityGetIdentifiers',  function(...) return NCIdentity.GetIdentifiers(...)  end)
exports('IdentityFindByIdentifier', function(...) return NCIdentity.FindByIdentifier(...) end)

-- Callbacks
exports('CallbacksRegister', function(...) NCCallbacks.Register(...) end)
exports('CallbacksHas',      function(...) return NCCallbacks.Has(...) end)
