local M = {}

function M.gen_doc_file(filename)
    return require('mkHTML.HtmlClass')(filename)
        :setBodyStyle([[display: flex; flex-direction: column]])
        :insertManyHeads({
            [[<div style="text-align: center;">]],
            [[<style>]],
            [[a { color: #1a73e8; text-decoration: none; }]],
            [[a:visited { color: #1a73e8; }]],
            [[a:hover { color: #155ab6; text-decoration: underline; }]],
            [[a:active { color: #003d99; }]],
            [[</style>]],
            [[<a href="./index.html" style="margin-right: 10px;">HOME</a>]],
            [[<a href="./TOC.html" style="margin-right: 10px;">TOC</a>]],
            [[<a href="https://github.com/BirdeeHub/nixCats-nvim">REPO</a>]],
            [[</div>]],
            [[<div style="flex-direction: row">]],
        })
        :insertTail("</div>")
        :get_content()
end

return M
