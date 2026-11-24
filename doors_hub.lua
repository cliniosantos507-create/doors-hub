--[[ DOORS Hub | Delta Executor | 50 funções | RightShift = abrir/fechar ]]
if getgenv().DoorsHub then pcall(getgenv().DoorsHub) end

local Players, RepS, Light = game:GetService("Players"), game:GetService("ReplicatedStorage"), game:GetService("Lighting")
local UIS, RS, TS, TPS = game:GetService("UserInputService"), game:GetService("RunService"), game:GetService("TweenService"), game:GetService("TeleportService")
local WS, lp = workspace, Players.LocalPlayer

local conns, S, V, feats, alive, unload = {}, {}, {}, {}, true, nil
local lastDt = 1 / 60

local function conn(sig, fn) local c = sig:Connect(fn) conns[#conns + 1] = c return c end
local function new(cls, props, par)
	local i = Instance.new(cls)
	for k, v in pairs(props) do i[k] = v end
	i.Parent = par
	return i
end
local function corner(o, r) new("UICorner", {CornerRadius = UDim.new(0, r or 6)}, o) end

-- ===== cores =====
local ACC, BG, BG2, OFF, TXT = Color3.fromRGB(120, 95, 255), Color3.fromRGB(16, 16, 24), Color3.fromRGB(28, 28, 40), Color3.fromRGB(55, 55, 72), Color3.fromRGB(235, 235, 245)
local RED, GRN, YEL, BLU = Color3.fromRGB(255, 85, 85), Color3.fromRGB(80, 230, 120), Color3.fromRGB(255, 205, 70), Color3.fromRGB(90, 170, 255)

local okH, root = pcall(function() return gethui() end)
local gui = new("ScreenGui", {Name = "DoorsHub", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999}, okH and root or game:GetService("CoreGui"))
local ESPF = new("Folder", {Name = "ESP"}, gui)

-- ===== notificações =====
local toasts = new("Frame", {Size = UDim2.fromOffset(260, 300), Position = UDim2.new(1, -270, 0, 10), BackgroundTransparency = 1}, gui)
new("UIListLayout", {Padding = UDim.new(0, 4), HorizontalAlignment = Enum.HorizontalAlignment.Right}, toasts)
local function notify(txt, col)
	local t = new("TextLabel", {Size = UDim2.fromOffset(250, 26), BackgroundColor3 = BG, Text = "  " .. txt, TextColor3 = col or TXT, Font = Enum.Font.GothamMedium, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left}, toasts)
	corner(t); new("UIStroke", {Color = col or ACC, Thickness = 1}, t)
	task.delay(4, function()
		if t.Parent then TS:Create(t, TweenInfo.new(.4), {TextTransparency = 1, BackgroundTransparency = 1}):Play() task.wait(.4) t:Destroy() end
	end)
end

-- ===== helpers do jogo =====
local function hrp() local c = lp.Character return c and c:FindFirstChild("HumanoidRootPart") end
local function hum() local c = lp.Character return c and c:FindFirstChildOfClass("Humanoid") end
local function partOf(o) return o:IsA("BasePart") and o or (o:IsA("Model") and o.PrimaryPart) or o:FindFirstChildWhichIsA("BasePart", true) end
local function near(o, r) local p, h = partOf(o), hrp() return p and h and (p.Position - h.Position).Magnitude <= r end
local function rooms() return WS:FindFirstChild("CurrentRooms") end
local function curRoom()
	local gd = RepS:FindFirstChild("GameData")
	local lr, rs = gd and gd:FindFirstChild("LatestRoom"), rooms()
	return lr and rs and rs:FindFirstChild(tostring(lr.Value))
end
local function curDoor() local r = curRoom() return r and r:FindFirstChild("Door") end
local function remotes() return RepS:FindFirstChild("RemotesFolder") end

-- cache de objetos por nome (atualizado só quando alguma função precisa)
local C = {}
local function scan()
	local t, rs = {}, rooms()
	if not rs then C = t return end
	t._pp = {}
	for _, r in ipairs(rs:GetChildren()) do
		for _, d in ipairs(r:GetDescendants()) do
			local l = t[d.Name]
			if not l then l = {} t[d.Name] = l end
			l[#l + 1] = d
			if d:IsA("ProximityPrompt") then t._pp[#t._pp + 1] = d end
		end
	end
	C = t
end

-- ===== ESP =====
local esp = setmetatable({}, {__index = function(t, k) local n = {} rawset(t, k, n) return n end})
local function clear(cat) for _, e in pairs(esp[cat]) do e.b:Destroy() e.g:Destroy() end esp[cat] = {} end
local function prune(cat)
	for o, e in pairs(esp[cat]) do
		if not o:IsDescendantOf(WS) then e.b:Destroy() e.g:Destroy() esp[cat][o] = nil end
	end
end
local function mark(cat, o, col, txt)
	local e = esp[cat][o]
	if e then if e.l.Text ~= txt then e.l.Text = txt end return end
	local p = partOf(o)
	if not p then return end
	local sz = o:IsA("Model") and o:GetExtentsSize() or p.Size
	local b = new("BoxHandleAdornment", {Adornee = p, AlwaysOnTop = true, ZIndex = 2, Size = sz, Color3 = col, Transparency = .6}, ESPF)
	local g = new("BillboardGui", {Adornee = p, AlwaysOnTop = true, Size = UDim2.fromOffset(150, 16), StudsOffset = Vector3.new(0, 2, 0)}, ESPF)
	local l = new("TextLabel", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = txt, TextColor3 = col, TextStrokeTransparency = 0, Font = Enum.Font.GothamBold, TextSize = 12}, g)
	esp[cat][o] = {b = b, g = g, l = l}
end

local function feat(cat, name, o)
	o.cat, o.name, o.acc = cat, name, 0
	if o.slider then V[name] = o.slider[3] end
	feats[#feats + 1] = o
end

local function espf(name, cat, col, names, lab)
	feat("ESP", name, {scan = true, rate = 1.2,
		on = function(v) if not v then clear(cat) end end,
		step = function()
			for _, n in ipairs(names) do
				for _, o in ipairs(C[n] or {}) do mark(cat, o, col, lab and lab(o, n) or n) end
			end
			prune(cat)
		end})
end

local ENT = {RushMoving = "Rush", AmbushMoving = "Ambush", A60 = "A-60", A120 = "A-120", Eyes = "Eyes", JeffTheKiller = "Jeff",
	BackdoorRush = "Haste", BackdoorLookman = "Lookman", SeekMovingNewClone = "Seek", GloombatSwarm = "Gloombats"}
local ITEMS = {"Lighter", "Flashlight", "Lockpicks", "Vitamins", "Bandage", "Battery", "BatteryPack", "Crucifix", "Candle", "Smoothie", "Compass", "Shakelight", "Straplight", "Bulklight", "Glowstick"}

-- ===== 1) ESP (10) =====
feat("ESP", "ESP Portas", {scan = true, rate = 1.2,
	on = function(v) if not v then clear("door") end end,
	step = function()
		local rs = rooms()
		for _, o in ipairs(C.Door or {}) do
			if o:IsA("Model") and o.Parent.Parent == rs then
				mark("door", o, YEL, "Porta " .. o.Parent.Name .. (o:FindFirstChild("Lock") and " [TRANCADA]" or ""))
			end
		end
		prune("door")
	end})
espf("ESP Armários", "lock", BLU, {"Wardrobe", "Rooms_Locker", "Rooms_Locker_Fridge"}, function() return "Armário" end)
espf("ESP Moedas", "gold", YEL, {"GoldPile"}, function(o) return "Ouro " .. tostring(o:GetAttribute("GoldValue") or "") end)
espf("ESP Chaves", "key", GRN, {"KeyObtain"}, function() return "CHAVE" end)
espf("ESP Alavancas", "lever", GRN, {"LeverForGate"}, function() return "Alavanca" end)
espf("ESP Livros e Disjuntores", "book", Color3.fromRGB(200, 140, 255), {"LiveHintBook", "LiveBreakerPolePickup"}, function(o, n) return n == "LiveHintBook" and "Livro" or "Disjuntor" end)
espf("ESP Itens", "item", Color3.fromRGB(255, 160, 80), ITEMS)
espf("ESP Gavetas e Baús", "chest", Color3.fromRGB(180, 180, 200), {"DrawerContainer", "ChestBoxLocked", "Toolbox"}, function(o, n) return n == "DrawerContainer" and "Gaveta" or "Baú" end)
feat("ESP", "ESP Entidades", {rate = .3,
	on = function(v) if not v then clear("ent") end end,
	step = function()
		for _, c in ipairs(WS:GetChildren()) do if ENT[c.Name] then mark("ent", c, RED, ENT[c.Name]) end end
		prune("ent")
	end})
feat("ESP", "ESP Jogadores", {rate = .5,
	on = function(v) if not v then clear("ply") end end,
	step = function()
		for _, p in ipairs(Players:GetPlayers()) do if p ~= lp and p.Character then mark("ply", p.Character, GRN, p.Name) end end
		prune("ply")
	end})

-- ===== 2) Entidades (8) =====
feat("Entidades", "Notificar Entidades", {})
conn(WS.ChildAdded, function(c)
	if S["Notificar Entidades"] and ENT[c.Name] then notify(ENT[c.Name] .. " apareceu!", RED) end
end)
feat("Entidades", "Alerta Porta Trancada", {})
task.spawn(function()
	local gd = RepS:WaitForChild("GameData", 15)
	local lr = gd and gd:WaitForChild("LatestRoom", 15)
	if not lr then return end
	conn(lr.Changed, function(v)
		if not S["Alerta Porta Trancada"] then return end
		task.wait(1.5)
		local d = curDoor()
		if d and d:FindFirstChild("Lock") then notify("Sala " .. v .. ": porta trancada, ache a chave", Color3.fromRGB(255, 130, 80)) end
	end)
end)
feat("Entidades", "Anti-Screech", {rate = .05, step = function()
	local s = WS.CurrentCamera and WS.CurrentCamera:FindFirstChild("Screech")
	if s then
		local rf = remotes()
		if rf and rf:FindFirstChild("Screech") then rf.Screech:FireServer(true) end -- confirma o "acerto" no servidor
		s:Destroy()
	end
end})
feat("Entidades", "Anti-Eyes", {rate = .1, step = function()
	local rf = remotes()
	if WS:FindFirstChild("Eyes") and rf and rf:FindFirstChild("MotorReplication") then rf.MotorReplication:FireServer(-649) end -- olhar pro chão
end})
local function killer(name, cat, names, rate)
	feat("Entidades", name, {scan = true, rate = rate or 1, step = function()
		for _, n in ipairs(names) do for _, o in ipairs(C[n] or {}) do pcall(o.Destroy, o) end end
	end})
end
killer("Anti-Seek (Obstáculos)", nil, {"Seek_Arm", "ChandelierObstruction"})
killer("Anti-Snare", nil, {"Snare"})
killer("Anti-Giggle", nil, {"GiggleCeiling"})
feat("Entidades", "Anti-Lookman", {rate = .5, step = function()
	local l = WS:FindFirstChild("BackdoorLookman")
	if l then l:Destroy() end
end})

-- ===== 3) Movimento (6) =====
local orig = {}
feat("Movimento", "Velocidade", {slider = {16, 60, 24}, on = function(v) local h = hum() if h and not v then h.WalkSpeed = 15 end end,
	step = function() local h = hum() if h then h.WalkSpeed = V["Velocidade"] end end})
feat("Movimento", "Pulo Alto", {slider = {30, 120, 60},
	on = function(v) local h = hum() if not h then return end if v then orig.jp = h.JumpPower else h.JumpPower = orig.jp or 0 end end,
	step = function() local h = hum() if h then h.UseJumpPower = true h.JumpPower = V["Pulo Alto"] end end})
feat("Movimento", "Pulo Infinito", {})
conn(UIS.JumpRequest, function()
	if S["Pulo Infinito"] then local h = hum() if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end end
end)
feat("Movimento", "Noclip", {})
conn(RS.Stepped, function()
	if S["Noclip"] and lp.Character then
		for _, p in ipairs(lp.Character:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end
	end
end)
feat("Movimento", "Gravidade Baixa", {slider = {20, 196, 60}, on = function(v) if not v then WS.Gravity = 196.2 end end,
	step = function() WS.Gravity = V["Gravidade Baixa"] end})
local fv
feat("Movimento", "Voar", {slider = {20, 80, 40},
	on = function(v) if not v and fv then fv:Destroy() fv = nil end end,
	step = function()
		local h, hm = hrp(), hum()
		if not h or not hm then return end
		if not fv or not fv.Parent then fv = new("BodyVelocity", {MaxForce = Vector3.new(1e5, 1e5, 1e5), Velocity = Vector3.zero}, h) end
		local sp = V["Voar"]
		local up = (UIS:IsKeyDown(Enum.KeyCode.Space) or hm.Jump) and sp or (UIS:IsKeyDown(Enum.KeyCode.LeftControl) and -sp or 0)
		fv.Velocity = hm.MoveDirection * sp + Vector3.new(0, up, 0)
	end})

-- ===== 4) Interação (9) =====
local function openDoor(d)
	local r = d:FindFirstChild("ClientOpen")
	if r then if r:IsA("RemoteFunction") then r:InvokeServer() else r:FireServer() end end
end
feat("Interação", "Abrir Portas Auto", {rate = .3, step = function()
	local d = curDoor()
	local p = d and d:FindFirstChild("Door")
	if d and p and not d:FindFirstChild("Lock") and not d:GetAttribute("Opened") and near(p, 18) then openDoor(d) end
end})
feat("Interação", "Interação Instantânea", {scan = true, rate = 1,
	on = function(v) if not v then for _, pp in ipairs(C._pp or {}) do local h = pp:GetAttribute("h") if h then pp.HoldDuration = h end end end end,
	step = function()
		for _, pp in ipairs(C._pp or {}) do
			if pp:GetAttribute("h") == nil then pp:SetAttribute("h", pp.HoldDuration) end
			pp.HoldDuration = 0
		end
	end})
feat("Interação", "Alcance Estendido", {scan = true, rate = 1, slider = {1, 3, 1.6, true},
	on = function(v) if not v then for _, pp in ipairs(C._pp or {}) do local d = pp:GetAttribute("d") if d then pp.MaxActivationDistance = d end end end end,
	step = function()
		for _, pp in ipairs(C._pp or {}) do
			if pp:GetAttribute("d") == nil then pp:SetAttribute("d", pp.MaxActivationDistance) end
			pp.MaxActivationDistance = pp:GetAttribute("d") * V["Alcance Estendido"]
			pp.RequiresLineOfSight = false
		end
	end})
local function auto(name, names)
	feat("Interação", name, {scan = true, rate = .35, step = function()
		for _, n in ipairs(names) do
			for _, o in ipairs(C[n] or {}) do
				if o.Parent and near(o, 20) then
					local pp = o:FindFirstChildWhichIsA("ProximityPrompt", true)
					if pp and pp.Enabled then
						pp.MaxActivationDistance = math.max(pp.MaxActivationDistance, 24)
						pp.HoldDuration = 0
						pcall(fireproximityprompt, pp)
					end
				end
			end
		end
	end})
end
auto("Auto Moedas", {"GoldPile"})
auto("Auto Itens", ITEMS)
auto("Auto Chave", {"KeyObtain"})
auto("Auto Alavanca", {"LeverForGate"})
auto("Auto Livros/Disjuntores", {"LiveHintBook", "LiveBreakerPolePickup"})
auto("Auto Gavetas", {"DrawerContainer", "ChestBoxLocked", "Toolbox"})

-- ===== 5) Visual (8) =====
local LO, EF, FG = nil, {}, nil
feat("Visual", "Fullbright", {rate = .3,
	on = function(v)
		if v then LO = {Light.Brightness, Light.Ambient, Light.OutdoorAmbient, Light.GlobalShadows}
		elseif LO then Light.Brightness, Light.Ambient, Light.OutdoorAmbient, Light.GlobalShadows = table.unpack(LO) end
	end,
	step = function() Light.Brightness = 2 Light.Ambient = Color3.new(1, 1, 1) Light.OutdoorAmbient = Color3.new(1, 1, 1) Light.GlobalShadows = false end})
feat("Visual", "Sem Neblina", {rate = .3,
	on = function(v)
		if v then FG = {Light.FogStart, Light.FogEnd} elseif FG then Light.FogStart, Light.FogEnd = FG[1], FG[2] end
		for _, a in ipairs(Light:GetChildren()) do if a:IsA("Atmosphere") then if v then a:SetAttribute("dn", a.Density) a.Density = 0 else a.Density = a:GetAttribute("dn") or a.Density end end end
	end,
	step = function() Light.FogStart = 9e8 Light.FogEnd = 9e9 end})
feat("Visual", "Remover Efeitos", {rate = .5,
	on = function(v) if not v then for e, s in pairs(EF) do if e.Parent then e.Enabled = s end end EF = {} end end,
	step = function()
		for _, e in ipairs(Light:GetChildren()) do
			if e:IsA("PostEffect") then if EF[e] == nil then EF[e] = e.Enabled end e.Enabled = false end
		end
	end})
feat("Visual", "FOV", {slider = {70, 120, 90}, on = function(v) if not v then WS.CurrentCamera.FieldOfView = 70 end end,
	step = function() WS.CurrentCamera.FieldOfView = V["FOV"] end})
feat("Visual", "Terceira Pessoa", {slider = {5, 30, 12},
	on = function(v) if not v then lp.CameraMode = Enum.CameraMode.LockFirstPerson lp.CameraMaxZoomDistance = .5 end end,
	step = function() lp.CameraMode = Enum.CameraMode.Classic lp.CameraMaxZoomDistance = V["Terceira Pessoa"] end})
local fpsL = new("TextLabel", {Size = UDim2.fromOffset(120, 18), Position = UDim2.new(.5, -60, 0, 4), BackgroundTransparency = 1, TextColor3 = GRN, Font = Enum.Font.GothamBold, TextSize = 13, TextStrokeTransparency = .5, Visible = false, Text = ""}, gui)
local roomL = new("TextLabel", {Size = UDim2.fromOffset(220, 18), Position = UDim2.new(.5, -110, 0, 22), BackgroundTransparency = 1, TextColor3 = YEL, Font = Enum.Font.GothamBold, TextSize = 13, TextStrokeTransparency = .5, Visible = false, Text = ""}, gui)
feat("Visual", "Contador de FPS", {rate = .5, on = function(v) fpsL.Visible = v end, step = function() fpsL.Text = "FPS " .. math.floor(1 / lastDt) end})
feat("Visual", "Contador de Sala", {rate = .5, on = function(v) roomL.Visible = v end, step = function()
	local gd = RepS:FindFirstChild("GameData")
	local lr, d = gd and gd:FindFirstChild("LatestRoom"), curDoor()
	roomL.Text = "Sala " .. (lr and lr.Value or "?") .. " | Porta: " .. (d and (d:FindFirstChild("Lock") and "trancada" or "livre") or "?")
end})
feat("Visual", "Anti-Lag", {on = function(v)
	pcall(function() settings().Rendering.QualityLevel = v and Enum.QualityLevel.Level01 or Enum.QualityLevel.Automatic end)
	Light.GlobalShadows = not v
end})

-- ===== 6) Utilidades (9) =====
local afk
feat("Utilidades", "Anti-AFK", {on = function(v)
	if afk then afk:Disconnect() afk = nil end
	if v then
		afk = lp.Idled:Connect(function()
			local vu = game:GetService("VirtualUser")
			vu:CaptureController() vu:ClickButton2(Vector2.new())
		end)
	end
end})
local lowFlag = false
feat("Utilidades", "Aviso Vida Baixa", {rate = .5, step = function()
	local h = hum()
	if h and h.Health > 0 and h.Health < 35 then
		if not lowFlag then notify("Vida baixa: " .. math.floor(h.Health), RED) end
		lowFlag = true
	else lowFlag = false end
end})
local function tpNear(o)
	local p, h = partOf(o), hrp()
	if not p or not h then return end
	local dir = h.Position - p.Position
	dir = dir.Magnitude > 1 and dir.Unit or Vector3.new(0, 0, 1)
	h.CFrame = CFrame.new(p.Position + dir * 5 + Vector3.new(0, 1, 0))
end
feat("Utilidades", "Auto TP Porta", {rate = .6, step = function()
	local d = curDoor()
	local p = d and d:FindFirstChild("Door")
	if d and p and not d:FindFirstChild("Lock") and not near(p, 10) then tpNear(p) end
end})
feat("Utilidades", "TP Porta", {btn = function() local d = curDoor() if d and d:FindFirstChild("Door") then tpNear(d.Door) else notify("Porta não encontrada", RED) end end})
feat("Utilidades", "TP Chave", {btn = function()
	scan()
	local k = C.KeyObtain and C.KeyObtain[1]
	if k then tpNear(k) else notify("Nenhuma chave nesta sala", RED) end
end})
feat("Utilidades", "Voltar ao Lobby", {btn = function() TPS:Teleport(6516141723, lp) end})
feat("Utilidades", "Copiar JobId", {btn = function()
	if setclipboard then setclipboard(game.JobId) notify("JobId copiado", GRN) end
end})
feat("Utilidades", "Resetar Personagem", {btn = function() local h = hum() if h then h.Health = 0 end end})
feat("Utilidades", "Descarregar Hub", {btn = function() unload() end})

-- ===== loop principal =====
conn(RS.Heartbeat, function(dt)
	lastDt = dt
	for _, f in ipairs(feats) do
		if f.step and S[f.name] then
			f.acc += dt
			if f.acc >= (f.rate or 0) then f.acc = 0 pcall(f.step) end
		end
	end
end)
task.spawn(function()
	while alive do
		for _, f in ipairs(feats) do if f.scan and S[f.name] then pcall(scan) break end end
		task.wait(2.5)
	end
end)

-- ===== interface =====
local function setF(f, v)
	S[f.name] = v
	if f.ui then f.ui(v) end
	if f.on then pcall(f.on, v) end
end

local main = new("Frame", {Size = UDim2.fromOffset(310, 420), Position = UDim2.fromOffset(30, 60), BackgroundColor3 = BG, ClipsDescendants = true}, gui)
corner(main, 10); new("UIStroke", {Color = ACC, Thickness = 1.5}, main)
local bar = new("Frame", {Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = BG2}, main)
new("TextLabel", {Size = UDim2.new(1, -50, 1, 0), Position = UDim2.fromOffset(12, 0), BackgroundTransparency = 1, Text = "DOORS HUB  ·  50 funções", TextColor3 = TXT, Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left}, bar)
local min = new("TextButton", {Size = UDim2.fromOffset(28, 24), Position = UDim2.new(1, -36, 0, 6), BackgroundColor3 = OFF, Text = "–", TextColor3 = TXT, Font = Enum.Font.GothamBold, TextSize = 16}, bar)
corner(min, 6)

local drag, ds, sp = false
bar.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag, ds, sp = true, i.Position, main.Position end
end)
conn(UIS.InputChanged, function(i)
	if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
		local d = i.Position - ds
		main.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
	end
end)
conn(UIS.InputEnded, function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = false end
end)

local list = new("ScrollingFrame", {Size = UDim2.new(1, 0, 1, -36), Position = UDim2.fromOffset(0, 36), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new()}, main)
new("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, list)
new("UIPadding", {PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 8)}, list)

local function build(f, par)
	local r = new("Frame", {Size = UDim2.new(1, 0, 0, f.slider and 50 or 30), BackgroundTransparency = 1}, par)
	local lbl = new("TextLabel", {Size = UDim2.new(1, -70, 0, 30), Position = UDim2.fromOffset(12, 0), BackgroundTransparency = 1, Text = f.name, TextColor3 = TXT, Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left}, r)
	if f.btn then
		local b = new("TextButton", {Size = UDim2.fromOffset(52, 20), Position = UDim2.new(1, -60, 0, 5), BackgroundColor3 = ACC, Text = "Usar", TextColor3 = TXT, Font = Enum.Font.GothamBold, TextSize = 12}, r)
		corner(b, 6)
		b.MouseButton1Click:Connect(function() pcall(f.btn) end)
		return
	end
	local sw = new("TextButton", {Size = UDim2.fromOffset(38, 18), Position = UDim2.new(1, -50, 0, 6), BackgroundColor3 = OFF, Text = "", AutoButtonColor = false}, r)
	corner(sw, 9)
	local kn = new("Frame", {Size = UDim2.fromOffset(14, 14), Position = UDim2.fromOffset(2, 2), BackgroundColor3 = Color3.new(1, 1, 1)}, sw)
	corner(kn, 7)
	f.ui = function(v)
		TS:Create(sw, TweenInfo.new(.15), {BackgroundColor3 = v and ACC or OFF}):Play()
		TS:Create(kn, TweenInfo.new(.15), {Position = v and UDim2.fromOffset(22, 2) or UDim2.fromOffset(2, 2)}):Play()
	end
	sw.MouseButton1Click:Connect(function() setF(f, not S[f.name]) end)
	if f.slider then
		local mn, mx, df, dec = f.slider[1], f.slider[2], f.slider[3], f.slider[4]
		local sbar = new("Frame", {Size = UDim2.new(1, -24, 0, 10), Position = UDim2.fromOffset(12, 34), BackgroundColor3 = OFF}, r)
		corner(sbar, 5)
		local fill = new("Frame", {Size = UDim2.fromScale((df - mn) / (mx - mn), 1), BackgroundColor3 = ACC}, sbar)
		corner(fill, 5)
		local function show() lbl.Text = f.name .. "  ·  " .. (dec and string.format("%.1f", V[f.name]) or tostring(V[f.name])) end
		show()
		local function setX(x)
			local a = math.clamp((x - sbar.AbsolutePosition.X) / sbar.AbsoluteSize.X, 0, 1)
			local v = mn + (mx - mn) * a
			v = dec and math.floor(v * 10 + .5) / 10 or math.floor(v + .5)
			V[f.name] = v; fill.Size = UDim2.fromScale(a, 1); show()
		end
		local dr = false
		sbar.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dr = true setX(i.Position.X) end
		end)
		conn(UIS.InputChanged, function(i)
			if dr and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then setX(i.Position.X) end
		end)
		conn(UIS.InputEnded, function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dr = false end
		end)
	end
end

for idx, cn in ipairs({"ESP", "Entidades", "Movimento", "Interação", "Visual", "Utilidades"}) do
	local group, n = {}, 0
	for _, f in ipairs(feats) do if f.cat == cn then group[#group + 1] = f n += 1 end end
	local box = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = BG2, LayoutOrder = idx}, list)
	corner(box, 8)
	new("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder}, box)
	local hdr = new("TextButton", {Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1, Text = "", LayoutOrder = 0}, box)
	local ht = new("TextLabel", {Size = UDim2.new(1, -12, 1, 0), Position = UDim2.fromOffset(12, 0), BackgroundTransparency = 1, Text = "▶  " .. cn .. "  (" .. n .. ")", TextColor3 = ACC, Font = Enum.Font.GothamBold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left}, hdr)
	local body = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Visible = false, LayoutOrder = 1}, box)
	new("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder}, body)
	for _, f in ipairs(group) do build(f, body) end
	hdr.MouseButton1Click:Connect(function()
		body.Visible = not body.Visible
		ht.Text = (body.Visible and "▼  " or "▶  ") .. cn .. "  (" .. n .. ")"
	end)
end

local fab = new("TextButton", {Size = UDim2.fromOffset(38, 38), Position = UDim2.fromOffset(8, 110), BackgroundColor3 = ACC, Text = "D", TextColor3 = TXT, Font = Enum.Font.GothamBold, TextSize = 18}, gui)
corner(fab, 19)
local function toggleUI() main.Visible = not main.Visible end
fab.MouseButton1Click:Connect(toggleUI)
min.MouseButton1Click:Connect(toggleUI)
conn(UIS.InputBegan, function(i, g) if not g and i.KeyCode == Enum.KeyCode.RightShift then toggleUI() end end)

unload = function()
	alive = false
	for _, f in ipairs(feats) do
		if S[f.name] and f.on then pcall(f.on, false) end
		S[f.name] = false
	end
	for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
	gui:Destroy()
	getgenv().DoorsHub = nil
end
getgenv().DoorsHub = unload

notify("DOORS Hub carregado", GRN)
