fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'nc-tests'
author 'NativeCore Team'
description 'NativeCore — Automated Test Framework'
version '0.2.0'

dependencies {
    'nativecore',
}

shared_scripts {
    '@nativecore/import.lua',
    'shared/reporter.lua',
    'shared/assertions.lua',
    'shared/spy.lua',
    'shared/framework.lua',
}

server_scripts {
    'server/registry.lua',
    
    -- Core Internal Tests
    'server/tests/test_config.lua',
    'server/tests/test_logger.lua',
    'server/tests/test_events.lua',
    'server/tests/test_state.lua',
    'server/tests/test_db.lua',
    'server/tests/test_player.lua',
    'server/tests/test_callbacks.lua',
    'server/tests/test_modules.lua',
    
    'server/main.lua',
}

-- Make the test registry available
exports {
    'RegisterSuite'
}
