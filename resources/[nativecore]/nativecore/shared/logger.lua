--[[
    NativeCore — Logger
    Structured logger with levels, module tagging, and spam suppression.
    Output format: [NC] [LEVEL] [module] message {context}
]]

NCLogger = {}

local _levelNames = { 'DEBUG', 'INFO', 'WARN', 'ERROR' }
local _levelColors = {
    [1] = '^5',  -- DEBUG = cyan
    [2] = '^2',  -- INFO  = green
    [3] = '^3',  -- WARN  = yellow
    [4] = '^1',  -- ERROR = red
}

local _lastMessage  = nil
local _repeatCount  = 0
local _maxRepeat    = 5  -- after N repeats, suppress and show count

--- Resolve the configured minimum log level.
--- @return number level enum value
local function getMinLevel()
    local name = NCConfig.Get('core.LogLevel', 'INFO')
    return NC_LOG_LEVEL[name] or NC_LOG_LEVEL.INFO
end

--- Format context table as key=value string.
--- @param ctx table?
--- @return string
local function formatContext(ctx)
    if not ctx or type(ctx) ~= 'table' then return '' end
    local parts = {}
    for k, v in pairs(ctx) do
        parts[#parts + 1] = ('%s=%s'):format(tostring(k), tostring(v))
    end
    if #parts == 0 then return '' end
    return ' {' .. table.concat(parts, ', ') .. '}'
end

--- Internal log function with spam suppression.
--- @param level number NC_LOG_LEVEL value
--- @param module string module/subsystem name
--- @param msg string stable message string
--- @param ctx table? structured context data
local function log(level, module, msg, ctx)
    if level < getMinLevel() then return end

    local signature = ('%d:%s:%s'):format(level, module, msg)

    -- Spam suppression
    if signature == _lastMessage then
        _repeatCount = _repeatCount + 1
        if _repeatCount > _maxRepeat then
            return -- suppressed
        elseif _repeatCount == _maxRepeat then
            print(('[^7NC^0] [%s%s^0] [%s] ... repeated %d times (suppressing)')
                :format(_levelColors[level], _levelNames[level], module, _repeatCount))
            return
        end
    else
        _lastMessage = signature
        _repeatCount = 0
    end

    local contextStr = formatContext(ctx)
    print(('[^7NC^0] [%s%s^0] [%s] %s%s')
        :format(_levelColors[level], _levelNames[level], module, msg, contextStr))
end

--- Log at DEBUG level.
--- @param module string
--- @param msg string
--- @param ctx table?
function NCLogger.Debug(module, msg, ctx)
    log(NC_LOG_LEVEL.DEBUG, module, msg, ctx)
end

--- Log at INFO level.
--- @param module string
--- @param msg string
--- @param ctx table?
function NCLogger.Info(module, msg, ctx)
    log(NC_LOG_LEVEL.INFO, module, msg, ctx)
end

--- Log at WARN level.
--- @param module string
--- @param msg string
--- @param ctx table?
function NCLogger.Warn(module, msg, ctx)
    log(NC_LOG_LEVEL.WARN, module, msg, ctx)
end

--- Log at ERROR level.
--- @param module string
--- @param msg string
--- @param ctx table?
function NCLogger.Error(module, msg, ctx)
    log(NC_LOG_LEVEL.ERROR, module, msg, ctx)
end
