--!strict

local EventService = {}

local eventMessages = {
    [1] = "As engrenagens do tabuleiro rangeram. Um caminho se abriu.",
    [2] = "Uma energia antiga percorre as paredes da torre.",
    [3] = "A névoa se move entre as colunas. Algo observa o grupo.",
    [4] = "A sala desperta. Uma das portas respondeu ao tabuleiro.",
    [5] = "Sussurros ecoam entre os livros e as pedras antigas.",
    [6] = "O tabuleiro decidiu o próximo destino do grupo.",
}

function EventService.GetMessage(dice: number): string
    return eventMessages[dice] or "Algo desconhecido aconteceu."
end

return EventService