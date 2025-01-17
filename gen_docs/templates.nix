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
    local nixCatsSrc = [[${nixCats}/templates/]]
    local templatetable = ${nixCats.utils.n2l.toLua nixCats.utils.templates}
    local resmarkdown = ""
    for k, v in pairs(templatetable) do
      if type(v) == "table" then
        if v.path:sub(1, #nixCatsSrc) == nixCatsSrc then
            v.path = "nix flake init -t github.com/BirdeeHub/nixCats-nvim#" .. v.path:sub(#nixCatsSrc + 1)
            resmarkdown = resmarkdown .. "# " .. k .. "\n\n"
            resmarkdown = resmarkdown .. "`" .. v.path .. "`\n\n"
            resmarkdown = resmarkdown .. v.description .. "\n\n"
        end
      end
    end
    print(resmarkdown)
  '';
  executable = true;
  destination = "/bin/${APPNAME}";
}
