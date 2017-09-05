local base = game:HttpGet('https://raw.githubusercontent.com/fox-sploosh/Cmd/master/CmdBase.lua', true)
local cmds = game:HttpGet('https://raw.githubusercontent.com/fox-sploosh/Cmd/master/CmdLoad.lua', true)

local a,b = loadstring(base)

if not a then error(b) end

Cmd = a()

local c,d = loadstring(cmds)

if not c then error(d) end

c()

-- Extra commands can go below :D




