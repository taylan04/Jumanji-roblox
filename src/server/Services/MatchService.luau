--!strict
local Players = game:GetService("Players")
local MatchService = {}
local remotesFolder: Folder? = nil
local activeUserId: number? = nil
local function sortedPlayers(): { Player }
    local result = Players:GetPlayers()
    table.sort(result, function(a, b)
        return a.UserId < b.UserId
    end)
    return result
end
local function publishTurn(player: Player?)
    activeUserId = if player then player.UserId else nil
    local folder = remotesFolder
    if folder then
        folder:SetAttribute("CurrentTurnUserId", activeUserId or 0)
        folder:SetAttribute("CurrentTurnPlayerName", if player then player.DisplayName else "Aguardando jogadores")
    end
end
local function ensureTurn()
    if activeUserId then
        for _, player in sortedPlayers() do
            if player.UserId == activeUserId then
                return
            end
        end
    end
    publishTurn(sortedPlayers()[1])
end
function MatchService.Start(folder: Folder)
    remotesFolder = folder
    publishTurn(nil)
    ensureTurn()
    Players.PlayerAdded:Connect(function()
        ensureTurn()
    end)
    Players.PlayerRemoving:Connect(function(player)
        if player.UserId == activeUserId then
            local remaining = {}
            for _, other in sortedPlayers() do
                if other ~= player then
                    table.insert(remaining, other)
                end
            end
            publishTurn(remaining[1])
        end
    end)
end
function MatchService.IsPlayersTurn(player: Player): boolean
    ensureTurn()
    return activeUserId == player.UserId
end
function MatchService.AdvanceTurn(player: Player)
    local players = sortedPlayers()
    if #players == 0 then
        publishTurn(nil)
        return
    end
    for i, current in players do
        if current.UserId == player.UserId then
            publishTurn(players[(i % #players) + 1])
            return
        end
    end
    publishTurn(players[1])
end
return MatchService
