--[[
    NativeCore — Config System
    Hierarchical configuration loader with dot-notation access.
    Loads files from configs/ directory and caches them in memory.
]]

NCConfig = {}

local _cache   = {}
local _frozen  = false
local _loaded  = false

--- Load a specific config file from configs/ directory.
--- @param name string config filename without extension (e.g. 'core')
--- @return table|nil config data
function NCConfig.Load(name)
    local path = ('configs/%s.lua'):format(name)
    local chunk, err = load(LoadResourceFile(GetCurrentResourceName(), path), path)
    if not chunk then
        print(('[^1NC Config^0] Failed to load %s: %s'):format(path, err or 'unknown'))
        return nil
    end

    local ok, data = NCUtils.SafeCall(chunk)
    if not ok or type(data) ~= 'table' then
        print(('[^1NC Config^0] Invalid config %s: must return a table'):format(path))
        return nil
    end

    _cache[name] = data
    return data
end

--- Load all default configs (core, database).
function NCConfig.LoadAll()
    if _loaded then return end
    NCConfig.Load('core')
    NCConfig.Load('database')
    NCConfig.Load('tests')
    _loaded = true
end

--- Get a config value by dot-notation path.
--- @param path string e.g. 'core.LogLevel' or 'database.Adapter'
--- @param default any? fallback value if path not found
--- @return any value
function NCConfig.Get(path, default)
    if not _loaded then NCConfig.LoadAll() end

    local value = NCUtils.GetNestedValue(_cache, path)
    if value == nil then return default end
    return value
end

--- Set a config value at runtime (will not persist to file).
--- @param path string dot-notation path
--- @param value any
--- @return boolean success
function NCConfig.Set(path, value)
    if _frozen then
        print('[^1NC Config^0] Cannot modify frozen config')
        return false
    end
    if not _loaded then NCConfig.LoadAll() end

    NCUtils.SetNestedValue(_cache, path, value)
    return true
end

--- Freeze config to prevent runtime modifications.
function NCConfig.Freeze()
    _frozen = true
end

--- Check if config is frozen.
--- @return boolean
function NCConfig.IsFrozen()
    return _frozen
end

--- Get entire config namespace as table (deep copy to prevent mutation).
--- @param namespace string e.g. 'core', 'database'
--- @return table|nil
function NCConfig.GetNamespace(namespace)
    if not _loaded then NCConfig.LoadAll() end
    local ns = _cache[namespace]
    if ns then return NCUtils.DeepCopy(ns) end
    return nil
end

--- Reset config cache (useful for testing).
function NCConfig.Reset()
    _cache = {}
    _frozen = false
    _loaded = false
end
