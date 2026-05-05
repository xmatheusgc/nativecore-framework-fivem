--[[
    NativeCore — Test Framework Runner
    Handles test registration, async execution, and lifecycle hooks.
]]

Test = Test or {}

local _suites = {}
local _currentSuite = nil
local _hasOnly = false

-- Test Registration Functions
function Test.Describe(name, fn)
    local suite = {
        name = name,
        resource = GetInvokingResource() or GetCurrentResourceName(),
        tests = {},
        hooks = {
            beforeAll = {},
            afterAll = {},
            beforeEach = {},
            afterEach = {}
        }
    }
    
    _currentSuite = suite
    table.insert(_suites, suite)
    
    -- Execute definition immediately to collect tests
    local ok, err = pcall(fn, Test)
    if not ok then
        print(('^1[NC Tests] Error defining suite %s: %s^0'):format(name, err))
    end
    
    _currentSuite = nil
end

function Test.It(name, fn, opts)
    if not _currentSuite then
        error('Test.It must be called inside Test.Describe')
    end
    opts = opts or {}
    table.insert(_currentSuite.tests, {
        name = name,
        fn = fn,
        skip = opts.skip or false,
        only = opts.only or false,
        timeout = opts.timeout or 5000,
    })
    if opts.only then _hasOnly = true end
end

function Test.Skip(name, fn)
    Test.It(name, fn, { skip = true })
end

function Test.Only(name, fn)
    Test.It(name, fn, { only = true })
end

-- Hook Registration
function Test.BeforeAll(fn)  table.insert(_currentSuite.hooks.beforeAll, fn) end
function Test.AfterAll(fn)   table.insert(_currentSuite.hooks.afterAll, fn) end
function Test.BeforeEach(fn) table.insert(_currentSuite.hooks.beforeEach, fn) end
function Test.AfterEach(fn)  table.insert(_currentSuite.hooks.afterEach, fn) end

-- Async Test Executor
local function executeTestAsync(test)
    local p = promise.new()
    local isAsync = false
    local doneCalled = false
    
    local done = function(err)
        if doneCalled then return end
        doneCalled = true
        if err then p:reject(err) else p:resolve(true) end
    end

    -- Run test function in a thread to catch errors and handle sync/async
    Citizen.CreateThread(function()
        local ok, err = xpcall(function()
            -- Determine if test expects `done` callback by checking debug info (arg count)
            local info = debug.getinfo(test.fn, "u")
            isAsync = info.nparams > 0

            if isAsync then
                test.fn(done)
                -- Timeout handling
                Citizen.SetTimeout(test.timeout, function()
                    if not doneCalled then
                        done("Async test timed out after " .. test.timeout .. "ms")
                    end
                end)
            else
                test.fn()
                done()
            end
        end, debug.traceback)

        if not ok then
            done(err)
        end
    end)

    local ok, result = pcall(Citizen.Await, p)
    if not ok then
        return false, result
    end
    return true, nil
end

-- Run hooks safely
local function runHooks(hooks)
    for _, hook in ipairs(hooks) do
        local ok, err = xpcall(hook, debug.traceback)
        if not ok then return false, err end
    end
    return true, nil
end

-- Main Runner
function Test.Run(filter)
    local startTotal = GetGameTimer()
    
    local results = {
        suitesTotal = 0,
        suitesPassed = 0,
        suitesFailed = 0,
        passed = 0,
        failed = 0,
        skipped = 0,
        totalTime = 0
    }

    Test.Reporter.PrintHeader()

    for _, suite in ipairs(_suites) do
        local filterText = (filter or ''):lower():gsub('%s+', '')
        local suiteName = suite.name:lower()
        local resourceName = suite.resource:lower()

        if not filter or string.find(suiteName, filterText, 1, true) or string.find(resourceName, filterText, 1, true) then
            results.suitesTotal = results.suitesTotal + 1
            Test.Reporter.PrintSuite(suite.name, suite.resource)

            local suiteFailed = false
            local skipRest = false

            -- BeforeAll
            local ok, err = runHooks(suite.hooks.beforeAll)
            if not ok then
                print('    ^1✗ BeforeAll hook failed. Skipping suite.^0')
                print('      ^1' .. err .. '^0')
                suiteFailed = true
                skipRest = true
            end

            for _, test in ipairs(suite.tests) do
                if skipRest or test.skip or (_hasOnly and not test.only) then
                    results.skipped = results.skipped + 1
                    test.skipped = true
                    Test.Reporter.PrintTestResult(test)
                else
                    local testStart = GetGameTimer()

                    -- BeforeEach
                    local hookOk, hookErr = runHooks(suite.hooks.beforeEach)
                    if not hookOk then
                        test.passed = false
                        test.error = "BeforeEach hook failed: " .. hookErr
                    else
                        -- Run Test
                        local testOk, testErr = executeTestAsync(test)
                        test.passed = testOk
                        test.error = testErr

                        -- AfterEach
                        hookOk, hookErr = runHooks(suite.hooks.afterEach)
                        if not hookOk and test.passed then
                            test.passed = false
                            test.error = "AfterEach hook failed: " .. hookErr
                        end
                    end

                    -- Cleanup Spies automatically
                    if Test.ResetSpies then Test.ResetSpies() end

                    test.duration = GetGameTimer() - testStart

                    if test.passed then
                        results.passed = results.passed + 1
                    else
                        results.failed = results.failed + 1
                        suiteFailed = true
                    end
                    
                    Test.Reporter.PrintTestResult(test)
                end
            end

            -- AfterAll
            if not skipRest then
                local ok, err = runHooks(suite.hooks.afterAll)
                if not ok then
                    print('    ^1✗ AfterAll hook failed.^0')
                    print('      ^1' .. err .. '^0')
                    suiteFailed = true
                end
            end

            if suiteFailed then
                results.suitesFailed = results.suitesFailed + 1
            else
                results.suitesPassed = results.suitesPassed + 1
            end
        end
    end

    results.totalTime = GetGameTimer() - startTotal
    Test.Reporter.PrintSummary(results)

    return results
end

-- Clear registered suites
function Test.ClearSuites(resourceName)
    if not resourceName then
        _suites = {}
        _hasOnly = false
        return
    end

    local i = 1
    while i <= #_suites do
        if _suites[i].resource == resourceName then
            table.remove(_suites, i)
        else
            i = i + 1
        end
    end
end
