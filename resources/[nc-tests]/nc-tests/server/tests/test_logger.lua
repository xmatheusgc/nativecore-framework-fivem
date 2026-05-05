--[[
    Tests — Logger System
]]

Test.Describe('Logger', function()
    Test.It('should log without errors at all levels', function()
        -- These should not throw errors
        NativeCore.Logger.Debug('test', 'Debug message', { key = 'val' })
        NativeCore.Logger.Info('test', 'Info message')
        NativeCore.Logger.Warn('test', 'Warn message', { code = 42 })
        NativeCore.Logger.Error('test', 'Error message', { err = 'test' })
        Test.Expect(true).ToBeTrue() -- if we got here, no errors
    end)

    Test.It('should handle nil context gracefully', function()
        NativeCore.Logger.Info('test', 'No context')
        Test.Expect(true).ToBeTrue()
    end)

    Test.It('should handle empty context table', function()
        NativeCore.Logger.Info('test', 'Empty context', {})
        Test.Expect(true).ToBeTrue()
    end)
end)
