--[[
INVOKYR - Script 14: Montar o Atrio (primeira sala da mansao)
==================================================================
Rode na BARRA DE COMANDOS (View > Command Bar), com o jogo PARADO.
Nao precisa importar nada: tudo aqui e Part do Roblox com os MaterialVariants
que ja existem no place, mais os 3 armarios que voce ja importou.

O que faz (pode rodar quantas vezes quiser, nao duplica nada):
  - Mede o portal escolhido da Sala Principal (posicao, direcao, dobradicas) e
    encaixa o Atrio nele. Nada e chutado: as medidas saem do proprio place.
  - Monta piso, paredes, teto em caixotoes, pilastras, lambril, cornija, lareira,
    cortinas, lustre, arandelas, passadeira e mesa central.
  - Cria 2 portais laterais FECHADOS, no mesmo padrao da Sala Principal
    (vao 4,87 x 9,00, mesmas folhas de porta), prontos para as proximas salas.
  - Copia os 3 armarios (os originais ficam onde estao) e encosta na parede.
  - Cria 8 esconderijos com a tag Invokyr_Esconderijo. O Script 09 ja os enxerga.
  - Guarda em ServerStorage > Invokyr_Backup o que sai de uso (fundo preto do
    portal e os 8 esconderijos de teste). Nada e apagado.
  - Imprime um relatorio no Output.

Tudo fica em Workspace > Invokyr > Mansao > Atrio.
]]

local CONFIG = {
	PORTAL = "North",                 -- portal da Sala Principal onde o Atrio encaixa: North, East, South ou West

	MESA_CENTRAL = true,              -- mesa redonda no meio (tambem e esconderijo)
	TAMPOES_TORRE = true,             -- tampa de pedra atras da moldura do portal da torre (ver relatorio)
	RETIRAR_ESCONDERIJOS_DE_TESTE = true,  -- os 8 de teste da sala principal vao para o Backup
	MOSTRAR_ESCONDERIJOS = false,     -- true = esconderijos aparecem em verde para conferir
	MOSTRAR_COLISOES = false,         -- true = colisoes invisiveis aparecem em vermelho
	TRAVAR = true,                    -- pecas travadas (nao selecionam com clique). false para editar na mao
	PISO_GIRADO = false,              -- true = gira as tabuas do piso 90 graus

	-- LUZ. Tudo fraco de proposito: a lanterna continua sendo a luz principal.
	LUSTRE_BRILHO = 0.8,   LUSTRE_ALCANCE = 28,
	ARANDELA_BRILHO = 0.55, ARANDELA_ALCANCE = 11,
	BRASA_BRILHO = 0.45,   BRASA_ALCANCE = 9,

	-- COR. Part.Color MULTIPLICA a textura: branco = textura pura, cinza = escurece.
	-- Acerte aqui, com a luz noturna ligada, e rode de novo.
	COR = {
		Painel   = Color3.fromRGB(235, 228, 220),   -- Invokyr_PainelEscuro (pilastras, molduras, paredes)
		Lambril  = Color3.fromRGB(190, 175, 160),   -- Invokyr_Lambril (almofadas dos paineis)
		Caixotao = Color3.fromRGB(150, 140, 130),   -- Invokyr_Lambril no teto
		Piso     = Color3.fromRGB(200, 195, 195),   -- Invokyr_PisoMadeira
		Veludo   = Color3.fromRGB(165, 135, 140),   -- Invokyr_Veludo na passadeira
		Cortina  = Color3.fromRGB(120, 95, 100),    -- Invokyr_Veludo nas cortinas
		Rocha    = Color3.fromRGB(150, 146, 140),   -- Invokyr_Rocha (lareira, soleiras)
		Pedra    = Color3.fromRGB(120, 114, 108),   -- Invokyr_Pedra
		Fuligem  = Color3.fromRGB(45, 42, 40),      -- Invokyr_Pedra dentro da lareira
		Ferro    = Color3.fromRGB(110, 105, 100),   -- Invokyr_Metal (lustre)
		Latao    = Color3.fromRGB(200, 160, 90),    -- Invokyr_Metal (arandelas)
		Galao    = Color3.fromRGB(150, 118, 62),    -- debrum dourado da passadeira
	},

	-- MOVEIS. Medidas (largura, altura, profundidade) lidas do place. O script acha cada
	-- armario pela medida, copia e encosta na parede indicada. t = posicao ao longo da parede.
	MOVEIS = {
		{ nome = "Armario_Gotico",   medida = { 6.14, 8.43, 3.99 },  parede = "LadoB",   t = 13.2 },
		{ nome = "Armario_Antigo",   medida = { 7.22, 7.98, 2.39 },  parede = "LadoA",   t = 30.8 },
		{ nome = "Armario_Oriental", medida = { 4.51, 10.26, 1.95 }, parede = "Entrada", t = 6.1 },
	},
}

-- ================================================================== guarda
local RunService = game:GetService("RunService")
if RunService:IsRunning() then
	error("[Invokyr] Pare o jogo (Stop) antes de rodar o Script 14. Em Play nada do que ele monta fica salvo.")
end

local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local MaterialService = game:GetService("MaterialService")
local Lighting = game:GetService("Lighting")

local avisos, linhas = {}, {}
local function info(...) local t = table.concat({ ... }, " "); table.insert(linhas, t) end
local function aviso(...) local t = table.concat({ ... }, " "); table.insert(avisos, t) end

local raiz = workspace:FindFirstChild("Invokyr")
local sala = raiz and raiz:FindFirstChild("SalaPrincipal")
if not sala then
	error("[Invokyr] Nao achei Workspace > Invokyr > SalaPrincipal. Rode os Scripts 01 a 03 antes deste.")
end

local recording
pcall(function() recording = ChangeHistoryService:TryBeginRecording("Invokyr montar atrio") end)

-- ================================================================== medidas do padrao de portal
-- Tudo abaixo foi medido no place (Jogo-V2.rbxl), no eixo do portal:
--   x = para o lado, y = altura acima do piso, p = profundidade para FORA da sala.
local PADRAO = {
	VAO_MEIA_LARGURA = 2.435,   -- vao de 4,87
	VAO_ALTURA = 9.0,
	FACE_PEDRA = 1.5,           -- onde acaba a cantaria da torre (15,985 - 14,4853)
	DOBRADICA_P = 1.575,        -- 16,0603 - 14,4853
	DOBRADICA_X = 2.455,
	FOLHA_P0 = 1.295, FOLHA_P1 = 1.95,   -- espessura da folha fechada
	FOLHA_Y0 = 0.066, FOLHA_Y1 = 9.007,
	FUNDO_P = 2.72,             -- placa preta atras da porta (17,2078 - 14,4853)
	-- A folha aberta a 100 graus varre ate x = 3,25 e p = 4,02. Por isso o encaixe da sala
	-- vizinha e um vao fundo de 7,0 de largura que so fecha em p = 4,6.
	ENCAIXE_MEIA_LARGURA = 3.5,
	ENCAIXE_ALTURA = 9.5,
	ENCAIXE_FIM = 4.6,
}

-- ================================================================== portal da torre
local UP = Vector3.new(0, 1, 0)
local pontos = sala:FindFirstChild("PontosDeLuz")
local ancoraLuz = pontos and pontos:FindFirstChild("AncoraLuzes")
local attPortal = ancoraLuz and ancoraLuz:FindFirstChild("Portal" .. CONFIG.PORTAL)
if not attPortal then
	error("[Invokyr] Nao achei o ponto Portal" .. CONFIG.PORTAL .. " em SalaPrincipal > PontosDeLuz > AncoraLuzes. Rode o Script 02 de novo.")
end
local FORA = attPortal:GetAttribute("Fora")
if typeof(FORA) ~= "Vector3" then error("[Invokyr] O ponto Portal" .. CONFIG.PORTAL .. " esta sem o atributo Fora.") end
FORA = Vector3.new(FORA.X, 0, FORA.Z).Unit
local posPortal = ancoraLuz.Position + attPortal.Position

local colisaoSala = sala:FindFirstChild("Colisao")
local colPiso = colisaoSala and colisaoSala:FindFirstChild("COL_Piso")
local pisoY = colPiso and (colPiso.Position.Y + colPiso.Size.Y / 2) or (posPortal.Y - 0.0061)

-- L = eixo local do Atrio. Origem no portal, no nivel do piso.
--   L * (u, y, w): u = para o lado, y = altura, w = profundidade para dentro do Atrio.
local P0 = Vector3.new(posPortal.X, pisoY, posPortal.Z)
local L = CFrame.fromMatrix(P0, UP:Cross(FORA), UP, FORA)

-- confere se as dobradicas reais batem com o padrao (pega escala errada do Script 02)
local colPortas = colisaoSala and colisaoSala:FindFirstChild("Portas")
local folhasTorre = {}
if colPortas then
	local visuais = {}
	for _, v in ipairs(CollectionService:GetTagged("Invokyr_PortaVisual")) do
		if v:IsDescendantOf(sala) then table.insert(visuais, v) end
	end
	for _, c in ipairs(colPortas:GetChildren()) do
		if c:GetAttribute("Portal") == CONFIG.PORTAL then
			local H = c:GetAttribute("Dobradica")
			if typeof(H) == "Vector3" then
				local rel = L:PointToObjectSpace(Vector3.new(H.X, pisoY, H.Z))
				if math.abs(math.abs(rel.X) - PADRAO.DOBRADICA_X) > 0.05 or math.abs(rel.Z - PADRAO.DOBRADICA_P) > 0.05 then
					aviso(("Dobradica de %s fora do padrao: x=%.3f p=%.3f (esperado %.3f e %.3f). A sala principal esta em escala diferente de 1?")
						:format(c.Name, rel.X, rel.Z, PADRAO.DOBRADICA_X, PADRAO.DOBRADICA_P))
				end
			end
			local melhor, dist = nil, 3
			for _, v in ipairs(visuais) do
				local d = (v.Position - c.Position).Magnitude
				if d < dist then melhor, dist = v, d end
			end
			if melhor then
				local prof = L:PointToObjectSpace(melhor.Position).Z
				if math.abs(prof - (PADRAO.FOLHA_P0 + PADRAO.FOLHA_P1) / 2) < 0.15 then
					table.insert(folhasTorre, { vis = melhor, lado = c:GetAttribute("Lado") or "?", dobradica = H })
				else
					aviso("A folha " .. c.Name .. " nao esta fechada (profundidade " .. string.format("%.2f", prof) .. "). Nao foi usada como molde.")
				end
			end
		end
	end
end

-- ================================================================== medidas do Atrio
local HW = 15            -- meia largura interna (30 studs)
local W0 = PADRAO.ENCAIXE_FIM   -- face interna da parede da entrada
local W1 = W0 + 44       -- face interna da parede do fundo (44 de profundidade)
local H = 14             -- pe-direito
local ESP = 1            -- espessura das paredes
local MODULO = 8.8       -- distancia entre pilastras nas paredes laterais
local PT = 22            -- centro do portal lateral, ao longo da parede (meio do 3o vao)
local CENTRO_W = W0 + PT -- 26,6: centro da sala, lustre e mesa

-- eixos das 4 paredes: (t, y, d). t = ao longo da parede, d = para dentro da sala.
local function eixoParede(u, w, tx, tz, nx, nz)
	return L * CFrame.fromMatrix(Vector3.new(u, 0, w), Vector3.new(tx, 0, tz), UP, Vector3.new(nx, 0, nz))
end
local PAREDE = {
	Entrada = eixoParede(-HW, W0, 1, 0, 0, 1),     -- t de 0 a 30
	Fundo   = eixoParede(HW, W1, -1, 0, 0, -1),    -- t de 0 a 30
	LadoA   = eixoParede(HW, W0, 0, 1, -1, 0),     -- t de 0 a 44
	LadoB   = eixoParede(-HW, W1, 0, -1, 1, 0),    -- t de 0 a 44
}

-- ================================================================== materiais
local C = CONFIG.COR
local function variante(nome)
	if not MaterialService:FindFirstChild(nome) then
		aviso("MaterialVariant " .. nome .. " nao existe no MaterialService. Rode os Scripts 12 e 13. A peca fica com o material base.")
		return ""
	end
	return nome
end
local vPainel, vLambril, vPiso = variante("Invokyr_PainelEscuro"), variante("Invokyr_Lambril"), variante("Invokyr_PisoMadeira")
local vVeludo, vMetal, vPedra, vRocha = variante("Invokyr_Veludo"), variante("Invokyr_Metal"), variante("Invokyr_Pedra"), variante("Invokyr_Rocha")
local M = {
	Painel   = { Enum.Material.Wood, vPainel, C.Painel },
	Lambril  = { Enum.Material.WoodPlanks, vLambril, C.Lambril },
	Caixotao = { Enum.Material.WoodPlanks, vLambril, C.Caixotao },
	Piso     = { Enum.Material.WoodPlanks, vPiso, C.Piso },
	Veludo   = { Enum.Material.Fabric, vVeludo, C.Veludo },
	Cortina  = { Enum.Material.Fabric, vVeludo, C.Cortina },
	Rocha    = { Enum.Material.Marble, vRocha, C.Rocha },
	Pedra    = { Enum.Material.Cobblestone, vPedra, C.Pedra },
	Fuligem  = { Enum.Material.Cobblestone, vPedra, C.Fuligem },
	Ferro    = { Enum.Material.Metal, vMetal, C.Ferro },
	Latao    = { Enum.Material.Metal, vMetal, C.Latao },
	Galao    = { Enum.Material.Fabric, "", C.Galao },
	Cinza    = { Enum.Material.Slate, "", Color3.fromRGB(34, 32, 31) },
	Cera     = { Enum.Material.SmoothPlastic, "", Color3.fromRGB(226, 214, 184) },
	Chama    = { Enum.Material.Neon, "", Color3.fromRGB(255, 170, 80) },
	Brasa    = { Enum.Material.Neon, "", Color3.fromRGB(255, 70, 20) },
	Preto    = { Enum.Material.SmoothPlastic, "", Color3.fromRGB(6, 6, 7) },
}

-- ================================================================== pastas
local mansao = raiz:FindFirstChild("Mansao")
if not mansao then mansao = Instance.new("Folder"); mansao.Name = "Mansao"; mansao.Parent = raiz end
local atrio = mansao:FindFirstChild("Atrio")
if not atrio then atrio = Instance.new("Model"); atrio.Name = "Atrio"; atrio.Parent = mansao end

local backup = ServerStorage:FindFirstChild("Invokyr_Backup")
if not backup then backup = Instance.new("Folder"); backup.Name = "Invokyr_Backup"; backup.Parent = ServerStorage end

-- so as pastas que ESTE script gera sao refeitas. Qualquer outra coisa dentro do Atrio fica.
local P = {}
for _, nome in ipairs({ "Estrutura", "Acabamento", "Teto", "Portais", "Lareira", "Tapetes", "Mobilia", "Luzes", "Colisao", "Esconderijos", "Encaixes" }) do
	local velha = atrio:FindFirstChild(nome)
	if velha then velha:Destroy() end
	local f = Instance.new("Folder"); f.Name = nome; f.Parent = atrio
	P[nome] = f
end
local moveis = atrio:FindFirstChild("Moveis")   -- armarios copiados: NAO e refeita, so reposicionada
if not moveis then moveis = Instance.new("Folder"); moveis.Name = "Moveis"; moveis.Parent = atrio end

-- ================================================================== fabrica de pecas
local SOLIDO = { colide = true }
local DECOR = {}
local FINO = { sombra = false }
local total = 0
local function peca(pai, nome, cf, tam, mat, opt)
	opt = opt or DECOR
	local p = Instance.new("Part")
	p.Name = nome
	p.Anchored = true
	p.Size = tam
	p.CFrame = cf
	p.Material = mat[1]
	if mat[2] ~= "" then p.MaterialVariant = mat[2] end
	p.Color = mat[3]
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CanCollide = opt.colide == true
	p.CanQuery = opt.colide == true
	p.CanTouch = false
	p.CastShadow = opt.sombra ~= false
	p.Locked = CONFIG.TRAVAR
	if opt.forma then p.Shape = opt.forma end
	if opt.transparencia then p.Transparency = opt.transparencia end
	p.Parent = pai
	total += 1
	return p
end
-- caixa dada por minimo e maximo nos 3 eixos de um quadro F
local function caixa(pai, nome, F, a0, a1, y0, y1, c0, c1, mat, opt)
	local tam = Vector3.new(math.abs(a1 - a0), math.abs(y1 - y0), math.abs(c1 - c0))
	return peca(pai, nome, F * CFrame.new((a0 + a1) / 2, (y0 + y1) / 2, (c0 + c1) / 2), tam, mat, opt)
end
-- cilindro em pe
local function cilindro(pai, nome, F, a, y0, y1, c, diametro, mat, opt)
	local o = { forma = Enum.PartType.Cylinder, colide = opt and opt.colide, sombra = not opt or opt.sombra }
	return peca(pai, nome, F * CFrame.new(a, (y0 + y1) / 2, c) * CFrame.Angles(0, 0, math.pi / 2),
		Vector3.new(math.abs(y1 - y0), diametro, diametro), mat, o)
end
-- vara entre dois pontos do mundo (nao serve para vara exatamente vertical)
local function vara(pai, nome, p1, p2, diametro, mat)
	local cf = CFrame.lookAt((p1 + p2) / 2, p2) * CFrame.Angles(0, math.pi / 2, 0)
	return peca(pai, nome, cf, Vector3.new((p2 - p1).Magnitude, diametro, diametro), mat,
		{ forma = Enum.PartType.Cylinder, sombra = false })
end
local function invisivel(pai, nome, F, a0, a1, y0, y1, c0, c1)
	local p = caixa(pai, nome, F, a0, a1, y0, y1, c0, c1, M.Preto, SOLIDO)
	p.Transparency = CONFIG.MOSTRAR_COLISOES and 0.6 or 1
	p.Color = Color3.fromRGB(255, 60, 60)
	p.CastShadow = false
	return p
end
local function luz(pai, nome, posMundo, cor, brilho, alcance, sombras)
	local a = Instance.new("Part")
	a.Name = nome; a.Anchored = true; a.Size = Vector3.new(0.2, 0.2, 0.2); a.CFrame = CFrame.new(posMundo)
	a.Transparency = 1; a.CanCollide = false; a.CanQuery = false; a.CanTouch = false; a.CastShadow = false
	a.Locked = CONFIG.TRAVAR
	local l = Instance.new("PointLight")
	l.Name = "Luz"; l.Color = cor; l.Brightness = brilho; l.Range = alcance; l.Shadows = sombras == true
	l.Parent = a
	a.Parent = pai
	return l
end

-- ================================================================== 1. ESTRUTURA
local E = P.Estrutura
do
	-- piso (as tabuas correm no sentido do eixo X da peca)
	local piso = caixa(E, "Piso", L, -HW - ESP + 0.05, HW + ESP - 0.05, -1.05, 0, W0 - ESP + 0.05, W1 + ESP - 0.05, M.Piso, SOLIDO)
	if CONFIG.PISO_GIRADO then
		local s = piso.Size
		piso.Size = Vector3.new(s.Z, s.Y, s.X)
		piso.CFrame = piso.CFrame * CFrame.Angles(0, math.pi / 2, 0)
	end
	-- soleira de pedra do encaixe: cobre a emenda com o piso da torre. Fica 0,03 acima do piso;
	-- a folha da porta passa 0,066 acima, entao nao raspa.
	caixa(E, "Soleira_Entrada", L, -PADRAO.ENCAIXE_MEIA_LARGURA, PADRAO.ENCAIXE_MEIA_LARGURA, -0.3, 0.03,
		PADRAO.FACE_PEDRA - 0.2, W0, M.Rocha, SOLIDO)

	-- parede da entrada, com o vao fundo onde as folhas da torre abrem
	local eLado = PADRAO.ENCAIXE_MEIA_LARGURA + 1.2    -- 4,7
	-- Ombreiras e verga entram 0,3 na cantaria da torre (ficam enterradas na pedra), para nao
	-- sobrar fresta entre as duas salas caso a face de fora da torre nao esteja exatamente em 1,5.
	local ENTRA = 0.3
	caixa(E, "Parede_Entrada_1", PAREDE.Entrada, -ESP, HW - eLado, -1, H, -ESP, 0, M.Painel, SOLIDO)
	caixa(E, "Parede_Entrada_2", PAREDE.Entrada, HW + eLado, 2 * HW + ESP, -1, H, -ESP, 0, M.Painel, SOLIDO)
	for _, s in ipairs({ -1, 1 }) do
		caixa(E, "Encaixe_Ombreira", L, s * PADRAO.ENCAIXE_MEIA_LARGURA, s * eLado, -0.3, PADRAO.ENCAIXE_ALTURA,
			PADRAO.FACE_PEDRA - ENTRA, W0, M.Painel, SOLIDO)
		-- almofada na face da ombreira (a folha aberta fica a 0,19 dela)
		caixa(P.Acabamento, "Encaixe_Almofada", L, s * (PADRAO.ENCAIXE_MEIA_LARGURA - 0.06), s * PADRAO.ENCAIXE_MEIA_LARGURA,
			1.0, 8.6, PADRAO.FACE_PEDRA + 0.6, W0 - 0.3, M.Lambril, FINO)
	end
	caixa(E, "Encaixe_Verga", L, -eLado, eLado, PADRAO.ENCAIXE_ALTURA, H, PADRAO.FACE_PEDRA - ENTRA, W0, M.Painel, SOLIDO)

	-- parede do fundo
	caixa(E, "Parede_Fundo", PAREDE.Fundo, -ESP, 2 * HW + ESP, -1, H, -ESP, 0, M.Painel, SOLIDO)

	-- paredes laterais, cada uma com o vao padrao de 4,87 x 9,00
	for _, nome in ipairs({ "LadoA", "LadoB" }) do
		local F = PAREDE[nome]
		caixa(E, "Parede_" .. nome .. "_1", F, 0, PT - PADRAO.VAO_MEIA_LARGURA, -1, H, -ESP, 0, M.Painel, SOLIDO)
		caixa(E, "Parede_" .. nome .. "_2", F, PT + PADRAO.VAO_MEIA_LARGURA, W1 - W0, -1, H, -ESP, 0, M.Painel, SOLIDO)
		caixa(E, "Parede_" .. nome .. "_Verga", F, PT - PADRAO.VAO_MEIA_LARGURA, PT + PADRAO.VAO_MEIA_LARGURA,
			PADRAO.VAO_ALTURA, H, -ESP, 0, M.Painel, SOLIDO)
	end

	-- laje do teto (a face de baixo e o fundo dos caixotoes)
	caixa(E, "Laje", L, -HW - ESP, HW + ESP, H, H + 1, PADRAO.FACE_PEDRA, W1 + ESP, M.Painel, SOLIDO)

	-- tampoes: ficam ENTERRADOS na cantaria do portal da torre, logo atras da face de fora.
	-- Se a torre tiver essa face modelada, nunca aparecem. Se nao tiver, tapam o buraco.
	if CONFIG.TAMPOES_TORRE then
		local p0, p1 = PADRAO.FACE_PEDRA - ENTRA, PADRAO.FACE_PEDRA - 0.05
		for _, s in ipairs({ -1, 1 }) do
			caixa(E, "Tampao_Torre", L, s * (PADRAO.VAO_MEIA_LARGURA + 0.065), s * PADRAO.ENCAIXE_MEIA_LARGURA,
				0, PADRAO.ENCAIXE_ALTURA, p0, p1, M.Pedra, FINO)
		end
		caixa(E, "Tampao_Torre_Topo", L, -(PADRAO.VAO_MEIA_LARGURA + 0.065), PADRAO.VAO_MEIA_LARGURA + 0.065,
			PADRAO.VAO_ALTURA + 0.05, PADRAO.ENCAIXE_ALTURA, p0, p1, M.Pedra, FINO)
	end
end

-- ================================================================== 2. ACABAMENTO DAS PAREDES
local A = P.Acabamento

-- rodape + lambril almofadado + cimalha + painel alto, num trecho livre de parede
local function revestir(F, t0, t1, comPainelAlto)
	local vao = t1 - t0
	caixa(A, "Rodape", F, t0, t1, 0, 0.8, 0, 0.3, M.Painel)
	caixa(A, "Rodape_Filete", F, t0, t1, 0.8, 0.95, 0, 0.2, M.Painel, FINO)
	caixa(A, "Lambril_Fundo", F, t0, t1, 0.95, 4.0, 0, 0.08, M.Lambril, FINO)
	caixa(A, "Lambril_Travessa", F, t0, t1, 0.95, 1.35, 0.08, 0.2, M.Painel)
	caixa(A, "Lambril_Travessa", F, t0, t1, 3.6, 4.0, 0.08, 0.2, M.Painel)
	if vao >= 1.6 then
		local n = math.max(1, math.floor(vao / 3.4 + 0.5))
		local larg = (vao - 0.4 * (n + 1)) / n
		for i = 0, n do
			local a = t0 + i * (larg + 0.4)
			caixa(A, "Lambril_Montante", F, a, a + 0.4, 1.35, 3.6, 0.08, 0.2, M.Painel)
			if i < n then
				caixa(A, "Lambril_Almofada", F, a + 0.7, a + 0.1 + larg, 1.65, 3.3, 0.08, 0.16, M.Lambril)
			end
		end
	end
	caixa(A, "Cimalha", F, t0, t1, 4.0, 4.3, 0, 0.38, M.Painel)
	caixa(A, "Cimalha_Filete", F, t0, t1, 4.3, 4.42, 0, 0.22, M.Painel, FINO)
	if comPainelAlto and vao >= 3.2 then
		local a, b, y0, y1, m = t0 + 0.7, t1 - 0.7, 5.2, 11.3, 0.28
		caixa(A, "PainelAlto_Almofada", F, a + m, b - m, y0 + m, y1 - m, 0, 0.06, M.Lambril, FINO)
		caixa(A, "PainelAlto_Moldura", F, a, b, y0, y0 + m, 0, 0.18, M.Painel)
		caixa(A, "PainelAlto_Moldura", F, a, b, y1 - m, y1, 0, 0.18, M.Painel)
		caixa(A, "PainelAlto_Moldura", F, a, a + m, y0 + m, y1 - m, 0, 0.18, M.Painel)
		caixa(A, "PainelAlto_Moldura", F, b - m, b, y0 + m, y1 - m, 0, 0.18, M.Painel)
	end
end

-- pilastra completa: plinto, fuste com almofada, capitel
local Y_FRISO = 12.2
local function pilastra(F, tc)
	caixa(A, "Pilastra_Plinto", F, tc - 0.72, tc + 0.72, 0, 1.0, 0, 0.6, M.Painel)
	caixa(A, "Pilastra_Base", F, tc - 0.66, tc + 0.66, 1.0, 1.15, 0, 0.52, M.Painel)
	caixa(A, "Pilastra_Fuste", F, tc - 0.6, tc + 0.6, 1.15, 11.3, 0, 0.45, M.Painel)
	caixa(A, "Pilastra_Almofada", F, tc - 0.36, tc + 0.36, 1.7, 10.8, 0.45, 0.49, M.Lambril, FINO)
	caixa(A, "Pilastra_Colarinho", F, tc - 0.66, tc + 0.66, 11.3, 11.5, 0, 0.52, M.Painel)
	caixa(A, "Pilastra_Capitel", F, tc - 0.75, tc + 0.75, 11.5, 11.95, 0, 0.62, M.Painel)
	caixa(A, "Pilastra_Abaco", F, tc - 0.84, tc + 0.84, 11.95, Y_FRISO, 0, 0.72, M.Painel)
end

-- poste de canto (um em cada canto da sala)
for _, su in ipairs({ -1, 1 }) do
	for _, w in ipairs({ W0, W1 }) do
		local sw = (w == W0) and 1 or -1
		local function canto(nome, lado, y0, y1)
			caixa(A, nome, L, su * HW, su * (HW - lado), y0, y1, w, w + sw * lado, M.Painel)
		end
		canto("Canto_Plinto", 0.75, 0, 1.0)
		canto("Canto_Fuste", 0.6, 1.0, 11.5)
		canto("Canto_Capitel", 0.72, 11.5, 11.95)
		canto("Canto_Abaco", 0.82, 11.95, Y_FRISO)
	end
end

-- parede da entrada: 2 pilastras ladeando o vao, paineis nos 2 vaos de fora
pilastra(PAREDE.Entrada, 10); pilastra(PAREDE.Entrada, 20)
revestir(PAREDE.Entrada, 0.6, 9.4, true)
revestir(PAREDE.Entrada, 20.6, 29.4, true)
-- parede do fundo: cortinas nos 2 vaos de fora (sem painel alto atras delas)
revestir(PAREDE.Fundo, 0.6, 9.4, false)
revestir(PAREDE.Fundo, 20.6, 29.4, false)
-- paredes laterais: 5 vaos de 8,8; o do meio tem o portal
for _, nome in ipairs({ "LadoA", "LadoB" }) do
	local F = PAREDE[nome]
	for k = 1, 4 do pilastra(F, k * MODULO) end
	revestir(F, 0.6, MODULO - 0.6, true)
	revestir(F, MODULO + 0.6, 2 * MODULO - 0.6, true)
	revestir(F, 2 * MODULO + 0.6, PT - 3.2, false)
	revestir(F, PT + 3.2, 3 * MODULO - 0.6, false)
	revestir(F, 3 * MODULO + 0.6, 4 * MODULO - 0.6, true)
	revestir(F, 4 * MODULO + 0.6, 5 * MODULO - 0.6, true)
end

-- friso e cornija em volta da sala. A parede do fundo e interrompida pelo peito da lareira.
local PEITO_T0, PEITO_T1, PEITO_D = 9.4, 20.6, 2.4
local function anel(nome, y0, y1, d, mat)
	caixa(A, nome, PAREDE.Entrada, 0, 2 * HW, y0, y1, 0, d, mat)
	caixa(A, nome, PAREDE.Fundo, 0, PEITO_T0, y0, y1, 0, d, mat)
	caixa(A, nome, PAREDE.Fundo, PEITO_T1, 2 * HW, y0, y1, 0, d, mat)
	caixa(A, nome, PAREDE.LadoA, d, W1 - W0 - d, y0, y1, 0, d, mat)
	caixa(A, nome, PAREDE.LadoB, d, W1 - W0 - d, y0, y1, 0, d, mat)
	-- volta do peito da lareira
	caixa(A, nome, PAREDE.Fundo, PEITO_T0 - d, PEITO_T1 + d, y0, y1, PEITO_D, PEITO_D + d, mat)
	caixa(A, nome, PAREDE.Fundo, PEITO_T0 - d, PEITO_T0, y0, y1, d, PEITO_D, mat)
	caixa(A, nome, PAREDE.Fundo, PEITO_T1, PEITO_T1 + d, y0, y1, d, PEITO_D, mat)
end
anel("Friso", Y_FRISO, 13.1, 0.3, M.Painel)
anel("Cornija_1", 13.1, 13.5, 0.6, M.Painel)
anel("Cornija_2", 13.5, H, 0.95, M.Painel)

-- moldura do vao da entrada
do
	local F = PAREDE.Entrada
	local e0, e1 = HW - PADRAO.ENCAIXE_MEIA_LARGURA, HW + PADRAO.ENCAIXE_MEIA_LARGURA   -- 11,5 e 18,5
	local yv = PADRAO.ENCAIXE_ALTURA
	caixa(A, "Entrada_Plinto", F, e0 - 0.78, e0 + 0.08, 0, 1.0, 0, 0.36, M.Painel)
	caixa(A, "Entrada_Plinto", F, e1 - 0.08, e1 + 0.78, 0, 1.0, 0, 0.36, M.Painel)
	caixa(A, "Entrada_Guarnicao", F, e0 - 0.8, e0, 1.0, yv, 0, 0.25, M.Painel)
	caixa(A, "Entrada_Guarnicao", F, e1, e1 + 0.8, 1.0, yv, 0, 0.25, M.Painel)
	caixa(A, "Entrada_Guarnicao_Topo", F, e0 - 0.8, e1 + 0.8, yv, yv + 0.8, 0, 0.25, M.Painel)
	caixa(A, "Entrada_Sobreporta", F, 10.6, 19.4, yv + 0.8, yv + 1.2, 0, 0.6, M.Painel)
	caixa(A, "Entrada_Bandeira_Almofada", F, 11.4, 18.6, 11.1, 11.8, 0, 0.06, M.Lambril, FINO)
	caixa(A, "Entrada_Bandeira_Moldura", F, 11.2, 18.8, 10.9, 11.1, 0, 0.16, M.Painel)
	caixa(A, "Entrada_Bandeira_Moldura", F, 11.2, 18.8, 11.8, 12.0, 0, 0.16, M.Painel)
	caixa(A, "Entrada_Bandeira_Moldura", F, 11.2, 11.4, 11.1, 11.8, 0, 0.16, M.Painel)
	caixa(A, "Entrada_Bandeira_Moldura", F, 18.6, 18.8, 11.1, 11.8, 0, 0.16, M.Painel)
end

-- ================================================================== 3. TETO EM CAIXOTOES
do
	local T = P.Teto
	local borda = 0.95                       -- a cornija ja ocupa isso junto as paredes
	local vigasU = { -5, 5 }                 -- 2 vigas mestras no comprimento
	local linhasW = {}                       -- 4 linhas de travessas, na linha das pilastras
	for k = 1, 4 do table.insert(linhasW, W0 + k * MODULO) end
	for _, u in ipairs(vigasU) do
		caixa(T, "Viga_Mestra", L, u - 0.5, u + 0.5, 13.2, H, W0 + borda, W1 - borda, M.Painel)
	end
	local colunas = { { -HW + borda, -5.5 }, { -4.5, 4.5 }, { 5.5, HW - borda } }
	for _, w in ipairs(linhasW) do
		for _, c in ipairs(colunas) do
			caixa(T, "Viga_Travessa", L, c[1], c[2], 13.3, H, w - 0.4, w + 0.4, M.Painel)
		end
	end
	-- almofada no fundo de cada caixotao
	local faixas = { { W0 + borda, linhasW[1] - 0.4 } }
	for k = 1, 3 do table.insert(faixas, { linhasW[k] + 0.4, linhasW[k + 1] - 0.4 }) end
	table.insert(faixas, { linhasW[4] + 0.4, W1 - borda })
	for i, f in ipairs(faixas) do
		for j, c in ipairs(colunas) do
			local w1 = f[2]
			if i == 5 and j == 2 then w1 = W1 - PEITO_D end   -- o peito da lareira corta este
			caixa(T, "Caixotao", L, c[1] + 0.6, c[2] - 0.6, H - 0.1, H, f[1] + 0.6, w1 - 0.6, M.Caixotao, FINO)
		end
	end
end

-- ================================================================== 4. LAREIRA (parede do fundo)
do
	local F, Lr = PAREDE.Fundo, P.Lareira
	local b0, b1 = 12.2, 17.8      -- boca: 5,6 de largura
	local yb = 5.4                 -- altura da boca
	local D = PEITO_D
	-- peito (o volume que avanca da parede)
	caixa(Lr, "Peito_Pilar", F, PEITO_T0, b0, 0, yb, 0, D, M.Painel, SOLIDO)
	caixa(Lr, "Peito_Pilar", F, b1, PEITO_T1, 0, yb, 0, D, M.Painel, SOLIDO)
	caixa(Lr, "Peito_Alto", F, PEITO_T0, PEITO_T1, yb, H, 0, D, M.Painel, SOLIDO)
	-- forro da fornalha, enegrecido
	caixa(Lr, "Fornalha_Fundo", F, b0, b1, 0, yb, 0, 0.12, M.Fuligem)
	caixa(Lr, "Fornalha_Lado", F, b0, b0 + 0.12, 0, yb, 0.12, D, M.Fuligem)
	caixa(Lr, "Fornalha_Lado", F, b1 - 0.12, b1, 0, yb, 0.12, D, M.Fuligem)
	caixa(Lr, "Fornalha_Teto", F, b0 + 0.12, b1 - 0.12, yb - 0.12, yb, 0.12, D, M.Fuligem)
	-- guarnicao de pedra
	caixa(Lr, "Pedra_Ombreira", F, b0 - 1.3, b0, 0, yb, D, D + 0.3, M.Rocha)
	caixa(Lr, "Pedra_Ombreira", F, b1, b1 + 1.3, 0, yb, D, D + 0.3, M.Rocha)
	caixa(Lr, "Pedra_Verga", F, b0 - 1.3, b1 + 1.3, yb, 6.25, D, D + 0.3, M.Rocha)
	caixa(Lr, "Pedra_Fecho", F, 14.5, 15.5, yb - 0.1, 6.25, D + 0.3, D + 0.42, M.Rocha)
	-- consolos e prateleira
	caixa(Lr, "Consolo", F, b0 - 1.3, b0 - 0.7, 5.6, 6.25, D + 0.3, D + 0.7, M.Painel)
	caixa(Lr, "Consolo", F, b1 + 0.7, b1 + 1.3, 5.6, 6.25, D + 0.3, D + 0.7, M.Painel)
	caixa(Lr, "Prateleira_Moldura", F, b0 - 1.6, b1 + 1.6, 6.25, 6.5, D, D + 0.6, M.Painel)
	caixa(Lr, "Prateleira", F, b0 - 1.9, b1 + 1.9, 6.5, 6.85, D, D + 0.9, M.Painel)
	-- sobrelareira: moldura grande, pronta para um quadro
	caixa(Lr, "Sobrelareira_Almofada", F, 11.5, 18.5, 7.9, 11.1, D, D + 0.06, M.Lambril, FINO)
	caixa(Lr, "Sobrelareira_Moldura", F, 11.2, 18.8, 7.6, 7.9, D, D + 0.2, M.Painel)
	caixa(Lr, "Sobrelareira_Moldura", F, 11.2, 18.8, 11.1, 11.4, D, D + 0.2, M.Painel)
	caixa(Lr, "Sobrelareira_Moldura", F, 11.2, 11.5, 7.9, 11.1, D, D + 0.2, M.Painel)
	caixa(Lr, "Sobrelareira_Moldura", F, 18.5, 18.8, 7.9, 11.1, D, D + 0.2, M.Painel)
	-- filetes nas quinas do peito
	caixa(Lr, "Peito_Filete", F, PEITO_T0 + 0.1, PEITO_T0 + 0.8, 0, Y_FRISO, D, D + 0.15, M.Painel)
	caixa(Lr, "Peito_Filete", F, PEITO_T1 - 0.8, PEITO_T1 - 0.1, 0, Y_FRISO, D, D + 0.15, M.Painel)
	-- lar de pedra (degrau de 0,25) e leito de cinza com brasas quase mortas
	caixa(Lr, "Lar", F, b0 - 2.0, b1 + 2.0, 0, 0.25, 0.12, D + 1.8, M.Rocha, SOLIDO)
	caixa(Lr, "Cinza", F, b0 + 0.4, b1 - 0.4, 0.25, 0.33, 0.3, D - 0.3, M.Cinza, FINO)
	local brasas = { { 12.9, 0.5 }, { 13.6, 1.7 }, { 16.3, 0.6 }, { 17.0, 1.5 }, { 15.9, 1.95 }, { 14.2, 0.45 } }
	for _, b in ipairs(brasas) do
		caixa(Lr, "Brasa", F, b[1], b[1] + 0.2, 0.33, 0.39, b[2], b[2] + 0.14, M.Brasa, FINO)
	end
	luz(P.Luzes, "Luz_Brasas", (F * CFrame.new(15, 1.0, 1.2)).Position, Color3.fromRGB(255, 96, 48),
		CONFIG.BRASA_BRILHO, CONFIG.BRASA_ALCANCE, false)

	-- cortinas pesadas dos dois lados (13 pregas cada)
	for _, tc in ipairs({ 5, 25 }) do
		for i = 0, 12 do
			local d = (i % 2 == 0) and 0.72 or 0.9
			cilindro(Lr, "Cortina_Prega", F, tc - 2.88 + i * 0.48, 0.1, 11.2, d, 0.58, M.Cortina, { sombra = i % 2 == 0 })
		end
		caixa(Lr, "Cortina_Sanefa", F, tc - 3.5, tc + 3.5, 11.2, 12.0, 0, 1.3, M.Painel)
		caixa(Lr, "Cortina_Sanefa_Coroa", F, tc - 3.62, tc + 3.62, 12.0, Y_FRISO, 0, 1.42, M.Painel)
		caixa(Lr, "Cortina_Sanefa_Almofada", F, tc - 3.0, tc + 3.0, 11.35, 11.85, 1.3, 1.34, M.Lambril, FINO)
	end
end

-- ================================================================== 5. PORTAIS LATERAIS (fechados)
-- Mesmo padrao do portal da torre: o plano p = 0 fica 0,5 para DENTRO da face da parede,
-- de modo que a face de fora (parede de 1,0) cai em p = 1,5, igual a cantaria da torre.
local encaixes = {}   -- { nome, cframe do encaixe }
for _, nome in ipairs({ "LadoA", "LadoB" }) do
	local F = PAREDE[nome]
	local pasta = Instance.new("Folder"); pasta.Name = "Portal_" .. nome; pasta.Parent = P.Portais
	local v, yv = PADRAO.VAO_MEIA_LARGURA, PADRAO.VAO_ALTURA
	-- quadro do encaixe: x para o lado, z = p para fora da sala
	local S = F * CFrame.new(PT, 0, 0.5) * CFrame.Angles(0, math.pi, 0)
	table.insert(encaixes, { nome = nome, cf = S })

	-- guarnicao
	caixa(pasta, "Plinto", F, PT - v - 0.78, PT - v + 0.07, 0, 1.0, 0, 0.36, M.Painel)
	caixa(pasta, "Plinto", F, PT + v - 0.07, PT + v + 0.78, 0, 1.0, 0, 0.36, M.Painel)
	caixa(pasta, "Guarnicao", F, PT - v - 0.7, PT - v, 1.0, yv, 0, 0.25, M.Painel)
	caixa(pasta, "Guarnicao", F, PT + v, PT + v + 0.7, 1.0, yv, 0, 0.25, M.Painel)
	caixa(pasta, "Guarnicao_Topo", F, PT - v - 0.7, PT + v + 0.7, yv, yv + 0.7, 0, 0.25, M.Painel)
	caixa(pasta, "Sobreporta", F, PT - 3.45, PT + 3.45, yv + 0.7, yv + 1.05, 0, 0.55, M.Painel)
	caixa(pasta, "Bandeira_Almofada", F, PT - 2.6, PT + 2.6, 10.7, 11.5, 0, 0.06, M.Lambril, FINO)
	caixa(pasta, "Bandeira_Moldura", F, PT - 2.8, PT + 2.8, 10.5, 10.7, 0, 0.16, M.Painel)
	caixa(pasta, "Bandeira_Moldura", F, PT - 2.8, PT + 2.8, 11.5, 11.7, 0, 0.16, M.Painel)
	caixa(pasta, "Bandeira_Moldura", F, PT - 2.8, PT - 2.6, 10.7, 11.5, 0, 0.16, M.Painel)
	caixa(pasta, "Bandeira_Moldura", F, PT + 2.6, PT + 2.8, 10.7, 11.5, 0, 0.16, M.Painel)
	-- soleira
	caixa(pasta, "Soleira", S, -v, v, -0.3, 0.03, 0.5, PADRAO.FUNDO_P, M.Rocha, SOLIDO)

	-- folhas: copia das folhas reais da torre, giradas para este portal
	local copiadas = 0
	local delta = S * L:Inverse()
	for _, f in ipairs(folhasTorre) do
		local c = f.vis:Clone()
		for _, tag in ipairs(CollectionService:GetTags(c)) do CollectionService:RemoveTag(c, tag) end
		c.Name = "Folha_" .. f.lado
		c.CFrame = delta * f.vis.CFrame
		c.Anchored = true; c.CanCollide = false; c.CanTouch = false; c.CanQuery = false
		c.Locked = CONFIG.TRAVAR
		c:SetAttribute("Lado", f.lado)
		if typeof(f.dobradica) == "Vector3" then c:SetAttribute("Dobradica", delta * f.dobradica) end
		c.Parent = pasta
		copiadas += 1
	end
	if copiadas < 2 then
		-- sem as folhas da torre: duas folhas simples de madeira, no mesmo lugar e medida
		for _, c in ipairs(pasta:GetChildren()) do
			if string.sub(c.Name, 1, 6) == "Folha_" then c:Destroy() end
		end
		for _, s in ipairs({ -1, 1 }) do
			local lado = (s == 1) and "Left" or "Right"
			local fl = caixa(pasta, "Folha_" .. lado, S, s * 0.025, s * v, PADRAO.FOLHA_Y0, PADRAO.FOLHA_Y1,
				PADRAO.FOLHA_P0, PADRAO.FOLHA_P1, M.Painel)
			fl:SetAttribute("Lado", lado)
			fl:SetAttribute("Dobradica", S * Vector3.new(s * PADRAO.DOBRADICA_X, 0, PADRAO.DOBRADICA_P))
			for _, y in ipairs({ { 0.7, 3.0 }, { 3.5, 5.9 }, { 6.4, 8.5 } }) do
				caixa(pasta, "Folha_Almofada", S, s * 0.45, s * (v - 0.4), y[1], y[2], PADRAO.FOLHA_P0 - 0.06, PADRAO.FOLHA_P0, M.Lambril, FINO)
			end
		end
		aviso("Portal_" .. nome .. ": nao consegui copiar as folhas da torre (achei " .. copiadas .. "). Usei folhas simples de madeira.")
	end

	-- colisao do portal fechado e fundo preto, como na torre
	local col = invisivel(P.Colisao, "COL_Portal_" .. nome, S, -v, v, 0, yv, PADRAO.FOLHA_P0, PADRAO.FOLHA_P1)
	col:SetAttribute("Portal", nome)
	local fundo = caixa(pasta, "Fundo_" .. nome, S, -3.75, 3.75, -0.4, 10.6, PADRAO.FUNDO_P - 0.15, PADRAO.FUNDO_P + 0.15, M.Preto)
	fundo.CastShadow = true
end

-- ================================================================== 6. TAPETES
do
	local Tp = P.Tapetes
	local cx = CENTRO_W
	local function tapete(nome, u0, u1, w0, w1, bordaU, bordaW)
		caixa(Tp, nome .. "_Galao", L, u0, u1, 0, 0.035, w0, w1, M.Galao, FINO)
		caixa(Tp, nome, L, u0 + bordaU[1], u1 - bordaU[2], 0, 0.055, w0 + bordaW[1], w1 - bordaW[2], M.Veludo, FINO)
	end
	local g = 0.3
	tapete("Passadeira_Entrada", -2.8, 2.8, W0, cx - 6.3, { g, g }, { 0, 0 })
	tapete("Tapete_Central", -6.3, 6.3, cx - 6.3, cx + 6.3, { g, g }, { g, g })
	tapete("Passadeira_Fundo", -2.8, 2.8, cx + 6.3, W1 - PEITO_D - 2.0, { g, g }, { 0, g })
	tapete("Passadeira_LadoA", 6.3, HW - 0.8, cx - 2.8, cx + 2.8, { 0, g }, { g, g })
	tapete("Passadeira_LadoB", -HW + 0.8, -6.3, cx - 2.8, cx + 2.8, { g, 0 }, { g, g })
	-- filete dourado dentro do tapete central
	local a = 4.9
	caixa(Tp, "Tapete_Filete", L, -a, a, 0, 0.062, cx - a, cx - a + 0.14, M.Galao, FINO)
	caixa(Tp, "Tapete_Filete", L, -a, a, 0, 0.062, cx + a - 0.14, cx + a, M.Galao, FINO)
	caixa(Tp, "Tapete_Filete", L, -a, -a + 0.14, 0, 0.062, cx - a + 0.14, cx + a - 0.14, M.Galao, FINO)
	caixa(Tp, "Tapete_Filete", L, a - 0.14, a, 0, 0.062, cx - a + 0.14, cx + a - 0.14, M.Galao, FINO)
end

-- ================================================================== 7. LUSTRE E ARANDELAS
do
	local Lz = P.Luzes
	local corVela = Color3.fromRGB(255, 190, 135)

	-- lustre de roda de ferro, 6 velas (4 acesas), pendurado no caixotao central
	local yr = 9.7
	local Cc = L * CFrame.new(0, yr, CENTRO_W)
	local R, N = 3.0, 12
	local lado = 2 * R * math.tan(math.pi / N) + 0.06
	for i = 0, N - 1 do
		peca(Lz, "Lustre_Aro", Cc * CFrame.Angles(0, i * 2 * math.pi / N, 0) * CFrame.new(0, 0, -R),
			Vector3.new(lado, 0.34, 0.14), M.Ferro)
	end
	peca(Lz, "Lustre_Cruz", Cc, Vector3.new(2 * R, 0.12, 0.12), M.Ferro)
	peca(Lz, "Lustre_Cruz", Cc * CFrame.Angles(0, math.pi / 2, 0) * CFrame.new(0, -0.015, 0), Vector3.new(2 * R, 0.11, 0.11), M.Ferro)
	cilindro(Lz, "Lustre_Cubo", L, 0, yr - 0.28, yr + 0.28, CENTRO_W, 0.7, M.Ferro)
	local topo = Cc * Vector3.new(0, 3.1, 0)
	for k = 0, 3 do
		local ang = math.pi / 4 + k * math.pi / 2
		vara(Lz, "Lustre_Corrente", Cc * Vector3.new(math.sin(ang) * R, 0.17, -math.cos(ang) * R), topo, 0.07, M.Ferro)
	end
	cilindro(Lz, "Lustre_Argola", L, 0, yr + 3.0, yr + 3.25, CENTRO_W, 0.34, M.Ferro, FINO)
	cilindro(Lz, "Lustre_Haste", L, 0, yr + 3.25, H, CENTRO_W, 0.1, M.Ferro, FINO)
	for k = 0, 5 do
		local ang = k * math.pi / 3
		local Fv = Cc * CFrame.Angles(0, ang, 0) * CFrame.new(0, 0, -R)
		local acesa = (k % 3) ~= 2
		local hv = acesa and 0.8 or 0.42
		peca(Lz, "Lustre_Prato", Fv * CFrame.new(0, 0.22, 0) * CFrame.Angles(0, 0, math.pi / 2), Vector3.new(0.1, 0.44, 0.44), M.Ferro,
			{ forma = Enum.PartType.Cylinder, sombra = false })
		peca(Lz, "Lustre_Vela", Fv * CFrame.new(0, 0.27 + hv / 2, 0) * CFrame.Angles(0, 0, math.pi / 2), Vector3.new(hv, 0.24, 0.24), M.Cera,
			{ forma = Enum.PartType.Cylinder, sombra = false })
		if acesa then
			peca(Lz, "Lustre_Chama", Fv * CFrame.new(0, 0.27 + hv + 0.17, 0) * CFrame.Angles(0, 0, math.pi / 2), Vector3.new(0.3, 0.13, 0.13), M.Chama,
				{ forma = Enum.PartType.Cylinder, sombra = false })
		end
	end
	local ll = luz(Lz, "Luz_Lustre", Cc * Vector3.new(0, 0.9, 0), corVela, CONFIG.LUSTRE_BRILHO, CONFIG.LUSTRE_ALCANCE, true)
	ll:SetAttribute("Grupo", "lustre")

	-- arandela de 2 velas, presa na face de uma pilastra
	local function arandela(F, tc, acesa)
		local d0 = 0.49
		caixa(Lz, "Arandela_Espelho", F, tc - 0.22, tc + 0.22, 6.2, 7.5, d0, d0 + 0.07, M.Latao, FINO)
		caixa(Lz, "Arandela_Braco", F, tc - 0.06, tc + 0.06, 6.5, 6.62, d0 + 0.07, d0 + 0.76, M.Latao, FINO)
		caixa(Lz, "Arandela_Travessa", F, tc - 0.62, tc + 0.62, 6.47, 6.6, d0 + 0.7, d0 + 0.8, M.Latao, FINO)
		for _, s in ipairs({ -1, 1 }) do
			local t = tc + s * 0.55
			local hv = acesa and 0.75 or (s == 1 and 0.5 or 0.3)
			cilindro(Lz, "Arandela_Prato", F, t, 6.6, 6.68, d0 + 0.75, 0.36, M.Latao, FINO)
			cilindro(Lz, "Arandela_Vela", F, t, 6.68, 6.68 + hv, d0 + 0.75, 0.2, M.Cera, FINO)
			if acesa then cilindro(Lz, "Arandela_Chama", F, t, 6.72 + hv, 7.0 + hv, d0 + 0.75, 0.12, M.Chama, FINO) end
		end
		if acesa then
			local l = luz(Lz, "Luz_Arandela", (F * CFrame.new(tc, 7.6, d0 + 0.85)).Position, Color3.fromRGB(255, 182, 122),
				CONFIG.ARANDELA_BRILHO, CONFIG.ARANDELA_ALCANCE, false)
			l:SetAttribute("Grupo", "arandela")
		end
	end
	-- so as 4 que ladeiam os portais laterais ficam acesas. As da entrada ficam apagadas de
	-- proposito: luz sem sombra atravessa parede e vazaria para dentro da torre.
	for _, nome in ipairs({ "LadoA", "LadoB" }) do
		for k = 1, 4 do arandela(PAREDE[nome], k * MODULO, k == 2 or k == 3) end
	end
	arandela(PAREDE.Entrada, 10, false); arandela(PAREDE.Entrada, 20, false)
end

-- ================================================================== 8. MESA CENTRAL
if CONFIG.MESA_CENTRAL then
	local Mb = P.Mobilia
	local w = CENTRO_W
	cilindro(Mb, "Mesa_Base", L, 0, 0.055, 0.35, w, 3.6, M.Painel, SOLIDO)
	cilindro(Mb, "Mesa_Base2", L, 0, 0.35, 0.6, w, 2.6, M.Painel)
	cilindro(Mb, "Mesa_Coluna", L, 0, 0.6, 2.75, w, 1.1, M.Painel, SOLIDO)
	cilindro(Mb, "Mesa_Colar", L, 0, 2.75, 2.95, w, 1.9, M.Painel)
	cilindro(Mb, "Mesa_Saia", L, 0, 2.95, 3.2, w, 5.6, M.Lambril)
	cilindro(Mb, "Mesa_Tampo", L, 0, 3.2, 3.45, w, 6.4, M.Painel, SOLIDO)
end

-- ================================================================== 9. ARMARIOS
-- mede um movel no eixo da sua maior peca: devolve a peca, o minimo, o maximo e o lado da frente
local function medirMovel(model)
	local ref, vol = nil, 0
	local partes = {}
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			table.insert(partes, d)
			local v = d.Size.X * d.Size.Y * d.Size.Z
			if v > vol then ref, vol = d, v end
		end
	end
	if not ref then return nil end
	local inv = ref.CFrame:Inverse()
	local mn = Vector3.new(math.huge, math.huge, math.huge); local mx = -mn
	local somaZ, nZ = 0, 0
	for _, d in ipairs(partes) do
		local rel, s = inv * d.CFrame, d.Size / 2
		for _, sx in ipairs({ -1, 1 }) do for _, sy in ipairs({ -1, 1 }) do for _, sz in ipairs({ -1, 1 }) do
			local q = rel * Vector3.new(s.X * sx, s.Y * sy, s.Z * sz)
			mn = mn:Min(q); mx = mx:Max(q)
		end end end
		if d ~= ref then somaZ += rel.Position.Z; nZ += 1 end
	end
	-- as portas e gavetas ficam do lado da frente
	local frente = -1
	if nZ > 0 and (somaZ / nZ) > (mn.Z + mx.Z) / 2 then frente = 1 end
	return ref, mn, mx, frente, partes
end
local function mesmoTamanho(mn, mx, medida)
	local s = mx - mn
	return math.abs(s.X - medida[1]) < 0.25 and math.abs(s.Y - medida[2]) < 0.25 and math.abs(s.Z - medida[3]) < 0.25
end

local moveisPostos = {}
for _, mv in ipairs(CONFIG.MOVEIS) do
	local F = PAREDE[mv.parede]
	local modelo = moveis:FindFirstChild(mv.nome)
	if not modelo then
		-- procura o original solto no Workspace, pela medida, e copia
		for _, m in ipairs(workspace:GetChildren()) do
			if m:IsA("Model") and m ~= raiz then
				local ref, mn, mx = medirMovel(m)
				if ref and mesmoTamanho(mn, mx, mv.medida) then
					modelo = m:Clone(); modelo.Name = mv.nome; modelo.Parent = moveis
					break
				end
			end
		end
	end
	if not F then
		aviso(mv.nome .. ": parede '" .. tostring(mv.parede) .. "' nao existe. Use Entrada, Fundo, LadoA ou LadoB.")
	elseif not modelo then
		aviso(mv.nome .. ": nao achei no Workspace um modelo com a medida " .. table.concat(mv.medida, " x ") .. ". Importe o GLB e rode de novo.")
	else
		local ref, mn, mx, frente, partes = medirMovel(modelo)
		local larg, alt, prof = mx.X - mn.X, mx.Y - mn.Y, mx.Z - mn.Z
		local costas = (frente == -1) and mx.Z or mn.Z
		-- quadro do movel: origem no meio da base, encostado nas costas; Z aponta para a frente
		local G = ref.CFrame * CFrame.fromMatrix(Vector3.new((mn.X + mx.X) / 2, mn.Y, costas),
			Vector3.new(frente, 0, 0), UP, Vector3.new(0, 0, frente))
		local folga = 0.42   -- a cimalha do lambril avanca 0,38
		local alvo = F * CFrame.new(mv.t, 0, folga)
		modelo:PivotTo(alvo * G:Inverse() * modelo:GetPivot())
		for _, d in ipairs(partes) do
			d.Anchored = true; d.CanCollide = false; d.CanTouch = false; d.CanQuery = false
			d.Locked = CONFIG.TRAVAR
		end
		invisivel(P.Colisao, "COL_" .. mv.nome, F, mv.t - larg / 2, mv.t + larg / 2, 0, alt, folga, folga + prof)
		table.insert(moveisPostos, ("%s (%.2f x %.2f x %.2f)"):format(mv.nome, larg, alt, prof))
	end
end

-- ================================================================== 10. ESCONDERIJOS
-- O Script 09 poe a base do totem no CENTRO da peca marcada. Totem: 2,2 x 4,7 x 2,1.
do
	local Es = P.Esconderijos
	local function esconderijo(nome, u, y, w)
		local p = Instance.new("Part")
		p.Name = "Esc_" .. nome
		p.Size = Vector3.new(2.2, 0.1, 2.2)
		p.CFrame = L * CFrame.new(u, y, w)
		p.Anchored = true; p.CanCollide = false; p.CanTouch = false; p.CanQuery = false; p.CastShadow = false
		p.Material = Enum.Material.Neon; p.Color = Color3.fromRGB(120, 255, 170)
		p.Transparency = CONFIG.MOSTRAR_ESCONDERIJOS and 0.5 or 1
		p.Locked = CONFIG.TRAVAR
		p.Parent = Es
		CollectionService:AddTag(p, "Invokyr_Esconderijo")
	end
	esconderijo("Lareira", 0, 0.33, W1 - 1.26)                    -- dentro da fornalha, sobre as cinzas
	if CONFIG.MESA_CENTRAL then esconderijo("Mesa", 0, 3.45, CENTRO_W) end
	esconderijo("Portal_LadoA", HW - 2.2, 0.055, CENTRO_W)        -- aos pes da porta trancada
	esconderijo("Portal_LadoB", -HW + 2.2, 0.055, CENTRO_W)
	esconderijo("Canto_Fundo_A", HW - 1.9, 0, W1 - 2.7)           -- canto, na ponta da cortina
	esconderijo("Canto_Fundo_B", -HW + 1.9, 0, W1 - 2.7)
	esconderijo("Entrada_Parede", 10, 0, W0 + 1.7)                -- parede vazia ao lado da entrada
	esconderijo("Entrada_Armario", -HW + 2.2, 0, W0 + 1.6)        -- entre o armario oriental e o canto
end

-- ================================================================== 11. ENCAIXES (para as proximas salas)
do
	local anc = Instance.new("Part")
	anc.Name = "AncoraEncaixes"; anc.Anchored = true; anc.Size = Vector3.new(1, 1, 1); anc.CFrame = CFrame.new(P0)
	anc.Transparency = 1; anc.CanCollide = false; anc.CanQuery = false; anc.CanTouch = false; anc.CastShadow = false
	anc.Locked = true
	anc.Parent = P.Encaixes
	local function ponto(nome, cf, livre)
		local a = Instance.new("Attachment")
		a.Name = "Encaixe_" .. nome
		a.Position = cf.Position - P0
		a:SetAttribute("Tipo", "portal")
		a:SetAttribute("Fora", cf.ZVector)
		a:SetAttribute("Livre", livre)
		a.Parent = anc
	end
	ponto("Entrada", L * CFrame.Angles(0, math.pi, 0), false)   -- ocupado pela Sala Principal
	for _, e in ipairs(encaixes) do ponto(e.nome, e.cf, true) end
end

-- ================================================================== 12. O QUE SAI DE USO VAI PARA O BACKUP
do
	local fundos = sala:FindFirstChild("Efeitos") and sala.Efeitos:FindFirstChild("FundoPortas")
	-- se o Atrio mudou de portal, devolve o fundo preto do portal antigo
	local antigo = atrio:GetAttribute("Portal")
	if antigo and antigo ~= CONFIG.PORTAL and fundos then
		local f = backup:FindFirstChild("Fundo_" .. antigo)
		if f then f.Parent = fundos; info("Fundo_" .. antigo .. " devolvido ao portal antigo") end
	end
	atrio:SetAttribute("Portal", CONFIG.PORTAL)
	local f = fundos and fundos:FindFirstChild("Fundo_" .. CONFIG.PORTAL)
	if f then
		f.Parent = backup
		info("Fundo_" .. CONFIG.PORTAL .. " (placa preta atras da porta) movido para ServerStorage > Invokyr_Backup")
	end
	if CONFIG.RETIRAR_ESCONDERIJOS_DE_TESTE then
		local teste = raiz:FindFirstChild("Totens") and raiz.Totens:FindFirstChild("Esconderijos")
		local n = 0
		if teste then
			local destino = backup:FindFirstChild("Esconderijos_Teste")
			if not destino then destino = Instance.new("Folder"); destino.Name = "Esconderijos_Teste"; destino.Parent = backup end
			for _, e in ipairs(teste:GetChildren()) do e.Parent = destino; n += 1 end
		end
		if n > 0 then info(n .. " esconderijos de teste movidos para ServerStorage > Invokyr_Backup > Esconderijos_Teste") end
	end
end

-- ================================================================== conferencia
local nEsc, semChao = 0, {}
do
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Include
	rp.FilterDescendantsInstances = { atrio }
	for _, e in ipairs(P.Esconderijos:GetChildren()) do
		nEsc += 1
		local r = workspace:Raycast(e.Position + Vector3.new(0, 1.5, 0), Vector3.new(0, -3, 0), rp)
		if not r or math.abs(r.Position.Y - e.Position.Y) > 0.12 then table.insert(semChao, e.Name) end
	end
end
if #semChao > 0 then aviso("Esconderijos sem apoio logo abaixo: " .. table.concat(semChao, ", ")) end
local todos = 0
for _, p in ipairs(CollectionService:GetTagged("Invokyr_Esconderijo")) do
	if p:IsDescendantOf(workspace) then todos += 1 end
end
if Lighting.ClockTime > 6 and Lighting.ClockTime < 18 then
	info("Obs.: o place esta com luz de DIA (ClockTime " .. string.format("%.1f", Lighting.ClockTime) .. "). Julgue as cores com a luz noturna.")
end

info(("Atrio encaixado no portal %s | interno %d x %d x %d studs"):format(CONFIG.PORTAL, 2 * HW, W1 - W0, H))
info(("Pecas criadas: %d | luzes: 1 lustre + 4 arandelas + brasas"):format(total))
info(("Folhas da torre usadas como molde: %d"):format(#folhasTorre))
info("Armarios: " .. (#moveisPostos > 0 and table.concat(moveisPostos, ", ") or "nenhum"))
info(("Esconderijos no Atrio: %d | com a tag no Workspace inteiro: %d"):format(nEsc, todos))

pcall(function()
	workspace.CurrentCamera.CFrame = CFrame.lookAt(L * Vector3.new(4, 6.5, W0 + 3), L * Vector3.new(-2, 5, CENTRO_W + 6))
end)

if recording then pcall(function() ChangeHistoryService:FinishRecording(recording, Enum.FinishRecordingOperation.Commit) end) end
print("========== INVOKYR 14: ATRIO ==========")
for _, l in ipairs(linhas) do print("  " .. l) end
if #avisos == 0 then print("  Sem avisos.") else for _, a in ipairs(avisos) do warn("  AVISO: " .. a) end end
print("Agora: Play, role o dado e atravesse a porta " .. CONFIG.PORTAL .. ".")
