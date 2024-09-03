require('onedark').setup {
    -- Set a style preset. 'dark' is default.
    style = 'dark', -- dark, darker, cool, deep, warm, warmer, light
}
require('onedark').load()
vim.cmd.colorscheme('onedark')

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

local mkHTML = require('mkHTML')

for _, name in ipairs(filetable) do
    local outfile = doc_out .. "/" .. name .. ".html"
    converted[outfile] = mkHTML.gen_doc_file(name)
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
