--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EventService = require(script.Parent:WaitForChild("EventService"))
local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local BoardService = {}
local rng = Random.new()
local lastRollByUserId: { [number]: number } = {}
function BoardService.Start(prompt: ProximityPrompt, event: RemoteEvent, matchService)
    local board = prompt.Parent
    assert(board ~= nil and board:IsA("BasePart"), "ProximityPrompt deve estar em uma BasePart")
    prompt.Triggered:Connect(function(player: Player)
        local character = player.Character
        local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
        if not (root and root:IsA("BasePart")) then
            return
        end
        local distance = (root.Position - board.Position).Magnitude
        if distance > GameConfig.BOARD_INTERACTION_DISTANCE then
            return
        end
        local now = os.clock()
        local previous = lastRollByUserId[player.UserId] or -math.huge
        if now - previous < GameConfig.BOARD_COOLDOWN_SECONDS then
            return
        end
        lastRollByUserId[player.UserId] = now
        if not matchService.IsPlayersTurn(player) then
            event:FireClient(player, "Notice", { text = "Espere: não é a sua vez!" })
            return
        end
        local dice = rng:NextInteger(1, 6)
        local message = EventService.GetMessage(dice)
        event:FireAllClients("DiceRolled", {
            playerName = player.DisplayName,
            dice = dice,
            event = message,
        })
        matchService.AdvanceTurn(player)
        print(string.format("[BoardService] %s lançou %d", player.Name, dice))
    end)
end
return BoardService
