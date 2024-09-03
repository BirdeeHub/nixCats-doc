-- dark, darker, cool, deep, warm, warmer, light
require('onedark').setup { style = 'dark', }
require('onedark').load()
vim.cmd.colorscheme('onedark')

_G.my_assert = function(c, message)
    if not c then
        print("assertion failed: " .. message)
        vim.cmd.cquit("1")
    end
end

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

local doc_out = vim.g.nixCats_doc_out
local doc_src = vim.g.nixCats_doc_src

local HTML, writeToFile = require('mkHTML')(doc_src)
---@cast HTML htmlCONSTRUCTOR

for _, name in ipairs(filetable) do
    local converted = HTML(name, { number_lines = true })
        :setBodyStyle([[display: flex; flex-direction: column]])
        :insertManyHeads({
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
            -- NOTE: flex-row was the default before we overrode things.
            [[<div style="display: flex; flex-direction: row">]],
        }):insertManyTails({
            [[</div>]],
        }):get_content(false)

    local ok, msg = writeToFile(doc_out .. "/" .. name .. ".html", converted)
    print(msg)
    if not ok and nixCats("killAfter") then
        vim.cmd.cquit("1")
    end
end

if nixCats('killAfter') then
    vim.schedule(function()
        vim.cmd('qa!')
    end)
end
