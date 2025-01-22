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
        -- NOTE: dont forget to replact .txt with .html!
        table.insert(tags, {symbol = entry[1], file = string.sub(entry[2],1,-5) .. ".html", heading = entry[3]})
    end
    -- NOTE: new_tag_root will be false for relative path
    -- string for actual value if provided
    -- will never be called with nil
    return function (html_lines, new_tag_root, extraHelp)
        for i, line in ipairs(html_lines) do
            for match in line:gmatch([[<span class="%-label"></span><span class="%-label">(.-)</span><span class="%-label"></span>]]) do
                local matchname = tagToFile(match)
                my_assert(matchname ~= nil, "no tag found for heading: " .. vim.inspect(match))
                local linkpath = (new_tag_root or ".") .. "/" .. (matchname or "") .. [[#]] .. match
                local subbed = string.gsub(line,
                    [[<span class="%-label"></span><span class="%-label">.-</span><span class="%-label"></span>]],
                    [[<span class="-label"></span><a href="]] .. linkpath .. [[" class="%-label" id="]] .. match .. [[">]] .. match .. [[</a><span class="-label"></span>]]
                )
                html_lines[i] = subbed
            end
            for match in line:gmatch([[<span class="%-markup%-link"></span><span class="%-markup%-link">(.-)</span><span class="%-markup%-link"></span>]]) do
                local matchname = tagToFile(match)
                local linkpath
                if matchname == nil then
                    -- NOTE: we dont have 'rtp' in our list of paths...
                    if vim.list_contains(vim.tbl_keys(extraHelp), match) then
                        linkpath = extraHelp[match]
                    else
                        my_assert(false, "no help found for: " .. vim.inspect(match))
                        goto continue
                    end
                else
                    linkpath = (new_tag_root or ".") .. "/" .. matchname .. [[#]] .. match
                end
                local subbed = string.gsub(line,
                    [[<span class="%-markup%-link"></span><span class="%-markup%-link">.-</span><span class="%-markup%-link"></span>]],
                    [[<span class="-markup-link"></span><a href="]] .. linkpath .. [[" class="-markup-link">]] .. match .. [[</a><span class="-markup-link"></span>]]
                )
                html_lines[i] = subbed
                ::continue::
            end
            for match in line:gmatch([[<span class="Underlined">(.-)</span>]]) do
                local subbed = string.gsub(line,
                    [[<span class="Underlined">.-</span>]],
                    [[<a href="]] .. match .. [[" class="-markup-link">]] .. match .. [[</a>]]
                )
                html_lines[i] = subbed
            end
        end
        return html_lines
    end
end
