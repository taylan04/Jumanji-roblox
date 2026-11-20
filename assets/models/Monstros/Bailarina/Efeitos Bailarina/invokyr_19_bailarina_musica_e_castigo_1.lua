--[[
INVOKYR - Script 19: musica, castigo e risadas da BAILARINA (so script, nao importa modelo)
==========================================================================================
  - Enquanto a bailarina gira, toca uma caixinha de musica macabra (CaixinhaDaBailarina.ogg).
    Quando ela freia, a musica perde a corda e morre; parada, silencio total.
  - Com ela PARADA, quem se mexer leva 10 de dano. Ha um instante (0,45 s) para o jogador parar
    depois que a musica corta; quem continuar andando leva dano de novo a cada 0,9 s.
  - Quem leva dano solta um gemido de dor (DorDoJogador.ogg) e a tela leva um tranco, como um soco
    (LocalScript Invokyr_Dor: vale para qualquer dano do jogo).
  - Com gente na sala, ela da risadinhas baixas de vez em quando (RisadaDaBailarina.ogg),
    e as vezes logo depois de machucar alguem.
  - Nao mexe no giro do Codex (BailarinaGiro): so escuta o estado dela.
  - Vale para a sala guardada (Invokyr_Salas > SalaoDaBailarina) e para a Previa_SalaoDaBailarina.

ANTES: suba os audios no Roblox e cole os IDs abaixo (passo a passo no TXT). Sem a risada, ela nao ri;
sem a dor, toca o gemido padrao do Roblox. Pode rodar de novo quando quiser (IDs, dano, volumes...).
Rode com o jogo PARADO.
]]
local CONFIG = {
	MUSICA_ID = "72472246974970",   -- CaixinhaDaBailarina (ja enviada)
	RISADA_ID = "",                 -- RisadaDaBailarina.ogg
	DOR_ID = "",                    -- DorDoJogador.ogg (vazio = gemido padrao do Roblox)
	VOLUME = 0.4,                   -- musica (antes 0.8)
	VOLUME_RISADA = 0.45,
	VOLUME_DOR = 0.9,
	RISADA_A_CADA = { 18, 40 },     -- segundos entre uma risada e outra (sorteado)
	DANO = 10,
	CARENCIA = 0.45,        -- segundos para reagir depois que a musica para
	ESPERA_ENTRE_DANOS = 0.9,
	LIMIAR = 0.35,          -- quanto ele precisa andar (studs em 0,1 s) para contar como "se mexeu"
}

local RunService = game:GetService("RunService")
if RunService:IsRunning() then
	error("[Invokyr] Pare o jogo (Stop) antes de rodar o Script 19.")
end
local ServerStorage = game:GetService("ServerStorage")

local function asset(x)
	x = tostring(x or "")
	if x == "" or string.find(x, "^rbxasset") then return x end
	return "rbxassetid://" .. (string.match(x, "%d+") or "")
end
local id = asset(CONFIG.MUSICA_ID)
local idRisada = asset(CONFIG.RISADA_ID)
local idDor = asset(CONFIG.DOR_ID)
if idDor == "" then idDor = "rbxasset://sounds/uuhhh.mp3" end

local salas = {}
local biblioteca = ServerStorage:FindFirstChild("Invokyr_Salas")
if biblioteca and biblioteca:FindFirstChild("SalaoDaBailarina") then table.insert(salas, biblioteca.SalaoDaBailarina) end
for _, d in ipairs(workspace:GetDescendants()) do
	if d:IsA("Model") and d.Name == "Previa_SalaoDaBailarina" then table.insert(salas, d) end
end
if #salas == 0 then error("[Invokyr] Nao achei o Salao da Bailarina (Invokyr_Salas > SalaoDaBailarina ou Previa_SalaoDaBailarina).") end

local FONTE = [==[
-- INVOKYR - Regras da Bailarina (Script do servidor, dentro do Salao da Bailarina). Instalado pelo Script 19.
-- Nao edite aqui: mude o CONFIG do Script 19 e rode de novo.
-- Nao mexe no giro (isso e o BailarinaGiro); so ouve o atributo EstadoBailarina da sala:
--   Girando  -> a caixinha de musica toca (continua de onde parou)
--   Freando  -> a musica perde a corda e vai morrendo
--   Parada   -> silencio. Quem se mexer leva dano (depois de um instante para o jogador reagir)
--   Repouso  -> ninguem na sala: musica desligada e volta para o comeco
-- Com gente na sala ela da risadinhas baixas de vez em quando (e as vezes logo depois de machucar alguem).
-- Quem leva dano solta um gemido de dor (todo mundo perto ouve); o tremor da tela e do Invokyr_Dor.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local sala = script.Parent
local function cfg(nome, padrao)
	local v = script:GetAttribute(nome)
	if v == nil then return padrao end
	return v
end
local DANO = cfg("Dano", 10)
local CARENCIA = cfg("Carencia", 0.45)      -- segundos depois que ela para, antes de comecar a vigiar
local ESPERA = cfg("EsperaEntreDanos", 0.9) -- quem continua se mexendo leva dano de novo depois disso
local LIMIAR = cfg("Limiar", 0.35)          -- studs andados em 0,1 s que contam como "se mexeu"
local VOLUME = cfg("Volume", 0.8)

local musica = sala:FindFirstChild("MusicaDaCaixinha", true)
local risada = sala:FindFirstChild("RisadaDaBailarina", true)
local dorModelo = script:FindFirstChild("DorDoJogador")
local RISADA_MIN, RISADA_MAX = cfg("RisadaMin", 18), cfg("RisadaMax", 40)

local function rir()
	if risada and risada.SoundId ~= "" and not risada.IsPlaying then
		risada.PlaybackSpeed = 0.82 + math.random() * 0.22     -- cada risada um pouco diferente
		risada:Play()
	end
end
local function gemer(raiz)
	if not (dorModelo and dorModelo.SoundId ~= "") then return end
	local s = dorModelo:Clone()
	s.PlaybackSpeed = 0.92 + math.random() * 0.16
	s.Parent = raiz
	s:Play()
	task.delay(3, function() s:Destroy() end)
end

local function dentro(raiz)
	local p = sala:GetPivot():PointToObjectSpace(raiz.Position)
	return math.abs(p.X) < 37.5 and p.Z >= -131 and p.Z <= 131 and p.Y >= -1 and p.Y < 47
end

local estado = sala:GetAttribute("EstadoBailarina")
local vigiaDesde = math.huge
local ultimo, ultimoDano = {}, {}
local tweenMorrer

local function aoMudar()
	estado = sala:GetAttribute("EstadoBailarina")
	if tweenMorrer then tweenMorrer:Cancel(); tweenMorrer = nil end
	if estado == "Girando" then
		if musica and musica.SoundId ~= "" then
			musica.PlaybackSpeed = 1
			musica.Volume = VOLUME
			if musica.TimePosition > 0 and not musica.IsPlaying then musica:Resume() elseif not musica.IsPlaying then musica:Play() end
		end
		vigiaDesde = math.huge
	elseif estado == "Freando" then
		if musica and musica.IsPlaying then
			tweenMorrer = TweenService:Create(musica, TweenInfo.new(0.42, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{ PlaybackSpeed = 0.45, Volume = VOLUME * 0.6 })
			tweenMorrer:Play()
		end
	elseif estado == "Parada" then
		if musica then musica:Pause() end
		vigiaDesde = os.clock() + CARENCIA
		ultimo = {}
	else
		if musica then musica:Stop(); musica.TimePosition = 0 end
		vigiaDesde = math.huge
	end
end
sala:GetAttributeChangedSignal("EstadoBailarina"):Connect(aoMudar)
aoMudar()

local acc = 0
RunService.Heartbeat:Connect(function(dt)
	acc += dt
	if acc < 0.1 then return end
	acc = 0
	if estado ~= "Parada" or os.clock() < vigiaDesde then return end
	local agora = os.clock()
	for _, jogador in ipairs(Players:GetPlayers()) do
		local char = jogador.Character
		local raiz = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if raiz and hum and hum.Health > 0 and dentro(raiz) then
			local p = sala:GetPivot():PointToObjectSpace(raiz.Position)
			local antes = ultimo[jogador]
			ultimo[jogador] = p
			if antes then
				local d = p - antes
				local mexeu = Vector3.new(d.X, 0, d.Z).Magnitude > LIMIAR or math.abs(d.Y) > 0.8
				if mexeu and agora - (ultimoDano[jogador] or -10) >= ESPERA then
					ultimoDano[jogador] = agora
					hum:TakeDamage(DANO)
					gemer(raiz)
					if math.random() < 0.35 then task.delay(0.5 + math.random() * 0.6, rir) end
					jogador:SetAttribute("BailarinaViu", agora)   -- para um efeito na tela, se um dia quiser
				end
			end
		else
			ultimo[jogador] = nil
		end
	end
end)
Players.PlayerRemoving:Connect(function(j) ultimo[j] = nil; ultimoDano[j] = nil end)

-- risadinhas de vez em quando, so com gente na sala
task.spawn(function()
	while script.Parent do
		task.wait(RISADA_MIN + math.random() * (RISADA_MAX - RISADA_MIN))
		if estado and estado ~= "Repouso" then rir() end
	end
end)
]==]
local linhas = {}
for _, sala in ipairs(salas) do
	local giro = sala:FindFirstChild("BailarinaGiro")
	local parte = sala:FindFirstChild("Bailarina") and sala.Bailarina:FindFirstChild("ParteQueGira")
	local eixo = parte and (parte.PrimaryPart or parte:FindFirstChild("Eixo"))
	if not (giro and eixo) then
		warn("[Invokyr] " .. sala:GetFullName() .. " nao tem BailarinaGiro ou a Bailarina > ParteQueGira > Eixo. Pulei.")
	else
		-- a musica sai da propria estatua (gira junto com ela)
		local som = eixo:FindFirstChild("MusicaDaCaixinha")
		if not som then som = Instance.new("Sound"); som.Name = "MusicaDaCaixinha"; som.Parent = eixo end
		som.SoundId = id; som.Looped = true; som.Volume = CONFIG.VOLUME; som.PlaybackSpeed = 1
		som.RollOffMode = Enum.RollOffMode.InverseTapered
		som.RollOffMinDistance = 45; som.RollOffMaxDistance = 190
		som.Playing = false
		local ri = eixo:FindFirstChild("RisadaDaBailarina")
		if not ri then ri = Instance.new("Sound"); ri.Name = "RisadaDaBailarina"; ri.Parent = eixo end
		ri.SoundId = idRisada; ri.Looped = false; ri.Volume = CONFIG.VOLUME_RISADA
		ri.RollOffMode = Enum.RollOffMode.InverseTapered; ri.RollOffMinDistance = 25; ri.RollOffMaxDistance = 150
		local sc = sala:FindFirstChild("BailarinaRegras")
		if sc and not sc:IsA("Script") then error("[Invokyr] Ja existe um BailarinaRegras que nao e Script em " .. sala:GetFullName()) end
		if not sc then sc = Instance.new("Script"); sc.Name = "BailarinaRegras"; sc.Parent = sala end
		sc.Source = FONTE
		sc:SetAttribute("Dano", CONFIG.DANO); sc:SetAttribute("Carencia", CONFIG.CARENCIA)
		sc:SetAttribute("EsperaEntreDanos", CONFIG.ESPERA_ENTRE_DANOS); sc:SetAttribute("Limiar", CONFIG.LIMIAR)
		sc:SetAttribute("Volume", CONFIG.VOLUME)
		sc:SetAttribute("RisadaMin", CONFIG.RISADA_A_CADA[1]); sc:SetAttribute("RisadaMax", CONFIG.RISADA_A_CADA[2])
		local dor = sc:FindFirstChild("DorDoJogador")
		if not dor then dor = Instance.new("Sound"); dor.Name = "DorDoJogador"; dor.Parent = sc end
		dor.SoundId = idDor; dor.Volume = CONFIG.VOLUME_DOR
		dor.RollOffMode = Enum.RollOffMode.InverseTapered; dor.RollOffMinDistance = 10; dor.RollOffMaxDistance = 80
		-- na biblioteca o script fica desligado (ServerStorage nao roda); o gerador liga ao por a sala no mapa
		sc.Disabled = false
		table.insert(linhas, sala:GetFullName() .. ": musica " .. (id ~= "" and id or "(sem)") .. " vol " .. CONFIG.VOLUME
			.. " | risada " .. (idRisada ~= "" and idRisada or "(sem)") .. " | dor " .. idDor .. " | dano " .. CONFIG.DANO)
	end
end

-- tranco na tela quando o jogador leva dano
local sps = game:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts")
local ld = sps:FindFirstChild("Invokyr_Dor")
if ld and not ld:IsA("LocalScript") then error("[Invokyr] Ja existe um Invokyr_Dor que nao e LocalScript.") end
if not ld then ld = Instance.new("LocalScript"); ld.Name = "Invokyr_Dor"; ld.Parent = sps end
ld.Source = [==[
-- INVOKYR - Sentir o golpe (LocalScript). Instalado pelo Script 19.
-- Nao edite aqui: rode de novo o instalador que ele volta igual.
-- Sempre que o jogador perde vida (de qualquer coisa: bailarina, monstro, queda...), a camera leva um
-- tranco como um soco, treme um pouco e a tela pisca vermelho escuro. Quanto maior o dano, maior o tranco.
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local jogador = Players.LocalPlayer
local tremor = 0          -- forca atual (0 a 1)
local direcao = 1

local flash = Lighting:FindFirstChild("Invokyr_Golpe")
if not flash then
	flash = Instance.new("ColorCorrectionEffect")
	flash.Name = "Invokyr_Golpe"
	flash.Parent = Lighting
end
flash.Enabled = true; flash.TintColor = Color3.new(1, 1, 1); flash.Brightness = 0; flash.Saturation = 0

local function golpe(dano)
	local forca = math.clamp(dano / 15, 0.35, 1)
	tremor = math.max(tremor, forca)
	direcao = math.random() < 0.5 and -1 or 1
	flash.TintColor = Color3.fromRGB(255, 120, 110); flash.Brightness = -0.08 * forca; flash.Saturation = -0.3 * forca
	TweenService:Create(flash, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ TintColor = Color3.new(1, 1, 1), Brightness = 0, Saturation = 0 }):Play()
end

local function ligar(char)
	local hum = char:WaitForChild("Humanoid", 10)
	if not hum then return end
	local vida = hum.Health
	hum.HealthChanged:Connect(function(nova)
		if nova < vida - 0.5 and nova > 0 then golpe(vida - nova) end
		vida = nova
	end)
end
if jogador.Character then task.spawn(ligar, jogador.Character) end
jogador.CharacterAdded:Connect(ligar)

-- roda depois da camera do Roblox: so soma o tranco por cima do que ela calculou
local t = 0
RunService:BindToRenderStep("Invokyr_Golpe", Enum.RenderPriority.Camera.Value + 1, function(dt)
	if tremor <= 0.001 then tremor = 0 return end
	t += dt
	local cam = workspace.CurrentCamera
	local a = tremor * tremor
	local rx = math.rad(4.5) * a * (math.noise(t * 25, 1) + 0.6)          -- cabeca vai para tras
	local rz = math.rad(3.5) * a * direcao + math.rad(1.5) * a * math.noise(t * 30, 2)
	local ry = math.rad(1.5) * a * math.noise(t * 28, 3)
	cam.CFrame = cam.CFrame * CFrame.Angles(rx, ry, rz)
	tremor = math.max(0, tremor - dt * 2.6)                               -- some em ~0,4 s
end)
]==]
ld.Disabled = false
table.insert(linhas, "LocalScript Invokyr_Dor (tranco na tela) em StarterPlayerScripts")

print("========== INVOKYR 19: BAILARINA - MUSICA, CASTIGO E RISADAS ==========")
for _, l in ipairs(linhas) do print("  " .. l) end
if idRisada == "" then
	warn("  Sem RISADA_ID: ela nao vai rir. Suba o RisadaDaBailarina.ogg, cole o ID e rode de novo.")
end
if CONFIG.DOR_ID == "" then
	warn("  Sem DOR_ID: usando o gemido padrao do Roblox. Suba o DorDoJogador.ogg, cole o ID e rode de novo.")
end
print("Teste: Play Here na previa, espere ela girar e parar; ande com ela parada (-10 de vida).")
