local tempdir = arg[1]
local outpath = arg[2]
local nixinfo = require("nixinfo")

local cjson = require('cjson.safe')

-- Function to read a file and return its content
local function read_file(filename)
  local file = assert(io.open(filename, "r"))  -- Open the file for reading
  local content = file:read("*a")  -- Read the entire content
  file:close()  -- Close the file
  return content
end

-- Function to read a file and return its content
local function write_file(filename, content)
  local file = assert(io.open(filename, "w"))  -- Open the file for reading
  file:write(content)  -- Read the entire content
  file:close()  -- Close the file
end

-- Function to load JSON from a file
local function load_json(filename)
  local content = read_file(filename)  -- Read file content
  return cjson.decode(content)  -- Decode JSON into a Lua table
end

local function link_strip(name)
  return string.lower(name:gsub("[^%w%.]", ""))
end

local result = load_json(tempdir.."/tags.json")
for k, v in pairs(nixinfo.templates) do
  result[k] = v
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
