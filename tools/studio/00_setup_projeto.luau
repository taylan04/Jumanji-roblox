-- Cole na Barra de Comandos do Roblox Studio, fora do Play.
local entries = {
    {game:GetService("ServerScriptService"), "GameScripts"},
    {game:GetService("ReplicatedStorage"), "Shared"},
    {game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts"), "GameClient"},
}
for _, entry in ipairs(entries) do
    local parent, name = entry[1], entry[2]
    local current = parent:FindFirstChild(name)
    if not current then
        local folder = Instance.new("Folder")
        folder.Name = name
        folder.Parent = parent
        print("[Setup] Criada:", folder:GetFullName())
    else
        print("[Setup] Já existe:", current:GetFullName())
    end
end
