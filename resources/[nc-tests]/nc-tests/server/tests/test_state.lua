--[[
    Tests — State Manager
]]

Test.Describe('State', function()
    Test.It('should set and get memory state', function()
        NativeCore.State.Memory.Set('test', 'key1', 'value1')
        local val = NativeCore.State.Memory.Get('test', 'key1')
        Test.Expect(val).ToBe('value1')
    end)

    Test.It('should return nil for missing memory key', function()
        local val = NativeCore.State.Memory.Get('nonexistent', 'key')
        Test.Expect(val).ToBeNil()
    end)

    Test.It('should set and get global state', function()
        NativeCore.State.SetGlobal('testKey', 'testValue')
        -- StateBags may need a tick to propagate
        Citizen.Wait(50)
        local val = NativeCore.State.GetGlobal('testKey')
        Test.Expect(val).ToBe('testValue')
    end)
end)
