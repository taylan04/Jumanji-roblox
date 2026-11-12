--[[
INVOKYR - Script 08: Movimento (andar devagar, Shift = correr, Ctrl = agachar)
Rode na barra de comandos com o jogo PARADO. Pode rodar de novo.
Ajuste as velocidades no topo de StarterPlayerScripts > Invokyr_Movimento.
]]
if game:GetService("RunService"):IsRunning() then error("[Invokyr] O jogo esta em Play. Clique em PARAR e rode de novo.") end
local SP = game:GetService("StarterPlayer")
SP.CharacterWalkSpeed = 8
SP.EnableMouseLockOption = false   -- o Shift do Roblox (shift lock) atrapalharia o correr
local FONTE = [==[--[[ Invokyr_Movimento (LocalScript, StarterPlayerScripts) - gerado pelo Script 08
Andar devagar, Shift = correr, Ctrl = agachar. No celular: botoes "Correr" e "Agachar" (liga/desliga). ]]
local CFG = {
	ANDAR = 8,             -- velocidade normal (Roblox padrao = 16)
	CORRER = 17,
	AGACHAR = 4,
	ALTURA_AGACHADO = -1.6,   -- quanto a camera desce ao agachar (studs)
	FOV_NORMAL = 70, FOV_CORRENDO = 77,
	FOLEGO = true,         -- correr gasta folego (false = corre sem limite)
	FOLEGO_SEGUNDOS = 4,   -- quanto tempo da para correr com o folego cheio
	FOLEGO_RECUPERA = 4,   -- segundos para encher de novo (andando/parado)
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CAS = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

local querCorrer, agachado = false, false
local folego = 1
local offsetAtual = 0

-- barra de folego discreta (so aparece quando nao esta cheia)
local gui = Instance.new("ScreenGui"); gui.Name = "Invokyr_Folego"; gui.ResetOnSpawn = false
local fundo = Instance.new("Frame")
fundo.AnchorPoint = Vector2.new(0.5, 1); fundo.Position = UDim2.new(0.5, 0, 1, -28); fundo.Size = UDim2.new(0, 220, 0, 5)
fundo.BackgroundColor3 = Color3.fromRGB(20, 16, 12); fundo.BackgroundTransparency = 1; fundo.BorderSizePixel = 0; fundo.Parent = gui
local barra = Instance.new("Frame")
barra.Size = UDim2.new(1, 0, 1, 0); barra.BackgroundColor3 = Color3.fromRGB(236, 222, 190); barra.BackgroundTransparency = 1
barra.BorderSizePixel = 0; barra.Parent = fundo
for _, f in ipairs({ fundo, barra }) do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1, 0); c.Parent = f end
gui.Parent = player:WaitForChild("PlayerGui")

local function acaoCorrer(_, estado)
	if estado == Enum.UserInputState.Begin then
		querCorrer = true
	elseif estado == Enum.UserInputState.End then
		querCorrer = false
	end
	return Enum.ContextActionResult.Pass
end
local function acaoAgachar(_, estado)
	if estado == Enum.UserInputState.Begin then agachado = true
	elseif estado == Enum.UserInputState.End then agachado = false end
	return Enum.ContextActionResult.Pass
end
-- teclado: segurar
CAS:BindAction("InvokyrCorrer", acaoCorrer, false, Enum.KeyCode.LeftShift, Enum.KeyCode.RightShift, Enum.KeyCode.ButtonL3)
CAS:BindAction("InvokyrAgachar", acaoAgachar, false, Enum.KeyCode.LeftControl, Enum.KeyCode.RightControl, Enum.KeyCode.C, Enum.KeyCode.ButtonB)
-- celular: botoes que ligam/desligam
CAS:BindAction("InvokyrCorrerToque", function(_, st)
	if st == Enum.UserInputState.Begin then querCorrer = not querCorrer; if querCorrer then agachado = false end end
	return Enum.ContextActionResult.Pass
end, true)
CAS:BindAction("InvokyrAgacharToque", function(_, st)
	if st == Enum.UserInputState.Begin then agachado = not agachado; if agachado then querCorrer = false end end
	return Enum.ContextActionResult.Pass
end, true)
CAS:SetTitle("InvokyrCorrerToque", "Correr"); CAS:SetTitle("InvokyrAgacharToque", "Agachar")
CAS:SetPosition("InvokyrCorrerToque", UDim2.new(1, -170, 1, -150))
CAS:SetPosition("InvokyrAgacharToque", UDim2.new(1, -100, 1, -205))

local barraVisivel = false
RunService.RenderStepped:Connect(function(dt)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return end
	local movendo = hum.MoveDirection.Magnitude > 0.1
	local correndo = querCorrer and not agachado and movendo and (not CFG.FOLEGO or folego > 0.02)
	-- folego
	if CFG.FOLEGO then
		if correndo then folego = math.max(0, folego - dt / CFG.FOLEGO_SEGUNDOS)
		else folego = math.min(1, folego + dt / CFG.FOLEGO_RECUPERA * (movendo and 0.6 or 1)) end
		if folego <= 0.02 then querCorrer = false end
		barra.Size = UDim2.new(folego, 0, 1, 0)
		local mostrar = folego < 0.99
		if mostrar ~= barraVisivel then
			barraVisivel = mostrar
			TweenService:Create(fundo, TweenInfo.new(0.4), { BackgroundTransparency = mostrar and 0.5 or 1 }):Play()
			TweenService:Create(barra, TweenInfo.new(0.4), { BackgroundTransparency = mostrar and 0.15 or 1 }):Play()
		end
	end
	-- velocidade
	hum.WalkSpeed = agachado and CFG.AGACHAR or (correndo and CFG.CORRER or CFG.ANDAR)
	player:SetAttribute("Correndo", correndo); player:SetAttribute("Agachado", agachado)
	-- camera: desce ao agachar, abre um pouco ao correr
	local alvo = agachado and CFG.ALTURA_AGACHADO or 0
	offsetAtual += (alvo - offsetAtual) * (1 - math.exp(-10 * dt))
	hum.CameraOffset = Vector3.new(0, offsetAtual, 0)
	local cam = workspace.CurrentCamera
	local fov = correndo and CFG.FOV_CORRENDO or CFG.FOV_NORMAL
	cam.FieldOfView += (fov - cam.FieldOfView) * (1 - math.exp(-6 * dt))
end)
]==]
local pai = SP:WaitForChild("StarterPlayerScripts")
local s = pai:FindFirstChild("Invokyr_Movimento"); if s then s:Destroy() end
s = Instance.new("LocalScript"); s.Name = "Invokyr_Movimento"; s.Source = FONTE; s.Parent = pai
print("========== INVOKYR: SCRIPT 08 ==========")
print("  Movimento instalado: andar 8 | Shift = correr 17 | Ctrl (ou C) = agachar 4 | folego de 4 s")
print("  Celular: botoes Correr e Agachar na tela.")
