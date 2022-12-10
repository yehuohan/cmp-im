local M = {}

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
    local tbls = {}

    if fp then
        local line = fp:read()
        while line do
            local parts = split(line)
            if #parts == 2 then
                tbls[#tbls+1] = parts
            elseif #parts > 2 then
                local tk = parts[1]
                for i, tv in ipairs(parts) do
                    if i > 1 then
                        tbls[#tbls+1] = { tk, tv }
                    end
                end
            end
            line = fp:read()
        end
    end

    return tbls
end

return M
