{ APPNAME
, nixCats
, luajit
, writeTextFile
, ...
}:
writeTextFile {
  name = APPNAME;
  text = /*lua*/ ''
    #!${luajit.interpreter}
    function toMD(name,path,description)
      local res = ""
      local srclen = #[[${nixCats}]]
      if path:sub(1, srclen) == [[${nixCats}]] then
        local link = "https://github.com/BirdeeHub/nixCats-nvim/tree/main" .. path:sub(srclen + 1)
        local initcmd = "nix flake init -t github.com/BirdeeHub/nixCats-nvim#" .. name
        res = "# [" .. name .. "](" .. link .. ")\n\n"
        res = res .. "`" .. initcmd .. "`\n\n"
        res = res .. description .. "\n\n"
      end
      return res
    end
    local templatetable = ${nixCats.utils.n2l.toLua nixCats.utils.templates}
    local resmarkdown = ""
    for k, v in pairs(templatetable) do
      resmarkdown = resmarkdown .. toMD(k,v.path,v.description)
    end
    print(resmarkdown)
  '';
  executable = true;
  destination = "/bin/${APPNAME}";
}
