local utils = require('cmp_im.utils')

--- Default options
local im_opts = {
    enable = false,
    keyword = [[\l\+]],
    tables = {},
    symbols = {},
    format = function(key, text)
        return vim.fn.printf('%-15S %s', text, key)
    end,
    maxn = 10,
}
--- All IM tables
local im_tbls = nil

local source = {}

function source:is_available()
    return im_opts.enable
end

function source:get_keyword_pattern()
    return im_opts.keyword
end

function source:get_trigger_characters()
    -- stylua: ignore start
    local chars = {'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'}
    -- stylua: ignore end
    for k, _ in pairs(im_opts.symbols) do
        chars[#chars + 1] = k
    end
    return chars
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

--- Match completions from IM tables
--- @param params cmp.SourceCompletionApiParams
local function match_tbls(params)
    local res = {}
    if not im_tbls then
        return res
    end

    local add_item = function(txt, key, val, len)
        local ctx = params.context
        local cur = ctx.cursor
        local ofs = len or (cur.col - params.offset)
        res[#res + 1] = {
            label = im_opts.format(key, val),
            sortText = key,
            filterText = key,
            textEdit = {
                newText = val,
                range = {
                    ['start'] = {
                        line = cur.line,
                        character = cur.character - ofs,
                    },
                    ['end'] = { line = cur.line, character = cur.character },
                },
            },
        }
    end

    local pre = params.context.cursor_before_line
    local sym = vim.fn.strcharpart(pre, vim.fn.strcharlen(pre) - 1)
    local val = im_opts.symbols[sym]
    if val then
        if type(val) == 'table' then
            for _, v in ipairs(val) do
                add_item(sym, sym, v, 1)
            end
        else
            add_item(sym, sym, val, 1)
        end
    else
        local str = string.sub(pre, params.offset)
        for _, tbl in ipairs(im_tbls) do
            tbl:match(add_item, str, im_opts.maxn)
        end
    end
    return res
end

--- Invoke completion
--- @param params cmp.SourceCompletionApiParams
--- @param callback fun(response: lsp.CompletionResponse|nil)
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
    local cmp = require('cmp')
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
