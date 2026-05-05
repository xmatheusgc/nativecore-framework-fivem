fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'nativecore'
author 'NativeCore Team'
description 'Modular FiveM Framework — Core'
version '0.1.0'

-- Shared scripts (loaded on both client and server, in order)
shared_scripts {
    'shared/constants.lua',
    'shared/utils.lua',
    'shared/config.lua',
    'shared/logger.lua',
}

-- Server scripts
server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/db.lua',
    'server/db_builder.lua',
    'server/migrations.lua',
    'server/events.lua',
    'server/callbacks.lua',
    'server/state.lua',
    'server/identity.lua',
    'server/player.lua',
    'server/modules.lua',
    'server/main.lua',
}

-- Client scripts
client_scripts {
    'client/events.lua',
    'client/callbacks.lua',
    'client/state.lua',
    'client/player.lua',
    'client/main.lua',
}

-- Files accessible to client (for import)
files {
    'import.lua',
    'configs/*.lua',
}

-- Allow modules to depend on this resource
provide 'nativecore'

-- Dependencies
dependencies {
    'oxmysql',
}
