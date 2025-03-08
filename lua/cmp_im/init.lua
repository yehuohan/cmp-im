local cmp = require('cmp')
local utils = require('cmp_im.utils')
local source = {}
---Default options
local im_opts = {
    enable = false,
    keyword = [[\l\+]],
    tables = {},
    format = function(key, text)
        return vim.fn.printf('%-15S %s', text, key)
    end,
    maxn = 8,
}
---All IM tables
local im_tbls = nil

function source:is_available()
    return im_opts.enable
end

function source:get_keyword_pattern()
    return im_opts.keyword
end

function source:get_trigger_characters()
    -- stylua: ignore start
    return { 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z' }
    -- stylua: ignore end
end

local function load_tbls(files)
    if not im_opts.enable then
        return
    end
    if not im_tbls then
        im_tbls = {}
        for _, fn in ipairs(files) do
            local tbl = utils.load_tbl(fn)
            if tbl:valid() then
                im_tbls[#im_tbls + 1] = tbl
            else
                vim.notify(
                    string.format("Failed to load %s as cmp-im's table", fn),
                    vim.log.levels.WARN
                )
            end
        end
    end
end

local function match_tbls(params)
    local res = {}
    if not im_tbls then
        return res
    end

    local add_item = function(txt, key, val)
        local ctx = params.context
        local cur = ctx.cursor
        res[#res + 1] = {
            label = im_opts.format(key, val),
            sortText = key,
            filterText = key,
            textEdit = {
                newText = val,
                range = {
                    ['start'] = {
                        line = cur.line,
                        character = cur.character - (cur.col - params.offset),
                    },
                    ['end'] = { line = cur.line, character = cur.character },
                },
            },
        }
    end

    local str = string.sub(params.context.cursor_before_line, params.offset)
    for _, tbl in ipairs(im_tbls) do
        tbl:match(add_item, str, im_opts.maxn)
    end
    return res
end

function source:complete(params, callback)
    load_tbls(im_opts.tables)
    -- local t0 = vim.fn.reltime()
    local res = match_tbls(params)
    -- vim.notify('Match elapsed: ' .. tostring(vim.fn.reltimestr(vim.fn.reltime(t0))))
    if #res > 0 then
        return callback(res)
    end
    return callback()
end

--- Setup IM's options
local function setup(opts)
    im_opts = vim.tbl_deep_extend('keep', opts, im_opts)
end

--- Enable/Disable IM source
local function toggle()
    im_opts.enable = not im_opts.enable
    return im_opts.enable
end

--- Select the entry from IM
local function select(index)
    return function(fallback)
        if im_opts.enable and cmp.visible() then
            local entries = cmp.get_entries()
            if index and index > 0 then
                local num = 0
                for k, e in ipairs(entries) do
                    if e.source.name == 'IM' then
                        num = num + 1
                        if num >= index then
                            -- `count` works only after `select_next_item()` is called once at least
                            cmp.select_next_item()
                            cmp.select_next_item({ count = k - 1 })
                            return cmp.confirm()
                        end
                    end
                end
            end
            if #entries > 0 and entries[1].source.name == 'IM' then
                return cmp.confirm({ select = true })
            end
        end
        return fallback()
    end
end

return {
    source = source,
    setup = setup,
    toggle = toggle,
    select = select,
}
