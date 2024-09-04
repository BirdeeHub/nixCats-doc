---@class htmlClass
---NOTE: private fields, do not set directly!
---@field content string[]
---@field body_style string?
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
---new_tag_root should be a string
---OR false for relative path
---OR nil to not fix tags
---@field get_content fun(self:htmlClass,new_tag_root?:string|false):string[]

---HTML(filename):setBodyStyle(styleString)
---:insertHead(head):insertTail(tail)
---:insertManyHeads(headlist):insertManyTails(endlist)
---:get_content(new_tag_root)
---head and tail are at beginning and end of BODY
---@alias htmlCONSTRUCTOR fun(target_filename:string, opts?:html_opts):htmlClass

---@class html_opts
---@field number_lines boolean
---@field font string[]|string
---@field width integer
---@field range integer[]

local tohtml = require('tohtml').tohtml

---@param doc_src string
---@return fun(target_filename:string, opts?:html_opts):htmlClass
---@return fun(output_file:string,lines:string[]):boolean,string
local function getConstructor(doc_src)
    local fix_tags = require("mkHTML.fix_tags")(doc_src .. "/tags")

    ---@param target_filename string
    ---@param opts html_opts?
    ---@return htmlClass
    local function HTML(target_filename, opts)
        local function getHTMLlines(fname)
            my_assert(type(fname) == "string" and fname ~= "", "cannot get html lines without a filename")

            local srcpath = doc_src .. "/" .. fname .. ".txt"
            local buffer = vim.api.nvim_create_buf(true, false)
            vim.api.nvim_buf_call(buffer, function()
                local ok = pcall(vim.cmd.edit,srcpath)
                my_assert(ok, "error: unable to open " .. srcpath)
            end)
            local win = vim.api.nvim_open_win(buffer, true, { split = "above" })
            local htmlopts = vim.tbl_extend("force", opts or {}, { title = fname })
            return tohtml(win, htmlopts)
        end
        local function getBdyInx(filelines)
            if #filelines == 0 then
                return nil
            end
            for i, line in ipairs(filelines) do
                if line:find("<body.*>") then
                    return i
                end
            end
            my_assert(false, "error: no start of body")
        end
        local function getEndBdyInx(filelines)
            if #filelines == 0 then
                return nil
            end
            for i = #filelines, 1, -1 do
                if filelines[i]:find("</body>") then
                    return i
                end
            end
            my_assert(false, "error: no end of body")
        end
        local content = getHTMLlines(target_filename)
        my_assert(type(content) == "table" and content ~= {}, "error: empty content")

        return vim.deepcopy({
            filename = target_filename,
            content = content,
            body_index = getBdyInx(content),
            end_body_index = getEndBdyInx(content),
            body_style = nil,
            get_content = function(self, new_tag_root)
                if new_tag_root then
                    return fix_tags(vim.deepcopy(self.content), self.filename, new_tag_root)
                elseif new_tag_root == false then
                    return fix_tags(vim.deepcopy(self.content), self.filename, false)
                else
                    return vim.deepcopy(self.content)
                end
            end,
            fixBdyInx = function(self)
                my_assert(type(self.content) == "table" and self.content ~= {}, "error: empty contents")
                self.body_index = getBdyInx(self.content)
                return self
            end,
            fixEndBdyInx = function(self)
                my_assert(type(self.content) == "table" and self.content ~= {}, "error: empty contents")
                self.end_body_index = getEndBdyInx(self.content)
                return self
            end,
            setBodyStyle = function(self, style)
                my_assert(self.body_index > 0, "error: empty contents")
                self.body_style = style
                table.remove(self.content, self.body_index)
                table.insert(self.content, self.body_index, [[<body style="]] .. style .. [[">]])
                return self
            end,
            insertHead = function(self, line)
                my_assert(self.body_index > 0, "error: empty contents")
                my_assert(self.end_body_index > 0, "error: empty contents")
                table.insert(self.content, self.body_index + 1, line)
                self.end_body_index = self.end_body_index + 1
                return self
            end,
            insertManyHeads = function(self, lines)
                my_assert(#lines > 0, "error: empty contents")
                for i = #lines, 1, -1 do
                    self:insertHead(lines[i])
                end
                return self
            end,
            insertTail = function(self, line)
                my_assert(self.body_index > 0, "error: empty contents")
                my_assert(self.end_body_index > 0, "error: empty contents")
                table.insert(self.content, self.end_body_index, line)
                return self
            end,
            insertManyTails = function(self, lines)
                my_assert(#lines > 0, "error: empty contents")
                for i = #lines, 1, -1 do
                    self:insertTail(lines[i])
                end
                return self
            end,
        })
    end

    local writeToFile = function(output_file, lines)
        local dirname = vim.fn.fnamemodify(output_file, ":p:h")
        vim.fn.mkdir(dirname, "p")
        local file = io.open(output_file, "w")
        if file then
            for _, line in ipairs(lines) do
                file:write(line .. "\n")
            end
            file:close()
            return true, "File written successfully to " .. output_file
        else
            return false, "Error: Unable to open file " .. output_file
        end
    end

    ---@cast HTML htmlCONSTRUCTOR
    return HTML, writeToFile
end

return getConstructor
