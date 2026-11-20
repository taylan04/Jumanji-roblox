--[[
INVOKYR - Script 16b: conserto da BANHEIRA (e do vaso) no Banheiro ja instalado
================================================================================
  1. Importe o Banheira_conserto.glb (Home > Import 3D). Sao so 2 pecas.
  2. Rode este script na BARRA DE COMANDOS, com o jogo PARADO.

O que faz (pode rodar de novo sem estragar nada):
  - Tira a tampa de madeira da banheira. O totem continua deitado la dentro, agora a vista.
  - Troca a porcelana de dentro da banheira e do vaso pela versao consertada
    (a parede de dentro estava virada para fora e sumia quando se olhava para dentro).
  - Vale para ServerStorage > Invokyr_Salas > Banheiro e para a Previa_Banheiro.
  - Nada e apagado: o que sai vai para ServerStorage > Invokyr_Backup > Banheiro_conserto_<data>.
]]

local RunService = game:GetService("RunService")
if RunService:IsRunning() then
	error("[Invokyr] Pare o jogo (Stop) antes de rodar o Script 16b.")
end
local Selection = game:GetService("Selection")
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")

local PECAS = { "Banheira__Porcelana", "Vaso__Porcelana" }

local function chave(s) return (string.gsub(string.lower(s), "[^a-z0-9]", "")) end
local function achar(modelo)
	local t = {}
	for _, d in ipairs(modelo:GetDescendants()) do
		if d:IsA("MeshPart") then
			for _, nome in ipairs(PECAS) do
				local k = chave(nome)
				if chave(d.Name) == k or string.gsub(chave(d.Parent.Name), "node$", "") == k then t[nome] = d end
			end
		end
	end
	return t
end
local function ehConserto(m)
	if not m:IsA("Model") or m:GetAttribute("PecaInvokyr") then return false end
	local t = achar(m)
	return t[PECAS[1]] ~= nil and t[PECAS[2]] ~= nil
end

-- 1. a importacao
local importado
local sel = Selection:Get()
if #sel == 1 and ehConserto(sel[1]) then importado = sel[1] end
if not importado then
	for _, m in ipairs(workspace:GetChildren()) do
		if ehConserto(m) then importado = m end
	end
end
if not importado then
	error("[Invokyr] Nao achei a importacao do Banheira_conserto.glb. Importe (Home > Import 3D) e rode de novo.")
end
local novas = achar(importado)

-- 2. as salas que recebem o conserto
local salas = {}
local biblioteca = ServerStorage:FindFirstChild("Invokyr_Salas")
if biblioteca and biblioteca:FindFirstChild("Banheiro") then table.insert(salas, biblioteca.Banheiro) end
for _, d in ipairs(workspace:GetDescendants()) do
	if d:IsA("Model") and d.Name == "Previa_Banheiro" and d:GetAttribute("PecaInvokyr") then table.insert(salas, d) end
end
if #salas == 0 then error("[Invokyr] Nao achei o Banheiro instalado. Rode o Script 16 primeiro.") end

local backup = ServerStorage:FindFirstChild("Invokyr_Backup") or Instance.new("Folder")
backup.Name = "Invokyr_Backup"; backup.Parent = ServerStorage
local guarda = Instance.new("Folder")
guarda.Name = "Banheiro_conserto_" .. os.date("%Y%m%d_%H%M%S")
guarda.Parent = backup

local relatorio = {}
for _, sala in ipairs(salas) do
	local pasta = Instance.new("Folder"); pasta.Name = sala.Name; pasta.Parent = guarda
	local feito = {}
	-- porcelana nova no lugar exato da antiga
	for _, nome in ipairs(PECAS) do
		local velha = sala:FindFirstChild("Visual") and sala.Visual:FindFirstChild(nome)
		local nova = novas[nome]
		if velha and velha:IsA("MeshPart") then
			if (velha.Size - nova.Size).Magnitude > 0.1 then
				warn(("[Invokyr] %s veio com tamanho diferente (%.2f x %.2f x %.2f). Importe com Scale Unit = Stud e Scale = 1.")
					:format(nome, nova.Size.X, nova.Size.Y, nova.Size.Z))
			else
				local p = nova:Clone()
				p.Name = nome
				p.CFrame = velha.CFrame
				p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
				p.Transparency = velha.Transparency
				p.Parent = velha.Parent
				velha.Parent = pasta
				table.insert(feito, nome)
			end
		end
	end
	-- sem tampa: o movel da banheira sai
	local movel = sala:FindFirstChild("Moveis") and sala.Moveis:FindFirstChild("Movel_Banheira")
	if movel then
		for _, d in ipairs(movel:GetDescendants()) do CollectionService:RemoveTag(d, "Invokyr_Abre") end
		movel.Parent = pasta
		table.insert(feito, "tampa removida")
	end
	local ponto = sala:FindFirstChild("Esconderijos") and sala.Esconderijos:FindFirstChild("Totem_Banheira")
	if ponto then ponto:SetAttribute("Movel", nil) end
	table.insert(relatorio, sala:GetFullName() .. ": " .. (#feito > 0 and table.concat(feito, ", ") or "nada a fazer (ja estava consertado)"))
end
importado.Name = "Banheira_conserto_importacao"
importado.Parent = guarda

print("========== INVOKYR 16b: BANHEIRA ==========")
for _, l in ipairs(relatorio) do print("  " .. l) end
print("  O que saiu esta em ServerStorage > Invokyr_Backup > " .. guarda.Name)
