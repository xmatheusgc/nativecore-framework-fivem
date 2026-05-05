--[[
    NativeCore — Test Reporter
    Formats and outputs test results to the console.
]]

Test = Test or {}
Test.Reporter = {}

function Test.Reporter.PrintHeader()
    print('')
    print('^5══════════════════════════════════════^0')
    print(('^5  NativeCore Test Runner v%s^0'):format(GetResourceMetadata('nc-tests', 'version', 0) or '0.2.0'))
    print('^5══════════════════════════════════════^0')
end

function Test.Reporter.PrintSuite(suiteName, resourceName)
    print('')
    print(('  ^3▸ %s ^8(%s)^0'):format(suiteName, resourceName or 'unknown'))
end

function Test.Reporter.PrintTestResult(test)
    if test.skipped then
        print(('    ^8-^0 %s ^8(skipped)^0'):format(test.name))
        return
    end

    local timeStr = test.duration > 0 and ('^8(%dms)^0'):format(test.duration) or ''
    
    if test.passed then
        print(('    ^2✓^0 %s %s'):format(test.name, timeStr))
    else
        print(('    ^1✗^0 %s %s'):format(test.name, timeStr))
        
        -- Format error trace cleanly
        if test.error then
            local lines = {}
            for s in string.gmatch(tostring(test.error), "[^\r\n]+") do
                table.insert(lines, s)
            end
            
            if #lines > 0 then
                -- Print first line as main error
                print(('      ^1%s^0'):format(lines[1]))
                -- Print trace if useful
                for i = 2, math.min(#lines, 4) do
                    -- Filter out framework internals if possible to make stack cleaner
                    if not string.find(lines[i], "nc-tests/shared/framework") and 
                       not string.find(lines[i], "nc-tests/shared/assertions") then
                        print(('      ^8%s^0'):format(lines[i]:gsub("\t", "  ")))
                    end
                end
            end
        end
    end
end

function Test.Reporter.PrintSummary(results)
    print('')
    print('^5──────────────────────────────────────^0')
    
    local suiteColor = results.suitesFailed > 0 and '^1' or '^2'
    local testColor = results.failed > 0 and '^1' or '^2'
    
    print(('  Suites:  %s%d passed^0, %s%d failed^0, %d total'):format(
        '^2', results.suitesPassed, 
        results.suitesFailed > 0 and '^1' or '^8', results.suitesFailed,
        results.suitesTotal
    ))
    
    print(('  Tests:   %s%d passed^0, %s%d failed^0, %d skipped, %d total'):format(
        '^2', results.passed,
        results.failed > 0 and '^1' or '^8', results.failed,
        results.skipped,
        results.passed + results.failed + results.skipped
    ))
    
    print(('  Time:    %dms'):format(results.totalTime))
    print('^5══════════════════════════════════════^0')
    print('')
end
