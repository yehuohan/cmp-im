local M = {}
local T = { }


function T.valid(self)
    return #self.lst > 0
end

function T.ordered(self)
    return self.inv
end

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

---Search the IM-key within IM table list
---Return lst index of IM-key that:
---     lst[index - 1].key < lst[index].key
--- and lst[index + 1].key >= lst[index].key
--- and lst[index + 1].key =~# '^' .. lst[index].key
function T.index(self, key)
    local idx = self.inv[key]
    if not idx then
        idx = search(self.lst, key)
    end
    return idx
end

---String split with space by default
local function split(line, sep)
    if not sep then
        sep = '%S+'
    end
    local list = {}
    for ele in string.gmatch(line, sep) do
        list[#list+1] = ele
    end
    return list
end

---Load IM table
function M.load_tbl(filename)
    local fp = io.open(filename, 'r')
    local lst = { } -- IM key-values list with key=lst[1] and values = lst[2:]
    local inv = { } -- Inverted lst
    local last = nil
    local order = true

    if fp then
        local line = fp:read()
        while line do
            local parts = split(line)
            if #parts >= 2 then
                lst[#lst+1] = parts

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

    return setmetatable({ lst = lst, inv = inv }, { __index = T })
end

return M
