--[[
    NativeCore — Client Main Entry Point
    Initializes client subsystems and notifies server when ready.
]]

-- Wait for player to be loaded, then notify server
Citizen.CreateThread(function()
    -- Wait for the game to be fully loaded
    while not NetworkIsSessionStarted() do
        Citizen.Wait(100)
    end

    -- Wait for player data from server (via StateBag)
    NCPlayer.WaitForLoad()

    -- Notify server that client is fully ready
    TriggerServerEvent('nc:client:playerJoined')

    NCLogger.Info('core', 'Client initialized', {
        uuid = NCPlayer.GetUUID(),
    })

    NCEvents.Emit('core:clientReady')
end)
