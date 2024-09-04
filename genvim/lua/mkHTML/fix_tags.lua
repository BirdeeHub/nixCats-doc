local function read_file_by_lines(filename)
    local lines = {}
    local file = io.open(filename, "r")
    if not file then
        error("Could not open file: " .. filename)
    end
    
    for line in file:lines() do
        table.insert(lines, line)
    end
    
    file:close()
    return lines
end

local function mysplit(inputstr, sep)
  if sep == nil then
    sep = "%s"
  end
  local t = {}
  for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
    table.insert(t, str)
  end
  return t
end

---@class tag_entry
---@field a string
---@field b string
---@field c string

---@type tag_entry[]
local tags = {}

return function (helptags_path)
    local lines = read_file_by_lines(helptags_path)
    for _, line in ipairs(lines) do
        table.insert(tags,mysplit(line, "\t"))
    end
    print(vim.inspect(tags))
    -- NOTE: new_tag_root will be false for relative path
    -- string for actual value if provided
    -- will never be called with nil
    return function (html_lines, filename, new_tag_root)
        -- TODO: make vimdoc tag links into links
        -- TODO: make vimdoc headings able to be linked to
        return html_lines
    end
end
