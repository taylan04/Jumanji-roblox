--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EventService = require(script.Parent:WaitForChild("EventService"))
local GameConfig = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("GameConfig"))

local BoardService = {}

local rng = Random.new()
local lastRollByUserId: { [number]: number } = {}

local DOOR_OPEN_OFFSET = 11

local function closeAllDoors(doors: { BasePart })
    for _, door in ipairs(doors) do
        local closedCFrame = door:GetAttribute("ClosedCFrame")
        if typeof(closedCFrame) == "CFrame" then
            door.CFrame = closedCFrame
        end
        door.CanCollide = true
    end
end

local function openDoor(door: BasePart)
    local closedCFrame = door:GetAttribute("ClosedCFrame")
    local openDirection = door:GetAttribute("OpenDirection")

    if typeof(closedCFrame) ~= "CFrame" then
        closedCFrame = door.CFrame
        door:SetAttribute("ClosedCFrame", closedCFrame)
    end

    if typeof(openDirection) ~= "string" then
        openDirection = "X"
    end

    if openDirection == "Z" then
        door.CFrame = closedCFrame + Vector3.new(0, 0, DOOR_OPEN_OFFSET)
    elseif openDirection == "-Z" then
        door.CFrame = closedCFrame + Vector3.new(0, 0, -DOOR_OPEN_OFFSET)
    elseif openDirection == "-X" then
        door.CFrame = closedCFrame + Vector3.new(-DOOR_OPEN_OFFSET, 0, 0)
    else
        door.CFrame = closedCFrame + Vector3.new(DOOR_OPEN_OFFSET, 0, 0)
    end

    door.CanCollide = false
end

function BoardService.Start(prompt: ProximityPrompt, event: RemoteEvent, matchService, doors: { BasePart })
    local board = prompt.Parent
    assert(board ~= nil and board:IsA("BasePart"), "ProximityPrompt deve estar em uma BasePart")

    closeAllDoors(doors)

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
            event:FireClient(player, "Notice", {
                text = "Espere: não é a sua vez."
            })
            return
        end

        local dice = rng:NextInteger(1, 6)
        local message = EventService.GetMessage(dice)

        closeAllDoors(doors)

        local selectedDoor = doors[((dice - 1) % #doors) + 1]
        openDoor(selectedDoor)

        event:FireAllClients("DiceRolled", {
            playerName = player.DisplayName,
            dice = dice,
            event = message,
            openedDoor = selectedDoor.Name,
        })

        matchService.AdvanceTurn(player)

        print(string.format("[BoardService] %s lançou %d", player.Name, dice))
    end)
end

return BoardService