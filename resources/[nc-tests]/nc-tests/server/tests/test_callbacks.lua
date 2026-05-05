--[[
    Tests — Callbacks
]]

Test.Describe('Callbacks', function()
    Test.It('should register and check existence', function()
        NativeCore.Callbacks.Register('test:cb', function(source)
            return 'pong'
        end)
        
        -- Give it enough time to propagate through events (cross-resource)
        Citizen.Wait(100)
        
        local has = NativeCore.Callbacks.Has('test:cb')
        Test.Expect(has).ToBeTrue()
    end)

    Test.It('should return false for missing callback', function()
        local has = NativeCore.Callbacks.Has('missing:cb')
        Test.Expect(has).ToBeFalse()
    end)
end)
