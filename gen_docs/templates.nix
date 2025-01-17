{ APPNAME
, nixCats
, luajit
, writeTextFile
, ...
}:
writeTextFile {
  name = APPNAME;
  text = /*lua*/ ''
    #!${luajit}/bin/luajit
    function os.capture(cmd, trim)
      local f = assert(io.popen(cmd, 'r'), "unable to execute: " .. cmd)
      local s = assert(f:read('*a'), "unable to read output of: " .. cmd)
      f:close()
      if not trim then return s end
      s = string.gsub(s, '^%s+', "")
      s = string.gsub(s, '%s+$', "")
      s = string.gsub(s, '[\n\r]+', ' ')
      return s
    end
    local nixCatsSrc = [[${nixCats}/]]
    local templatetable = ${nixCats.utils.n2l.toLua nixCats.utils.templates}
    local resmarkdown = ""
    for k, v in pairs(templatetable) do
      if type(v) == "table" then
        if v.path:sub(1, #nixCatsSrc) == nixCatsSrc then
            v.path = "nix flake init -t github.com/BirdeeHub/nixCats-nvim#" .. v.path:sub(#nixCatsSrc + 1)
            resmarkdown = resmarkdown .. "# " .. k .. "\n\n"
            resmarkdown = resmarkdown .. v.path .. "\n\n"
            resmarkdown = resmarkdown .. v.description .. "\n\n"
        end
      end
    end
    print(resmarkdown)
  '';
  executable = true;
  destination = "/bin/${APPNAME}";
}
