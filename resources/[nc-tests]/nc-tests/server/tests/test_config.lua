--[[
    Tests — Config System
]]

Test.Describe('Config', function()
    Test.It('should get a value from core config', function()
        local logLevel = NativeCore.Config.Get('core.LogLevel')
        Test.Expect(logLevel).ToBeNotNil()
        Test.Expect(logLevel).ToBeType('string')
    end)

    Test.It('should return default when key not found', function()
        local val = NativeCore.Config.Get('nonexistent.key', 'fallback')
        Test.Expect(val).ToBe('fallback')
    end)

    Test.It('should get database adapter', function()
        local adapter = NativeCore.Config.Get('database.Adapter')
        Test.Expect(adapter).ToBe('oxmysql')
    end)

    Test.It('should get nested values with dot notation', function()
        local spawn = NativeCore.Config.Get('core.DefaultSpawn')
        Test.Expect(spawn).ToBeType('table')
        Test.Expect(spawn).ToHaveKey('x')
        Test.Expect(spawn).ToHaveKey('y')
        Test.Expect(spawn).ToHaveKey('z')
    end)

    Test.It('should get identity priority as table', function()
        local priority = NativeCore.Config.Get('core.IdentityPriority')
        Test.Expect(priority).ToBeType('table')
        Test.Expect(priority).ToContain('license')
    end)
end)
