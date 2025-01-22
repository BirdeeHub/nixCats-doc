-- dark, darker, cool, deep, warm, warmer, light
require('onedark').setup { style = 'darker', }
require('onedark').load()
vim.cmd.colorscheme('onedark')

-- NOTE: make sure all failures exit nvim with a
-- non-zero exit code if killAfter is true
-- so that it actually prints the error
-- instead of just freezing the build
_G.my_assert = function(c, message)
    if not c then
        if nixCats('killAfter') then
            print("assertion failed: " .. message)
            vim.cmd.cquit()
        else
            error("assertion failed: " .. message)
        end
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

local okHTML, HTML, writeToFile = pcall(require('mkHTML'),doc_src)
---@cast HTML htmlCONSTRUCTOR
my_assert(okHTML, "unable to load HTML builder" .. vim.inspect(HTML))

local builder = function(name)
    return HTML(name, { number_lines = true })
        :setBodyStyle([[display: flex; flex-direction: column]])
        :insertManyHeads({
            [[<div id="nav-links" style="text-align: center;">]],
            [[<style>]],
            [[#nav-links a { color: #1a73e8; text-decoration: none; }]],
            [[#nav-links a:visited { color: #1a73e8; }]],
            [[#nav-links a:hover { color: #155ab6; text-decoration: underline; }]],
            [[#nav-links a:active { color: #003d99; }]],
            [[</style>]],
            [[<a href="./index.html" style="margin-right: 10px;">HOME</a>]],
            [[<a href="./TOC.html" style="margin-right: 10px;">TOC</a>]],
            [[<a href="https://github.com/BirdeeHub/nixCats-nvim">REPO</a>]],
            [[</div>]],
            -- NOTE: flex-row was the default before we overrode things.
            [[<div style="display: flex; flex-direction: row">]],
        }):insertManyTails({
            [[</div>]],
        }):finalize_content(false, {
            [ [['rtp']] ] = [[https://neovim.io/doc/user/options.html#'rtp']],
        })
end

for _, name in ipairs(filetable) do
    local ok, converted = pcall(builder, name)
    my_assert(ok, "HTML builder failed: " .. vim.inspect(converted))
    my_assert(type(converted) == "table" and converted ~= {}, "output HTML is empty")
    local iook, msg = writeToFile(doc_out .. "/" .. name .. ".html", converted)
    if iook then print(msg) end
    my_assert(iook, msg)
end

if nixCats('killAfter') then
    vim.schedule(function()
        vim.cmd('qa!')
    end)
end
