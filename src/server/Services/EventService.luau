--!strict
local EventService = {}
local eventMessages = {
    "Uma porta distante range no corredor...",
    "As luzes tremem por um instante.",
    "Um vento gelado atravessa a sala.",
    "O tabuleiro parece se mover sozinho.",
    "Passos ecoam atrás da parede.",
    "O grupo escuta uma voz sussurrando seus nomes.",
}
function EventService.GetMessage(dice: number): string
    return eventMessages[dice] or "Algo desconhecido aconteceu."
end
return EventService
