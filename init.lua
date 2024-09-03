require('onedark').setup {
    -- Set a style preset. 'dark' is default.
    style = 'dark', -- dark, darker, cool, deep, warm, warmer, light
}
require('onedark').load()
vim.cmd.colorscheme('onedark')

local doc_out = vim.g.nixCats_doc_out
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

local function gen_doc_file(filename)
    local srcpath = doc_src .. "/" .. filename .. ".txt"
    local buffer = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_buf_call(buffer, function()
        vim.cmd.edit(srcpath)
    end)
    local win = vim.api.nvim_open_win(buffer, true, { split = "above" })
    local htmlopts = { title = filename, }
    local filelines = tohtml(win, htmlopts)

    -- Find the first occurrence of "<pre>"
    local insert_index = nil
    for i, line in ipairs(filelines) do
        if line:find("</head>") then
            insert_index = i + 1
            break
        end
    end


    -- If "</head>" was found, remove <body ...> line so we can make a header
    if insert_index then
        table.remove(filelines, insert_index)
        for i = #linkLines, 1, -1 do
            table.insert(filelines, insert_index, linkLines[i])
        end
    end

    -- Find the last occurrence of "</body>" and insert a line before it
    local last_body_index = nil
    for i = #filelines, 1, -1 do
        if filelines[i]:find("</body>") then
            last_body_index = i
            break
        end
    end

    -- Insert a line before the last "</body>"
    if last_body_index then
        table.insert(filelines, last_body_index, "</div>")
    end

    return filelines
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
