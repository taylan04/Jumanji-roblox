--!strict

local GameConfig = {
    TITLE = "Tabuleiro das Sombras",
    SUBTITLE = "Protótipo",
    MAX_PLAYERS = 4,

    BOARD_INTERACTION_DISTANCE = 14,
    BOARD_COOLDOWN_SECONDS = 1.5,

    UI_NOTICE_DURATION = 4,
    UI_RESULT_DURATION = 8,

    ROOM = {
        WIDTH = 96,
        LENGTH = 96,
        WALL_HEIGHT = 42,
        WALL_THICKNESS = 3,
        FLOOR_THICKNESS = 2,
        PILLAR_HEIGHT = 34,
        PILLAR_SIZE = 4,
        DOOR_WIDTH = 14,
        DOOR_HEIGHT = 24,
        DOOR_THICKNESS = 2,
    },
}

return table.freeze(GameConfig)