--[[
	AVISO NA TELA (opcional)  -  "LUZ VERDE / LUZ VERMELHA"
	ONDE COLOCAR: LocalScript dentro de StarterPlayer > StarterPlayerScripts
	Ele so le o estado que o Script BailarinaGiro publica e mostra um aviso no topo da tela.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local estado = ReplicatedStorage:WaitForChild("BailarinaEstado")
local gui = Instance.new("ScreenGui")
gui.Name = "AvisoBailarina"; gui.ResetOnSpawn = false
gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

local txt = Instance.new("TextLabel")
txt.AnchorPoint = Vector2.new(0.5, 0)
txt.Position = UDim2.new(0.5, 0, 0.04, 0)
txt.Size = UDim2.new(0.5, 0, 0.08, 0)
txt.BackgroundTransparency = 0.35
txt.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
txt.Font = Enum.Font.GothamBlack
txt.TextScaled = true
txt.Parent = gui
Instance.new("UICorner", txt).CornerRadius = UDim.new(0.25, 0)

local function atualizar()
	if estado.Value == "vermelho" then
		txt.Text = "PARE! ELA ESTÁ OLHANDO"
		txt.TextColor3 = Color3.fromRGB(255, 70, 60)
	else
		txt.Text = "BATATINHA FRITA 1, 2, 3...  ANDE!"
		txt.TextColor3 = Color3.fromRGB(110, 255, 120)
	end
end
estado.Changed:Connect(atualizar)
atualizar()
