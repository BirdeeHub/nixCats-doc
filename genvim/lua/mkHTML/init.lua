local M = {}

local doc_src = vim.g.nixCats_doc_src
local tohtml = require('tohtml').tohtml

local linkLines = {
    [[<body style="display: flex; flex-direction: column">]],
    [[<div style="text-align: center;">]],
    [[<style>]],
    [[a { color: #1a73e8; text-decoration: none; }]],
    [[a:visited { color: #1a73e8; }]],
    [[a:hover { color: #155ab6; text-decoration: underline; }]],
    [[a:active { color: #003d99; }]],
    [[</style>]],
    [[<a href="./index.html" style="margin-right: 10px;">HOME</a>]],
    [[<a href="./TOC.html" style="margin-right: 10px;">TOC</a>]],
    [[<a href="https://github.com/BirdeeHub/nixCats-nvim">REPO</a>]],
    [[</div>]],
    [[<div style="flex-direction: row">]],
}

local function getHTMLlines(filename)
    local srcpath = doc_src .. "/" .. filename .. ".txt"
    local buffer = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_buf_call(buffer, function()
        vim.cmd.edit(srcpath)
    end)
    local win = vim.api.nvim_open_win(buffer, true, { split = "above" })
    local htmlopts = { title = filename, number_lines = true }
    return tohtml(win, htmlopts)
end

local function addNavHeader(filelines)

    local body_index = nil
    for i, line in ipairs(filelines) do
        if line:find("<body.*>") then
            body_index = i
            break
        end
    end
    if body_index then
        table.remove(filelines, body_index)
        for i = #linkLines, 1, -1 do
            table.insert(filelines, body_index, linkLines[i])
        end
    end
    local end_body_index = nil
    for i = #filelines, 1, -1 do
        if filelines[i]:find("</body>") then
            end_body_index = i
            break
        end
    end
    if end_body_index then
        table.insert(filelines, end_body_index, "</div>")
    end
    
    return filelines
end

function M.gen_doc_file(filename)
    local filelines = getHTMLlines(filename)

    filelines = addNavHeader(filelines)

    return filelines
end

return M
