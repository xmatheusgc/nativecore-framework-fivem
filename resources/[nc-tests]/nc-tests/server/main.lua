--[[
    NativeCore Tests — Main Runner
    Registers nc-tests as a module and provides the /nc_test command.
]]

-- Register as a module
NativeCore.Modules.Register({
    name    = 'nc-tests',
    version = '0.2.0',
    requires = {},
    onReady = function()
        NativeCore.Logger.Info('nc-tests', 'Test framework ready')

        -- Auto-run tests after a small delay based on config
        local autoRun      = NativeCore.Config.Get('tests.AutoRun', false)
        local autoRunDelay = NativeCore.Config.Get('tests.AutoRunDelay', 5000)
        local filter       = NativeCore.Config.Get('tests.AutoRunFilter', '')
        local debug        = NativeCore.Config.Get('core.Debug', false)

        if autoRun or debug then
            Citizen.CreateThread(function()
                Citizen.Wait(autoRunDelay)
                print(('[NC Tests] %s detected — auto-running tests...'):format(autoRun and 'AutoRun' or 'Debug mode'))
                local results = Test.Run(filter ~= '' and filter or nil)
                
                -- Handle ExitOnError for CI/CD
                if results.failed > 0 and NativeCore.Config.Get('tests.ExitOnError', false) then
                    print('^1[NC Tests] FATAL: Tests failed and ExitOnError is enabled. Shutting down server...^0')
                    Citizen.Wait(1000)
                    os.exit()
                end
            end)
        else
            print('[NC Tests] Ready. Run tests with: nc_test [suite_filter]')
        end
    end,
})

-- Register test command
RegisterCommand('nc_test', function(source, args)
    -- Only allow from server console (source 0)
    if source ~= 0 then
        print('[NC Tests] Tests can only be run from server console')
        return
    end

    local filter = args[1] or nil

    if filter == "--list" then
        print('^5══════════════════════════════════════^0')
        print('  Registered Test Suites:')
        -- We can just print the names of registered suites
        -- This is a simple implementation; framework could expose a GetSuites() function
        print('  Run with: nc_test [filter]')
        print('^5══════════════════════════════════════^0')
        return
    end

    -- Run tests in a thread to allow Citizen.Wait
    Citizen.CreateThread(function()
        local results = Test.Run(filter)

        if results.failed > 0 then
            print('^1[NC Tests] Some tests failed!^0')
        else
            print('^2[NC Tests] All tests passed!^0')
        end
    end)
end, true)  -- restricted = true
