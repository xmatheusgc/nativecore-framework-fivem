--[[
    NativeCore — Spy System
    Provides Spy, Stub, and Mock functionality for tests.
]]

Test = Test or {}

local activeSpies = {}

-- Resets all active spies (should be called in AfterEach)
function Test.ResetSpies()
    for _, spy in ipairs(activeSpies) do
        spy:Reset()
    end
end

-- Clear the spy registry completely
function Test.ClearSpies()
    activeSpies = {}
end

--- Create a Spy around a function (or an empty function if nil)
function Test.Spy(originalFn)
    local spy = {
        callCount = 0,
        calls = {},
        original = originalFn,
    }

    function spy.Reset(self)
        self.callCount = 0
        self.calls = {}
    end

    local wrapper = function(...)
        if spy.callCount < 10000 then -- Prevent memory leaks in loops
            spy.callCount = spy.callCount + 1
            table.insert(spy.calls, { ... })
        end
        if spy.original then
            return spy.original(...)
        end
    end
    
    -- Attach methods to the wrapper so `mySpy.callCount` works directly
    setmetatable(wrapper, {
        __index = spy,
        __call = function(_, ...) return wrapper(...) end
    })

    table.insert(activeSpies, spy)
    return wrapper
end

--- Create a Stub that returns a fixed value
function Test.Stub(returnValue)
    local wrapper = Test.Spy(function() return returnValue end)
    return wrapper
end

--- Create a Mock of a table, recursively stubbing functions
function Test.Mock(tbl)
    if type(tbl) ~= 'table' then return tbl end
    
    local mocked = {}
    for k, v in pairs(tbl) do
        if type(v) == 'function' then
            mocked[k] = Test.Spy(v)
        elseif type(v) == 'table' then
            mocked[k] = Test.Mock(v) -- Deep mock
        else
            mocked[k] = v
        end
    end
    return mocked
end
