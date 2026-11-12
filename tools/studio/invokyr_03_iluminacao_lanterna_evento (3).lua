--[[
INVOKYR - Script 03 (v6): Iluminacao noturna, lanterna e evento de ativacao da Sala Principal
=========================================================================================
Rode na BARRA DE COMANDOS (com o jogo PARADO), depois do Script 02.
Pode rodar de novo quantas vezes quiser: substitui so o que ele mesmo criou.

Cria:
  - Noite com luar: luz do luar entrando pelas 8 janelas (mais forte do lado da lua),
    feixe frio pelo oculo sobre a mesa, preenchimento fraco para a sala ficar legivel,
    feixes de luz visiveis e poeira suspensa iluminada.
  - Lamparinas, lustre e vela nas posicoes REAIS do Blender (comecam apagados).
  - Poeira que cai do teto durante o tremor.
  - ServerScriptService > Invokyr_SalaPrincipal  (sequencia: tremor, poeira, luzes piscando, acende)
  - StarterPlayerScripts > Invokyr_Cliente       (lanterna 1a pessoa, tremor, botoes de teste)
  - Camera em primeira pessoa.
Nao apaga nada seu: efeitos antigos do Lighting sao desativados ou movidos para
ServerStorage > Invokyr_Backup.
]]

local CONFIG = {
	-- noite (estado inicial)
	HORA = 2.2,                                   -- hora da noite (posicao da lua)
	LATITUDE = 38,
	AMBIENTE = Color3.fromRGB(9, 9, 12),          -- escuridao geral (meios-tons ainda aparecem)
	AMBIENTE_EXTERNO = Color3.fromRGB(14, 15, 19),
	BRILHO_LUA = 0.8,
	COR_LUAR = Color3.fromRGB(172, 182, 204),     -- luar acinzentado e frio, sem azul saturado
	LUAR_JANELA = 1.8,                            -- janelas do lado da lua
	JANELAS_ACESAS = 2,                           -- so as N janelas mais voltadas para a lua recebem luar
	LUAR_JANELA_FRACO = 0.0,                      -- as demais: apagadas (contraste)
	LUAR_OCULO = 0.9,
	PREENCHIMENTO = 0.03,                         -- quase nada: quem ilumina e a lanterna
	SOMBRAS_LUAR = true,
	FEIXES_VISIVEIS = true,
	POEIRA_SUSPENSA = true,
	-- luzes quentes (depois do dado)
	LAMPARINA_BRILHO = 0.75, LAMPARINA_ALCANCE = 13,
	LUSTRE_BRILHO = 0.9, LUSTRE_ALCANCE = 22,
	VELA_BRILHO = 0.6, VELA_ALCANCE = 8,
	COR_LAMPARINA = Color3.fromRGB(255, 182, 122),  -- ambar suave (antes era laranja forte)
	SOMBRAS_LAMPARINAS = true,
	PRIMEIRA_PESSOA = true,
}

if game:GetService("RunService"):IsRunning() then
	error("[Invokyr] O jogo esta em Play. Clique em PARAR e rode este script de novo (em Play nada fica salvo).")
end
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local CollectionService = game:GetService("CollectionService")

local linhas, avisos = {}, {}
local function info(t) table.insert(linhas, t) end
local function aviso(t) table.insert(avisos, t); warn("[Invokyr] " .. t) end

local sala = workspace:FindFirstChild("Invokyr") and workspace.Invokyr:FindFirstChild("SalaPrincipal")
local pontos = sala and sala:FindFirstChild("PontosDeLuz")
local ancora = pontos and pontos:FindFirstChild("AncoraLuzes")
if not ancora then
	error("[Invokyr] Nao encontrei Workspace > Invokyr > SalaPrincipal > PontosDeLuz. Rode o Script 02 antes.")
end
local function backup()
	local bk = ServerStorage:FindFirstChild("Invokyr_Backup") or Instance.new("Folder")
	bk.Name = "Invokyr_Backup"; bk.Parent = ServerStorage
	return bk
end

-- ---------------------------------------------------------------- 0. sobras antigas
for _, s in ipairs(workspace:GetDescendants()) do
	if s:IsA("SpawnLocation") and s:GetAttribute("DesativadoPorInvokyr") then s.Parent = backup() end
end
for _, svc in ipairs({ ServerScriptService, workspace, StarterPlayer, game:GetService("StarterGui"), ReplicatedStorage }) do
	for _, s in ipairs(svc:GetDescendants()) do
		if (s:IsA("Script") or s:IsA("LocalScript")) and not string.find(s.Name, "^Invokyr_") then
			local ok, src = pcall(function() return s.Source end)
			if ok and src and (string.find(src, "Dormant") or string.find(src, "Lighting%.ClockTime")) and s.Enabled then
				s.Enabled = false; s:SetAttribute("DesativadoPorInvokyr", true)
				aviso("Script antigo de iluminacao desativado (nao apagado): " .. s:GetFullName())
			end
		end
	end
end

-- ---------------------------------------------------------------- 1. Lighting (noite)
pcall(function() Lighting.Technology = Enum.Technology.Future end)
Lighting.ClockTime = CONFIG.HORA
Lighting.GeographicLatitude = CONFIG.LATITUDE
Lighting.Brightness = CONFIG.BRILHO_LUA
Lighting.Ambient = CONFIG.AMBIENTE
Lighting.OutdoorAmbient = CONFIG.AMBIENTE_EXTERNO
Lighting.EnvironmentDiffuseScale = 0.04
Lighting.EnvironmentSpecularScale = 0.35
Lighting.ExposureCompensation = 0
Lighting.GlobalShadows = true
pcall(function() Lighting.ShadowSoftness = 0.3 end)

for _, e in ipairs(Lighting:GetChildren()) do
	if not string.find(e.Name, "^Invokyr_") then
		if e:IsA("Atmosphere") then
			e.Parent = backup(); info("Atmosphere antiga movida para ServerStorage > Invokyr_Backup")
		elseif e:IsA("PostEffect") and e.Enabled then
			e.Enabled = false; e:SetAttribute("DesativadoPorInvokyr", true); info("Efeito antigo desativado: " .. e.Name)
		end
	end
end
local function efeito(classe, nome)
	local e = Lighting:FindFirstChild(nome) or Instance.new(classe)
	e.Name = nome; e.Parent = Lighting; return e
end
local atm = efeito("Atmosphere", "Invokyr_Atmosfera")
atm.Density = 0.3; atm.Offset = 0; atm.Color = Color3.fromRGB(70, 72, 80)
atm.Decay = Color3.fromRGB(30, 30, 36); atm.Glare = 0; atm.Haze = 1.6
local cc = efeito("ColorCorrectionEffect", "Invokyr_Cor")
cc.Enabled = true; cc.Brightness = 0; cc.Contrast = 0.1; cc.Saturation = -0.35
cc.TintColor = Color3.fromRGB(236, 238, 246)
local bloom = efeito("BloomEffect", "Invokyr_Bloom")
bloom.Enabled = true; bloom.Intensity = 0.6; bloom.Size = 36; bloom.Threshold = 1.25

-- ---------------------------------------------------------------- 2. luzes nas posicoes reais
for _, c in ipairs(ancora:GetChildren()) do
	if string.find(c.Name, "^Invokyr_") then c:Destroy() end
end
local efeitosPasta = sala:FindFirstChild("Efeitos")
if efeitosPasta then efeitosPasta:Destroy() end
efeitosPasta = Instance.new("Folder"); efeitosPasta.Name = "Efeitos"; efeitosPasta.Parent = sala

local O = ancora.Position
local lua = Lighting:GetMoonDirection()                      -- direcao PARA a lua
local luaPlana = Vector3.new(-lua.X, 0, -lua.Z)
luaPlana = luaPlana.Magnitude > 0.01 and luaPlana.Unit or Vector3.new(0, 0, 1)

local function ponto(nome, posLocal, olharPara)
	local a = Instance.new("Attachment")
	a.Name = "Invokyr_" .. nome
	a.CFrame = olharPara and CFrame.lookAt(posLocal, posLocal + olharPara) or CFrame.new(posLocal)
	a.Parent = ancora
	return a
end
local function luz(classe, pai, props, grupo, aceso)
	local l = Instance.new(classe)
	for k, v in pairs(props) do l[k] = v end
	l:SetAttribute("Grupo", grupo); l:SetAttribute("BrilhoAceso", aceso)
	l.Parent = pai
	return l
end
local function beam(nome, p0, p1, w0, w1, cor, opac)
	local a0 = ponto(nome .. "_A", p0); local a1 = ponto(nome .. "_B", p1)
	local b = Instance.new("Beam")
	b.Name = "Invokyr_Feixe_" .. nome; b.Attachment0 = a0; b.Attachment1 = a1
	b.Width0 = w0; b.Width1 = w1; b.FaceCamera = true; b.Segments = 1
	b.Color = ColorSequence.new(cor); b.LightEmission = 1; b.LightInfluence = 0; b.Brightness = 1
	local t = 1 - opac
	b.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.12, t),
		NumberSequenceKeypoint.new(0.75, t + (1 - t) * 0.4), NumberSequenceKeypoint.new(1, 1) })
	b.Parent = a0
end

local corLuar = CONFIG.COR_LUAR
-- ranking das janelas pela direcao da lua (contraste: so as mais voltadas para a lua ficam fortes)
local rank = {}
for _, a in ipairs(ancora:GetChildren()) do
	local d = a:IsA("Attachment") and a:GetAttribute("Tipo") == "janela" and a:GetAttribute("Direcao")
	if d then table.insert(rank, { a = a, dot = Vector3.new(d.X, 0, d.Z).Unit:Dot(luaPlana) }) end
end
table.sort(rank, function(x, y) return x.dot > y.dot end)
local forca = {}
for i, r in ipairs(rank) do
	forca[r.a] = (i <= CONFIG.JANELAS_ACESAS) and (i == 1 and 1 or 0.7) or CONFIG.LUAR_JANELA_FRACO
end
local corQuente = CONFIG.COR_LAMPARINA
local n = { lamparina = 0, janela = 0, lustre = 0, vela = 0, oculo = 0, preenchimento = 0 }
for _, a in ipairs(ancora:GetChildren()) do
	if a:IsA("Attachment") and not string.find(a.Name, "^Invokyr_") then
		local tipo = a:GetAttribute("Tipo"); local p = a.Position; local dir = a:GetAttribute("Direcao")
		if tipo == "lamparina" then
			local dentro = Vector3.new(p.X, 0, p.Z); dentro = dentro.Magnitude > 0.01 and -dentro.Unit or Vector3.zero
			local pt = ponto(a.Name, p + dentro * 0.9 + Vector3.new(0, 0.2, 0))
			local l = luz("PointLight", pt, { Color = corQuente, Range = CONFIG.LAMPARINA_ALCANCE, Brightness = 0,
				Enabled = false, Shadows = CONFIG.SOMBRAS_LAMPARINAS }, "lamparina", CONFIG.LAMPARINA_BRILHO)
			l:SetAttribute("Ordem", tonumber(string.match(a.Name, "%d+")) or 0)
			n.lamparina += 1
		elseif tipo == "lustre" then
			local pt = ponto(a.Name, p)
			luz("PointLight", pt, { Color = Color3.fromRGB(255, 190, 135), Range = CONFIG.LUSTRE_ALCANCE, Brightness = 0,
				Enabled = false, Shadows = CONFIG.SOMBRAS_LAMPARINAS }, "lustre", CONFIG.LUSTRE_BRILHO)
			n.lustre += 1
		elseif tipo == "vela" then
			local pt = ponto(a.Name, p + Vector3.new(0, 0.35, 0))
			luz("PointLight", pt, { Color = Color3.fromRGB(255, 160, 90), Range = CONFIG.VELA_ALCANCE, Brightness = 0,
				Enabled = false, Shadows = false }, "vela", CONFIG.VELA_BRILHO)
			n.vela += 1
		elseif tipo == "janela" and dir then
			local peso = forca[a] or CONFIG.LUAR_JANELA_FRACO
			local pt = ponto(a.Name, p, dir)
			local b = CONFIG.LUAR_JANELA * peso
			if b > 0 then luz("SpotLight", pt, { Color = corLuar, Range = 50, Angle = 38, Brightness = b, Face = Enum.NormalId.Front,
				Shadows = CONFIG.SOMBRAS_LUAR, Enabled = true }, "luar", b) end
			if CONFIG.FEIXES_VISIVEIS and peso >= 0.7 then
				beam(a.Name, p + dir * 2.5, p + dir * 26, 2.0, 5.5, corLuar, 0.05 * peso)
			end
			n.janela += 1
		elseif tipo == "oculo" then
			local pt = ponto(a.Name, p - Vector3.new(0, 1, 0), Vector3.new(0, -1, 0))
			luz("SpotLight", pt, { Color = corLuar, Range = 45, Angle = 24, Brightness = CONFIG.LUAR_OCULO,
				Face = Enum.NormalId.Front, Shadows = CONFIG.SOMBRAS_LUAR, Enabled = true }, "oculo", CONFIG.LUAR_OCULO)
			if CONFIG.FEIXES_VISIVEIS then
				beam(a.Name, p - Vector3.new(0, 6, 0), Vector3.new(0, 3, 0), 2.5, 4.5, corLuar, 0.04)
			end
			n.oculo += 1
		elseif tipo == "preenchimento" then
			local pt = ponto(a.Name, Vector3.new(0, 14, 0))
			luz("PointLight", pt, { Color = Color3.fromRGB(150, 156, 170), Range = 40, Brightness = CONFIG.PREENCHIMENTO,
				Shadows = false, Enabled = true }, "preenchimento", CONFIG.PREENCHIMENTO)
			n.preenchimento += 1
		end
	end
end
info(("Luzes: %d lamparinas, %d lustre, %d vela, %d janelas de luar, %d oculo, %d preenchimento")
	:format(n.lamparina, n.lustre, n.vela, n.janela, n.oculo, n.preenchimento))
if n.lamparina == 0 or n.janela == 0 then aviso("Faltam pontos de luz. Rode o Script 02 de novo e depois este.") end

-- ---------------------------------------------------------------- 3. particulas
local function caixaEfeito(nome, pos, tam)
	local p = Instance.new("Part")
	p.Name = nome; p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
	p.CastShadow = false; p.Transparency = 1; p.Size = tam; p.CFrame = CFrame.new(O + pos); p.Locked = true
	p.Parent = efeitosPasta
	return p
end
local teto = caixaEfeito("PoeiraDoTeto", Vector3.new(0, 23, 0), Vector3.new(24, 1, 24))
local function emissor(pai, props, attrs)
	local e = Instance.new("ParticleEmitter")
	e.Shape = Enum.ParticleEmitterShape.Box; e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	for k, v in pairs(props) do e[k] = v end
	for k, v in pairs(attrs or {}) do e:SetAttribute(k, v) end
	e.Parent = pai
	return e
end
emissor(teto, {
	Name = "PoeiraFina", Enabled = false, Rate = 45, Texture = "rbxasset://textures/particles/smoke_main.dds",
	Color = ColorSequence.new(Color3.fromRGB(150, 140, 125)), LightInfluence = 1, LightEmission = 0,
	Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 2.2) }),
	Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.15, 0.6),
		NumberSequenceKeypoint.new(1, 1) }),
	Lifetime = NumberRange.new(4, 7), Speed = NumberRange.new(1, 3), Acceleration = Vector3.new(0, -2.5, 0),
	Drag = 0.8, EmissionDirection = Enum.NormalId.Bottom, SpreadAngle = Vector2.new(25, 25),
	Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-20, 20),
}, { Tremor = true, Rajada = 25 })
emissor(teto, {
	Name = "Fragmentos", Enabled = false, Rate = 30, Texture = "rbxasset://textures/particles/sparkles_main.dds",
	Color = ColorSequence.new(Color3.fromRGB(95, 88, 78)), LightInfluence = 1, LightEmission = 0,
	Size = NumberSequence.new(0.08), Transparency = NumberSequence.new(0.1),
	Lifetime = NumberRange.new(2, 3), Speed = NumberRange.new(2, 5), Acceleration = Vector3.new(0, -35, 0),
	EmissionDirection = Enum.NormalId.Bottom, SpreadAngle = Vector2.new(10, 10),
}, { Tremor = true, Rajada = 15 })
if CONFIG.POEIRA_SUSPENSA then
	local ar = caixaEfeito("PoeiraSuspensa", Vector3.new(0, 9, 0), Vector3.new(24, 16, 24))
	emissor(ar, {
		Name = "Particulas", Enabled = true, Rate = 8, Texture = "rbxasset://textures/particles/sparkles_main.dds",
		Color = ColorSequence.new(Color3.fromRGB(215, 215, 210)), LightInfluence = 1, LightEmission = 0.1,
		Size = NumberSequence.new(0.07), Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.3, 0.3), NumberSequenceKeypoint.new(0.7, 0.3), NumberSequenceKeypoint.new(1, 1) }),
		Lifetime = NumberRange.new(8, 14), Speed = NumberRange.new(0.05, 0.25), Drag = 1,
		Acceleration = Vector3.new(0, -0.05, 0), SpreadAngle = Vector2.new(180, 180),
	})
end

-- ---------------------------------------------------------------- 4. chamas comecam apagadas
local nChamas = 0
for _, p in ipairs(CollectionService:GetTagged("Invokyr_Chama")) do
	if p:IsDescendantOf(sala) then p.Transparency = 1; nChamas += 1 end
end
if nChamas == 0 then aviso("Nenhuma chama marcada (Invokyr_Chama). Rode o Script 02 de novo.") end

-- ---------------------------------------------------------------- 5. remotes
local pasta = ReplicatedStorage:FindFirstChild("Invokyr") or Instance.new("Folder")
pasta.Name = "Invokyr"; pasta.Parent = ReplicatedStorage
local function remote(classe, nome)
	local r = pasta:FindFirstChild(nome)
	if r and r.ClassName ~= classe then r:Destroy(); r = nil end
	if not r then r = Instance.new(classe); r.Name = nome; r.Parent = pasta end
	return r
end
remote("RemoteEvent", "EfeitosSala")
remote("RemoteEvent", "TesteSala")
remote("BindableEvent", "AtivarSala")
if not pcall(function() remote("UnreliableRemoteEvent", "LanternaMira") end) then remote("RemoteEvent", "LanternaMira") end

-- ---------------------------------------------------------------- 6. scripts
local FONTE_SERVIDOR = [==[--[[ Invokyr_SalaPrincipal (Script, ServerScriptService) - gerado pelo Script 03
Controla o estado da Sala Principal: Dormente (luar) -> Ativando (tremor, poeira, luzes piscando) -> Ativa.
Para o sistema de dados (futuro): ReplicatedStorage.Invokyr.AtivarSala:Fire() no servidor.
]]
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local CFG = {
	TREMOR_DURACAO = 4.5,
	TREMOR_FORCA = 0.35,
	POEIRA_DURACAO = 3.0,
	PISCAR_LUSTRE = 2.2,          -- segundos piscando antes de firmar
	INTERVALO_LAMPARINAS = 0.35,  -- atraso entre uma lamparina e a proxima
	ESTABILIZAR = 1.6,            -- tempo para a luz firmar
	-- iluminacao geral depois de acesa (quente e suave, ainda sombria)
	ATIVA_AMBIENT = Color3.fromRGB(15, 13, 12),   -- quase escuro: as lamparinas fazem pocas de luz
	ATIVA_EXPOSICAO = 0,
	ATIVA_TINT = Color3.fromRGB(250, 243, 234),   -- calor bem leve, sem amarelar tudo
	ATIVA_SATURACAO = -0.32,
	LUAR_FATOR_ATIVA = 0.75,      -- luar continua presente
	-- piscadas ocasionais depois de acesa (terror)
	PISCADAS_ALEATORIAS = true,
	PISCADA_INTERVALO_MIN = 8,
	PISCADA_INTERVALO_MAX = 20,
}

local sala = workspace:WaitForChild("Invokyr"):WaitForChild("SalaPrincipal")
local pontos = sala:WaitForChild("PontosDeLuz")
local efeitosPasta = sala:WaitForChild("Efeitos")
local remotes = ReplicatedStorage:WaitForChild("Invokyr")
local efeitos = remotes:WaitForChild("EfeitosSala")
local teste = remotes:WaitForChild("TesteSala")
local ativarBE = remotes:WaitForChild("AtivarSala")
local miraRE = remotes:WaitForChild("LanternaMira")

-- ------------------------------------------------------------ coleta
local lamparinas, lustre, vela, luar = {}, {}, {}, {}
for _, l in ipairs(pontos:GetDescendants()) do
	if l:IsA("Light") then
		local g = l:GetAttribute("Grupo")
		if g == "lamparina" then table.insert(lamparinas, l)
		elseif g == "lustre" then table.insert(lustre, l)
		elseif g == "vela" then table.insert(vela, l)
		elseif g == "luar" or g == "oculo" then table.insert(luar, l) end
	end
end
table.sort(lamparinas, function(a, b) return (a:GetAttribute("Ordem") or 0) < (b:GetAttribute("Ordem") or 0) end)

local function chamas(filtro)
	local t = {}
	for _, p in ipairs(CollectionService:GetTagged("Invokyr_Chama")) do
		if p:IsDescendantOf(sala) and filtro(p.Name) then table.insert(t, p) end
	end
	return t
end
local chamasLustre = chamas(function(n) return string.find(n, "Lantern") ~= nil end)
local chamasVela = chamas(function(n) return string.find(n, "Mesa") ~= nil end)

local cc = Lighting:FindFirstChild("Invokyr_Cor")
local poeira = {}
for _, e in ipairs(efeitosPasta:GetDescendants()) do
	if e:IsA("ParticleEmitter") and e:GetAttribute("Tremor") then table.insert(poeira, e) end
end

-- valores do estado dormente (como o instalador deixou)
local dormente = {
	Ambient = Lighting.Ambient,
	Exposicao = Lighting.ExposureCompensation,
	Tint = cc and cc.TintColor,
	Saturacao = cc and cc.Saturation,
	luar = {},
}
for _, l in ipairs(luar) do dormente.luar[l] = l.Brightness end

-- ------------------------------------------------------------ utilidades
local estado = "Dormente"
local ocupado = false
local function setEstado(e) estado = e; sala:SetAttribute("Estado", e) end

local function setLuz(l, f)
	local alvo = l:GetAttribute("BrilhoAceso") or 1
	l.Brightness = alvo * f
	l.Enabled = f > 0.01
end
local function setChamas(lista, visivel)
	for _, p in ipairs(lista) do p.Transparency = visivel and 0 or 1 end
end
local function piscar(luzes, dur, listaChamas)
	local t0 = os.clock()
	while os.clock() - t0 < dur do
		local on = math.random() < 0.55
		local f = on and (0.35 + math.random() * 0.8) or (math.random() * 0.06)
		for _, l in ipairs(luzes) do setLuz(l, f) end
		if listaChamas then setChamas(listaChamas, on) end
		task.wait(0.04 + math.random() * 0.16)
	end
end
local function firmar(luzes, dur)
	for _, l in ipairs(luzes) do
		l.Enabled = true
		TweenService:Create(l, TweenInfo.new(dur, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
			{ Brightness = l:GetAttribute("BrilhoAceso") or 1 }):Play()
	end
end
local function tweenAmbiente(ativa, dur)
	local info = TweenInfo.new(dur, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	TweenService:Create(Lighting, info, {
		Ambient = ativa and CFG.ATIVA_AMBIENT or dormente.Ambient,
		ExposureCompensation = ativa and CFG.ATIVA_EXPOSICAO or dormente.Exposicao,
	}):Play()
	if cc then
		TweenService:Create(cc, info, {
			TintColor = ativa and CFG.ATIVA_TINT or dormente.Tint,
			Saturation = ativa and CFG.ATIVA_SATURACAO or dormente.Saturacao,
		}):Play()
	end
	for l, b in pairs(dormente.luar) do
		TweenService:Create(l, info, { Brightness = ativa and b * CFG.LUAR_FATOR_ATIVA or b }):Play()
	end
end
local function soltarPoeira(dur)
	for _, e in ipairs(poeira) do
		e.Enabled = true
		e:Emit(e:GetAttribute("Rajada") or 20)
	end
	task.delay(dur, function() for _, e in ipairs(poeira) do e.Enabled = false end end)
end

-- ------------------------------------------------------------ estados
local function aplicarDormente()
	for _, grupo in ipairs({ lamparinas, lustre, vela }) do
		for _, l in ipairs(grupo) do l.Brightness = 0; l.Enabled = false end
	end
	setChamas(chamasLustre, false); setChamas(chamasVela, false)
	for _, e in ipairs(poeira) do e.Enabled = false end
	tweenAmbiente(false, 0.01)
	setEstado("Dormente")
end

local function ativar()
	if ocupado or estado == "Ativa" then return end
	ocupado = true
	setEstado("Ativando")
	efeitos:FireAllClients("tremor", CFG.TREMOR_DURACAO, CFG.TREMOR_FORCA)
	soltarPoeira(CFG.POEIRA_DURACAO)
	task.wait(0.7)
	-- 1) o lustre luta para acender
	piscar(lustre, CFG.PISCAR_LUSTRE, chamasLustre)
	setChamas(chamasLustre, true)
	firmar(lustre, CFG.ESTABILIZAR)
	-- 2) as lamparinas acendem em sequencia ao redor da sala
	for i, l in ipairs(lamparinas) do
		task.delay((i - 1) * CFG.INTERVALO_LAMPARINAS, function()
			piscar({ l }, 0.6 + math.random() * 0.8)
			firmar({ l }, CFG.ESTABILIZAR)
		end)
	end
	task.wait(#lamparinas * CFG.INTERVALO_LAMPARINAS + 1.0)
	-- 3) vela da mesa e clima quente
	setChamas(chamasVela, true)
	firmar(vela, 1.0)
	tweenAmbiente(true, 2.5)
	task.wait(2.5)
	setEstado("Ativa")
	efeitos:FireAllClients("ativa")
	ocupado = false
end

local function resetar()
	if ocupado then return end
	aplicarDormente()
	efeitos:FireAllClients("dormente")
end

-- piscadas ocasionais quando a sala esta acesa
task.spawn(function()
	while true do
		task.wait(CFG.PISCADA_INTERVALO_MIN + math.random() * (CFG.PISCADA_INTERVALO_MAX - CFG.PISCADA_INTERVALO_MIN))
		if CFG.PISCADAS_ALEATORIAS and estado == "Ativa" and not ocupado and #lamparinas > 0 then
			local l = lamparinas[math.random(1, #lamparinas)]
			piscar({ l }, 0.25 + math.random() * 0.5)
			if estado == "Ativa" then setLuz(l, 1) end
		end
	end
end)

-- ------------------------------------------------------------ conexoes
ativarBE.Event:Connect(function() task.spawn(ativar) end)

teste.OnServerEvent:Connect(function(_, acao)
	if not RunService:IsStudio() then return end   -- botoes de teste so funcionam no Studio
	if acao == "ativar" then task.spawn(ativar)
	elseif acao == "resetar" then resetar() end
end)

-- direcao da lanterna de cada jogador (para os outros enxergarem)
local ultimo = {}
miraRE.OnServerEvent:Connect(function(player, dir, ligada)
	if typeof(dir) ~= "Vector3" or dir.Magnitude < 0.5 or dir.Magnitude > 1.5 then return end
	local agora = os.clock()
	if ultimo[player] and agora - ultimo[player] < 0.05 then return end
	ultimo[player] = agora
	local char = player.Character
	if char then
		char:SetAttribute("LanternaMira", dir.Unit)
		char:SetAttribute("LanternaLigada", ligada == true)
	end
end)
game:GetService("Players").PlayerRemoving:Connect(function(p) ultimo[p] = nil end)

aplicarDormente()
print("[Invokyr] Sala Principal pronta (Dormente). Lamparinas:", #lamparinas, "Lustre:", #lustre, "Luar:", #luar)
]==]
local FONTE_CLIENTE = [==[--[[ Invokyr_Cliente (LocalScript, StarterPlayerScripts) - gerado pelo Script 03
Lanterna em primeira pessoa (F no PC, botao na tela no celular, R1 no controle),
lanterna dos outros jogadores, tremor de camera e botoes de teste (so no Studio).
]]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CFG = {
	-- feixe em 3 camadas: ponto quente, feixe principal e espalhamento
	QUENTE_BRILHO = 1.6, QUENTE_ANGULO = 20, QUENTE_ALCANCE = 60,
	BRILHO = 1.3, ALCANCE = 50, ANGULO = 46,
	BORDA_BRILHO = 0.22, BORDA_ALCANCE = 24, BORDA_ANGULO = 95,
	-- luz rebatida (o Roblox nao calcula): luz fraca no ponto onde o feixe bate
	REBATIDA_BRILHO = 0.45, REBATIDA_MIN = 7, REBATIDA_MAX = 20,
	REBATIDA_COR = Color3.fromRGB(255, 226, 190),
	ORIGEM_LUZ = Vector3.new(0.35, -0.4, -0.9),       -- de onde a luz sai (perto dos olhos, sem paralaxe)
	COR = Color3.fromRGB(255, 214, 165),              -- lampada incandescente quente
	TAMANHO_MAO = 0.72,                               -- escala da lanterna na tela
	POSICAO_MAO = Vector3.new(0.5, -0.55, -1.2),      -- onde a lanterna fica na tela (direita, baixo, frente)
	INCLINACAO = Vector3.new(4, 7, 0),                -- graus: aponta levemente para o centro
	SUAVIDADE = 10,                                   -- quanto menor, mais "pesada" a lanterna
	BALANCO = 1.0,                                    -- balanco ao andar (0 = desliga)
	SOMBRAS = true,
	OUTROS_BRILHO = 2.4,
	COMECA_LIGADA = true,
}

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local remotes = ReplicatedStorage:WaitForChild("Invokyr")
local efeitos = remotes:WaitForChild("EfeitosSala")
local teste = remotes:WaitForChild("TesteSala")
local miraRE = remotes:WaitForChild("LanternaMira")

-- ------------------------------------------------------------ lanterna na mao (modelo visivel)
-- pecas simples por enquanto; depois pode ser trocada por um modelo do Blender
local modelo = Instance.new("Model"); modelo.Name = "Invokyr_LanternaMao"
local pecas = {}
local function peca(nome, forma, tam, z, cor, mat)
	local k = CFG.TAMANHO_MAO
	tam = tam * k; z = z * k
	local p = Instance.new("Part")
	p.Name = nome; p.Shape = forma; p.Size = tam; p.Color = cor; p.Material = mat
	p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = modelo
	-- cilindros do Roblox ficam deitados no eixo X: giramos para apontar para frente (-Z)
	local rot = forma == Enum.PartType.Cylinder and CFrame.Angles(0, math.rad(90), 0) or CFrame.new()
	table.insert(pecas, { p = p, cf = CFrame.new(0, 0, z) * rot })
	return p
end
local CIL = Enum.PartType.Cylinder
local metal, borracha = Color3.fromRGB(58, 58, 62), Color3.fromRGB(24, 24, 26)
peca("Corpo", CIL, Vector3.new(1.0, 0.2, 0.2), 0, metal, Enum.Material.Metal)
for i = 0, 3 do
	peca("Anel" .. i, CIL, Vector3.new(0.045, 0.215, 0.215), 0.25 - i * 0.11, borracha, Enum.Material.Rubber)
end
peca("Pescoco", CIL, Vector3.new(0.14, 0.26, 0.26), -0.55, metal, Enum.Material.Metal)
peca("Cabeca", CIL, Vector3.new(0.26, 0.33, 0.33), -0.74, metal, Enum.Material.Metal)
peca("Aro", CIL, Vector3.new(0.05, 0.35, 0.35), -0.89, Color3.fromRGB(110, 108, 104), Enum.Material.Metal)
local lente = peca("Lente", CIL, Vector3.new(0.02, 0.29, 0.29), -0.915, CFG.COR, Enum.Material.Neon)
local botaoL = peca("Botao", Enum.PartType.Block, Vector3.new(0.07, 0.05, 0.12), -0.2, borracha, Enum.Material.Rubber)
table.remove(pecas); table.insert(pecas, { p = botaoL, cf = CFrame.new(0, 0.115 * CFG.TAMANHO_MAO, -0.2 * CFG.TAMANHO_MAO) })
modelo.Parent = camera

local suporte = Instance.new("Attachment")   -- ponto de onde sai a luz (frente da lente)
suporte.Name = "Invokyr_LanternaLuz"
local ancoraLuz = Instance.new("Part")
ancoraLuz.Name = "Invokyr_LanternaLocal"; ancoraLuz.Anchored = true; ancoraLuz.CanCollide = false
ancoraLuz.CanQuery = false; ancoraLuz.CanTouch = false; ancoraLuz.CastShadow = false
ancoraLuz.Transparency = 1; ancoraLuz.Size = Vector3.new(0.1, 0.1, 0.1); ancoraLuz.Parent = workspace
suporte.Parent = ancoraLuz

local function spot(brilho, alcance, angulo, sombras)
	local s = Instance.new("SpotLight")
	s.Face = Enum.NormalId.Front; s.Brightness = brilho; s.Range = alcance
	s.Angle = angulo; s.Color = CFG.COR; s.Shadows = sombras; s.Parent = ancoraLuz
	return s
end
local quente = spot(CFG.QUENTE_BRILHO, CFG.QUENTE_ALCANCE, CFG.QUENTE_ANGULO, CFG.SOMBRAS)
local feixe = spot(CFG.BRILHO, CFG.ALCANCE, CFG.ANGULO, CFG.SOMBRAS)
local borda = spot(CFG.BORDA_BRILHO, CFG.BORDA_ALCANCE, CFG.BORDA_ANGULO, false)

-- luz rebatida: acompanha o ponto onde o feixe bate
local rebatePart = Instance.new("Part")
rebatePart.Name = "Invokyr_LanternaRebatida"; rebatePart.Anchored = true; rebatePart.CanCollide = false
rebatePart.CanQuery = false; rebatePart.CanTouch = false; rebatePart.CastShadow = false
rebatePart.Transparency = 1; rebatePart.Size = Vector3.new(0.1, 0.1, 0.1); rebatePart.Parent = workspace
local rebatida = Instance.new("PointLight")
rebatida.Color = CFG.REBATIDA_COR; rebatida.Brightness = CFG.REBATIDA_BRILHO; rebatida.Shadows = false
rebatida.Range = CFG.REBATIDA_MIN; rebatida.Parent = rebatePart
local rebatePos = nil

-- brilho proprio na cabeca da lanterna (para o objeto na mao nao virar um bloco preto)
local brilhoLente = Instance.new("PointLight")
brilhoLente.Color = CFG.COR; brilhoLente.Brightness = 0.7; brilhoLente.Range = 1.4; brilhoLente.Shadows = false
brilhoLente.Parent = lente

local ligada = CFG.COMECA_LIGADA
local function aplicar()
	quente.Enabled = ligada; feixe.Enabled = ligada; borda.Enabled = ligada
	rebatida.Enabled = ligada; brilhoLente.Enabled = ligada
	lente.Material = ligada and Enum.Material.Neon or Enum.Material.Glass
	lente.Color = ligada and CFG.COR or Color3.fromRGB(40, 40, 42)
end
aplicar()

local tremorFim, tremorDur, tremorForca = 0, 1, 0
local rotAtual = camera.CFrame.Rotation
local passo = 0
local distAtual = 20
local mira = RaycastParams.new()
mira.FilterType = Enum.RaycastFilterType.Exclude
local function atualizarFiltro()
	mira.FilterDescendantsInstances = { modelo, ancoraLuz, player.Character }
end
atualizarFiltro()
player.CharacterAdded:Connect(function() task.wait(); atualizarFiltro() end)
local inclinacao = CFrame.Angles(math.rad(CFG.INCLINACAO.X), math.rad(CFG.INCLINACAO.Y), math.rad(CFG.INCLINACAO.Z))

RunService:BindToRenderStep("InvokyrCamera", Enum.RenderPriority.Camera.Value + 1, function(dt)
	camera = workspace.CurrentCamera
	-- tremor (rotacao leve + deslocamento), com subida e descida suaves
	local agora = os.clock()
	if agora < tremorFim then
		local t = 1 - (tremorFim - agora) / tremorDur
		local env = math.sin(math.pi * math.clamp(t, 0, 1)) * tremorForca
		local n = agora * 22
		local off = Vector3.new(math.noise(n, 0, 1), math.noise(0, n, 2) * 0.7, math.noise(3, 0, n)) * env * 0.6
		local rot = CFrame.Angles(math.noise(n, 5, 0) * env * 0.05, math.noise(n, 9, 0) * env * 0.05, math.noise(n, 13, 0) * env * 0.08)
		camera.CFrame = camera.CFrame * CFrame.new(off) * rot
	end
	-- lanterna: segue a camera com leve atraso (peso) e balanca ao andar
	local a = 1 - math.exp(-CFG.SUAVIDADE * dt)
	rotAtual = rotAtual:Lerp(camera.CFrame.Rotation, a)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local andando = (hum and hum.MoveDirection.Magnitude > 0.1 and hum.FloorMaterial ~= Enum.Material.Air) and 1 or 0
	passo += dt * (andando == 1 and 9 or 1.2)
	local amp = CFG.BALANCO * (andando == 1 and 1 or 0.25)
	local balanco = Vector3.new(math.cos(passo * 0.5) * 0.035, math.abs(math.sin(passo * 0.5)) * -0.045, 0) * amp
	-- atraso da rotacao vira deslocamento lateral (sensacao de peso)
	local atraso = camera.CFrame.Rotation:ToObjectSpace(rotAtual)
	local ax, ay = atraso:ToEulerAnglesYXZ()
	local base = CFrame.new(camera.CFrame.Position) * camera.CFrame.Rotation
		* CFrame.new(CFG.POSICAO_MAO + balanco + Vector3.new(ay * 0.6, -ax * 0.6, 0)) * atraso * inclinacao
	for _, item in ipairs(pecas) do item.p.CFrame = base * item.cf end
	modelo.Parent = camera
	-- a luz mira o ponto exato no centro da tela (perto ou longe), com o mesmo "peso" da lanterna
	local pos = camera.CFrame.Position
	local olhar = rotAtual.LookVector
	local hit = workspace:Raycast(pos, olhar * 60, mira)
	local dist = hit and math.max((hit.Position - pos).Magnitude, 1.5) or 60
	distAtual += (dist - distAtual) * (1 - math.exp(-20 * dt))
	local origem = (CFrame.new(pos) * rotAtual * CFrame.new(CFG.ORIGEM_LUZ)).Position
	ancoraLuz.CFrame = CFrame.lookAt(origem, pos + olhar * distAtual)
	-- luz rebatida: fica um pouco afastada da superficie atingida, voltada para o jogador
	if hit then
		local alvoReb = hit.Position + hit.Normal * 1.2 - olhar * 0.8
		rebatePos = rebatePos and rebatePos:Lerp(alvoReb, 1 - math.exp(-14 * dt)) or alvoReb
		rebatePart.CFrame = CFrame.new(rebatePos)
		-- perto: rebatida forte e curta; longe: mais fraca e larga (como na vida real)
		local d = distAtual
		rebatida.Range = math.clamp(CFG.REBATIDA_MIN + d * 0.35, CFG.REBATIDA_MIN, CFG.REBATIDA_MAX)
		rebatida.Brightness = CFG.REBATIDA_BRILHO * math.clamp(14 / (d + 6), 0.35, 1.3)
		rebatida.Enabled = ligada
	else
		rebatida.Enabled = false
	end
end)

local function alternar(_, estado)
	if estado == Enum.UserInputState.Begin then
		ligada = not ligada; aplicar()
		miraRE:FireServer(camera.CFrame.LookVector, ligada)
	end
	return Enum.ContextActionResult.Pass
end
ContextActionService:BindAction("InvokyrLanterna", alternar, true, Enum.KeyCode.F, Enum.KeyCode.ButtonR1)
ContextActionService:SetTitle("InvokyrLanterna", "Luz")

-- envia a direcao da lanterna ~10x por segundo (para os outros jogadores)
task.spawn(function()
	while true do
		task.wait(0.1)
		miraRE:FireServer(camera.CFrame.LookVector, ligada)
	end
end)

-- ------------------------------------------------------------ lanterna dos outros
local outros = {}
RunService.RenderStepped:Connect(function(dt)
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player then
			local char = p.Character
			local head = char and char:FindFirstChild("Head")
			local reg = outros[p]
			if head and (not reg or reg.att.Parent ~= head) then
				if reg then reg.att:Destroy() end
				local att = Instance.new("Attachment"); att.Name = "Invokyr_LanternaOutro"
				local s = Instance.new("SpotLight"); s.Face = Enum.NormalId.Front; s.Brightness = CFG.OUTROS_BRILHO
				s.Range = CFG.ALCANCE * 0.8; s.Angle = CFG.ANGULO; s.Color = CFG.COR; s.Shadows = CFG.SOMBRAS; s.Parent = att
				att.Parent = head
				reg = { att = att, luz = s, dir = head.CFrame.LookVector }
				outros[p] = reg
			end
			if head and reg then
				local d = char:GetAttribute("LanternaMira")
				if typeof(d) == "Vector3" then reg.dir = reg.dir:Lerp(d, 1 - math.exp(-10 * dt)) end
				reg.luz.Enabled = char:GetAttribute("LanternaLigada") ~= false
				local origem = head.Position + Vector3.new(0, -0.3, 0) + reg.dir * 0.8
				reg.att.CFrame = head.CFrame:ToObjectSpace(CFrame.lookAt(origem, origem + reg.dir))
			end
		end
	end
end)
Players.PlayerRemoving:Connect(function(p)
	if outros[p] then outros[p].att:Destroy(); outros[p] = nil end
end)

-- ------------------------------------------------------------ efeitos da sala
efeitos.OnClientEvent:Connect(function(tipo, dur, forca)
	if tipo == "tremor" then
		tremorDur = dur or 4; tremorForca = forca or 0.3
		tremorFim = os.clock() + tremorDur
	end
end)

-- ------------------------------------------------------------ botoes de teste (so no Studio)
if RunService:IsStudio() then
	local gui = Instance.new("ScreenGui")
	gui.Name = "Invokyr_Teste"; gui.ResetOnSpawn = false
	local quadro = Instance.new("Frame")
	quadro.AnchorPoint = Vector2.new(0.5, 0); quadro.Position = UDim2.new(0.5, 0, 0, 8)
	quadro.Size = UDim2.new(0, 460, 0, 40); quadro.BackgroundTransparency = 1; quadro.Parent = gui
	local lista = Instance.new("UIListLayout")
	lista.FillDirection = Enum.FillDirection.Horizontal; lista.Padding = UDim.new(0, 8)
	lista.HorizontalAlignment = Enum.HorizontalAlignment.Center; lista.Parent = quadro
	local function botao(texto, acao)
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(0, 220, 1, 0); b.Text = texto; b.TextScaled = true
		b.Font = Enum.Font.GothamBold; b.TextColor3 = Color3.fromRGB(240, 230, 210)
		b.BackgroundColor3 = Color3.fromRGB(20, 16, 14); b.BackgroundTransparency = 0.45
		local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = b
		local pad = Instance.new("UIPadding"); pad.PaddingLeft = UDim.new(0, 8); pad.PaddingRight = UDim.new(0, 8)
		pad.PaddingTop = UDim.new(0, 6); pad.PaddingBottom = UDim.new(0, 6); pad.Parent = b
		b.Activated:Connect(function() teste:FireServer(acao) end)
		b.Parent = quadro
	end
	botao("[G] TESTE: jogar dado", "ativar")
	botao("[R] Resetar sala", "resetar")
	gui.Parent = player:WaitForChild("PlayerGui")
	-- em primeira pessoa o mouse fica preso: use as teclas G e R
	ContextActionService:BindAction("InvokyrTesteDado", function(_, st)
		if st == Enum.UserInputState.Begin then teste:FireServer("ativar") end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.G)
	ContextActionService:BindAction("InvokyrTesteReset", function(_, st)
		if st == Enum.UserInputState.Begin then teste:FireServer("resetar") end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.R)
end
]==]
local function instalar(classe, pai, nome, fonte)
	local s = pai:FindFirstChild(nome)
	if s then s:Destroy() end
	s = Instance.new(classe); s.Name = nome; s.Source = fonte; s.Parent = pai
end
instalar("Script", ServerScriptService, "Invokyr_SalaPrincipal", FONTE_SERVIDOR)
instalar("LocalScript", StarterPlayer:WaitForChild("StarterPlayerScripts"), "Invokyr_Cliente", FONTE_CLIENTE)

if CONFIG.PRIMEIRA_PESSOA then
	StarterPlayer.CameraMode = Enum.CameraMode.LockFirstPerson
	info("Camera: primeira pessoa travada")
end

print("========== INVOKYR: SCRIPT 03 ==========")
for _, l in ipairs(linhas) do print("  " .. l) end
if #avisos == 0 then print("  Sem avisos.") else for _, a in ipairs(avisos) do warn("  AVISO: " .. a) end end
print("Agora: Play. F = lanterna | G = testar dado | R = resetar sala (teclas de teste so no Studio).")
