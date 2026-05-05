--[[
    Tests — Event Bus
]]

Test.Describe('Events', function()
    Test.It('should emit and receive events', function()
        local received = false
        NativeCore.Events.On('test:basic', function()
            received = true
        end)
        NativeCore.Events.Emit('test:basic')
        -- Events are synchronous within same resource
        Test.Expect(received).ToBeTrue()
    end)

    Test.It('should pass arguments through events', function()
        local capturedA, capturedB
        NativeCore.Events.On('test:args', function(a, b)
            capturedA = a
            capturedB = b
        end)
        NativeCore.Events.Emit('test:args', 'hello', 42)
        Test.Expect(capturedA).ToBe('hello')
        Test.Expect(capturedB).ToBe(42)
    end)

    Test.It('should handle multiple listeners on same event', function()
        local count = 0
        NativeCore.Events.On('test:multi', function() count = count + 1 end)
        NativeCore.Events.On('test:multi', function() count = count + 1 end)
        NativeCore.Events.Emit('test:multi')
        Test.Expect(count).ToBe(2)
    end)
end)
