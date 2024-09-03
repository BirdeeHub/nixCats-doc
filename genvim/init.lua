require('onedark').setup {
    -- Set a style preset. 'dark' is default.
    style = 'dark', -- dark, darker, cool, deep, warm, warmer, light
}
require('onedark').load()
vim.cmd.colorscheme('onedark')

local html_opts = { number_lines = true }
local bodystyle = [[display: flex; flex-direction: column]]
local linkLines = {
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
local tailLines = {
    "</div>",
}

local filetable = {
    "nixCats_installation",
    "nixCats_format",
    "nixCats_luaUtils",
    "nixCats_modules",
    "nixCats_plugin",
    "nixCats_overriding",
    "nix_LSPS",
    "nix_overlays",
}

local converted = {}

local doc_out = vim.g.nixCats_doc_out
local doc_src = vim.g.nixCats_doc_src

local mkHTML = require('mkHTML')(doc_src)

for _, name in ipairs(filetable) do
    local outfile = doc_out .. "/" .. name .. ".html"
    converted[outfile] = mkHTML(name, html_opts)
        :setBodyStyle(bodystyle)
        :insertManyHeads(linkLines)
        :insertManyTails(tailLines)
        :get_content()
end

for output_file, lines in pairs(converted) do
    local dirname = vim.fn.fnamemodify(output_file, ":p:h")
    vim.fn.mkdir(dirname, "p")
    local file = io.open(output_file, "w")
    if file then
        for _, line in ipairs(lines) do
            file:write(line .. "\n")
        end
        file:close()
        print("File written successfully to " .. output_file)
    else
        print("Error: Unable to open file " .. output_file)
    end
end

if nixCats('killAfter') then
    vim.schedule(function()
        vim.cmd('qa!')
    end)
end
