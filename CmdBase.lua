local Cmd = {}

local function safeget(iname)
	local ret
	pcall(function()
		ret = loadstring("return "..iname)()
	end)
	return ret
end

local function safedel(iname)
	local x = safeget(iname)
	if type(x) == "userdata" then
		x:Destroy()
	end
end

local types = {
	['number'] = tonumber,
	['bool'] = function(a) 
		return a == "true" and true or a == "false" and false
	end,
	['string'] = tostring,
	['table'] = function(a)
		local b = loadstring(a)
		if b then
			pcall(function()
				b = b()
			end)
		end
		if type(b) == "table" then
			return b
		end
	end
}

local Commands = {}
local Separator = [[ ]]
local NCards = {}	
local msgs = {}
local NCard
local synt
local GuiCreated = false

function Cmd:GetCmds()
	return Commands
end

function Cmd:ClearCmds()
	Commands = {}
end

function Cmd:Count()
	return #Commands
end

function Cmd:Separator(nsep)
	Separator = nsep
end

function Cmd:Execute(whole)
	local sect = whole:trim():split("/")
	local cmdn = sect[1]:trim()
	local cmd = Cmd:Get(cmdn)
	omsg = whole:sub(#cmdn + 1)
	msg = Cmd:RepCode(omsg)
	local args = Cmd:ParseArg(msg, cmd)

	if cmd ~= nil then
		spawn(function()
			if #args > cmd.Satisfiable then
				Cmd:Notify('Invalid arguments: Argument amount not satisfied')
				return
			end
			local x = cmd.Func
			for i,v in pairs(args) do
				getfenv(x)[i] = v
			end
			x()
		end)
	else
		Cmd:Notify('Invalid command entered: '..sect[1])
	end
	local e = tick()
end

function Cmd:Add(name,args,desc,func)
	Commands[Cmd:Count() + 1] = {
		Name = name,
		ATab = (function()
			local t = {}
			for name,atype in args:gmatch('/(%a+):(%a+)') do
				local a = {}
				a.name = name
				a.type = atype
				t[#t+1] = a
			end
			return t
		end)(),
		Args = args,
		Desc = desc,
		Func = func,
		Satisfiable = (function()
			local c = 0
			for _ in args:gmatch("/%a+:%a+") do
				c = c + 1
			end
			return c
		end)(),
		Card = (function()
			local function csyn(text, color, pos, parent)
				local nsyn = synt:Clone()
				nsyn.Text = text
				nsyn.TextColor3 = color
				nsyn.Position = pos
				nsyn.Parent = parent or base
			end
			local nmsg = NCard:Clone()
			local t = ("%s %s"):format(name,args)	
			local u2 = UDim2.new
			local c3 = function(r,g,b) return Color3.new(r/255,g/255,b/255) end
			local delcol = c3(0,178,255)
			local keycol = c3(178,96,255)
			local propcol = c3(255,96,96)
			local valcol = c3(95,255,96)

			nmsg.Size = u2(1,0,0,25)
			nmsg.Parent = nil

			local x = t:getchars()
			local iname = false
			local ival = false

			for i,v in pairs(x) do
				local col = keycol
				if iname then 
					col = propcol
				elseif ival then 
					col = valcol
				end
				if v == "/" then 
					col = delcol
					iname = true
					ival = false
				elseif v == ":" then 
					col = delcol
					ival = true
					iname = false
				end
				csyn(v, col, u2(0,(i-1)*8,0,0), nmsg.Text)
			end

			nmsg.Text.Text = ("%s %s - %s"):format(string.rep(" ", #name),string.rep(" ", #args),desc)

			return nmsg
		end)()
	}
end

function Cmd:Get(name)
	for _,v in pairs(Commands) do
		if v.Name == name:lower() then
			return v
		end
	end
end

function Cmd:RepCode(msg)
	local codeparts = {}

	for s,isplain,code in msg:gmatch("()(.)(%b[])") do
		table.insert(codeparts, {
			plain = isplain == "$",
			code = code:sub(2,#code-1),
			st = s,
			en = s + #code + 1
		})
	end

	local sz = #msg

	for i,v in pairs(codeparts) do
		local diff = sz - #msg
		if not v.plain then
			msg = msg:sub(1, v.st - diff) .. tostring(loadstring("return " .. v.code)()) .. msg:sub(v.en - diff)
		end
	end

	return msg
end

function Cmd:ParseArg(str, cmd)
	local t = str:getchars()
	local fargs = {}
	local args = {}
	local curr = ""
	local cuarg = 0
	local iname = false
	local ivar = false

	for i,v in pairs(t) do
		if v == "/" then
			cuarg = cuarg + 1
			iname = true
			ivar = false
		elseif v == ":" then
			ivar = true
			iname = false
		else
			if not fargs[cuarg] then fargs[cuarg] = {} end
			if not fargs[cuarg].name then fargs[cuarg].name = "" end
			if not fargs[cuarg].val then fargs[cuarg].val = "" end
			if iname then
				fargs[cuarg].name = fargs[cuarg].name .. v
				fargs[cuarg].used = false
			elseif ivar then
				fargs[cuarg].val = fargs[cuarg].val .. v
			end
		end
	end

	for i,arg in pairs(fargs) do
		for i,carg in pairs(cmd.ATab) do
			if Cmd:Find(carg.name, arg.name) then
				local v = types[carg.type] and types[carg.type](arg.val) or arg.val:trim()
				args[carg.name] = v

				fargs[i].used = true
			end
		end
	end

	for i,v in pairs(fargs) do
		if not v.used then
			Cmd:Notify('arg '..v.name..' was not used and has been dropped')
		end
	end

	return args
end

function Cmd:GetPlr(n)
	n = n:lower()
	local fnd = {}
	local pls = game.Players
	local players = pls:children()
	local lplayer = pls.LocalPlayer
	do
		if n == "me" then
			fnd[#fnd + 1] = lplayer
		elseif n == "others" then
			for i,v in pairs(players) do
				if v ~= lplayer then
					fnd[#fnd + 1] = v
				end
			end
		elseif n == "all" then
			for i,v in pairs(players) do
				fnd[#fnd + 1] = v
			end
		elseif n == "guests" then
			for i,v in pairs(players) do
				if v.Guest then
					fnd[#fnd + 1] = v
				end
			end
		elseif n == "nonguests" then
			for i,v in pairs(players) do
				if not v.Guest then
					fnd[#fnd + 1] = v
				end
			end
		else
			for i,v in pairs(players) do
				if Cmd:GFind(v.Name, n) then
					fnd[#fnd + 1] = v
				end
			end
		end
	end
	return fnd
end

function Cmd:AltGetPlr(n)
	n = n:lower()
	local fnd = {}
	local players = game.Players:children()
	if n == "me" then
		fnd[#fnd+1] = game.Players.LocalPlayer
	else
		for i,v in pairs(players) do
			if Cmd:Find(v.Name,n) then
				fnd[#fnd+1] = v
			end
		end
	end
	return fnd
end

function Cmd:FindCmds(n)
	n = n:lower()
	local c = {}
	for i,v in pairs(Commands) do
		if Cmd:Find(v.Name, n) then
			c[#c+1] = v
		end
	end
	return c
end

function Cmd:Apoc()
	if game.Players.LocalPlayer.PlayerGui:FindFirstChild("HitEqualsYouDie") then
		fireserver = debug.getfenv(game.Players.LocalPlayer.PlayerGui.HitEqualsYouDie).shared.fireserver
		if not fireserver then
			return false
		end
		setfenv(1,getfenv(game:GetService('ReplicatedStorage').ClearAllChildren))
		function destroy(obj) fireserver('Destruct', obj) end
		function changeparent(obj, npar) fireserver('ChangeParent', obj, npar) end
		function changehum(player, func)
			local me = game.Players.LocalPlayer.Character
			local you = player.Character
			local mh = me:FindFirstChildOfClass('Humanoid')
			local yh = me:FindFirstChildOfClass('Humanoid')
			
			changeparent(yh, me)
			changeparent(mh, you)
			while yh.Parent ~= me and mh.Parent ~= you do game:GetService('RunService').Heartbeat:wait() end
			func()
			changeparent(yh, you)
			changeparent(mh, me)
			while yh.Parent ~= you and mh.Parent ~= me do game:GetService('RunService').Heartbeat:wait() end
		end
		function sethum(prop, nval) fireserver('HealthSet', prop, nval) end
		function changeval(obj, nval) fireserver('ChangeValue', obj, nval) end
		function damage(player, amount) fireserver('Damage', player, amount) end
		function invispart(brick) fireserver('BreakWindow2', brick, true) end
		function placemat(model, pos) workspace.Remote.PlaceMaterial:FireServer(model, pos) end
		function setcframe(part, nf) workspace.Remote.SetCFrame:FireServer(part, nf) end
		destroy(workspace.Remote:FindFirstChild'AddDamageSelf')
		return true
	end
	return false
end

function Cmd:CreateGui()
	safedel'game.CoreGui.Cmd'
	local new = LoadLibrary("RbxUtility").Create
	local cui = game.CoreGui
	local u2 = UDim2.new
	local c3 = function(r,g,b) return Color3.new(r/255,g/255,b/255) end
	local syns = {}
	local pos = 0
	local lsize = 0
	
	function tpos(obj, nu2, sec, override)
		obj:TweenPosition(nu2, override or "InOut", "Quad", sec, true)
	end

	function tsize(obj, nu2, sec, override)
		obj:TweenSize(nu2, override or "InOut", "Quad", sec, true)
	end
	
	sc = new'ScreenGui'{Name = "Cmd",Parent = cui}
	
	local base = new'Frame'{
		Name = "Base",
		Size = u2(0, 0, 0, 25),
		Position = u2(0, 0, 1, -25),
		BackgroundColor3 = c3(10,30,50),
		BorderSizePixel = 0,
		BackgroundTransparency = 0.1,
		ClipsDescendants = true,
		Parent = sc
	}

	local precursor = new'TextLabel'{
		Name = "Precursor",
		Size = u2(0, 20, 0, 25),
		Position = u2(0, 0, 0, -1),
		BackgroundTransparency = 1,
		TextColor3 = c3(235,235,235),
		Text = ">",
		Font = Enum.Font.Code,
		BorderSizePixel = 0,
		TextSize = 15,
		Parent = base
	}

	local text = new'TextBox'{
		Name = "Text",
		Size = u2(1, -20, 0, 26),
		Position = u2(0,20,0,-2),
		Text = "",
		Transparency = 1,
		BorderSizePixel = 0,
		TextColor3 = c3(235,235,235),
		TextXAlignment = 0,
		Parent = base
	}
	
	local cursor = new'Frame'{
		Name = "Cursor",
		Size = u2(0,1,0,15),
		Position = u2(0,20,0,5),
		BackgroundColor3 = c3(255,255,255),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = base
	}
	
	local msg = new'Frame'{
		Name = "Message",
		Size = u2(1,0,0,25),
		Position = u2(0,0,2,0),
		BackgroundColor3 = c3(0,0,0),
		BorderSizePixel = 0,
		BackgroundTransparency = 0.1,
		ClipsDescendants = true,
		Parent = sc
	}
	
	local msgtext = new'TextLabel'{
		Name = "Text",
		Size = u2(1, 0, 0, 25),
		Position = u2(0, 4, 0, -2),
		BackgroundTransparency = 1,
		TextColor3 = c3(235,235,235),
		Text = "",
		Font = Enum.Font.Code,
		BorderSizePixel = 0,
		TextSize = 15,
		TextXAlignment = 0,
		Parent = msg
	}
	
	local syn = new'TextLabel'{
		Name = "Syntax",
		Size = u2(0,8,0,25),
		BackgroundTransparency = 1,
		TextColor3 = c3(235,235,235),
		Text = "",
		Font = Enum.Font.Code,
		BorderSizePixel = 0,
		TextSize = 15,
		TextXAlignment = 0,
		TextTransparency = 0
	}

	NCard = msg
	synt = syn

	local function csyn(text, color, pos, parent)
		local nsyn = syn:Clone()
		nsyn.Text = text
		nsyn.TextColor3 = color
		nsyn.Position = pos
		nsyn.Parent = parent or base
		syns[#syns+1] = nsyn
	end

	function textsize(str)
		local sz = game:GetService('TextService'):GetTextSize(str, 15, Enum.Font.Code, Vector2.new(1e3, 1e3))
		return sz.X
	end
	
	csyn("Press ", c3(96,178,255), u2(0,20,0,-2))
	csyn("\";\" "  , c3(255,96,96), u2(0,20+6*8,0,-2))
	csyn("to focus onto this command prompt", c3(96,178,255), u2(0,20+10*8,0,-2))
	
	local keystart = game:GetService("UserInputService").InputEnded:connect(function(k)
		if sc == safeget('game.CoreGui.Cmd') then
			local b = k.KeyCode
			local c = b.Value
			if b == Enum.KeyCode.Right and focused then --Right
				pos = pos + 1
				if pos > #text.Text then pos = #text.Text end
				tpos(cursor, u2(0,20+pos*8,0,5), 0.08, "Out")
			elseif b == Enum.KeyCode.Left and focused then --Left
				pos = pos - 1
				if pos < 0 then pos = 0 end
				tpos(cursor, u2(0,20+pos*8,0,5), 0.08, "Out")
			end
		end
	end)

	local capture = game.Players.LocalPlayer:GetMouse().KeyUp:connect(function(k)
		if k == ";" then
			text:CaptureFocus()
		end
	end)
	
	local focus = text.Focused:connect(function()
		if sc == safeget('game.CoreGui.Cmd') then
			for i,v in pairs(syns) do
				v:Destroy()
				syns[i] = nil
			end
			focused = true
			cursor.BackgroundTransparency = 0
			tsize(base, u2(1,0,0,25), 0.3)
			tpos(cursor, u2(0,20,0,5), 0.05)
		end
	end)

	local focuslost = text.FocusLost:connect(function(enter)
		if sc == safeget('game.CoreGui.Cmd') then
			if enter then
				if text.Text:trim() ~= "" then
					Cmd(text.Text)
				end
			end
			tsize(base, u2(0,0,0,25), 0.3)
			cursor.BackgroundTransparency = 1
			focused = false
			for i,v in pairs(msgs) do
				v:Destroy()
				msgs[i] = nil
			end
		end
	end)

	local delcol = c3(0,178,255)
	local keycol = c3(178,96,255)
	local propcol = c3(255,96,96)
	local valcol = c3(95,255,96)
	
	local tchanged = text:GetPropertyChangedSignal("Text"):connect(function()
		if sc == safeget('game.CoreGui.Cmd') then
			pos = pos + #text.Text - lsize
			if pos < 0 then pos = 0 end
			tpos(cursor, u2(0,20+pos*8,0,5), 0.08, "Out")
			lsize = #text.Text
			do --Syntax
				for i,v in pairs(syns) do
					v:Destroy()
					syns[i] = nil
				end

				local t = text.Text:getchars()
				local iname = false
				local ival = false

				for i,v in pairs(t) do
					local col = keycol
					if iname then 
						col = propcol 
					elseif ival then 
						col = valcol 
					end
					if v == "/" then 
						col = delcol 
						iname = true 
						ival = false 
					end
					if v == ":" then 
						col = delcol 
						ival = true 
						iname = false 
					end
					csyn(v, col, u2(0,(i-1)*8,0,0), text)
				end
			end
			-- Command Suggestions --
			for i,v in pairs(msgs) do
				v:Destroy()
				msgs[i] = nil
			end
			if text.Text:trim() ~= "" then
				local found = Cmd:FindCmds(text.Text:split("/")[1]:trim())
				for i,cmd in pairs(found) do
					local nmsg = cmd.Card:Clone()
					
					nmsg.Position = UDim2.new(0,0,1,-i*25-25)
					nmsg.Parent = sc
					
					msgs[#msgs+1] = nmsg
				end
			else
				for i,v in pairs(msgs) do
					v:Destroy()
					msgs[i] = nil
				end
			end
		end
	end)
	
	tsize(base, u2(1,0,0,25), 0.3)
	GuiCreated = true
end

function Cmd:PNotify(msg)
	local tpos = function(obj, nu2, sec, override)
		obj:TweenPosition(nu2, "InOut", "Quad", sec, override or true)
	end

	local u2 = UDim2.new

	local msize = textsize(msg)
	local card = NCard:Clone()
	card.Text.Text = msg
	card.Text.TextXAlignment = 2
	card.Text.Position = u2(0,0,0,-2)
	card.Size = u2(0,msize + 24,0,25)
	card.Position = u2(0.5,-(msize + 24)/2,0,-61)
	card.Parent = sc
	card.Text.Size = card.Size
	NCards[#NCards+1] = card
	local cardn = #NCards
	local cobj = {card=card}
	function cobj:Destroy()
		if cobj.card and cobj.card.Parent ~= nil then
			NCards[cardn] = nil
			tpos(cobj.card, u2(0.5,-cobj.card.Size.Width.Offset / 2,0,-61), 0.3)
			wait(0.3)
			cobj.card:Destroy()
			local count = 0
			for i = #NCards, 1, -1 do
				if NCards[i] and NCards[i].Parent ~= nil then
					local card = NCards[i]
					count = count + 1
					local pos = u2(0.5,-card.Size.Width.Offset/2,0,25*(count-1))
					tpos(card, pos, 0.5)
				end
			end
		end
	end
	function cobj:ChangeText(ntext)
		if card and card.Parent ~= nil then
			local s = textsize(ntext)
			card.Text.Text = ntext
			card.Size = u2(0,s+24,0,25)
			card.Position = u2(0.5,-(s+24)/2,0,card.Position.Y.Offset)
			card.Text.Size = card.Size
			Cmd:SortNCards()
		end
	end
	local count = 0
	for i = #NCards, 1, -1 do
		local card = NCards[i]
		count = count + 1
		local pos = u2(0.5,-card.Size.Width.Offset/2,0,25*(count-1))
		tpos(card, pos, 0.5)
	end
	return cobj
end

function Cmd:Notify(msg)
	if not Instance then
		print("--> " .. tostring(msg))
		return
	end

	local tpos = function(obj, nu2, sec, override)
		obj:TweenPosition(nu2, "InOut", "Quad", sec, override or true)
	end

	local u2 = UDim2.new

	local msize = textsize(msg)
	local card = NCard:Clone()
	card.Text.Text = msg
	card.Text.TextXAlignment = 2
	card.Text.Position = u2(0,0,0,-2)
	card.Size = u2(0,msize + 24,0,25)
	card.Position = u2(0.5,-(msize + 24)/2,0,-61)
	card.Parent = sc
	card.Text.Size = card.Size
	NCards[#NCards+1] = card
	local cardn = #NCards
	local count = 0
	for i = #NCards, 1, -1 do
		local card = NCards[i]
		count = count + 1
		local pos = u2(0.5,-card.Size.Width.Offset/2,0,25*(count-1))
		tpos(card, pos, 0.5)
	end
	spawn(function()
		wait(5)
		NCards[cardn] = nil
		tpos(card, u2(0.5,-card.Size.Width.Offset / 2,0,-61), 0.3)
		wait(0.3)
		card:Destroy()
		local count = 0
		for i = #NCards, 1, -1 do
			local card = NCards[i]
			count = count + 1
			local pos = u2(0.5,-card.Size.Width.Offset/2,0,25*(count-1))
			tpos(card, pos, 0.5)
		end
	end)
end

function Cmd:SortNCards()
	local u2 = UDim2.new
	local tpos = function(obj, nu2, sec, override)
		obj:TweenPosition(nu2, "InOut", "Quad", sec, override or true)
	end

	local count = 0
	for i = #NCards, 1, -1 do
		local card = NCards[i]
		count = count + 1
		local pos = u2(0.5,-card.Size.Width.Offset/2,0,25*(count-1))
		tpos(card, pos, 0.5)
	end
end

function Cmd:Find(str, fnd)
	local found = false
	local sc = str:getchars()
	local fc = fnd:getchars()
	for i = 1, #fc do
		if (fc[i] and sc[i]) and (fc[i]:lower() == sc[i]:lower()) then
			found = true
		else
			found = false
			break
		end
	end
	return found
end

function Cmd:GFind(str, fnd)
	return str:lower():find(fnd:lower(), 1, true)
end

setmetatable(Cmd,{
	__call = function(_,...)
		local args = {...}
		if #args == 1 then
			Cmd:Execute(...)
		else
			Cmd:Add(...)
		end
	end,
	__index = function(_,b)
		return Cmd:Get(b)
	end
})

Cmd:CreateGui()

return Cmd
