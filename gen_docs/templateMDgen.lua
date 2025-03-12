local function write_file(filename, content)
  local file = assert(io.open(filename, "w"))
  file:write(content)
  file:close()
end

local nixinfo = require("nixinfo")
local function toMD(name,description)
  local res = ""
  local link = (name == "default" and "https://github.com/BirdeeHub/nixCats-nvim/tree/main/templates/fresh") or ("https://github.com/BirdeeHub/nixCats-nvim/tree/main/templates/" .. name)
  local initcmd = (name == "default" and "nix flake init -t github:BirdeeHub/nixCats-nvim") or ("nix flake init -t github:BirdeeHub/nixCats-nvim#" .. name)
  res = "# [" .. name .. "](" .. link .. ")\n\n"
  res = res .. "`" .. initcmd .. "`\n\n"
  res = res .. description .. "\n\n"
  return res
end

local order = {
    "default",
    "luaUtils",
    "home-manager",
    "nixos",
    "flakeless",
    "nixExpressionFlakeOutputs",
    "example",
    "kickstart-nvim",
    "LazyVim",
}

local templatetable = {}
for _, v in ipairs(order) do
    table.insert(templatetable, nixinfo.templates[v])
    nixinfo.templates[v] = nil
end
for _, v in pairs(nixinfo.templates) do
  table.insert(templatetable, v)
end

local resmarkdown = ""
for _, v in ipairs(templatetable) do
  resmarkdown = resmarkdown .. toMD(v.name,v.description)
end
resmarkdown = resmarkdown .. [[

---

# Note for `zsh` users:

If using `zsh` with `extendedglob` AND `nomatch` options turned on,
you will need to escape the `#` in Nix Flake commands.

Disabling one or both of them with `unsetopt` is a more long term solution.
]]

write_file(arg[1], resmarkdown)
