require('onedark').setup {
    -- Set a style preset. 'dark' is default.
    style = 'dark', -- dark, darker, cool, deep, warm, warmer, light
}
require('onedark').load()
vim.cmd.colorscheme('onedark')

local doc_out = vim.g.nixCats_doc_out
local doc_src = vim.g.nixCats_doc_src
local tohtml = require('tohtml').tohtml

local function gen_doc_file(filename)
    local srcpath = doc_src .. "/" .. filename .. ".txt"
    local buffer = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_buf_call(buffer, function()
        vim.cmd.edit(srcpath)
    end)
    local win = vim.api.nvim_open_win(buffer, true, { split = "above" })
    local htmlopts = { title = filename, }
    local file = tohtml(win, htmlopts)

    return file
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

local converted = {}

for _, name in pairs(filetable) do
    local outfile = doc_out .. "/" .. name .. ".html"
    converted[outfile] = gen_doc_file(name)
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

vim.schedule(function()
    vim.cmd('qa!')
end)
