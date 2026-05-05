--[[
    NativeCore — Query Builder (Server)
    Lightweight chainable query builder. Compiles to raw SQL + params.
    Uses NCDB.Query/Execute under the hood.
]]

NCDBBuilder = {}

--- Create a new query builder instance.
--- @return table builder instance
function NCDBBuilder.New()
    local self = {
        _type    = nil,
        _table   = nil,
        _columns = {},
        _wheres  = {},
        _params  = {},
        _orderBy = nil,
        _limit   = nil,
        _offset  = nil,
        _joins   = {},
        _sets    = {},
        _values  = {},
    }

    local builder = {}

    function builder:Select(...)
        self._type = 'SELECT'
        local args = { ... }
        if #args == 0 then
            self._columns = { '*' }
        else
            self._columns = args
        end
        return builder
    end

    function builder:InsertInto(tbl)
        self._type = 'INSERT'
        self._table = tbl
        return builder
    end

    function builder:UpdateTable(tbl)
        self._type = 'UPDATE'
        self._table = tbl
        return builder
    end

    function builder:DeleteFrom(tbl)
        self._type = 'DELETE'
        self._table = tbl
        return builder
    end

    function builder:From(tbl)
        self._table = tbl
        return builder
    end

    function builder:Where(column, operator, value)
        self._wheres[#self._wheres + 1] = {
            column   = column,
            operator = operator,
            value    = value,
            logic    = 'AND',
        }
        return builder
    end

    function builder:OrWhere(column, operator, value)
        self._wheres[#self._wheres + 1] = {
            column   = column,
            operator = operator,
            value    = value,
            logic    = 'OR',
        }
        return builder
    end

    function builder:Set(column, value)
        self._sets[#self._sets + 1] = { column = column, value = value }
        return builder
    end

    function builder:Values(data)
        self._values = data
        return builder
    end

    function builder:Join(tbl, on)
        self._joins[#self._joins + 1] = { type = 'INNER', table = tbl, on = on }
        return builder
    end

    function builder:LeftJoin(tbl, on)
        self._joins[#self._joins + 1] = { type = 'LEFT', table = tbl, on = on }
        return builder
    end

    function builder:OrderBy(column, direction)
        self._orderBy = { column = column, direction = (direction or 'ASC'):upper() }
        return builder
    end

    function builder:Limit(n)
        self._limit = n
        return builder
    end

    function builder:Offset(n)
        self._offset = n
        return builder
    end

    --- Compile the builder into SQL string + params array.
    --- @return string sql, table params
    function builder:Build()
        local sql = ''
        local params = {}

        if self._type == 'SELECT' then
            sql = 'SELECT ' .. table.concat(self._columns, ', ')
            sql = sql .. ' FROM ' .. self._table

        elseif self._type == 'INSERT' then
            local cols, placeholders = {}, {}
            for k, v in pairs(self._values) do
                cols[#cols + 1] = ('`%s`'):format(k)
                placeholders[#placeholders + 1] = '?'
                params[#params + 1] = v
            end
            sql = ('INSERT INTO %s (%s) VALUES (%s)'):format(
                self._table,
                table.concat(cols, ', '),
                table.concat(placeholders, ', ')
            )
            return sql, params

        elseif self._type == 'UPDATE' then
            sql = 'UPDATE ' .. self._table .. ' SET '
            local setParts = {}
            for _, s in ipairs(self._sets) do
                setParts[#setParts + 1] = ('`%s` = ?'):format(s.column)
                params[#params + 1] = s.value
            end
            sql = sql .. table.concat(setParts, ', ')

        elseif self._type == 'DELETE' then
            sql = 'DELETE FROM ' .. self._table
        end

        -- Joins (SELECT only)
        if self._type == 'SELECT' then
            for _, j in ipairs(self._joins) do
                sql = sql .. (' %s JOIN %s ON %s'):format(j.type, j.table, j.on)
            end
        end

        -- Where clauses
        if #self._wheres > 0 then
            sql = sql .. ' WHERE '
            for i, w in ipairs(self._wheres) do
                if i > 1 then
                    sql = sql .. (' %s '):format(w.logic)
                end
                sql = sql .. ('`%s` %s ?'):format(w.column, w.operator)
                params[#params + 1] = w.value
            end
        end

        -- Order
        if self._orderBy then
            sql = sql .. (' ORDER BY `%s` %s'):format(
                self._orderBy.column,
                self._orderBy.direction
            )
        end

        -- Limit / Offset
        if self._limit then
            sql = sql .. ' LIMIT ' .. self._limit
        end
        if self._offset then
            sql = sql .. ' OFFSET ' .. self._offset
        end

        return sql, params
    end

    --- Build and execute the query, returning the result.
    --- @return any result
    function builder:Execute()
        local sql, params = builder:Build()

        if self._type == 'SELECT' then
            if self._limit == 1 then
                return NCDB.Single(sql, params)
            end
            return NCDB.Query(sql, params)
        elseif self._type == 'INSERT' then
            return NCDB.Insert(sql, params)
        elseif self._type == 'UPDATE' then
            return NCDB.Update(sql, params)
        elseif self._type == 'DELETE' then
            return NCDB.Update(sql, params)
        end
    end

    return builder
end

--- Shorthand: NCDB.Builder() creates a new builder instance.
function NCDB.Builder()
    return NCDBBuilder.New()
end
