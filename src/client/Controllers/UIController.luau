--!strict
-- HUD compacto: informações temporárias, respeitando a área segura da tela.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local GameConfig = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("GameConfig"))
local UIController = {}
local connections: { RBXScriptConnection } = {}
local generation = 0

local function disconnect()
    for _, connection in ipairs(connections) do
        connection:Disconnect()
    end
    table.clear(connections)
end

local function card(parent: Instance, name: string, y: number, width: number, maxWidth: number): (CanvasGroup, TextLabel)
    local group = Instance.new("CanvasGroup")
    group.Name = name
    group.AnchorPoint = Vector2.new(0.5, 0)
    group.Position = UDim2.new(0.5, 0, 0, y)
    group.Size = UDim2.new(width, 0, 0, 0)
    group.AutomaticSize = Enum.AutomaticSize.Y
    group.BackgroundColor3 = Color3.fromRGB(20, 23, 20)
    group.BackgroundTransparency = 0.16
    group.GroupTransparency = 1
    group.Visible = false
    group.Parent = parent

    local limit = Instance.new("UISizeConstraint")
    limit.MaxSize = Vector2.new(maxWidth, 220)
    limit.Parent = group

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 9)
    corner.Parent = group

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 12)
    padding.PaddingRight = UDim.new(0, 12)
    padding.PaddingTop = UDim.new(0, 9)
    padding.PaddingBottom = UDim.new(0, 9)
    padding.Parent = group

    local label = Instance.new("TextLabel")
    label.Name = "Text"
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, 0, 0, 0)
    label.AutomaticSize = Enum.AutomaticSize.Y
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 14
    label.TextColor3 = Color3.fromRGB(237, 226, 204)
    label.TextWrapped = true
    label.Text = ""
    label.Parent = group
    return group, label
end

function UIController.Start(remotes: Folder, gameEvent: RemoteEvent)
    generation += 1
    local currentGeneration = generation
    disconnect()

    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    local old = playerGui:FindFirstChild("JumanjiHUD")
    if old then old:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name = "JumanjiHUD"
    gui.ResetOnSpawn = false
    gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = playerGui

    local turnCard, turnText = card(gui, "Turn", 10, 0.72, 300)
    local eventCard, eventText = card(gui, "Event", 58, 0.86, 420)
    eventText.Font = Enum.Font.Gotham
    eventText.TextSize = 13

    -- Mantém o aviso abaixo do turno, mesmo se um nome longo quebrar linha.
    local function positionEvent()
        eventCard.Position = UDim2.new(0.5, 0, 0, 18 + turnCard.AbsoluteSize.Y)
    end
    table.insert(connections, turnCard:GetPropertyChangedSignal("AbsoluteSize"):Connect(positionEvent))

    local function temporary(group: CanvasGroup, label: TextLabel)
        local token = 0
        local tween: Tween? = nil
        return function(text: string, seconds: number)
            token += 1
            local activeToken = token
            if tween then tween:Cancel() end
            label.Text = text
            group.Visible = true
            group.GroupTransparency = 0
            task.delay(seconds, function()
                if generation ~= currentGeneration or activeToken ~= token or gui.Parent == nil then return end
                local fade = TweenService:Create(group, TweenInfo.new(0.35), { GroupTransparency = 1 })
                tween = fade
                fade.Completed:Once(function(state)
                    if state == Enum.PlaybackState.Completed and generation == currentGeneration
                        and activeToken == token and gui.Parent ~= nil then
                        group.Visible = false
                    end
                end)
                fade:Play()
            end)
        end
    end

    local showTurn = temporary(turnCard, turnText)
    local showEvent = temporary(eventCard, eventText)

    local function updateTurn()
        local name = remotes:GetAttribute("CurrentTurnPlayerName")
        local userId = remotes:GetAttribute("CurrentTurnUserId")
        if typeof(name) ~= "string" or name == "" then
            showTurn("Aguardando jogadores", 5)
        elseif userId == player.UserId then
            showTurn("Sua vez de lançar o dado", 6)
        else
            showTurn("Vez de " .. name, 5)
        end
    end

    table.insert(connections, remotes:GetAttributeChangedSignal("CurrentTurnUserId"):Connect(updateTurn))
    table.insert(connections, remotes:GetAttributeChangedSignal("CurrentTurnPlayerName"):Connect(updateTurn))
    table.insert(connections, gameEvent.OnClientEvent:Connect(function(kind: string, payload)
        if typeof(payload) ~= "table" then return end
        if kind == "DiceRolled" then
            local playerName = tostring(payload.playerName or "Jogador")
            local dice = tonumber(payload.dice) or 0
            local message = tostring(payload.event or "")
            local door = tostring(payload.openedDoor or "")
            local text = string.format("%s lançou %d", playerName, dice)
            if message ~= "" then text ..= "\n" .. message end
            if door ~= "" then text ..= "\nPassagem liberada: " .. door end
            showEvent(text, math.clamp(GameConfig.UI_RESULT_DURATION, 4, 8))
        elseif kind == "Notice" then
            showEvent(tostring(payload.text or ""), math.clamp(GameConfig.UI_NOTICE_DURATION, 3, 6))
        end
    end))

    updateTurn()
    showEvent("Aproxime-se do tabuleiro para interagir.", 5)
end

return UIController

