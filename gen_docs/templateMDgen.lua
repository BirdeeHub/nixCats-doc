local nixinfo = require("nixinfo")
local function toMD(name,path,description)
  local res = ""
  local srclen = #nixinfo.nixCats
  if path:sub(1, srclen) == nixinfo.nixCats then
    local link = "https://github.com/BirdeeHub/nixCats-nvim/tree/main" .. path:sub(srclen + 1)
    local initcmd = "nix flake init -t github:BirdeeHub/nixCats-nvim#" .. name
    res = "# [" .. name .. "](" .. link .. ")\n\n"
    res = res .. "`" .. initcmd .. "`\n\n"
    res = res .. description .. "\n\n"
  end
  return res
end

local order = {
    "default",
    "luaUtils",
    "home-manager",
    "nixos",
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
  resmarkdown = resmarkdown .. toMD(v.name,v.path,v.description)
end
print(resmarkdown)
