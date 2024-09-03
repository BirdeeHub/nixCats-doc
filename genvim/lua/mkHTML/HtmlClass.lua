local doc_src = vim.g.nixCats_doc_src
local tohtml = require('tohtml').tohtml

---@class htmlClass
---@field content string[]
---@field body_style string
---@field filename string
---@field body_index number
---@field end_body_index number
---
---@field setBodyStyle fun(self:htmlClass, style:string):htmlClass
---@field fixBdyInx fun(self:htmlClass):htmlClass
---@field fixEndBdyInx fun(self:htmlClass):htmlClass
---@field insertHead fun(self:htmlClass, line:string):htmlClass
---@field insertTail fun(self:htmlClass, line:string):htmlClass
---@field insertManyHeads fun(self:htmlClass, lines:string[]):htmlClass
---@field insertManyTails fun(self:htmlClass, lines:string[]):htmlClass
---
---@field get_content fun(self:htmlClass):string[]

---@param target_filename string
---@param body_style string?
---@return htmlClass
local function HTMLclass(target_filename, body_style)
    local function getHTMLlines(fname)
        assert(fname ~= nil and fname ~= "", "cannot get html lines without a filename")

        local srcpath = doc_src .. "/" .. fname .. ".txt"
        local buffer = vim.api.nvim_create_buf(true, false)
        vim.api.nvim_buf_call(buffer, function()
            vim.cmd.edit(srcpath)
        end)
        local win = vim.api.nvim_open_win(buffer, true, { split = "above" })
        local htmlopts = { title = fname, number_lines = true }
        return tohtml(win, htmlopts)
    end
    local function getBdyInx(filelines)
        for i, line in ipairs(filelines) do
            if line:find("<body.*>") then
                if body_style then
                    table.remove(filelines, i)
                    table.insert(filelines, i, [[<body style="]] .. body_style .. [[">]])
                end
                return i
            end
        end
    end
    local function getEndBdyInx(filelines)
        for i = #filelines, 1, -1 do
            if filelines[i]:find("</body>") then
                return i
            end
        end
    end
    local content = getHTMLlines(target_filename)
    local body_index = getBdyInx(content)
    local end_body_index = getEndBdyInx(content)
    local bodystyle = type(body_style) == "string" and body_style or ""

    return vim.deepcopy({
        filename = target_filename,
        content = content,
        body_index = body_index,
        end_body_index = end_body_index,
        body_style = bodystyle,
        get_content = function(self)
            --TODO: call a fix ctags function
            -- here if you can make one maybe?
            return vim.deepcopy(self.content)
        end,
        fixBdyInx = function(self)
            assert(content ~= {}, "error: empty contents")
            self.body_index = getBdyInx(self.content)
            return self
        end,
        fixEndBdyInx = function(self)
            assert(content ~= {}, "error: empty contents")
            self.end_body_index = getEndBdyInx(self.content)
            return self
        end,
        setBodyStyle = function(self, style)
            self.body_style = style
            table.remove(self.content, self.body_index)
            table.insert(self.content, self.body_index, [[<body style="]] .. style .. [[">]])
            return self
        end,
        insertHead = function(self, line)
            table.insert(self.content, self.body_index + 1, line)
            self.end_body_index = self.end_body_index + 1
            return self
        end,
        insertManyHeads = function(self, lines)
            for i = #lines, 1, -1 do
                self:insertHead(lines[i])
            end
            return self
        end,
        insertTail = function(self, line)
            table.insert(content, end_body_index, line)
            return self
        end,
        insertManyTails = function(self, lines)
            for i = #lines, 1, -1 do
                self:insertTail(lines[i])
            end
            return self
        end,
    })
end

return HTMLclass
