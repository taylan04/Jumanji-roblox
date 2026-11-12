--[[
INVOKYR - Script 05: Preparar a lanterna com mao (VM_LanternaMao.glb) no Roblox
================================================================================
1) Importe VM_LanternaMao.glb (Importar 3D). 2) Com o jogo PARADO, rode este script na barra de comandos.
3) Rode de novo o Script 03 (v7). O cliente passa a usar este modelo automaticamente.
Pode rodar de novo quantas vezes quiser. O modelo antigo vai para ServerStorage > Invokyr_Backup.
]]
if game:GetService("RunService"):IsRunning() then
	error("[Invokyr] O jogo esta em Play. Clique em PARAR e rode de novo.")
end
-- medidas exportadas pelo Blender (eixos do Roblox, lente na origem, em studs)
local ESPERADO_MIN = Vector3.new(-0.1597, -0.8023, 0.0)
local ESPERADO_MAX = Vector3.new(0.8007, 0.1872, 2.4054)

local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")

local function temCorpo(m)
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("MeshPart") and string.find(d.Name, "VM_Corpo") then return true end
	end
	return false
end
local modelo
for _, m in ipairs(workspace:GetChildren()) do
	if m:IsA("Model") and temCorpo(m) then modelo = m end
end
if not modelo then
	-- ja preparado antes: reprocessa o que esta no ReplicatedStorage (nao precisa importar de novo)
	local ja = RS:FindFirstChild("Invokyr") and RS.Invokyr:FindFirstChild("LanternaMao")
	if ja and temCorpo(ja) then modelo = ja; modelo.Parent = workspace end
end
if not modelo then error("[Invokyr] Nao encontrei o modelo importado (VM_LanternaMao). Importe o GLB e rode de novo.") end

local function caixa(m)
	local mn = Vector3.new(math.huge, math.huge, math.huge); local mx = -mn
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") and d.Name ~= "Raiz" then
			local cf, s = d.CFrame, d.Size / 2
			for _, x in ipairs({ -1, 1 }) do for _, y in ipairs({ -1, 1 }) do for _, z in ipairs({ -1, 1 }) do
				local w = cf:PointToWorldSpace(Vector3.new(s.X * x, s.Y * y, s.Z * z))
				mn = mn:Min(w); mx = mx:Max(w)
			end end end
		end
	end
	return mn, mx
end

-- ---------------------------------------------------------------- orientacao automatica
-- o importador pode girar o modelo; a lente deve ficar na FRENTE (-Z), em CIMA e a ESQUERDA do centro
local lenteParte
for _, d in ipairs(modelo:GetDescendants()) do
	if d:IsA("MeshPart") and string.find(d.Name, "VM_Lente") then lenteParte = d end
end
if not lenteParte then error("[Invokyr] Nao encontrei a lente (VM_Lente) no modelo importado.") end
local centroEsp = (ESPERADO_MIN + ESPERADO_MAX) / 2
local relEsp = (Vector3.zero - centroEsp).Unit
local mn, mx = caixa(modelo)
local c = (mn + mx) / 2
local rel = (lenteParte.Position - c)
local melhor, melhorErro = CFrame.new(), math.huge
for ix = 0, 3 do for iy = 0, 3 do for iz = 0, 3 do
	local R = CFrame.Angles(ix * math.pi / 2, iy * math.pi / 2, iz * math.pi / 2)
	local erro = ((R * rel).Unit - relEsp).Magnitude
	if erro < melhorErro - 1e-4 then melhor, melhorErro = R, erro end
end end end
local giro = "nenhum"
if melhor ~= CFrame.new() then
	local rx, ry, rz = melhor:ToEulerAnglesXYZ()
	giro = ("%.0f, %.0f, %.0f graus"):format(math.deg(rx), math.deg(ry), math.deg(rz))
	modelo:PivotTo(CFrame.new(c) * melhor * CFrame.new(c):Inverse() * modelo:GetPivot())
	mn, mx = caixa(modelo)
end

local esp = ESPERADO_MAX - ESPERADO_MIN
local atual = mx - mn
local fator = (atual.X / esp.X + atual.Y / esp.Y + atual.Z / esp.Z) / 3
if math.abs(fator - 1) > 0.01 then
	modelo:ScaleTo(modelo:GetScale() / fator)
	mn, mx = caixa(modelo)
end
local lente = mn - ESPERADO_MIN   -- posicao da lente no mundo

local raiz = modelo:FindFirstChild("Raiz") or Instance.new("Part")
raiz.Name = "Raiz"; raiz.Size = Vector3.new(0.05, 0.05, 0.05); raiz.Transparency = 1
raiz.CFrame = CFrame.new(lente); raiz.Parent = modelo
modelo.PrimaryPart = raiz

local nPartes = 0
for _, d in ipairs(modelo:GetDescendants()) do
	if d:IsA("BasePart") then
		nPartes += 1
		d.Anchored = true; d.CanCollide = false; d.CanQuery = false; d.CanTouch = false
		d.CastShadow = false; d.Massless = true
		if d:IsA("MeshPart") then pcall(function() d.RenderFidelity = Enum.RenderFidelity.Precise end) end
		if string.find(d.Name, "VM_Lente") then
			d.Name = "VM_Lente"; d.Material = Enum.Material.Neon; d.Color = Color3.fromRGB(255, 214, 165)
		elseif string.find(d.Name, "VM_Corpo") then
			d.Name = "VM_Corpo"
		end
	end
end

local pasta = RS:FindFirstChild("Invokyr") or Instance.new("Folder")
pasta.Name = "Invokyr"; pasta.Parent = RS
local antigo = pasta:FindFirstChild("LanternaMao")
if antigo and antigo ~= modelo then
	local bk = SS:FindFirstChild("Invokyr_Backup") or Instance.new("Folder")
	bk.Name = "Invokyr_Backup"; bk.Parent = SS
	antigo.Name = "LanternaMao_antiga"; antigo.Parent = bk
end
modelo.Name = "LanternaMao"
modelo.Parent = pasta

local temSA = modelo:FindFirstChild("VM_Corpo", true) and modelo:FindFirstChild("VM_Corpo", true):FindFirstChildOfClass("SurfaceAppearance")
print("========== INVOKYR: SCRIPT 05 ==========")
print(("  Lanterna com mao pronta em ReplicatedStorage > Invokyr > LanternaMao (%d pecas)"):format(nPartes))
print(("  Escala de importacao corrigida: fator %.3f"):format(fator))
print("  Giro corrigido pelo script: " .. giro)
-- verificacao da SALA: a chama da vela deve estar no ponto de luz da vela
local sala = workspace:FindFirstChild("Invokyr") and workspace.Invokyr:FindFirstChild("SalaPrincipal")
local ancora = sala and sala:FindFirstChild("PontosDeLuz") and sala.PontosDeLuz:FindFirstChild("AncoraLuzes")
local pontoVela = ancora and ancora:FindFirstChild("Vela_da_mesa")
local chamaVela
if sala then
	for _, d in ipairs(sala:GetDescendants()) do
		if d:IsA("BasePart") and string.find(d.Name, "EMIS_Chama_Mesa") then chamaVela = d end
	end
end
if pontoVela and chamaVela then
	local dist = (chamaVela.Position - pontoVela.WorldPosition).Magnitude
	if dist < 1.5 then
		print(("  Sala: orientacao OK (vela a %.2f studs do ponto esperado)"):format(dist))
	else
		warn(("  AVISO: a SALA parece girada (vela a %.1f studs do ponto esperado). Me mande este relatorio."):format(dist))
	end
end
if temSA then print("  Textura: OK") else warn("  AVISO: VM_Corpo sem textura (SurfaceAppearance). Me mande este relatorio.") end
print("  Agora rode o Script 03 (v7) de novo e de Play.")
