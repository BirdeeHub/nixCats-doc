require('onedark').setup {
    -- Set a style preset. 'dark' is default.
    style = 'dark', -- dark, darker, cool, deep, warm, warmer, light
}
require('onedark').load()
vim.cmd.colorscheme('onedark')

require("todo-comments").setup({ signs = false })

local doc_out = vim.g.nixCats_doc_out
local doc_src = vim.g.nixCats_doc_src

local function gen_doc_file(filename)
    local srcpath = doc_src .. "/" .. filename .. ".txt"
    local editcmd = vim.api.nvim_replace_termcodes(":e " .. srcpath .. "<cr>", true, false, true)
    vim.api.nvim_feedkeys(editcmd, 'n', false)
    vim.cmd('redraw')
    vim.cmd('sleep 100m')

    local outpath = doc_out .. "/" .. filename .. ".html"
    local gencmd = vim.api.nvim_replace_termcodes(":TOhtml " .. outpath .. "<cr>", true, false, true)
    vim.api.nvim_feedkeys(gencmd, 'n', false)
    vim.cmd('redraw')
    vim.cmd('sleep 100m')
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

for _, v in pairs(filetable) do
    gen_doc_file(v)
end

-- wait for all that to finish:

local uv = vim.loop

-- Start a new thread
-- otherwise it would block all the TOhtml stuff
local function start_thread()
  -- Create a new timer
  local timer = uv.new_timer()

  -- Wait for 10 seconds (10000 milliseconds), then close Neovim
  timer:start(10000, 0, function()
    timer:stop()
    timer:close()
    -- schedule it because you cant call this in a vim.loop space
    vim.schedule(function()
      vim.cmd('qa!')
    end)
  end)
end

-- Run the thread
start_thread()
