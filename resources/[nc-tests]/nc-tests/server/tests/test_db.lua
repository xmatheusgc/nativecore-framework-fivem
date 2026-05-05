--[[
    Tests — Database Layer
]]

Test.Describe('Database (DB)', function()
    Test.It('should report ready status', function()
        local ready = NativeCore.DB.Ready()
        Test.Expect(ready).ToBeTrue()
    end)

    Test.It('should execute a simple query', function()
        local rows = NativeCore.DB.Query('SELECT 1 as result')
        Test.Expect(rows).ToBeType('table')
        Test.Expect(#rows).ToBeGreaterThan(0)
        Test.Expect(rows[1].result).ToBe(1)
    end)

    Test.It('should return single row', function()
        local row = NativeCore.DB.Single('SELECT 1 as val')
        Test.Expect(row).ToBeNotNil()
        Test.Expect(row.val).ToBe(1)
    end)

    Test.It('should return scalar value', function()
        local val = NativeCore.DB.Scalar('SELECT 42 as answer')
        Test.Expect(val).ToBe(42)
    end)

    Test.It('should handle parameterized queries', function()
        local row = NativeCore.DB.Single('SELECT ? as echo', { 'hello' })
        Test.Expect(row).ToBeNotNil()
        Test.Expect(row.echo).ToBe('hello')
    end)

    Test.It('should verify nc_users table exists', function()
        local rows = NativeCore.DB.Query(
            "SELECT COUNT(*) as cnt FROM information_schema.tables WHERE table_name = 'nc_users'"
        )
        Test.Expect(rows[1].cnt).ToBeGreaterThan(0)
    end)

    Test.It('should verify nc_identifiers table exists', function()
        local rows = NativeCore.DB.Query(
            "SELECT COUNT(*) as cnt FROM information_schema.tables WHERE table_name = 'nc_identifiers'"
        )
        Test.Expect(rows[1].cnt).ToBeGreaterThan(0)
    end)
end)
