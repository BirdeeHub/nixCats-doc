function os.capture(cmd, trim)
  local f = assert(io.popen(cmd, 'r'), "unable to execute: " .. cmd)
  local s = assert(f:read('*a'), "unable to read output of: " .. cmd)
  f:close()
  if not trim then return s end
  s = string.gsub(s, '^%s+', "")
  s = string.gsub(s, '%s+$', "")
  s = string.gsub(s, '[\n\r]+', ' ')
  return s
end
local cjson = require "cjson.safe"
local path = arg[1]
local nixCatsSrc = arg[2] .. "/"
local templatejson = require "NIX_GenCatTemplateDoc_VALUES.lua"
local templatetable, err = cjson.decode(templatejson)
local resmarkdown = ""
for k, v in pairs(templatetable) do
  if type(v) == "table" then
    if v.path:sub(1, #nixCatsSrc) == nixCatsSrc then
        v.path = "nix flake init -t github.com/BirdeeHub/nixCats-nvim#" .. v.path:sub(#nixCatsSrc + 1)
        resmarkdown = resmarkdown .. "#" .. k .. "\n\n"
        resmarkdown = resmarkdown .. v.path .. "\n\n"
        resmarkdown = resmarkdown .. v.description .. "\n\n"
    end
  end
end
print(resmarkdown)
