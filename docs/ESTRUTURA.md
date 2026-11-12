# Estrutura do projeto

```
Invokyr-Roblox/
├── src/                     Código Luau do jogo (sincronizado com o Studio via Script Sync)
│   ├── server/              → ServerScriptService/GameScripts   (Services, Generation)
│   ├── client/              → StarterPlayerScripts/GameClient   (Controllers)
│   └── shared/              → ReplicatedStorage/Shared          (configs e tipos)
│
├── assets/                  Arte do jogo
│   ├── models/              Fonte do Blender (.blend) + exportação para o Roblox (.glb)
│   │   ├── Ambientes/       Salas e cenários (Salão Principal, Átrio, Sala de Jantar)
│   │   ├── Monstros/        Inimigos (Alligator, Planta Carnívora, Múmia, Yeti)
│   │   ├── Props/           Objetos de cena (armários, lanterna, lenha, portal, torre...)
│   │   └── Totens/          Totens elementais (fonte + Export_Roblox)
│   ├── textures/            Texturas usadas no jogo (interior, interior2)
│   │   └── pbr_4k/          Biblioteca 4K do Poly Haven — NÃO vai pro GitHub
│   └── vfx/                 Efeitos visuais (fogo)
│
├── tools/                   Ferramentas de desenvolvimento (não rodam no jogo)
│   ├── studio/              Scripts para colar na Barra de Comandos do Studio
│   ├── blender/             Scripts Python que geram modelos no Blender
│   └── prototipos/          Protótipos em Python (gerador da mansão)
│
├── docs/                    Documentação
│   └── design/              Resumos do projeto, mapa e imagens de referência
│
└── places/                  Arquivos .rbxl do Studio — só locais, NÃO vão pro GitHub
```

## Regras rápidas

- **Código do jogo** sempre em `src/`. Server = lógica autoritativa; client = interface/câmera; shared = o que os dois usam.
- **Modelos novos**: crie uma pasta em `assets/models/<Categoria>/<Nome>/` com o `.blend` e o `.glb`.
- **GitHub aceita no máximo 100 MB por arquivo.** Se um `.blend` ou `.glb` passar disso, coloque no `.gitignore` (ou use Git LFS).
- **Backups do Blender** (`.blend1`) e **places do Studio** (`.rbxl`) são ignorados automaticamente.
