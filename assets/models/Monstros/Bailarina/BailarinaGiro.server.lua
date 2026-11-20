--[[
	BAILARINA GIGANTE  -  giro + "Batatinha frita 1, 2, 3"
	------------------------------------------------------
	ONDE COLOCAR: este Script vai DENTRO do Model "Bailarina" (que fica no Workspace).
	Ele faz 3 coisas sozinho quando o jogo comeca:
	  1) aumenta a estatua ate a altura que voce escolher (ALTURA_STUDS)
	  2) faz a bailarina (e o bloquinho) girar em cima do pedestal, que fica parado
	  3) no MODO "batatinha": gira com a musica (luz verde), para de repente (luz vermelha)
	     e quem se mexer enquanto ela esta parada e punido.
	Tudo que voce precisa mudar esta na tabela CONFIG logo abaixo.
]]

local CONFIG = {
	ALTURA_STUDS     = 60,          -- altura final da estatua (do chao ate a ponta da mao). Use 0 para nao mexer no tamanho
	MODO             = "batatinha", -- "batatinha" = gira e para para vigiar | "giro" = so gira sem parar
	VELOCIDADE_GIRO  = 50,          -- graus por segundo enquanto ela danca
	TEMPO_DANCA_MIN  = 3,           -- segundos girando (luz verde), sorteado entre MIN e MAX
	TEMPO_DANCA_MAX  = 7,
	TEMPO_REACAO     = 0.7,         -- segundos de "tolerancia" logo depois que ela para (pra dar tempo de frear)
	TEMPO_VIGIA      = 4,           -- segundos parada vigiando (luz vermelha)
	TOLERANCIA_PASSO = 0.6,         -- quantos studs o jogador pode escorregar sem ser pego
	CAMPO_DE_VISAO   = 360,         -- 360 = ve a sala inteira | 120 = so pega quem esta na frente dela
	INVERTER_FRENTE  = false,       -- so importa se CAMPO_DE_VISAO < 360: troque se ela "enxergar" pelas costas
	ALCANCE          = 400,         -- distancia maxima (studs) que ela vigia
	PUNICAO          = "morrer",    -- "morrer" ou "voltar" (volta para o SpawnLocation)
	ID_MUSICA        = "",          -- opcional, ex: "rbxassetid://1234567890" (toca so enquanto ela gira)
	VOLUME_MUSICA    = 0.6,
	PARTE_FIXA       = "Pedestal",  -- nome da peca que NAO gira
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local modelo = script.Parent
assert(modelo:IsA("Model"), "Coloque o Script BailarinaGiro DENTRO do Model da bailarina")

-- 1) tamanho -------------------------------------------------------------------------------
for _, p in ipairs(modelo:GetDescendants()) do
	if p:IsA("BasePart") then p.Anchored = true end
end
if CONFIG.ALTURA_STUDS > 0 then
	local altura = modelo:GetExtentsSize().Y
	if altura > 0 then modelo:ScaleTo(modelo:GetScale() * CONFIG.ALTURA_STUDS / altura) end
end

-- 2) separa o que gira do que fica parado ----------------------------------------------------
local fixa = modelo:FindFirstChild(CONFIG.PARTE_FIXA, true)
local giratoria = Instance.new("Model")
giratoria.Name = "ParteQueGira"
for _, p in ipairs(modelo:GetChildren()) do
	if p:IsA("BasePart") and p ~= fixa then p.Parent = giratoria end
end
giratoria.Parent = modelo
local centro = (fixa and fixa.Position) or modelo:GetPivot().Position
local caixa = giratoria:GetBoundingBox()   -- (CFrame do centro, tamanho)
giratoria.WorldPivot = CFrame.new(centro.X, caixa.Position.Y, centro.Z)
local pivoInicial = giratoria:GetPivot()

local estado = ReplicatedStorage:FindFirstChild("BailarinaEstado") or Instance.new("StringValue")
estado.Name = "BailarinaEstado"; estado.Value = "verde"; estado.Parent = ReplicatedStorage

local musica
if CONFIG.ID_MUSICA ~= "" then
	musica = Instance.new("Sound")
	musica.SoundId = CONFIG.ID_MUSICA; musica.Looped = true; musica.Volume = CONFIG.VOLUME_MUSICA
	musica.RollOffMaxDistance = 1000; musica.Parent = fixa or giratoria.PrimaryPart or modelo
end

-- giro suave (acelera e freia)
local angulo, vel, girando = 0, 0, true
RunService.Heartbeat:Connect(function(dt)
	local alvo = girando and math.rad(CONFIG.VELOCIDADE_GIRO) or 0
	vel = vel + (alvo - vel) * math.min(1, dt * 3.5)
	if math.abs(vel) < 1e-4 and not girando then vel = 0 end
	angulo = angulo + vel * dt
	giratoria:PivotTo(pivoInicial * CFrame.Angles(0, angulo, 0))
end)

if CONFIG.MODO ~= "batatinha" then
	if musica then musica:Play() end
	return
end

-- 3) batatinha frita 1, 2, 3 ------------------------------------------------------------------
local function raiz(plr)
	local ch = plr.Character
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
	if hum and hrp and hum.Health > 0 then return hum, hrp end
end

local function estaVendo(hrp)
	local d = hrp.Position - centro
	local plano = Vector3.new(d.X, 0, d.Z)
	if plano.Magnitude > CONFIG.ALCANCE then return false end
	if CONFIG.CAMPO_DE_VISAO >= 360 or plano.Magnitude < 1 then return true end
	local frente = giratoria:GetPivot().LookVector * (CONFIG.INVERTER_FRENTE and 1 or -1)
	frente = Vector3.new(frente.X, 0, frente.Z).Unit
	local ang = math.deg(math.acos(math.clamp(frente:Dot(plano.Unit), -1, 1)))
	return ang <= CONFIG.CAMPO_DE_VISAO / 2
end

local function punir(plr)
	local hum, hrp = raiz(plr)
	if not hum then return end
	if CONFIG.PUNICAO == "voltar" then
		local spawn = workspace:FindFirstChildWhichIsA("SpawnLocation", true)
		if spawn then hrp.CFrame = spawn.CFrame + Vector3.new(0, 4, 0) else plr:LoadCharacter() end
	else
		hum.Health = 0
	end
end

while true do
	-- LUZ VERDE: musica + giro
	estado.Value = "verde"; girando = true
	if musica then if musica.IsPaused then musica:Resume() else musica:Play() end end
	task.wait(math.random() * (CONFIG.TEMPO_DANCA_MAX - CONFIG.TEMPO_DANCA_MIN) + CONFIG.TEMPO_DANCA_MIN)

	-- LUZ VERMELHA: para e vigia
	girando = false
	if musica then musica:Pause() end
	estado.Value = "vermelho"
	task.wait(CONFIG.TEMPO_REACAO)
	local inicio = {}
	for _, plr in ipairs(Players:GetPlayers()) do
		local _, hrp = raiz(plr)
		if hrp then inicio[plr] = hrp.Position end
	end
	local t0 = os.clock()
	while os.clock() - t0 < CONFIG.TEMPO_VIGIA do
		for plr, pos in pairs(inicio) do
			local _, hrp = raiz(plr)
			if not hrp or not plr.Parent then
				inicio[plr] = nil
			elseif (hrp.Position - pos).Magnitude > CONFIG.TOLERANCIA_PASSO and estaVendo(hrp) then
				punir(plr); inicio[plr] = nil
			end
		end
		task.wait(0.1)
	end
end
