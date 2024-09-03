return function (helptags_path)
    -- TODO: read and parse helptags
    -- for the urls to each tag
    return function (html_lines, filename)
        -- TODO: make vimdoc tag links into links
        -- TODO: make vimdoc headings able to be linked to
        return html_lines
    end
end
