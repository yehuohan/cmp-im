local M = {}

--- @class IMTable
--- {
---     lst = {
---         { 'a', '工', '或', '戈' }， -- key = [1], values = [2:]
---         ...
---     },
---     inv = {
---         a = 1, -- lst[inv.a] = { 'a', ... }
---     }
--- }
--- @field lst table IM key-values list
--- @field inv table|nil Inverted `lst`
---
--- @field valid fun(): boolean Check IMTable.lst has key-values
--- @field ordered fun(): boolean Check IMTable.lst is ascending or not
--- @field match fun(item:AddItem, key:string, maxn:integer) Add the matched IM key-value as completion item

--- @alias AddItem fun(txt:string, key:string, val:string):table

local T = {}

function T.valid(self)
    return #self.lst > 0
end

function T.ordered(self)
    return self.inv
end

--- @param lst IMTable.lst
local function search(lst, key)
    local lo = 1
    local hi = #lst
    while lo < hi do
        local mi = math.floor((lo + hi) / 2)
        if vim.stricmp(key, lst[mi][1]) > 0 then
            lo = mi + 1 -- Make sure lst[lo] >= key
        else
            hi = mi
        end
    end
    local idx = lo
    if string.match(lst[idx][1], '^' .. key) then
        return idx
    end
    return nil
end

--- Search the IM-key within IMTable.lst
--- Return lst index of IM-key that:
---     lst[index - 1].key < lst[index].key
--- and lst[index + 1].key >= lst[index].key
--- and lst[index + 1].key =~# '^' .. lst[index].key
--- @param key string IM-key
--- @return integer|nil idx
function T.index(self, key)
    local idx = self.inv[key]
    if not idx then
        idx = search(self.lst, key)
    end
    return idx
end

--- Match IM-key within IMTable.lst
--- @param add_item AddItem
--- @param txt string The text to match IM-key
function T.match(self, add_item, txt, maxn)
    local cnt = 0
    if self:ordered() then
        -- Match start from idx
        local idx = self:index(txt)
        if idx then
            repeat
                local kvs = self.lst[idx + cnt]
                if (not kvs) or (not string.match(kvs[1], '^' .. txt)) then
                    break
                end
                for i = 2, #kvs do
                    add_item(txt, kvs[1], kvs[i])
                    cnt = cnt + 1
                    if cnt >= maxn then
                        break
                    end
                end
            until cnt >= maxn
        end
    else
        -- A brute force match that still provides a pretty acceptable performance!(Yes, luajit)
        for _, kvs in ipairs(self.lst) do
            if string.match(kvs[1], '^' .. txt) then
                for i = 2, #kvs do
                    add_item(txt, kvs[1], kvs[i])
                    cnt = cnt + 1
                    if cnt >= maxn then
                        break
                    end
                end
                if cnt >= maxn then
                    break
                end
            end
        end
    end
end

--- String split with space by default
---
--- ```lua
---     { 'a', '工', '或', '戈' } = split('a 工 或 戈')
--- ```
---
--- @param line string One line string separated with `sep`
--- @param sep string|nil
--- @return string[] list
local function split(line, sep)
    if not sep then
        sep = '%S+'
    end
    local list = {}
    for ele in string.gmatch(line, sep) do
        list[#list + 1] = ele
    end
    return list
end

--- Load IM table
--- @param filename string
--- @return IMTable
function M.load_tbl(filename)
    local fp = io.open(filename, 'r')
    local lst = {}
    local inv = {}
    local last = nil
    local order = true

    if fp then
        local line = fp:read()
        while line do
            local parts = split(line)
            if #parts >= 2 then
                lst[#lst + 1] = parts

                local key = parts[1]
                if not inv[key] then
                    inv[key] = #lst
                end

                if order then
                    if last and vim.stricmp(last, key) > 0 then
                        order = false
                    end
                end
                last = key
            end
            line = fp:read()
        end
    end
    if not order then
        inv = nil
    end

    --- @type IMTable
    local res = setmetatable({ lst = lst, inv = inv }, { __index = T })

    return res
end

return M
