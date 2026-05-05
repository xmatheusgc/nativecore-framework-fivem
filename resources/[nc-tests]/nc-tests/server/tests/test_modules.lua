--[[
    Tests — Module Loader
]]

Test.Describe('Modules', function()
    Test.It('should list registered modules', function()
        local list = NativeCore.Modules.List()
        Test.Expect(list).ToBeType('table')
    end)

    Test.It('should report nc-tests as registered', function()
        -- nc-tests registered itself in main.lua
        -- Give it time to process
        Citizen.Wait(100)
        local has = NativeCore.Modules.Has('nc-tests')
        Test.Expect(has).ToBeTrue()
    end)

    Test.It('should get module info', function()
        Citizen.Wait(100)
        local info = NativeCore.Modules.Get('nc-tests')
        Test.Expect(info).ToBeNotNil()
        Test.Expect(info.name).ToBe('nc-tests')
        Test.Expect(info.version).ToBe('0.2.0')
    end)

    Test.It('should return false for non-existent module', function()
        local has = NativeCore.Modules.Has('nonexistent-module')
        Test.Expect(has).ToBeFalse()
    end)

    Test.It('should return stats', function()
        local stats = NativeCore.Modules.Stats()
        Test.Expect(stats).ToBeType('table')
        Test.Expect(stats).ToHaveKey('total')
        Test.Expect(stats.total).ToBeGreaterThan(0)
    end)
end)
