--[[
    NativeCore Tests — External Registry
    Allows other resources to register test suites via export.
]]

-- Export to register a suite from another resource
exports('RegisterSuite', function(suiteName, fn)
    local resource = GetInvokingResource()
    if not resource then
        print('^1[NC Tests] RegisterSuite must be called from another resource^0')
        return false
    end

    if type(suiteName) ~= 'string' or type(fn) ~= 'function' then
        print(('^1[NC Tests] Invalid test registration from %s^0'):format(resource))
        return false
    end

    -- Temporarily set the _currentResource for accurate tracking if needed by Describe
    -- However, GetInvokingResource() in framework.lua will handle it if called correctly.
    -- We pass the `Test` global table to the callback so the external resource doesn't need to import framework
    
    local ok, err = pcall(function()
        -- The external function should define its Describe blocks using the provided Test table
        fn(Test)
    end)

    if not ok then
        print(('^1[NC Tests] Error registering suite from %s: %s^0'):format(resource, err))
        return false
    end

    return true
end)

-- Auto-cleanup when a resource stops
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then return end
    
    -- Clear suites associated with this resource
    if Test and Test.ClearSuites then
        Test.ClearSuites(resourceName)
    end
end)
