---@class htmlClass
---@field setBodyStyle fun(self:htmlClass, style:string):htmlClass
---@field insertHeaderLines fun(self:htmlClass, lines:string[]):htmlClass
---@field insertBefore fun(self:htmlClass, lines:string[]):htmlClass
---@field insertAfter fun(self:htmlClass, lines:string[]):htmlClass
---
---new_tag_root should be a string
---OR falsey for relative path
---@field finalize_content fun(self:htmlClass,lang:string,new_tag_root?:string|false,extraHelp?:table<string, string>):string[]

---@class html_opts
---@field number_lines boolean
---@field font string[]|string
---@field width integer
---@field range integer[]

---@alias htmlCONSTRUCTOR fun(target_filename:string, opts?:html_opts):htmlClass

local tohtml = require('tohtml').tohtml

---@param doc_src string
---@return htmlCONSTRUCTOR
return function(doc_src)
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
            local htmlopts = vim.tbl_extend("keep", opts or {}, { title = fname })
            return tohtml(win, htmlopts)
        end
        local function replaceHtmlTag(filelines, lang)
            if #filelines == 0 then
                return
            end
            for i, line in ipairs(filelines) do
                if line:find("<html.*>") then
                    table.remove(filelines, i)
                    table.insert(filelines, i, [[<html lang="]] .. lang .. [[">]])
                    return
                end
            end
            my_assert(false, "error: no start of html")
        end
        local function getHeaderStart(filelines)
            if #filelines == 0 then
                return nil
            end
            for i, line in ipairs(filelines) do
                if line:find("<head.*>") then
                    return i
                end
            end
            my_assert(false, "error: no start of header")
        end
        local function getHeaderEnd(filelines)
            if #filelines == 0 then
                return nil
            end
            for i, line in ipairs(filelines) do
                if line:find("</head>") then
                    return i
                end
            end
            my_assert(false, "error: no end of header")
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

        ---@type htmlClass
        return vim.deepcopy({
            filename = target_filename,
            content = content,
            header_start = getHeaderStart(content),
            header_end = getHeaderEnd(content),
            body_index = getBdyInx(content),
            end_body_index = getEndBdyInx(content),
            body_style = nil,

            finalize_content = function(self, lang, new_tag_root, extraHelp)
                local final_copy = vim.deepcopy(self.content)
                replaceHtmlTag(final_copy, lang)
                if new_tag_root then
                    return fix_tags(final_copy, new_tag_root, extraHelp)
                elseif new_tag_root == false then
                    return fix_tags(final_copy, false, extraHelp)
                else
                    return final_copy
                end
            end,
            setBodyStyle = function(self, style)
                my_assert(self.body_index > 0, "error: empty contents")
                self.body_style = style
                table.remove(self.content, self.body_index)
                table.insert(self.content, self.body_index, [[<body style="]] .. style .. [[">]])
                return self
            end,
            insertHeaderLines = function(self, lines)
                my_assert(#lines > 0, "error: empty contents")
                my_assert(self.header_start > 0, "error: empty contents")
                my_assert(self.header_end > 0, "error: empty contents")
                my_assert(self.body_index > 0, "error: empty contents")
                my_assert(self.end_body_index > 0, "error: empty contents")
                if type(lines) == "table" then
                    local insertat = self.header_end
                    for i = #lines, 1, -1 do
                        table.insert(self.content, insertat, lines[i])
                        self.header_end = self.header_end + 1
                        self.body_index = self.body_index + 1
                        self.end_body_index = self.end_body_index + 1
                    end
                end
                return self
            end,
            insertBefore = function(self, lines)
                my_assert(#lines > 0, "error: empty contents")
                my_assert(self.header_start > 0, "error: empty contents")
                my_assert(self.header_end > 0, "error: empty contents")
                my_assert(self.body_index > 0, "error: empty contents")
                my_assert(self.end_body_index > 0, "error: empty contents")
                if type(lines) == "table" then
                    local insertat = self.body_index + 1
                    for i = #lines, 1, -1 do
                        table.insert(self.content, insertat, lines[i])
                        self.end_body_index = self.end_body_index + 1
                    end
                end
                return self
            end,
            insertAfter = function(self, lines)
                my_assert(#lines > 0, "error: empty contents")
                my_assert(self.header_start > 0, "error: empty contents")
                my_assert(self.header_end > 0, "error: empty contents")
                my_assert(self.body_index > 0, "error: empty contents")
                my_assert(self.end_body_index > 0, "error: empty contents")
                if type(lines) == "table" then
                    local insertat = self.end_body_index
                    for i = #lines, 1, -1 do
                        table.insert(self.content, insertat, lines[i])
                        self.end_body_index = self.end_body_index + 1
                    end
                end
                return self
            end,
        })
    end

    return HTML
end
