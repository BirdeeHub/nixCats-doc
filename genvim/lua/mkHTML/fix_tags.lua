return function (helptags_path)
    -- TODO: read and parse helptags
    -- for the urls to each tag
    -- NOTE: new_tag_root will be false for relative path
    -- string for actual value if provided
    -- will never be called with nil
    return function (html_lines, filename, new_tag_root)
        -- TODO: make vimdoc tag links into links
        -- TODO: make vimdoc headings able to be linked to
        return html_lines
    end
end
