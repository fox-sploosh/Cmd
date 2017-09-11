Apoc = Cmd:Apoc()


if Apoc then
	-------------------------------------------------------------------
	-- Credits to Josh for making Selenium and letting it be cracked --
	-------------------------------------------------------------------
	Cmd('kill', '/pname:string', 'Kills a player', function()
		for i,player in pairs(Cmd:GetPlr(pname)) do
			destroy(player.Character.Head)
		end
	end)
	Cmd('kick', '/pname:string', 'Kicks a player', function()
		for i,player in pairs(Cmd:GetPlr(pname)) do
			destroy(player)
		end
	end)
	Cmd('god', '/pname:string', 'Gods a player', function()
		for i,player in pairs(Cmd:GetPlr(pname)) do
			changehum(player, function()
				sethum('MaxHealth', 1e9)
				sethum('Health', 1e9)
			end)
			break
		end
	end)
	Cmd('ungod', '/pname:string', 'Ungods a player', function()
		for i,player in pairs(Cmd:GetPlr(pname)) do
			changehum(player, function()
				sethum('MaxHealth', 100)
				sethum('Health', 100)
			end)
		end
	end)
	Cmd('nohunger', '/pname:string', 'Sets a players hunger to -1 [NOTE: Eating will bring this back up]', function()
		for i,player in pairs(Cmd:GetPlr(pname)) do
			changeval(player.playerstats.Hunger, -1)
		end
	end)
	Cmd('nothirst', '/pname:string', 'Sets a players thirst to -1 [NOTE: Drinking will bring this back up]', function()
		for i,player in pairs(Cmd:GetPlr(pname)) do
			changeval(player.playerstats.Thirst, -1)
		end
	end)
	Cmd('jump', '/pname:string', 'Makes a player jump!', function()
		for i,player in pairs(Cmd:GetPlr(pname)) do
			changehum(player, function()
				sethum('Jump', true)
			end)
		end
	end)
	Cmd('damage', '/pname:string /amount:number', 'Damages a player the amount you set', function()
		for i,player in pairs(Cmd:GetPlr(pname)) do
			damage(player, amount)
		end
	end)
	Cmd('heal', '/pname:string /amount:number', 'Heals a player the amount you set', function()
		for i,player in pairs(Cmd:GetPlr(pname)) do
			damage(player, -amount)
		end
	end)
	Cmd('invis', '/pname:string', 'Makes a player invisible', function()
		for i,player in pairs(Cmd:GetPlr(pname)) do
			if player.Character then
				for i,part in pairs(player.Character:GetDescendants()) do
					if part:IsA('BasePart') then
						invispart(part)
					end
				end
				if player.Character.Head:FindFirstChild'face' then
					changeparent(player.Character.Head.face, player.Character.Humanoid)
				end
			end
		end
	end)
	Cmd('spawn', '/pname:string /items:string', 'Spawns an item. Syntax: `item=amount,item=amount`. Default amount is 1.', function()
		items = split(items, ',')
		for k,it in pairs(items) do
			local amount = split(it, '=')[2] or 1
			it = split(it, '=')[1]
			local sel
			for i,v in pairs(game.Lighting.LootDrops:children()) do
				if Cmd:GFind(v.Name, it) then
					sel = v
					break
				end
			end
			if sel then
				for i,player in pairs(Cmd:GetPlr(pname)) do
					local spos = sel.PrimaryPart and sel:GetPrimaryPartCFrame().p or sel.Model:FindFirstChildOfClass('Part').CFrame.p
					local pos = player.Character.HumanoidRootPart.Position - spos
					for i = 1, amount do
						local apos = (k - #items / 2) * 2.8
						placemat(sel, pos + Vector3.new(i + 4, 0, (k - #items / 2) * 2.8))
						Cmd:Notify('Spawned item: '..sel.Name)
					end
				end
			else
				Cmd:Notify('Couldn\'t find item: '..it)
			end
		end
	end)
	Cmd('finditem', '/iname:string', 'Finds an item with the specified search string', function()
		for i,v in pairs(game.Lighting.LootDrops:children()) do
			if Cmd:GFind(v.Name, iname) then
				Cmd:Notify(v.Name)
			end
		end
	end)

	local ncard
	local hcard
	local changedevent
	function round(num)
	  return math.floor(num + 0.5) / 1
	end
	Cmd('view', '/pname:string', 'Sets your camera to another player', function()
		if not pname then Cmd:Notify('Expected value for pname') return end
		for i,player in pairs(Cmd:AltGetPlr(pname)) do
			if player == game.Players.LocalPlayer then
				workspace.CurrentCamera.CameraSubject = player.Character.Humanoid
				if ncard and ncard.card then ncard:Destroy() end
				if hcard and hcard.card then hcard:Destroy() end
				return 
			end
			if player.Character and player.Character.Humanoid then
				workspace.CurrentCamera.CameraSubject = player.Character.Humanoid
				if ncard and ncard.card then ncard:Destroy() end
				if hcard and hcard.card then hcard:Destroy() end
				local percent = round(player.Character.Humanoid.Health / player.Character.Humanoid.MaxHealth * 100)
				ncard = Cmd:PNotify('Name: '.. player.Name)
				hcard = Cmd:PNotify('Health: '..round(player.Character.Humanoid.Health)..'/'..player.Character.Humanoid.MaxHealth..' : '..percent..'%')
				local x = hcard
				if changedevent then changedevent:disconnect() end
				changedevent = player.Character.Humanoid.GetPropertyChangedSignal('Health'):connect(function()
					if player.Character and player.Character:FindFirstChild('Humanoid') and hcard.card and ncard.card then
						local percent = round(player.Character.Humanoid.Health / player.Character.Humanoid.MaxHealth * 100)
						hcard:ChangeText('Health: '..round(player.Character.Humanoid.Health)..'/'..player.Character.Humanoid.MaxHealth..' : '..percent..'%')
					end
					if not player.Character:FindFirstChild('Humanoid') then
						hcard:Destroy()
						ncard:Destroy()
						workspace.CurrentCamera.CameraSubject = game.Players.LocalPlayer.Character.Humanoid
					end
				end)
				break
			else
				Cmd:Notify('Player '..player.Name..' has not spawned yet')
				break
			end
			Cmd:SortNCards()
		end
	end)
	Cmd('lua', '/code:string', 'Executes the lua code provided', function()
		local f, e1 = loadstring(code)
		if not f then Cmd:Notify(e1) return end
		local c, e2 = pcall(f)
		if not c then Cmd:Notify(e2) return end
	end)
	local msgcolors = {'Red', 'White', 'Blue', 'Green', 'Yellow'}
	local msgcolor = 'White'
	Cmd('msg', '/msg:string', 'Sends a message :D', function()
		for i,v in pairs(game.Players:children()) do
			workspace.Remote.SendMessage:FireServer(v, msgcolor, msg)
		end
	end)
	Cmd('setmsgcolor', '/color:string', 'Sets the msg command\'s color', function()
		for i,v in pairs(msgcolors) do
			if Cmd:GFind(v, color) then
				msgcolor = v
				break
			end
		end
		Cmd:Notify('Set msg color to: '..msgcolor)
	end)
	Cmd('healthof', '/pname:string', 'Prints the health of a player', function()
		for i,player in pairs(Cmd:GetPlr(pname)) do
			Cmd:Notify('Health of '..player.Name..' is '..player.Character.Humanoid.Health)
		end
	end)
	Cmd('fillstam', '/pname:string', 'Fills a player\'s stamina', function()
		for i,player in pairs(Cmd:GetPlr(pname)) do
			changeval(player.Backpack.GlobalFunctions.Stamina, 100)
		end
	end)
	Cmd('setstam', '/pname:string /amount:number', 'Sets a player\'s stamina. Default amount is 100.', function()
		for i,player in pairs(Cmd:GetPlr(pname)) do
			changeval(player.Backpack.GlobalFunctions.Stamina, amount or 100)
		end
	end)
	local kits = {
		patriot = {
			'patriot',
			'acog',
			'suppressor556',
			'stanagammo100=20'
		},
		car = {
			'reinf=4',
			'sticglass',
			'scrap',
			'armor',
			'engine',
			'fuelt'
		},
		specops = {
			'specialt',
			'specialb',
			'maskspec',
			'sticspec',
			'packblack',
			'lightm'
		},
		navigation = {
			'map',
			'gps',
			'comp'
		}
	}
	Cmd('kit', '/pname:string /kitname:string', 'Spawns a kit', function()
		local sel
		for n,v in pairs(kits) do
			if Cmd:GFind(n, kitname) then
				sel = v
			end
		end
		if sel ~= nil then
			Cmd('spawn/'..pname..'/'..table.concat(sel, ','))
		else
			Cmd:Notify('Couldn\'t find kit: ' .. kitname)
		end
	end)
	Cmd('kits', '/none', 'Lists out the kits', function()
		for i,v in pairs(kits) do
			Cmd:Notify('Kit: ' .. i)
		end
	end)
	Cmd('cloneveh', '/pname:string /vehname:string', 'Clones a vehicle to you', function()
		for i,veh in pairs(workspace.Vehicles:children()) do
			if Cmd:GFind(veh.Name, vehname) and veh:FindFirstChild('Stats') then
				for i,plr in pairs(Cmd:AltGetPlr(pname)) do
					local ppart = veh.PrimaryPart and veh:GetPrimaryPartCFrame().p or veh:FindFirstChild('Base', true).Position
					placemat(veh, plr.Character.HumanoidRootPart.Position - ppart + Vector3.new(math.random(-20,20),0,math.random(-20,20)))
					break
				end
				break
			end
		end
	end)
	Cmd('vehicles', '/none', 'Lists out vehicles', function()
		for i,veh in pairs(workspace.Vehicles:children()) do
			Cmd:Notify('Vehicle: ' .. veh.Name)
		end
	end)
	Cmd('findveh', '/vehname:string', 'Finds the vehicle of name', function()
		for i,veh in pairs(workspace.Vehicles:children()) do
			if Cmd:GFind(veh.Name, vehname) then
				Cmd:Notify('Vehicle Found: '..veh.Name)
			end
		end
	end)
	Cmd('fhum', '/none', 'Fixes your humanoid :D', function()
		changeparent(MyHumanoid, game.Players.LocalPlayer.Character)
	end)


	Cmd:Notify('Apoc commands loaded')
else
	Cmd('print', '/msg:string', 'Prints things!', function()
		Cmd:Notify(msg)
	end)
	Cmd('kill', '/pname:string', 'Kills a player', function()
		for i,player in pairs(Cmd:GetPlr(pname)) do
			player.Character:BreakJoints()
		end
	end)
	Cmd('god', '/pname:string', 'Gods a player', function()
		for i,plr in pairs(Cmd:GetPlr(pname)) do
			if plr.Character and plr.Character:FindFirstChild'Humanoid' then
				plr.Character.Humanoid.MaxHealth = math.huge
				wait()
				plr.Character.Humanoid.Health = math.huge
			end
		end
	end)
	Cmd('ungod', '/pname:string', 'Ungods a player', function()
		for i,plr in pairs(Cmd:GetPlr(pname)) do
			if plr.Character and plr.Character:FindFirstChild'Humanoid' then
				plr.Character.Humanoid.MaxHealth = 100
			end
		end
	end)
	Cmd('sethealth', '/pname:string /amount:number', 'Sets a players health to the specified amount', function()
		for i,player in pairs(Cmd:GetPlr(pname)) do
			if player.Character and player.Character:FindFirstChildOfClass('Humanoid') then
				player.Character:FindFirstChildOfClass('Humanoid').Health = amount
			end
		end
	end)
	Cmd('setmhealth', '/pname:string /amount:number', 'Sets a players max health to the specified amount', function()
		for i,player in pairs(Cmd:GetPlr(pname)) do
			if player.Character and player.Character:FindFirstChildOfClass('Humanoid') then
				player.Character:FindFirstChildOfClass('Humanoid').MaxHealth = amount
			end
		end
	end)


	Cmd:Notify('Regular commands loaded')
end

Cmd:Notify('Hello, '..game.Players.LocalPlayer.Name..'!')