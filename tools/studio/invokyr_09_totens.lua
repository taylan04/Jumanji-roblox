--[[
INVOKYR - Script 09: Totens (esconderijos, coleta, maldicao, entrega e liberacao do dado)
=========================================================================================
Rode na BARRA DE COMANDOS (View > Command Bar) com o jogo PARADO. Pode rodar quantas vezes quiser.

REGRAS DESTA VERSAO (decididas por voce):
  - Um totem por jogador de cada vez.
  - Pode largar no meio do caminho: o totem fica exatamente onde caiu.
  - As maldicoes ATRAPALHAM, nao atacam o jogador.
  - A unica que causa dano e o FOGO, e so se voce andar para dentro da chama que o totem
    cuspiu. O dano tem piso em 1 de vida (CFG.VIDA_MINIMA no script do servidor): ninguem
    morre. Para deixar matar, troque esse 1 por 0.
  - Precisa entregar 3 totens no altar da mesa para liberar a proxima jogada do dado.

O que este script cria (e so mexe no que ele mesmo criou):
  - ReplicatedStorage > Invokyr > Totens  : moldes dos 5 totens (PROVISORIOS ate voce importar os GLB)
  - ReplicatedStorage > Invokyr > TotemEstado / TotemLargar / MaldicaoEfeito : remotes novos
  - Workspace > Invokyr > Totens > Esconderijos : 8 pontos de teste DENTRO da sala principal
  - Workspace > Invokyr > Totens > Ativos       : onde os totens sorteados aparecem
  - Workspace > Invokyr > Totens > Altar        : ponto de entrega ao lado da mesa
  - ServerScriptService > Invokyr_Totens        : regras (servidor)
  - StarterPlayerScripts > Invokyr_TotensCliente: HUD e efeitos (cliente)

NAO altera a sala, o tabuleiro, a lanterna nem o movimento. Tudo que sai de uso vai para
ServerStorage > Invokyr_Backup.

ESCONDERIJOS: qualquer Part com a tag "Invokyr_Esconderijo" vira um esconderijo, em qualquer
lugar do Workspace. Os 8 da sala principal sao so para testar o ciclo agora; quando a mansao
existir, basta marcar as pecas de la com essa tag e apagar estes.
]]

local RunService = game:GetService("RunService")
if RunService:IsRunning() then
	error("[Invokyr] O jogo esta em Play. Clique em PARAR e rode de novo.")
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local CollectionService = game:GetService("CollectionService")
local ChangeHistoryService = game:GetService("ChangeHistoryService")

local CFG = {
	ESCALA_TOTEM = 1.0,        -- 1.0 = o tamanho que veio do Blender (~4.3 studs de altura)
	MOSTRAR_ESCONDERIJOS = true,  -- true: marcadores visiveis no Studio para voce conferir
	ALTURA_ESCONDERIJO = 0.1,
}

local avisos, linhas = {}, {}
local function info(...) local t = table.concat({...}, " "); table.insert(linhas, t) end
local function aviso(...) local t = table.concat({...}, " "); table.insert(avisos, t) end

local recording
pcall(function() recording = ChangeHistoryService:TryBeginRecording("Invokyr Script 09 totens") end)

local function backup(inst)
	if not inst then return end
	local bk = ServerStorage:FindFirstChild("Invokyr_Backup") or Instance.new("Folder")
	bk.Name = "Invokyr_Backup"; bk.Parent = ServerStorage
	inst.Parent = bk
end

-- ---------------------------------------------------------------- confere o que ja existe
local raiz = workspace:FindFirstChild("Invokyr")
if not raiz then error("[Invokyr] Nao achei Workspace > Invokyr. Rode os scripts 02 e 03 antes.") end
local sala = raiz:FindFirstChild("SalaPrincipal")
if not sala then error("[Invokyr] Nao achei a SalaPrincipal. Rode o Script 02 antes.") end
local tab = sala:FindFirstChild("Tabuleiro")
if not tab then error("[Invokyr] Nao achei o Tabuleiro. Rode o Script 07 antes.") end
local remotes = ReplicatedStorage:FindFirstChild("Invokyr")
if not remotes then error("[Invokyr] Nao achei ReplicatedStorage > Invokyr. Rode o Script 03 antes.") end
for _, n in ipairs({ "LiberarDado", "AbrirPortas", "MensagemTabuleiro" }) do
	if not remotes:FindFirstChild(n) then aviso("Falta o remote '" .. n .. "' (Script 03/07). O ciclo pode nao fechar.") end
end

-- ---------------------------------------------------------------- remotes novos
local function remote(nome, classe)
	local r = remotes:FindFirstChild(nome)
	if r and r.ClassName ~= classe then r:Destroy(); r = nil end
	if not r then r = Instance.new(classe); r.Name = nome; r.Parent = remotes end
	return r
end
remote("TotemEstado", "RemoteEvent")       -- servidor -> cliente: o que voce carrega, quantos faltam
remote("TotemLargar", "RemoteEvent")       -- cliente -> servidor: quero largar
remote("MaldicaoEfeito", "RemoteEvent")    -- servidor -> cliente: clarao, empurrao, gelo, fogo

-- ---------------------------------------------------------------- moldes provisorios dos totens
-- Quando voce importar os GLB de verdade, coloque cada modelo aqui com o MESMO nome
-- (Totem_Fogo, Totem_Gelo, ...) e com PrimaryPart definida. O script passa a usar o seu
-- automaticamente, igual a lanterna com mao do Script 05.
local moldes = remotes:FindFirstChild("Totens")
if not moldes then moldes = Instance.new("Folder"); moldes.Name = "Totens"; moldes.Parent = remotes end

local TIPOS = {
	{ nome = "Fogo",      corpo = Color3.fromRGB(38, 30, 26),  brilho = Color3.fromRGB(255, 92, 30),  enfeite = Color3.fromRGB(176, 120, 48) },
	{ nome = "Gelo",      corpo = Color3.fromRGB(30, 36, 42),  brilho = Color3.fromRGB(150, 225, 255), enfeite = Color3.fromRGB(150, 165, 175) },
	{ nome = "Teleporte", corpo = Color3.fromRGB(34, 28, 42),  brilho = Color3.fromRGB(180, 95, 255),  enfeite = Color3.fromRGB(176, 120, 48) },
	{ nome = "Raio",      corpo = Color3.fromRGB(30, 34, 38),  brilho = Color3.fromRGB(255, 205, 70),  enfeite = Color3.fromRGB(176, 120, 48) },
	{ nome = "Diamante",  corpo = Color3.fromRGB(34, 40, 44),  brilho = Color3.fromRGB(170, 245, 255), enfeite = Color3.fromRGB(150, 165, 175) },
}

local function pecaDe(pai, nome, forma, tam, pos, cor, material)
	local p = Instance.new("Part")
	p.Name = nome
	p.Shape = forma
	p.Size = tam
	p.CFrame = CFrame.new(pos)
	p.Color = cor
	p.Material = material
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = pai
	return p
end

local BLOCO, CIL, BOLA = Enum.PartType.Block, Enum.PartType.Cylinder, Enum.PartType.Ball
local provisorios = 0
for _, t in ipairs(TIPOS) do
	local nomeMolde = "Totem_" .. t.nome
	local atual = moldes:FindFirstChild(nomeMolde)
	if atual and atual:GetAttribute("Provisorio") ~= true then
		-- modelo de verdade ja colocado por voce: nao encosta
		info("Molde '" .. nomeMolde .. "': usando o SEU modelo importado.")
	else
		if atual then atual:Destroy() end
		local m = Instance.new("Model")
		m.Name = nomeMolde
		m:SetAttribute("Provisorio", true)
		m:SetAttribute("Tipo", t.nome)
		-- silhueta grosseira so para o ciclo rodar: base octogonal, corpo, cabeca, olhos e coroa
		local base = pecaDe(m, "Base", CIL, Vector3.new(0.42, 2.05, 2.05), Vector3.new(0, 0.21, 0), t.corpo, Enum.Material.Metal)
		base.CFrame = CFrame.new(0, 0.21, 0) * CFrame.Angles(0, 0, math.rad(90))
		local faixa = pecaDe(m, "Faixa", CIL, Vector3.new(0.13, 1.96, 1.96), Vector3.new(0, 0.46, 0), t.enfeite, Enum.Material.Metal)
		faixa.CFrame = CFrame.new(0, 0.46, 0) * CFrame.Angles(0, 0, math.rad(90))
		pecaDe(m, "Corpo", BLOCO, Vector3.new(2.0, 1.5, 1.5), Vector3.new(0, 1.3, 0), t.corpo, Enum.Material.Metal)
		pecaDe(m, "Brasao", BLOCO, Vector3.new(0.9, 0.9, 0.12), Vector3.new(0, 1.35, -0.78), t.brilho, Enum.Material.Neon)
		pecaDe(m, "Cabeca", BLOCO, Vector3.new(1.7, 1.9, 1.45), Vector3.new(0, 3.0, 0), t.corpo, Enum.Material.Metal)
		pecaDe(m, "Boca", BLOCO, Vector3.new(0.95, 0.5, 0.2), Vector3.new(0, 2.45, -0.68), Color3.fromRGB(8, 8, 10), Enum.Material.SmoothPlastic)
		for _, lado in ipairs({ -1, 1 }) do
			pecaDe(m, "Olho", BOLA, Vector3.new(0.42, 0.42, 0.42), Vector3.new(lado * 0.42, 3.3, -0.62), t.brilho, Enum.Material.Neon)
		end
		local coroa = pecaDe(m, "Coroa", CIL, Vector3.new(0.16, 1.62, 1.62), Vector3.new(0, 3.92, 0), t.enfeite, Enum.Material.Metal)
		coroa.CFrame = CFrame.new(0, 3.92, 0) * CFrame.Angles(0, 0, math.rad(90))
		for i = 0, 4 do
			pecaDe(m, "Ponta", BLOCO, Vector3.new(0.2, 0.5, 0.2), Vector3.new((i - 2) * 0.33, 4.22, 0), t.brilho, Enum.Material.Neon)
		end
		local raizPeca = m:FindFirstChild("Corpo")
		m.PrimaryPart = raizPeca
		m.Parent = moldes
		provisorios += 1
	end
end
if provisorios > 0 then
	info("Moldes PROVISORIOS criados: " .. provisorios .. " (troque pelos GLB quando importar).")
end

-- ---------------------------------------------------------------- pasta dos totens no mundo
local velha = raiz:FindFirstChild("Totens")
if velha then velha:Destroy() end
local pasta = Instance.new("Folder"); pasta.Name = "Totens"; pasta.Parent = raiz
local esconderijos = Instance.new("Folder"); esconderijos.Name = "Esconderijos"; esconderijos.Parent = pasta
local ativos = Instance.new("Folder"); ativos.Name = "Ativos"; ativos.Parent = pasta

-- ---------------------------------------------------------------- esconderijos de teste
-- 8 pontos espalhados pela sala principal: 4 nos cantos das estantes, 4 na frente dos portais.
local colisao = sala:FindFirstChild("Colisao")
local piso = colisao and colisao:FindFirstChild("COL_Piso")
local centro = piso and piso.Position or Vector3.zero
local alturaPiso = piso and (piso.Position.Y + piso.Size.Y / 2) or 0.6

local PONTOS_TESTE = {
	{ nome = "Esc_Estante_NE", d = Vector3.new(9.0, 0, -9.0) },
	{ nome = "Esc_Estante_SE", d = Vector3.new(9.0, 0, 9.0) },
	{ nome = "Esc_Estante_SO", d = Vector3.new(-9.0, 0, 9.0) },
	{ nome = "Esc_Estante_NO", d = Vector3.new(-9.0, 0, -9.0) },
	{ nome = "Esc_Portal_N",   d = Vector3.new(0, 0, -12.4) },
	{ nome = "Esc_Portal_L",   d = Vector3.new(12.4, 0, 0) },
	{ nome = "Esc_Portal_S",   d = Vector3.new(0, 0, 12.4) },
	{ nome = "Esc_Portal_O",   d = Vector3.new(-12.4, 0, 0) },
}
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Include
params.FilterDescendantsInstances = { colisao }
local criados = 0
for _, pt in ipairs(PONTOS_TESTE) do
	local alvo = Vector3.new(centro.X, 0, centro.Z) + pt.d
	local y = alturaPiso
	local r = workspace:Raycast(Vector3.new(alvo.X, alturaPiso + 12, alvo.Z), Vector3.new(0, -30, 0), params)
	if r then y = r.Position.Y else aviso(pt.nome .. ": nao achei piso abaixo; usando a altura padrao.") end
	local p = Instance.new("Part")
	p.Name = pt.nome
	p.Size = Vector3.new(2.4, 0.2, 2.4)
	p.CFrame = CFrame.new(alvo.X, y + CFG.ALTURA_ESCONDERIJO, alvo.Z)
	p.Anchored = true; p.CanCollide = false; p.CanTouch = false; p.CanQuery = false
	p.CastShadow = false; p.Locked = true
	p.Transparency = CFG.MOSTRAR_ESCONDERIJOS and 0.7 or 1
	p.Color = Color3.fromRGB(120, 255, 170); p.Material = Enum.Material.Neon
	p.Parent = esconderijos
	CollectionService:AddTag(p, "Invokyr_Esconderijo")
	criados += 1
end
info("Esconderijos de teste criados na sala: " .. criados .. " (tag Invokyr_Esconderijo).")

-- ---------------------------------------------------------------- altar de entrega
local gatilho = tab:FindFirstChild("Gatilho")
local posAltar = gatilho and (gatilho.Position - Vector3.new(0, 1.2, 0)) or (centro + Vector3.new(0, 3, 0))
local altar = Instance.new("Part")
altar.Name = "Altar"
altar.Size = Vector3.new(3.2, 0.3, 3.2)
altar.CFrame = CFrame.new(posAltar)
altar.Anchored = true; altar.CanCollide = false; altar.CanTouch = false; altar.CanQuery = true
altar.Transparency = 1; altar.CastShadow = false; altar.Locked = true
altar.Parent = pasta
local promptAltar = Instance.new("ProximityPrompt")
promptAltar.Name = "Entregar"
promptAltar.ActionText = "Entregar o totem"
promptAltar.ObjectText = "Invokyr"
promptAltar.KeyboardKeyCode = Enum.KeyCode.E
promptAltar.HoldDuration = 0.6
promptAltar.MaxActivationDistance = 10
promptAltar.RequiresLineOfSight = false
promptAltar.Enabled = false
promptAltar.Parent = altar
info("Altar de entrega colocado ao lado da mesa.")

-- ================================================================ SERVIDOR
local FONTE_SERVIDOR = [==[--[[ Invokyr_Totens (Script, ServerScriptService) - gerado pelo Script 09
Sorteia os totens pelos esconderijos quando a rodada comeca, controla quem carrega o que,
aplica a maldicao, aceita a entrega no altar e libera a proxima jogada do dado.

Um totem por jogador. Pode largar: fica onde caiu. A maldicao atrapalha, mas NAO tira vida.
Tudo que muda o jogo e decidido aqui no servidor; o cliente so mostra e sente.
]]
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local CFG = {
	POR_RODADA = 3,             -- quantos totens entregar para liberar o dado
	NO_MAPA = 4,                -- quantos aparecem espalhados por rodada
	CHANCE_DIAMANTE = 0.18,     -- chance de um dos totens da rodada ser o raro
	-- onde o totem fica preso no jogador. Em primeira pessoa ele atrapalha a vista de proposito;
	-- se ficar tapando demais (ou de menos), mexa aqui. Os modelos de verdade vao pedir outro ajuste.
	ALTURA_CARREGADO = -1.4,
	DISTANCIA_CARREGADO = 3.0,
	-- FOGO: o totem cospe um jato PARA FRENTE, nunca no jogador. A chama fica no chao e
	-- queima quem pisar nela - inclusive os outros jogadores, e inclusive quem carrega,
	-- se ele andar para dentro do proprio fogo.
	FOGO_MIN = 6, FOGO_MAX = 10,
	FOGO_ALCANCE = 9,           -- a quantos studs na frente o jato cai
	FOGO_RAIO = 4.5,            -- tamanho da poca de fogo
	FOGO_DURACAO = 7,           -- segundos que a chama fica queimando no chao
	FOGO_DANO = 7,              -- dano por segundo em quem estiver dentro dela
	VIDA_MINIMA = 1,            -- 1 = o fogo NUNCA mata (foi o combinado). 0 = pode matar.
	-- demais maldicoes: nenhuma tira vida
	GELO_LADO = 8,              -- tamanho da placa de gelo que segue o jogador
	TELE_MIN = 7, TELE_MAX = 13, TELE_DISTANCIA = 22,
	RAIO_MIN = 5, RAIO_MAX = 10, RAIO_DISTANCIA = 9,
}

local remotes = RS:WaitForChild("Invokyr")
local moldes = remotes:WaitForChild("Totens")
local estadoRE = remotes:WaitForChild("TotemEstado")
local largarRE = remotes:WaitForChild("TotemLargar")
local maldicaoRE = remotes:WaitForChild("MaldicaoEfeito")
local liberar = remotes:WaitForChild("LiberarDado")
local abrirPortas = remotes:FindFirstChild("AbrirPortas")
local msg = remotes:FindFirstChild("MensagemTabuleiro")

local raiz = workspace:WaitForChild("Invokyr")
local sala = raiz:WaitForChild("SalaPrincipal")
local tab = sala:WaitForChild("Tabuleiro")
local pasta = raiz:WaitForChild("Totens")
local ativos = pasta:WaitForChild("Ativos")
local altar = pasta:WaitForChild("Altar")
local promptAltar = altar:WaitForChild("Entregar")

local ORDEM = { "Fogo", "Gelo", "Teleporte", "Raio" }
local carregando = {}      -- player -> { modelo = Model, tipo = string, desde = number }
local entregues = 0
local rodadaAtiva = false
local queimadura = {}      -- player -> os.clock() do ultimo aviso de queimadura
local chamasPasta = pasta:FindFirstChild("Chamas")
if not chamasPasta then
	chamasPasta = Instance.new("Folder"); chamasPasta.Name = "Chamas"; chamasPasta.Parent = pasta
end

local function dizer(texto, dur)
	if msg then msg:FireAllClients(texto, dur or 4) end
end
local function avisarUm(player, texto, dur)
	if msg then msg:FireClient(player, texto, dur or 3) end
end
local function mandarEstado(player)
	local reg = carregando[player]
	estadoRE:FireClient(player, reg and reg.tipo or nil, entregues, CFG.POR_RODADA)
end
local function mandarTodos()
	for _, p in ipairs(Players:GetPlayers()) do mandarEstado(p) end
end

-- ------------------------------------------------------------ montagem do totem
local function todasAsPecas(modelo)
	local t = {}
	for _, d in ipairs(modelo:GetDescendants()) do
		if d:IsA("BasePart") then table.insert(t, d) end
	end
	return t
end

local function soldar(modelo)
	local base = modelo.PrimaryPart
	if not base then return end
	for _, p in ipairs(todasAsPecas(modelo)) do
		if p ~= base then
			for _, w in ipairs(p:GetChildren()) do
				if w:IsA("WeldConstraint") or w:IsA("Weld") then w:Destroy() end
			end
			local w = Instance.new("WeldConstraint")
			w.Part0 = base; w.Part1 = p; w.Parent = p
		end
	end
end

local function criarTotem(tipo)
	local molde = moldes:FindFirstChild("Totem_" .. tipo)
	if not molde then return nil end
	local m = molde:Clone()
	m.Name = "Totem_" .. tipo
	m:SetAttribute("Tipo", tipo)
	if not m.PrimaryPart then
		local primeira = todasAsPecas(m)[1]
		m.PrimaryPart = primeira
	end
	for _, p in ipairs(todasAsPecas(m)) do
		p.Anchored = false
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = true
		p.Massless = true
		p.Locked = true
	end
	if m.PrimaryPart then m.PrimaryPart.CanCollide = true end
	soldar(m)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "Pegar"
	prompt.ActionText = "Pegar o totem"
	prompt.ObjectText = "Totem de " .. tipo
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0.4
	prompt.MaxActivationDistance = 9
	prompt.RequiresLineOfSight = false
	prompt.Parent = m.PrimaryPart
	return m
end

local function pousar(modelo, posicao)
	for _, p in ipairs(todasAsPecas(modelo)) do
		p.Anchored = true
		p.CanQuery = true
	end
	if modelo.PrimaryPart then modelo.PrimaryPart.CanCollide = true end
	modelo:PivotTo(CFrame.new(posicao) * CFrame.Angles(0, math.random() * math.pi * 2, 0))
	modelo:SetAttribute("Carregador", nil)
	local prompt = modelo.PrimaryPart and modelo.PrimaryPart:FindFirstChild("Pegar")
	if prompt then prompt.Enabled = true end
end

-- ------------------------------------------------------------ sorteio da rodada
local function limparTudo()
	for p, reg in pairs(carregando) do
		carregando[p] = nil
		if reg.modelo then reg.modelo:Destroy() end
	end
	for _, m in ipairs(ativos:GetChildren()) do m:Destroy() end
	for _, c in ipairs(chamasPasta:GetChildren()) do c:Destroy() end
	entregues = 0
	rodadaAtiva = false
	promptAltar.Enabled = false
	mandarTodos()
end

local function listaEsconderijos()
	local t = {}
	for _, p in ipairs(CollectionService:GetTagged("Invokyr_Esconderijo")) do
		if p:IsA("BasePart") and p:IsDescendantOf(workspace) then table.insert(t, p) end
	end
	return t
end

local function espalhar()
	limparTudo()
	local pontos = listaEsconderijos()
	if #pontos == 0 then
		warn("[Invokyr] Nenhum esconderijo com a tag Invokyr_Esconderijo. Os totens nao foram espalhados.")
		return
	end
	-- embaralha os esconderijos
	for i = #pontos, 2, -1 do
		local j = math.random(1, i); pontos[i], pontos[j] = pontos[j], pontos[i]
	end
	local tipos = {}
	for _, nome in ipairs(ORDEM) do table.insert(tipos, nome) end
	for i = #tipos, 2, -1 do
		local j = math.random(1, i); tipos[i], tipos[j] = tipos[j], tipos[i]
	end
	if math.random() < CFG.CHANCE_DIAMANTE then tipos[#tipos] = "Diamante" end
	local quantos = math.min(CFG.NO_MAPA, #pontos, #tipos)
	for i = 1, quantos do
		local m = criarTotem(tipos[i])
		if m then
			m.Parent = ativos
			pousar(m, pontos[i].Position + Vector3.new(0, 0.1, 0))
		else
			warn("[Invokyr] Nao achei o molde Totem_" .. tipos[i] .. " em ReplicatedStorage > Invokyr > Totens.")
		end
	end
	rodadaAtiva = true
	mandarTodos()
	print("[Invokyr] Totens espalhados:", quantos, "| precisa entregar", CFG.POR_RODADA)
end

-- ------------------------------------------------------------ pegar, largar, entregar
local function prender(player, modelo)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not (hrp and modelo.PrimaryPart) then return false end
	for _, p in ipairs(todasAsPecas(modelo)) do
		p.Anchored = false
		p.CanCollide = false
		p.CanQuery = false
		p.Massless = true
	end
	local alvo = hrp.CFrame * CFrame.new(0, CFG.ALTURA_CARREGADO, -CFG.DISTANCIA_CARREGADO)
	modelo:PivotTo(alvo)
	local w = Instance.new("WeldConstraint")
	w.Name = "Carregado"
	w.Part0 = hrp; w.Part1 = modelo.PrimaryPart; w.Parent = modelo.PrimaryPart
	modelo:SetAttribute("Carregador", player.UserId)
	local prompt = modelo.PrimaryPart:FindFirstChild("Pegar")
	if prompt then prompt.Enabled = false end
	modelo.Parent = ativos
	return true
end

local function soltar(player, motivo)
	local reg = carregando[player]
	if not reg then return end
	carregando[player] = nil
	local modelo = reg.modelo
	if not (modelo and modelo.Parent) then mandarEstado(player); return end
	local w = modelo.PrimaryPart and modelo.PrimaryPart:FindFirstChild("Carregado")
	if w then w:Destroy() end
	local pos = modelo:GetPivot().Position
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if hrp then pos = (hrp.CFrame * CFrame.new(0, -1.2, -2.6)).Position end
	-- encosta no chao mais proximo abaixo
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.FilterDescendantsInstances = { ativos, char }
	local hit = workspace:Raycast(pos + Vector3.new(0, 4, 0), Vector3.new(0, -40, 0), rp)
	if hit then pos = hit.Position + Vector3.new(0, 0.1, 0) end
	pousar(modelo, pos)
	maldicaoRE:FireClient(player, "fim", reg.tipo)
	mandarEstado(player)
	promptAltar.Enabled = false
end

local function pegar(player, modelo)
	if not rodadaAtiva then return end
	if carregando[player] then
		avisarUm(player, "Voce ja esta carregando um totem.", 2)
		return
	end
	if modelo:GetAttribute("Carregador") ~= nil then return end
	local tipo = modelo:GetAttribute("Tipo") or "Fogo"
	if not prender(player, modelo) then return end
	carregando[player] = { modelo = modelo, tipo = tipo, desde = os.clock(), proxima = 0 }
	maldicaoRE:FireClient(player, "inicio", tipo)
	mandarEstado(player)
end

local function entregar(player)
	local reg = carregando[player]
	if not reg then return end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	if (hrp.Position - altar.Position).Magnitude > promptAltar.MaxActivationDistance + 4 then return end
	local modelo = reg.modelo
	carregando[player] = nil
	if modelo then modelo:Destroy() end
	entregues += 1
	maldicaoRE:FireClient(player, "fim", reg.tipo)
	mandarTodos()
	if entregues >= CFG.POR_RODADA then
		dizer("Os totens foram entregues. O tabuleiro aceita a proxima jogada.", 5)
		if abrirPortas then abrirPortas:Fire("todas", false) end
		rodadaAtiva = false
		for _, m in ipairs(ativos:GetChildren()) do m:Destroy() end
		task.wait(0.4)
		liberar:Fire()
	else
		dizer("Totem entregue. Faltam " .. (CFG.POR_RODADA - entregues) .. ".", 3)
	end
end

-- liga os prompts que ja existem e os que aparecerem
local function ligarPrompt(modelo)
	local base = modelo.PrimaryPart
	local prompt = base and base:FindFirstChild("Pegar")
	if prompt then
		prompt.Triggered:Connect(function(jogador) pegar(jogador, modelo) end)
	end
end
ativos.ChildAdded:Connect(function(m)
	if m:IsA("Model") then task.defer(ligarPrompt, m) end
end)
promptAltar.Triggered:Connect(entregar)
largarRE.OnServerEvent:Connect(function(player)
	if carregando[player] then soltar(player, "jogador") end
end)

-- ------------------------------------------------------------ maldicoes (so atrapalham)
local gelos = {}   -- player -> Part
local function placaDeGelo(player)
	local g = gelos[player]
	if not g then
		g = Instance.new("Part")
		g.Name = "Invokyr_Gelo"
		g.Size = Vector3.new(CFG.GELO_LADO, 0.4, CFG.GELO_LADO)
		g.Anchored = true
		g.CanCollide = true
		g.CanTouch = false
		g.CanQuery = false
		g.CastShadow = false
		g.Locked = true
		g.Transparency = 0.5
		g.Color = Color3.fromRGB(190, 235, 255)
		g.Material = Enum.Material.Ice
		-- ordem: densidade, ATRITO, elasticidade, PESO DO ATRITO, peso da elasticidade.
		-- atrito 0 com peso 100 manda no contato: o jogador desliza mesmo em cima do piso normal.
		g.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0, 0.1, 100, 1)
		g.Parent = pasta
		gelos[player] = g
	end
	return g
end
local function tirarGelo(player)
	local g = gelos[player]
	if g then g:Destroy(); gelos[player] = nil end
end

local function chaoAbaixo(char, hrp)
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.FilterDescendantsInstances = { char, ativos, pasta }
	return workspace:Raycast(hrp.Position, Vector3.new(0, -12, 0), rp)
end

-- Fogo: um jato para a frente de quem carrega. Cai no chao e vira uma poca que queima.
-- Como sai na direcao em que o jogador esta olhando, ele acaba bloqueando o proprio caminho.
local function cuspirFogo(player, char, hrp)
	local frente = hrp.CFrame.LookVector * Vector3.new(1, 0, 1)
	if frente.Magnitude < 0.05 then return end
	frente = frente.Unit
	local alvo = hrp.Position + frente * CFG.FOGO_ALCANCE
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.FilterDescendantsInstances = { char, ativos, pasta }
	local hit = workspace:Raycast(alvo + Vector3.new(0, 7, 0), Vector3.new(0, -34, 0), rp)
	if not hit then return end
	local c = Instance.new("Part")
	c.Name = "Chama"
	c.Size = Vector3.new(CFG.FOGO_RAIO * 2, 0.4, CFG.FOGO_RAIO * 2)
	c.CFrame = CFrame.new(hit.Position + Vector3.new(0, 0.2, 0))
	c.Anchored = true; c.CanCollide = false; c.CanTouch = false; c.CanQuery = false
	c.Transparency = 1; c.CastShadow = false; c.Locked = true
	c.Parent = chamasPasta
	maldicaoRE:FireAllClients("chama", hit.Position, CFG.FOGO_RAIO, CFG.FOGO_DURACAO)
	task.delay(CFG.FOGO_DURACAO, function() c:Destroy() end)
end

local function queimar(player, hum, dt)
	local alvo = math.max(hum.Health - CFG.FOGO_DANO * dt, CFG.VIDA_MINIMA)
	if alvo >= hum.Health then return end
	hum.Health = alvo
	local agora = os.clock()
	if not queimadura[player] or agora - queimadura[player] > 0.4 then
		queimadura[player] = agora
		maldicaoRE:FireClient(player, "queimando", nil)
	end
end

local function teleportar(player, char, hrp)
	local ang = math.random() * math.pi * 2
	local dist = CFG.TELE_DISTANCIA * (0.5 + math.random() * 0.5)
	local alvo = hrp.Position + Vector3.new(math.cos(ang) * dist, 6, math.sin(ang) * dist)
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.FilterDescendantsInstances = { char, ativos, pasta }
	local hit = workspace:Raycast(alvo, Vector3.new(0, -40, 0), rp)
	if not hit then return false end
	maldicaoRE:FireClient(player, "teleporte", nil)
	task.wait(0.15)
	if char.Parent then char:PivotTo(CFrame.new(hit.Position + Vector3.new(0, 3.2, 0)) * (hrp.CFrame - hrp.CFrame.Position)) end
	return true
end

RunService.Heartbeat:Connect(function(dt)
	local agora = os.clock()
	for player, reg in pairs(carregando) do
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not (hum and hrp and hum.Health > 0) then
			-- o personagem sumiu: o totem fica onde ele estava
			soltar(player, "sumiu")
		else
			if reg.tipo == "Gelo" then
				local hit = chaoAbaixo(char, hrp)
				if hit then
					local g = placaDeGelo(player)
					-- o topo da placa fica rente ao chao, para o jogador nao subir um degrau
					g.CFrame = CFrame.new(hit.Position.X, hit.Position.Y + 0.05 - g.Size.Y / 2, hit.Position.Z)
				end
			end
			if reg.tipo == "Fogo" then
				if reg.proxima == 0 then
					reg.proxima = agora + CFG.FOGO_MIN + math.random() * (CFG.FOGO_MAX - CFG.FOGO_MIN)
				elseif agora >= reg.proxima then
					reg.proxima = agora + CFG.FOGO_MIN + math.random() * (CFG.FOGO_MAX - CFG.FOGO_MIN)
					task.spawn(cuspirFogo, player, char, hrp)
				end
			elseif reg.tipo == "Teleporte" then
				if reg.proxima == 0 then
					reg.proxima = agora + CFG.TELE_MIN + math.random() * (CFG.TELE_MAX - CFG.TELE_MIN)
				elseif agora >= reg.proxima then
					reg.proxima = agora + CFG.TELE_MIN + math.random() * (CFG.TELE_MAX - CFG.TELE_MIN)
					task.spawn(teleportar, player, char, hrp)
				end
			elseif reg.tipo == "Raio" then
				if reg.proxima == 0 then
					reg.proxima = agora + CFG.RAIO_MIN + math.random() * (CFG.RAIO_MAX - CFG.RAIO_MIN)
				elseif agora >= reg.proxima then
					reg.proxima = agora + CFG.RAIO_MIN + math.random() * (CFG.RAIO_MAX - CFG.RAIO_MIN)
					local ang = math.random() * math.pi * 2
					local ponto = hrp.Position + Vector3.new(math.cos(ang) * CFG.RAIO_DISTANCIA, 0, math.sin(ang) * CFG.RAIO_DISTANCIA)
					maldicaoRE:FireAllClients("raio", ponto)
					maldicaoRE:FireClient(player, "empurrao", (hrp.Position - ponto).Unit)
				end
			end
		end
	end
	-- queimadura: qualquer jogador em cima de uma poca de fogo, carregando totem ou nao
	local pocas = chamasPasta:GetChildren()
	if #pocas > 0 then
		for _, pl in ipairs(Players:GetPlayers()) do
			local ch = pl.Character
			local h = ch and ch:FindFirstChildOfClass("Humanoid")
			local r = ch and ch:FindFirstChild("HumanoidRootPart")
			if h and r and h.Health > 0 then
				for _, c in ipairs(pocas) do
					local plano = (r.Position - c.Position) * Vector3.new(1, 0, 1)
					if plano.Magnitude <= CFG.FOGO_RAIO and math.abs(r.Position.Y - c.Position.Y) < 6 then
						queimar(pl, h, dt)
						break
					end
				end
			end
		end
	end
	-- limpa gelo de quem nao carrega mais o totem de gelo
	for player, _ in pairs(gelos) do
		local reg = carregando[player]
		if not (reg and reg.tipo == "Gelo") then tirarGelo(player) end
	end
	-- o prompt de entrega so acende para quem esta carregando
	local algumPerto = false
	for player, _ in pairs(carregando) do
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hrp and (hrp.Position - altar.Position).Magnitude <= promptAltar.MaxActivationDistance then
			algumPerto = true
		end
	end
	if promptAltar.Enabled ~= algumPerto then promptAltar.Enabled = algumPerto end
end)

-- ------------------------------------------------------------ liga no tabuleiro
tab:GetAttributeChangedSignal("Estado"):Connect(function()
	local e = tab:GetAttribute("Estado")
	if e == "Explorando" then
		task.wait(0.3)
		espalhar()
	elseif e == "Fechado" then
		limparTudo()
	end
end)

Players.PlayerAdded:Connect(function(p)
	p.CharacterAdded:Connect(function()
		task.wait(0.4)
		mandarEstado(p)
	end)
	task.wait(0.5)
	mandarEstado(p)
end)
Players.PlayerRemoving:Connect(function(p)
	if carregando[p] then soltar(p, "saiu") end
	tirarGelo(p)
end)

for _, m in ipairs(ativos:GetChildren()) do ligarPrompt(m) end
if tab:GetAttribute("Estado") == "Explorando" then espalhar() end
print("[Invokyr] Totens prontos. Esconderijos:", #listaEsconderijos(), "| entregar", CFG.POR_RODADA, "por rodada")
]==]

-- ================================================================ CLIENTE
local FONTE_CLIENTE = [==[--[[ Invokyr_TotensCliente (LocalScript, StarterPlayerScripts) - gerado pelo Script 09
Mostra o que voce carrega e quantos faltam, a tecla Q para largar, e os efeitos
das maldicoes (brasa do fogo, clarao do raio, empurrao, piscada do teleporte).
Nao mexe em WalkSpeed: a corrida e o agachar continuam sendo do Script 08.
]]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CAS = game:GetService("ContextActionService")
local Lighting = game:GetService("Lighting")
local RS = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remotes = RS:WaitForChild("Invokyr")
local estadoRE = remotes:WaitForChild("TotemEstado")
local largarRE = remotes:WaitForChild("TotemLargar")
local maldicaoRE = remotes:WaitForChild("MaldicaoEfeito")

local CORES = {
	Fogo = Color3.fromRGB(255, 110, 50),
	Gelo = Color3.fromRGB(150, 225, 255),
	Teleporte = Color3.fromRGB(190, 110, 255),
	Raio = Color3.fromRGB(255, 210, 90),
	Diamante = Color3.fromRGB(180, 248, 255),
}
local AVISO = {
	Fogo = "O totem cospe fogo a sua frente. Nao ande para dentro dele.",
	Gelo = "O chao congela sob os seus pes.",
	Teleporte = "O totem de teleporte puxa voce para outro lugar.",
	Raio = "Os raios procuram quem carrega este totem.",
	Diamante = "Um totem raro. Leve-o inteiro ate a mesa.",
}

-- ------------------------------------------------------------ HUD
local gui = Instance.new("ScreenGui")
gui.Name = "Invokyr_Totens"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local painel = Instance.new("Frame")
painel.AnchorPoint = Vector2.new(0, 1)
painel.Position = UDim2.new(0, 24, 1, -24)
painel.Size = UDim2.new(0, 260, 0, 64)
painel.BackgroundColor3 = Color3.fromRGB(16, 12, 10)
painel.BackgroundTransparency = 1
painel.BorderSizePixel = 0
painel.Parent = gui
local canto = Instance.new("UICorner"); canto.CornerRadius = UDim.new(0, 8); canto.Parent = painel

local marca = Instance.new("Frame")
marca.Position = UDim2.new(0, 12, 0.5, -14); marca.Size = UDim2.new(0, 6, 0, 28)
marca.BackgroundColor3 = Color3.fromRGB(236, 222, 190); marca.BackgroundTransparency = 1
marca.BorderSizePixel = 0; marca.Parent = painel
local cantoM = Instance.new("UICorner"); cantoM.CornerRadius = UDim.new(1, 0); cantoM.Parent = marca

local function rotulo(pos, tam, tamanhoTexto, cor)
	local l = Instance.new("TextLabel")
	l.Position = pos; l.Size = tam
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.Garamond
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextSize = tamanhoTexto
	l.TextColor3 = cor
	l.TextStrokeColor3 = Color3.fromRGB(16, 10, 6)
	l.TextStrokeTransparency = 0.5
	l.TextTransparency = 1
	l.Text = ""
	l.Parent = painel
	return l
end
local linhaTotem = rotulo(UDim2.new(0, 30, 0, 8), UDim2.new(1, -40, 0, 26), 22, Color3.fromRGB(236, 222, 190))
local linhaConta = rotulo(UDim2.new(0, 30, 0, 32), UDim2.new(1, -40, 0, 22), 17, Color3.fromRGB(188, 176, 152))

local carregando, feitos, total = nil, 0, 3
local function pintar()
	local visivel = carregando ~= nil or feitos > 0
	local alvo = visivel and 0 or 1
	local info = TweenInfo.new(0.35)
	TweenService:Create(painel, info, { BackgroundTransparency = visivel and 0.35 or 1 }):Play()
	TweenService:Create(marca, info, { BackgroundTransparency = alvo }):Play()
	TweenService:Create(linhaTotem, info, { TextTransparency = alvo }):Play()
	TweenService:Create(linhaConta, info, { TextTransparency = alvo }):Play()
	if carregando then
		marca.BackgroundColor3 = CORES[carregando] or Color3.fromRGB(236, 222, 190)
		linhaTotem.Text = "Totem de " .. carregando .. "   [Q] largar"
	else
		marca.BackgroundColor3 = Color3.fromRGB(120, 112, 96)
		linhaTotem.Text = "Sem totem"
	end
	linhaConta.Text = "Entregues: " .. feitos .. " / " .. total
end
pintar()

estadoRE.OnClientEvent:Connect(function(tipo, entregues, precisa)
	carregando = tipo
	feitos = entregues or 0
	total = precisa or 3
	pintar()
end)

CAS:BindAction("InvokyrLargarTotem", function(_, st)
	if st == Enum.UserInputState.Begin and carregando then largarRE:FireServer() end
	return Enum.ContextActionResult.Pass
end, false, Enum.KeyCode.Q)
CAS:BindAction("InvokyrLargarToque", function(_, st)
	if st == Enum.UserInputState.Begin and carregando then largarRE:FireServer() end
	return Enum.ContextActionResult.Pass
end, true)
CAS:SetTitle("InvokyrLargarToque", "Largar")
CAS:SetPosition("InvokyrLargarToque", UDim2.new(1, -170, 1, -260))

-- ------------------------------------------------------------ aviso curto no centro
local avisoLabel = Instance.new("TextLabel")
avisoLabel.AnchorPoint = Vector2.new(0.5, 0.5)
avisoLabel.Position = UDim2.new(0.5, 0, 0.63, 0)
avisoLabel.Size = UDim2.new(0.7, 0, 0, 34)
avisoLabel.BackgroundTransparency = 1
avisoLabel.Font = Enum.Font.Garamond
avisoLabel.TextSize = 26
avisoLabel.TextColor3 = Color3.fromRGB(236, 222, 190)
avisoLabel.TextStrokeColor3 = Color3.fromRGB(20, 12, 6)
avisoLabel.TextStrokeTransparency = 0.4
avisoLabel.TextTransparency = 1
avisoLabel.Text = ""
avisoLabel.Parent = gui
local contaAviso = 0
local function avisar(texto, cor, dur)
	contaAviso += 1
	local meu = contaAviso
	avisoLabel.Text = texto
	avisoLabel.TextColor3 = cor or Color3.fromRGB(236, 222, 190)
	TweenService:Create(avisoLabel, TweenInfo.new(0.25), { TextTransparency = 0 }):Play()
	task.delay(dur or 2.5, function()
		if meu == contaAviso then
			TweenService:Create(avisoLabel, TweenInfo.new(0.6), { TextTransparency = 1 }):Play()
		end
	end)
end

-- ------------------------------------------------------------ efeitos das maldicoes
local corCena = Lighting:FindFirstChild("Invokyr_MaldicaoCor")
if not corCena then
	corCena = Instance.new("ColorCorrectionEffect")
	corCena.Name = "Invokyr_MaldicaoCor"
	corCena.Enabled = false
	corCena.Parent = Lighting
end

local brasa = nil
local function acenderBrasa(ligado)
	if ligado then
		if not brasa then
			local p = Instance.new("Part")
			p.Name = "Invokyr_BrasaLocal"
			p.Size = Vector3.new(0.4, 0.4, 0.4)
			p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
			p.Transparency = 1; p.CastShadow = false
			p.Parent = workspace
			local luz = Instance.new("PointLight")
			luz.Color = Color3.fromRGB(255, 120, 45); luz.Brightness = 2.2; luz.Range = 16; luz.Shadows = false
			luz.Parent = p
			local fogo = Instance.new("ParticleEmitter")
			fogo.Texture = "rbxasset://textures/particles/fire_main.dds"
			fogo.Rate = 26
			fogo.Lifetime = NumberRange.new(0.5, 0.9)
			fogo.Speed = NumberRange.new(1.2, 2.2)
			fogo.SpreadAngle = Vector2.new(18, 18)
			fogo.LightEmission = 0.8
			fogo.Color = ColorSequence.new(Color3.fromRGB(255, 160, 60), Color3.fromRGB(180, 40, 15))
			fogo.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0.05) })
			fogo.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
			fogo.Parent = p
			brasa = p
		end
	elseif brasa then
		brasa:Destroy(); brasa = nil
	end
end

RunService.RenderStepped:Connect(function()
	if brasa then
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hrp then brasa.CFrame = hrp.CFrame * CFrame.new(0, 0.4, -2.0) end
	end
end)

local function clarao(cor, forca, dur)
	corCena.Enabled = true
	corCena.TintColor = cor
	corCena.Brightness = forca
	TweenService:Create(corCena, TweenInfo.new(dur or 0.5), { Brightness = 0, TintColor = Color3.fromRGB(255, 255, 255) }):Play()
	task.delay((dur or 0.5) + 0.1, function()
		if corCena.Brightness <= 0.01 then corCena.Enabled = false end
	end)
end

local function riscoDeRaio(ponto)
	local p = Instance.new("Part")
	p.Name = "Invokyr_RaioLocal"
	p.Size = Vector3.new(0.6, 70, 0.6)
	p.CFrame = CFrame.new(ponto + Vector3.new(0, 35, 0))
	p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
	p.CastShadow = false
	p.Color = Color3.fromRGB(255, 240, 200)
	p.Material = Enum.Material.Neon
	p.Transparency = 0.1
	p.Parent = workspace
	local luz = Instance.new("PointLight")
	luz.Brightness = 8; luz.Range = 40; luz.Color = Color3.fromRGB(255, 240, 200); luz.Shadows = false
	luz.Parent = p
	TweenService:Create(p, TweenInfo.new(0.35), { Transparency = 1 }):Play()
	TweenService:Create(luz, TweenInfo.new(0.35), { Brightness = 0 }):Play()
	task.delay(0.5, function() p:Destroy() end)
end

-- poca de fogo que o totem cuspiu: todo mundo ve, nao so quem carrega
local function pocaDeFogo(pos, raio, dur)
	local p = Instance.new("Part")
	p.Name = "Invokyr_ChamaLocal"
	p.Size = Vector3.new(raio * 1.9, 0.2, raio * 1.9)
	p.CFrame = CFrame.new(pos + Vector3.new(0, 0.1, 0))
	p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
	p.Transparency = 1; p.CastShadow = false
	p.Parent = workspace
	local fogo = Instance.new("ParticleEmitter")
	fogo.Texture = "rbxasset://textures/particles/fire_main.dds"
	fogo.Shape = Enum.ParticleEmitterShape.Cylinder
	fogo.EmissionDirection = Enum.NormalId.Top
	fogo.Rate = math.floor(raio * 22)
	fogo.Lifetime = NumberRange.new(0.6, 1.2)
	fogo.Speed = NumberRange.new(2.5, 5)
	fogo.SpreadAngle = Vector2.new(12, 12)
	fogo.LightEmission = 0.9
	fogo.Color = ColorSequence.new(Color3.fromRGB(255, 180, 70), Color3.fromRGB(165, 35, 12))
	fogo.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.4), NumberSequenceKeypoint.new(1, 0.1) })
	fogo.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(1, 1) })
	fogo.Parent = p
	local fumaca = Instance.new("ParticleEmitter")
	fumaca.Texture = "rbxasset://textures/particles/smoke_main.dds"
	fumaca.Shape = Enum.ParticleEmitterShape.Cylinder
	fumaca.EmissionDirection = Enum.NormalId.Top
	fumaca.Rate = 8
	fumaca.Lifetime = NumberRange.new(1.6, 2.6)
	fumaca.Speed = NumberRange.new(1.5, 3)
	fumaca.Color = ColorSequence.new(Color3.fromRGB(60, 50, 44))
	fumaca.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 3.5) })
	fumaca.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.75), NumberSequenceKeypoint.new(1, 1) })
	fumaca.Parent = p
	local luz = Instance.new("PointLight")
	luz.Color = Color3.fromRGB(255, 140, 55); luz.Brightness = 3.2; luz.Range = raio * 4; luz.Shadows = false
	luz.Parent = p
	-- apaga aos poucos no fim
	task.delay(math.max(dur - 1.4, 0.2), function()
		fogo.Rate = 0; fumaca.Rate = 0
		TweenService:Create(luz, TweenInfo.new(1.4), { Brightness = 0 }):Play()
	end)
	task.delay(dur + 2.8, function() p:Destroy() end)
end

maldicaoRE.OnClientEvent:Connect(function(tipo, dado, extra1, extra2)
	if tipo == "inicio" then
		acenderBrasa(dado == "Fogo")
		avisar(AVISO[dado] or "O totem pesa na sua mao.", CORES[dado], 3)
	elseif tipo == "fim" then
		acenderBrasa(false)
	elseif tipo == "chama" then
		if typeof(dado) == "Vector3" then pocaDeFogo(dado, extra1 or 4.5, extra2 or 7) end
	elseif tipo == "queimando" then
		clarao(Color3.fromRGB(255, 110, 60), 0.22, 0.45)
	elseif tipo == "teleporte" then
		clarao(Color3.fromRGB(190, 120, 255), 0.35, 0.9)
	elseif tipo == "raio" then
		if typeof(dado) == "Vector3" then riscoDeRaio(dado) end
	elseif tipo == "empurrao" then
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hrp and typeof(dado) == "Vector3" then
			hrp.AssemblyLinearVelocity = hrp.AssemblyLinearVelocity + dado * 30 + Vector3.new(0, 12, 0)
			clarao(Color3.fromRGB(255, 250, 220), 0.5, 0.6)
		end
	end
end)
]==]

-- ---------------------------------------------------------------- instala os dois scripts
local antigoS = ServerScriptService:FindFirstChild("Invokyr_Totens")
if antigoS then antigoS.Name = "Invokyr_Totens_ANTIGO"; backup(antigoS) end
local s = Instance.new("Script")
s.Name = "Invokyr_Totens"
s.Source = FONTE_SERVIDOR
s.Parent = ServerScriptService

local spsPasta = StarterPlayer:WaitForChild("StarterPlayerScripts")
local antigoC = spsPasta:FindFirstChild("Invokyr_TotensCliente")
if antigoC then antigoC.Name = "Invokyr_TotensCliente_ANTIGO"; backup(antigoC) end
local c = Instance.new("LocalScript")
c.Name = "Invokyr_TotensCliente"
c.Source = FONTE_CLIENTE
c.Parent = spsPasta

if recording then
	pcall(function() ChangeHistoryService:FinishRecording(recording, Enum.FinishRecordingOperation.Commit) end)
end

print("========== INVOKYR: SCRIPT 09 (TOTENS) ==========")
for _, l in ipairs(linhas) do print("  " .. l) end
if #avisos == 0 then print("  Sem avisos.") else for _, a in ipairs(avisos) do warn("  AVISO: " .. a) end end
print("")
print("  COMO TESTAR (Play):")
print("   1. Chegue perto da mesa e aperte E  -> o tabuleiro abre e a sala acende.")
print("   2. Aperte E de novo                 -> o dado rola e as portas abrem.")
print("   3. Os totens aparecem nos esconderijos verdes da sala.")
print("   4. Aperte E num totem para pegar.   Q larga onde voce estiver.")
print("   5. Volte ate a mesa e aperte E      -> entrega. Na 3a entrega o dado libera sozinho.")
print("")
print("  Atalho: no Studio, Y ainda libera o dado na marra (Script 07).")
