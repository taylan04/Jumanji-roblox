--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = script.Parent:WaitForChild("Services")
local Generation = script.Parent:WaitForChild("Generation")
local MapGenerator = require(Generation:WaitForChild("MapGenerator"))
local PlayerService = require(Services:WaitForChild("PlayerService"))
local MatchService = require(Services:WaitForChild("MatchService"))
local BoardService = require(Services:WaitForChild("BoardService"))
local remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not remotes then
    remotes = Instance.new("Folder")
    remotes.Name = "Remotes"
    remotes.Parent = ReplicatedStorage
end
local gameEvent = remotes:FindFirstChild("GameEvent")
if not gameEvent then
    gameEvent = Instance.new("RemoteEvent")
    gameEvent.Name = "GameEvent"
    gameEvent.Parent = remotes
end
local boardPrompt = MapGenerator.Generate()
PlayerService.Start()
MatchService.Start(remotes)
BoardService.Start(boardPrompt, gameEvent, MatchService)
print("[Jumanji] Servidor iniciado. Sala e tabuleiro prontos para teste!")
