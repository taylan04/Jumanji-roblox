--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("GameConfig"))

local UIController = {}

local function createLabel(parent: Instance, name: string, y: number, size: number, text: string): TextLabel
    local label = Instance.new("TextLabel")
    label.Name = name
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, -20, 0, 28)
    label.Position = UDim2.fromOffset(10, y)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.TextColor3 = Color3.fromRGB(244, 231, 211)
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
    panel.Size = UDim2.new(0, 320, 0, 124)
    panel.Position = UDim2.new(0, 18, 0, 100)
    panel.BackgroundColor3 = Color3.fromRGB(20, 17, 23)
    panel.BackgroundTransparency = 0.24
    panel.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = panel

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(90, 76, 58)
    stroke.Transparency = 0.3
    stroke.Thickness = 1
    stroke.Parent = panel

    local title = createLabel(
        panel,
        "Title",
        10,
        14,
        string.upper(GameConfig.TITLE) .. "  •  " .. string.upper(GameConfig.SUBTITLE)
    )
    title.TextSize = 14

    local turnLabel = createLabel(panel, "Turn", 42, 12, "Turno: aguardando...")
    local hintLabel = createLabel(panel, "Hint", 69, 12, "Aproxime-se do tabuleiro e pressione E.")
    local eventLabel = createLabel(panel, "Event", 95, 11, "")

    local clearEventToken = 0

    local function showTemporaryEvent(text: string, duration: number)
        clearEventToken += 1
        local currentToken = clearEventToken

        eventLabel.Text = text

        task.delay(duration, function()
            if clearEventToken == currentToken then
                eventLabel.Text = ""
            end
        end)
    end

    local function updateTurn()
        local name = remotes:GetAttribute("CurrentTurnPlayerName")
        local turnUserId = remotes:GetAttribute("CurrentTurnUserId")

        if typeof(name) ~= "string" or name == "" then
            turnLabel.Text = "Turno: aguardando jogadores..."
        elseif turnUserId == Players.LocalPlayer.UserId then
            turnLabel.Text = "Turno: sua vez!"
        else
            turnLabel.Text = "Turno: " .. name
        end
    end

    remotes:GetAttributeChangedSignal("CurrentTurnUserId"):Connect(updateTurn)
    remotes:GetAttributeChangedSignal("CurrentTurnPlayerName"):Connect(updateTurn)
    updateTurn()

    gameEvent.OnClientEvent:Connect(function(kind: string, payload)
        if kind == "DiceRolled" then
            local playerName = tostring(payload.playerName)
            local dice = tonumber(payload.dice) or 0
            local message = tostring(payload.event or "")
            local openedDoor = tostring(payload.openedDoor or "")

            hintLabel.Text = string.format("%s lançou o dado: %d", playerName, dice)

            if openedDoor ~= "" then
                showTemporaryEvent(message .. " Porta aberta: " .. openedDoor .. ".", GameConfig.UI_RESULT_DURATION)
            else
                showTemporaryEvent(message, GameConfig.UI_RESULT_DURATION)
            end
        elseif kind == "Notice" then
            showTemporaryEvent(tostring(payload.text), GameConfig.UI_NOTICE_DURATION)
        end
    end)
end

return UIController