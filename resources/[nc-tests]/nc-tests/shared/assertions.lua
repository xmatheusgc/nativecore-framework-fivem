--[[
    NativeCore — Assertions Library
    Provides a comprehensive set of matchers for testing.
]]

Test = Test or {}
Test.Assertions = {}

-- Utility: Deep Compare Tables
local function deepCompare(t1, t2, ignore_mt, _refs)
    local ty1 = type(t1)
    local ty2 = type(t2)
    if ty1 ~= ty2 then return false end
    if ty1 ~= 'table' and ty2 ~= 'table' then return t1 == t2 end
    
    _refs = _refs or {}
    if _refs[t1] then
        return _refs[t1] == t2
    end
    _refs[t1] = t2

    local mt = getmetatable(t1)
    if not ignore_mt and mt and mt.__eq then return t1 == t2 end

    for k1, v1 in pairs(t1) do
        local v2 = t2[k1]
        if v2 == nil or not deepCompare(v1, v2, ignore_mt, _refs) then return false end
    end
    for k2, _ in pairs(t2) do
        if t1[k2] == nil then return false end
    end
    return true
end

-- Utility: Safe tostring for tables
local function safeToString(val, depth)
    depth = depth or 0
    if depth > 3 then return "{...}" end
    if type(val) == 'table' then
        local parts = {}
        for k, v in pairs(val) do
            table.insert(parts, tostring(k) .. "=" .. safeToString(v, depth + 1))
        end
        return "{" .. table.concat(parts, ", ") .. "}"
    end
    if type(val) == 'string' then return '"' .. val .. '"' end
    return tostring(val)
end

function Test.Expect(value)
    local assertion = { _isNot = false }
    
    local function evaluate(condition, defaultMsg)
        if assertion._isNot then condition = not condition end
        if not condition then
            local prefix = assertion._isNot and "NOT " or ""
            error(prefix .. defaultMsg, 3)
        end
        return true
    end

    local matchers = {}

    function matchers.ToBe(expected)
        return evaluate(value == expected, ("Expected %s to be %s"):format(safeToString(value), safeToString(expected)))
    end

    function matchers.ToEqual(expected)
        return evaluate(deepCompare(value, expected), ("Expected %s to deeply equal %s"):format(safeToString(value), safeToString(expected)))
    end

    function matchers.ToBeNil()
        return evaluate(value == nil, ("Expected %s to be nil"):format(safeToString(value)))
    end

    function matchers.ToBeNotNil()
        return evaluate(value ~= nil, ("Expected %s to not be nil"):format(safeToString(value)))
    end

    function matchers.ToBeTrue()
        return evaluate(value == true, ("Expected %s to be strictly true"):format(safeToString(value)))
    end

    function matchers.ToBeFalse()
        return evaluate(value == false, ("Expected %s to be strictly false"):format(safeToString(value)))
    end

    function matchers.ToBeTruthy()
        return evaluate(value ~= false and value ~= nil, ("Expected %s to be truthy"):format(safeToString(value)))
    end

    function matchers.ToBeFalsy()
        return evaluate(value == false or value == nil, ("Expected %s to be falsy"):format(safeToString(value)))
    end

    function matchers.ToBeType(expectedType)
        return evaluate(type(value) == expectedType, ("Expected type %s but got %s"):format(expectedType, type(value)))
    end

    function matchers.ToContain(item)
        local contains = false
        if type(value) == 'table' then
            for _, v in pairs(value) do
                if v == item then contains = true; break end
            end
        elseif type(value) == 'string' and type(item) == 'string' then
            contains = string.find(value, item, 1, true) ~= nil
        end
        return evaluate(contains, ("Expected %s to contain %s"):format(safeToString(value), safeToString(item)))
    end

    function matchers.ToContainKey(key)
        local contains = false
        if type(value) == 'table' then
            contains = value[key] ~= nil
        end
        return evaluate(contains, ("Expected %s to contain key %s"):format(safeToString(value), safeToString(key)))
    end

    function matchers.ToHaveKey(key)
        return matchers.ToContainKey(key)
    end

    function matchers.ToHaveLength(n)
        local len = 0
        if type(value) == 'table' then len = #value
        elseif type(value) == 'string' then len = string.len(value) end
        return evaluate(len == n, ("Expected length %d but got %d"):format(n, len))
    end

    function matchers.ToBeGreaterThan(n)
        return evaluate(type(value) == 'number' and value > n, ("Expected %s to be greater than %s"):format(tostring(value), tostring(n)))
    end

    function matchers.ToBeLessThan(n)
        return evaluate(type(value) == 'number' and value < n, ("Expected %s to be less than %s"):format(tostring(value), tostring(n)))
    end

    function matchers.ToBeGreaterOrEqual(n)
        return evaluate(type(value) == 'number' and value >= n, ("Expected %s to be >= %s"):format(tostring(value), tostring(n)))
    end

    function matchers.ToBeLessOrEqual(n)
        return evaluate(type(value) == 'number' and value <= n, ("Expected %s to be <= %s"):format(tostring(value), tostring(n)))
    end

    function matchers.ToBeCloseTo(n, delta)
        delta = delta or 0.001
        return evaluate(type(value) == 'number' and math.abs(value - n) <= delta, ("Expected %s to be close to %s (±%s)"):format(tostring(value), tostring(n), tostring(delta)))
    end

    function matchers.ToMatch(pattern)
        return evaluate(type(value) == 'string' and string.find(value, pattern) ~= nil, ("Expected %s to match pattern %s"):format(safeToString(value), safeToString(pattern)))
    end

    function matchers.ToThrow(expectedErrorPattern)
        if type(value) ~= 'function' then
            error("ToThrow expects a function", 2)
        end
        local ok, err = pcall(value)
        local threw = not ok
        local msg = threw and "Function threw an error" or "Expected function to throw an error, but it did not"
        
        if expectedErrorPattern and threw then
            local match = string.find(tostring(err), expectedErrorPattern) ~= nil
            if not match then
                threw = false
                msg = ("Expected error matching '%s' but got '%s'"):format(expectedErrorPattern, tostring(err))
            end
        end

        return evaluate(threw, msg)
    end

    -- Setup metatable for matchers and .Not
    setmetatable(assertion, {
        __index = function(t, k)
            if k == "Not" then
                t._isNot = true
                return t
            end
            return matchers[k]
        end
    })

    return assertion
end
