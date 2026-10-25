--!strict
local Players = game:GetService("Players")
local PlayerService = {}
function PlayerService.Start()
    Players.PlayerAdded:Connect(function(player)
        print("[PlayerService] Entrou:", player.Name)
    end)
    Players.PlayerRemoving:Connect(function(player)
        print("[PlayerService] Saiu:", player.Name)
    end)
    for _, player in Players:GetPlayers() do
        print("[PlayerService] Já presente:", player.Name)
    end
end
return PlayerService
