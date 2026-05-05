--[[
    NativeCore — Utility Functions
    Pure helpers with no side effects. No dependency on natives.
]]

NCUtils = {}

--- Generate a UUID v4 string.
--- @return string uuid in format 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
function NCUtils.UUID()
    local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function(c)
        local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format('%x', v)
    end)
end

--- Deep copy a table (handles nested tables, avoids metatables).
--- @param tbl table
--- @return table copy
function NCUtils.DeepCopy(tbl)
    if type(tbl) ~= 'table' then return tbl end
    local copy = {}
    for k, v in pairs(tbl) do
        copy[NCUtils.DeepCopy(k)] = NCUtils.DeepCopy(v)
    end
    return copy
end

--- Merge source table into target recursively (source wins on conflict).
--- @param target table
--- @param source table
--- @return table target (mutated)
function NCUtils.TableMerge(target, source)
    if type(target) ~= 'table' or type(source) ~= 'table' then
        return source
    end
    for k, v in pairs(source) do
        if type(v) == 'table' and type(target[k]) == 'table' then
            NCUtils.TableMerge(target[k], v)
        else
            target[k] = v
        end
    end
    return target
end

--- Safe function call with error capture.
--- @param fn function
--- @return boolean success, any result_or_error
function NCUtils.SafeCall(fn, ...)
    if type(fn) ~= 'function' then
        return false, 'SafeCall: expected function, got ' .. type(fn)
    end
    return xpcall(fn, function(err)
        return debug.traceback(err, 2)
    end, ...)
end

--- Create a debounced version of a function.
--- @param fn function
--- @param ms number debounce interval in milliseconds
--- @return function debounced
function NCUtils.Debounce(fn, ms)
    local lastCall = 0
    return function(...)
        local now = GetGameTimer()
        if now - lastCall >= ms then
            lastCall = now
            return fn(...)
        end
    end
end

--- Runtime type check with descriptive error.
--- @param value any
--- @param expected string expected type name
--- @param name string? variable name for error message
--- @return boolean valid
function NCUtils.TypeCheck(value, expected, name)
    local actual = type(value)
    if actual ~= expected then
        error(string.format(
            'Type error: %s expected %s, got %s',
            name or 'value', expected, actual
        ), 2)
    end
    return true
end

--- Get Unix timestamp in seconds.
--- @return number
function NCUtils.Timestamp()
    return os.time()
end

--- Check if a table contains a value.
--- @param tbl table
--- @param val any
--- @return boolean
function NCUtils.TableContains(tbl, val)
    for _, v in pairs(tbl) do
        if v == val then return true end
    end
    return false
end

--- Get table length (for non-sequential tables).
--- @param tbl table
--- @return number
function NCUtils.TableCount(tbl)
    local count = 0
    for _ in pairs(tbl) do count = count + 1 end
    return count
end

--- Split a string by delimiter.
--- @param str string
--- @param sep string delimiter
--- @return table parts
function NCUtils.StringSplit(str, sep)
    local parts = {}
    for part in string.gmatch(str, '([^' .. sep .. ']+)') do
        parts[#parts + 1] = part
    end
    return parts
end

--- Access nested table value via dot notation path.
--- @param tbl table
--- @param path string e.g. 'database.host'
--- @return any value or nil
function NCUtils.GetNestedValue(tbl, path)
    local current = tbl
    for _, key in ipairs(NCUtils.StringSplit(path, '.')) do
        if type(current) ~= 'table' then return nil end
        current = current[key]
    end
    return current
end

--- Set nested table value via dot notation path (creates intermediate tables).
--- @param tbl table
--- @param path string
--- @param value any
function NCUtils.SetNestedValue(tbl, path, value)
    local keys = NCUtils.StringSplit(path, '.')
    local current = tbl
    for i = 1, #keys - 1 do
        local key = keys[i]
        if type(current[key]) ~= 'table' then
            current[key] = {}
        end
        current = current[key]
    end
    current[keys[#keys]] = value
end
