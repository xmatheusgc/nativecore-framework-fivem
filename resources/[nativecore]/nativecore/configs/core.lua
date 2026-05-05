return {
    Debug = false,
    LogLevel = 'INFO',
    Locale = 'pt-BR',

    -- Player session
    AutoSaveInterval = 300,  -- seconds (5 min)
    DefaultGroup = 'user',
    DefaultSpawn = { x = -269.4, y = -955.3, z = 31.2, heading = 205.0 },

    -- Identity resolution
    IdentityPriority = { 'license', 'fivem', 'steam', 'discord' },

    -- Callbacks
    MaxCallbackTimeout = 10000,  -- ms
    CallbackRateLimit = 20,      -- max calls/sec per player

    -- Modules
    ModuleLoadTimeout = 15000,   -- ms to wait for a module to load
}
