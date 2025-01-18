local nixinfo = require("nixinfo")
function table.values(t)
  local values = {}
  for _, v in pairs(t) do
    table.insert(values, v)
  end
  return values
end
local function toMD(name,path,description)
  local res = ""
  local srclen = #nixinfo.nixCats
  if path:sub(1, srclen) == nixinfo.nixCats then
    local link = "https://github.com/BirdeeHub/nixCats-nvim/tree/main" .. path:sub(srclen + 1)
    local initcmd = "nix flake init -t github.com/BirdeeHub/nixCats-nvim#" .. name
    res = "# [" .. name .. "](" .. link .. ")\n\n"
    res = res .. "`" .. initcmd .. "`\n\n"
    res = res .. description .. "\n\n"
  end
  return res
end
local templatetable = table.values(nixinfo.templates);
local resmarkdown = ""
for _, v in ipairs(templatetable) do
  resmarkdown = resmarkdown .. toMD(v.name,v.path,v.description)
end
print(resmarkdown)
