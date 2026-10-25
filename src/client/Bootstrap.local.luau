--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIController = require(script.Parent:WaitForChild("Controllers"):WaitForChild("UIController"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local gameEvent = remotes:WaitForChild("GameEvent")
UIController.Start(remotes, gameEvent)
print("[Jumanji] Cliente iniciado.")
