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

---@type fun(output_file:string,lines:string[])
local writeToFile = function(output_file, lines)
    local dirname = vim.fn.fnamemodify(output_file, ":p:h")
    vim.fn.mkdir(dirname, "p")
    local file = io.open(output_file, "w")
    if file then
        for _, line in ipairs(lines) do
            file:write(line .. "\n")
        end
        file:close()
    else
        error("Error: Unable to open file " .. output_file)
    end
end

local okHTML, HTML = pcall(require('mkHTML'), vim.g.nixCats_doc_src)
my_assert(okHTML, "unable to load HTML builder" .. vim.inspect(HTML))
---@cast HTML htmlCONSTRUCTOR

local builder = function(name)
    return HTML(name, { number_lines = true }):insertBefore({
        -- NOTE: flex-row was the default before we override things.
        [[<div style="display: flex; flex-direction: row">]],
    }):insertAfter({
        -- NOTE: so we surround body content with a div with the same setting
        [[</div>]]
    }):insertHeaderLines({
        [[<meta name="viewport" content="width=device-width, initial-scale=1" />]],
        [[<meta name="description" content="A Neovim package manager written in Nix for those who prefer to use a normal Neovim directory without missing out.">]],
        [[<script src="./vim-help.js"></script>]],
        [[<style>]],
        [[#nav-links a { color: #1a73e8; text-decoration: none; }]],
        [[#nav-links a:visited { color: #1a73e8; }]],
        [[#nav-links a:hover { color: #155ab6; text-decoration: underline; }]],
        [[#nav-links a:active { color: #003d99; }]],
        [[a.-markup-link { color: #1a73e8; text-decoration: none; }]],
        [[a.-markup-link:visited { color: #1a73e8; }]],
        [[a.-markup-link:hover { color: #155ab6; text-decoration: underline; }]],
        [[a.-markup-link:active { color: #003d99; }]],
        [[a.-label { text-decoration: none; }]],
        [[a.-label:hover { text-decoration: underline; }]],
        [[</style>]],
    }):setBodyStyle(
        [[display: flex; flex-direction: column]]
    ):insertBefore({
        [[<div id="nav-links" style="text-align: center; position: fixed; top: 0; width: 100%; z-index: 1000">]],
        [[<a href="./index.html" style="margin-right: 10px;">HOME</a>]],
        [[<a href="./TOC.html" style="margin-right: 10px;">TOC</a>]],
        [[<a href="https://github.com/BirdeeHub/nixCats-nvim">REPO</a>]],
        [[</div>]],
        [[<vim-help></vim-help>]],
    }):finalize_content("en", false, {
        [ [['rtp']] ] = [[https://neovim.io/doc/user/options.html#'rtp']],
    })
end

for _, name in ipairs({
    "nixCats_installation",
    "nixCats_format",
    "nixCats_luaUtils",
    "nixCats_modules",
    "nixCats_plugin",
    "nixCats_overriding",
    "nix_LSPS",
    "nix_overlays",
}) do
    local ok, converted = pcall(builder, name)
    my_assert(ok and type(converted) == "table" and converted ~= {},
        "HTML builder failed for '" .. name .. "'. Final value was: " .. vim.inspect(converted))
    local iook, msg = pcall(function() writeToFile(vim.g.nixCats_doc_out .. "/" .. name .. ".html", converted) end)
    my_assert(iook, msg)
end

if nixCats('killAfter') then
    vim.schedule(function()
        vim.cmd('qa!')
    end)
end
