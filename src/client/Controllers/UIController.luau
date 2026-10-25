--!strict
local Players = game:GetService("Players")
local UIController = {}
local function createLabel(parent: Instance, name: string, y: number, size: number, text: string): TextLabel
    local label = Instance.new("TextLabel")
    label.Name = name
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, -24, 0, 36)
    label.Position = UDim2.fromOffset(12, y)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextColor3 = Color3.fromRGB(247, 228, 204)
    label.Font = Enum.Font.Gotham
    label.TextSize = size
    label.TextWrapped = true
    label.Text = text
    label.Parent = parent
    return label
end
function UIController.Start(remotes: Folder, gameEvent: RemoteEvent)
    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
    local old = playerGui:FindFirstChild("JumanjiHUD")
    if old then
        old:Destroy()
    end
    local gui = Instance.new("ScreenGui")
    gui.Name = "JumanjiHUD"
    gui.ResetOnSpawn = false
    gui.Parent = playerGui
    local panel = Instance.new("Frame")
    panel.Name = "HudPanel"
    panel.Size = UDim2.fromOffset(390, 167)
    panel.Position = UDim2.fromOffset(18, 24)
    panel.BackgroundColor3 = Color3.fromRGB(29, 25, 35)
    panel.BackgroundTransparency = 0.12
    panel.Parent = gui
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = panel
    createLabel(panel, "Title", 9, 18, "TABULEIRO DAS SOMBRAS  •  PROTÓTIPO")
    local turnLabel = createLabel(panel, "Turn", 48, 16, "Aguardando jogadores...")
    local resultLabel = createLabel(panel, "Result", 83, 16, "Aproxime-se do tabuleiro e pressione E.")
    local eventLabel = createLabel(panel, "Event", 123, 14, "Seu grupo precisa agir em conjunto.")
    local function updateTurn()
        local name = remotes:GetAttribute("CurrentTurnPlayerName")
        local turnUserId = remotes:GetAttribute("CurrentTurnUserId")
        if typeof(name) ~= "string" or name == "" then
            turnLabel.Text = "Turno: aguardando jogadores..."
        elseif turnUserId == Players.LocalPlayer.UserId then
            turnLabel.Text = "Turno: SUA VEZ!"
        else
            turnLabel.Text = "Turno: " .. name
        end
    end
    remotes:GetAttributeChangedSignal("CurrentTurnUserId"):Connect(updateTurn)
    remotes:GetAttributeChangedSignal("CurrentTurnPlayerName"):Connect(updateTurn)
    updateTurn()
    gameEvent.OnClientEvent:Connect(function(kind: string, payload)
        if kind == "DiceRolled" then
            resultLabel.Text = string.format("%s lançou o dado: %d", tostring(payload.playerName), tonumber(payload.dice) or 0)
            eventLabel.Text = tostring(payload.event)
        elseif kind == "Notice" then
            eventLabel.Text = tostring(payload.text)
        end
    end)
end
return UIController
