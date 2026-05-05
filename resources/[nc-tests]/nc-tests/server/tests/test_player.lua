--[[
    Tests — Player Session Manager
]]

Test.Describe('Player', function()
    Test.It('should get player count', function()
        local count = NativeCore.Player.Count()
        Test.Expect(count).ToBeType('number')
    end)

    Test.It('should get all players table', function()
        local all = NativeCore.Player.GetAll()
        Test.Expect(all).ToBeType('table')
    end)

    -- Note: Tests involving specific players require a source, 
    -- but we can test the structure with the first connected player if any
    Test.It('should verify data of first connected player', function()
        local all = NativeCore.Player.GetAll()
        local source, player = next(all)
        
        if source then
            Test.Expect(player).ToHaveKey('uuid')
            Test.Expect(player).ToHaveKey('group')
            Test.Expect(player.state).ToBe('loaded')
        else
            print('      (Skipping: no players online)')
        end
    end)
end)
