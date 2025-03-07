local tempdir = arg[1]
local outpath = arg[2]
local nixinfo = require("nixinfo")

local cjson = require('cjson.safe')

local function write_file(filename, content)
  local file = assert(io.open(filename, "w"))
  file:write(content)
  file:close()
end

local function load_json(filename)
  local file = assert(io.open(filename, "r"))
  local content = file:read("*a")
  file:close()
  return cjson.decode(content)
end

local function link_strip(name)
  return string.lower(name:gsub("[^%w%.]", ""))
end

local result = nixinfo.templates
for k, v in pairs(load_json(tempdir.."/tags.json")) do
  result[k] = v .. "#" .. k
end
for _, v in ipairs(load_json(tempdir.."/utils.json").entries) do
  result["utils."..v.name] = "./nixCats_utils.html#function-library-nixCats.utils." .. v.name
end

local HMjson = load_json(tempdir.."/HM.json")
local nixosjson = load_json(tempdir.."/nixos.json")
HMjson["_module.args"] = nil
nixosjson["_module.args"] = nil
for k, _ in pairs(HMjson) do
  result["home-manager."..k] = "./nixCats_hm_options.html#" .. link_strip(k)
end
for k, _ in pairs(nixosjson) do
  result["nixos."..k] = "./nixCats_nixos_options.html#" .. link_strip(k)
end

write_file(outpath, cjson.encode(result))
