--[[
    NativeCore — Constants & Enums
    Defines framework-wide constants used by all subsystems.
]]

NC_VERSION = '0.1.0'
NC_NAME    = 'NativeCore'
NC_PREFIX  = 'nc'

--- Log level enum (higher = more severe)
NC_LOG_LEVEL = {
    DEBUG = 1,
    INFO  = 2,
    WARN  = 3,
    ERROR = 4,
}

--- Module lifecycle states
NC_MODULE_STATE = {
    REGISTERED = 'registered',
    LOADING    = 'loading',
    READY      = 'ready',
    ERROR      = 'error',
    STOPPED    = 'stopped',
}

--- Player session states
NC_PLAYER_STATE = {
    CONNECTING    = 'connecting',
    LOADING       = 'loading',
    LOADED        = 'loaded',
    DISCONNECTING = 'disconnecting',
}

--- Event namespace prefix
NC_EVENT_PREFIX = 'nc:'

--- Callback event prefixes
NC_CALLBACK_PREFIX     = 'nc:cb:req:'
NC_CALLBACK_RESPONSE   = 'nc:cb:res'

--- State bag namespace
NC_STATE_PREFIX = 'nc:'
