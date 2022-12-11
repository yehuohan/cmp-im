local cmp = require('cmp')
local utils = require('cmp_im.utils')
local source = { }
---Default options
local im_opts = {
    enable = false,
    tables = { },
    format = function(key, text)
        return vim.fn.printf('%-15S %s', text, key)
    end,
    maxn = 8,
}
---All IM tables
local im_tbls = nil


local function load_tbls(files)
    if not im_tbls then
        im_tbls = {}
        for _, fn in ipairs(files) do
            local tbl = utils.load_tbl(fn)
            if #tbl > 0 then
                im_tbls[#im_tbls+1] = tbl
            else
                vim.notify(string.format("Failed to load %s as cmp-im's table", fn), vim.log.levels.WARN)
            end
        end
    end
end

local function match_tbls(params)
    local res = {}
    if not im_tbls then
        return res
    end

    local ctx = params.context
    local cur = ctx.cursor
    local key = string.sub(ctx.cursor_before_line, params.offset)
    for _, tbl in ipairs(im_tbls) do
        local cnt = 0
        for _, kv in ipairs(tbl) do
            if string.match(kv[1], '^' .. key) then
                cnt = cnt + 1
                local tk = kv[1]
                local tv = kv[2]
                res[#res+1] = {
                    label = im_opts.format(tk, tv),
                    sortText = tk,
                    filterText = tk,
                    textEdit = {
                        newText = tv,
                        insert = {
                            ['start'] = { line = cur.line, character = cur.character - (cur.col - params.offset) },
                            ['end'] = { line = cur.line, character = cur.character },
                        },
                    }
                }
            end

            if cnt >= im_opts.maxn then
                break
            end
        end
    end

    return res
end

function source:is_available()
    return im_opts.enable
end

function source:get_trigger_characters()
    return {'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z'}
end

function source:complete(params, callback)
    load_tbls(im_opts.tables)
    local res = match_tbls(params)
    if #res > 0 then
        return callback(res)
    end
    return callback()
end

---Setup IM's options
local function setup(opts)
    im_opts = vim.tbl_deep_extend('keep', opts, im_opts)
end

---Enable/Disable IM source
local function toggle()
    im_opts.enable = not im_opts.enable
    return im_opts.enable
end

---Select first entry if it's from IM
local function select(fallback)
    local entries = cmp.get_entries()
    if cmp.visible() and #entries > 0 and entries[1].source.name == 'IM' then
        cmp.confirm({ select = true })
    else
        fallback()
    end
end

return {
    source = source,
    setup = setup,
    toggle = toggle,
    select = select,
}
