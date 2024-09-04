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

local function split(inputstr, sep)
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
---@field symbol string
---@field file string
---@field heading string
---@field path? string

---@type tag_entry[]
local tags = {}

local tagToFile = function (symbol)
    for _, entry in ipairs(tags) do
        if entry.symbol == symbol then
            return entry.file
        end
    end
end

return function (helptags_path)
    local lines = read_file_by_lines(helptags_path)
    for _, line in ipairs(lines) do
        local entry = split(line, "\t")
        table.insert(tags, {symbol = entry[1], file = string.sub(entry[2],1,-5) .. ".html", heading = entry[3]})
    end
    -- NOTE: new_tag_root will be false for relative path
    -- string for actual value if provided
    -- will never be called with nil
    return function (html_lines, filename, new_tag_root)
        for i, line in ipairs(html_lines) do
            for match in line:gmatch([[<span class="%-label"></span><span class="%-label">(.-)</span><span class="%-label"></span>]]) do
                local subbed = string.gsub(line,
                    [[<span class="%-label"></span><span class="%-label">]] .. match .. [[</span><span class="%-label"></span>]],
                    [[<span class="-label"></span><span class="%-label" id="]] .. match .. [[">]] .. match .. [[</span><span class="-label"></span>]]
                )
                html_lines[i] = subbed
            end
            -- TODO: make vimdoc tag links into links to the headings above
            for match in line:gmatch([[<span class="%-markup%-link"></span><span class="%-markup%-link">(.-)</span><span class="%-markup%-link"></span>]]) do
                local matchname = tagToFile(match)
                if matchname == nil then
                    goto continue
                end
                local linkpath = (new_tag_root and new_tag_root or ".") .. "/" .. matchname .. [[#]] .. match
                local subbed = string.gsub(line,
                    [[<span class="%-markup%-link"></span><span class="%-markup%-link">]] .. match .. [[</span><span class="%-markup%-link"></span>]],
                    [[<span class="-markup-link"></span><a href="]] .. linkpath .. [[" class="-markup-link">]] .. match .. [[</a><span class="-markup-link"></span>]]
                )
                html_lines[i] = subbed
                ::continue::
            end
        end
        return html_lines
    end
end
