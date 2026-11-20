--[[
INVOKYR - Script 19: musica e castigo da BAILARINA (so script, nao importa modelo)
==================================================================================
  - Enquanto a bailarina gira, toca uma caixinha de musica macabra (CaixinhaDaBailarina.ogg).
    Quando ela freia, a musica perde a corda e morre; parada, silencio total.
  - Com ela PARADA, quem se mexer leva 10 de dano. Ha um instante (0,45 s) para o jogador parar
    depois que a musica corta; quem continuar andando leva dano de novo a cada 0,9 s.
  - Nao mexe no giro do Codex (BailarinaGiro): so escuta o estado dela.
  - Vale para a sala guardada (Invokyr_Salas > SalaoDaBailarina) e para a Previa_SalaoDaBailarina.

ANTES: suba a musica no Roblox e cole o ID abaixo (passo a passo no TXT). Sem ID o castigo ja
funciona, so fica sem musica. Pode rodar de novo quando quiser (mudar ID, dano, volume...).
Rode com o jogo PARADO.
]]
local CONFIG = {
	MUSICA_ID = "",         -- ex.: "rbxassetid://1234567890" (ou so o numero)
	VOLUME = 0.8,
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

local id = tostring(CONFIG.MUSICA_ID or "")
if id ~= "" and not string.find(id, "^rbxassetid://") then id = "rbxassetid://" .. string.match(id, "%d+") end

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
					jogador:SetAttribute("BailarinaViu", agora)   -- para um efeito na tela, se um dia quiser
				end
			end
		else
			ultimo[jogador] = nil
		end
	end
end)
Players.PlayerRemoving:Connect(function(j) ultimo[j] = nil; ultimoDano[j] = nil end)
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
		local sc = sala:FindFirstChild("BailarinaRegras")
		if sc and not sc:IsA("Script") then error("[Invokyr] Ja existe um BailarinaRegras que nao e Script em " .. sala:GetFullName()) end
		if not sc then sc = Instance.new("Script"); sc.Name = "BailarinaRegras"; sc.Parent = sala end
		sc.Source = FONTE
		sc:SetAttribute("Dano", CONFIG.DANO); sc:SetAttribute("Carencia", CONFIG.CARENCIA)
		sc:SetAttribute("EsperaEntreDanos", CONFIG.ESPERA_ENTRE_DANOS); sc:SetAttribute("Limiar", CONFIG.LIMIAR)
		sc:SetAttribute("Volume", CONFIG.VOLUME)
		sc.Disabled = false
		table.insert(linhas, sala:GetFullName() .. ": musica " .. (id ~= "" and id or "(SEM ID ainda)") .. ", dano " .. CONFIG.DANO)
	end
end

print("========== INVOKYR 19: BAILARINA - MUSICA E CASTIGO ==========")
for _, l in ipairs(linhas) do print("  " .. l) end
if id == "" then
	warn("  Falta o ID da musica: suba o CaixinhaDaBailarina.ogg (Asset Manager > Import), copie o ID,")
	warn("  cole em MUSICA_ID no comeco deste script e rode de novo. O castigo ja funciona sem ela.")
end
print("Teste: Play Here na previa, espere ela girar e parar; ande com ela parada (-10 de vida).")
