# INVOKYR — Resumo do projeto (v3, 09/11/2026)

> Cole este documento no início da nova conversa, junto com os arquivos da seção 9.
> Substitui o resumo anterior. Ele cobre tudo até o ciclo de totens funcionando.

## 1. O jogo

**Invokyr** — terror cooperativo no Roblox, até 4 jogadores, PC + celular. Ciclo:

1. Jogadores aparecem na **Sala Principal** (torre gótica octogonal, mesa redonda no centro).
2. **E** na mesa: o tabuleiro abre as 4 tampas, a sala treme, poeira cai, lustre e 8 lamparinas acendem.
3. **E** de novo: o dado rola, a peça anda as casas, uma dica rimada se forma em letras de fumaça.
4. As 4 portas abrem. Os jogadores exploram atrás de **totens**, fugindo de monstros.
5. Entregam 3 totens no altar da mesa → portas fecham, dado libera, entra o monstro da rodada.
6. 69 casas. Chegar ao poço central = fim.

### Regras de trabalho do usuário (IMPORTANTES)
- **Máxima automação**: scripts prontos que ele só cola na barra de comandos do Roblox Studio. Ele manda prints e Output de volta. **Ele não abre o Blender** — todo trabalho de Blender roda no ambiente do assistente (`pip install bpy`).
- **Nunca apagar trabalho existente**: o que sai de uso vai para `ServerStorage > Invokyr_Backup`.
- **Scripts idempotentes**, com guard `if RunService:IsRunning() then error(...)` — rodar em Play não persiste nada e já causou confusão.
- Comentários dos scripts **em português sem acento**.
- Validar sintaxe Luau antes de entregar (binário `luau-compile`, do GitHub do Luau).
- Qualidade visual alta, mas rodando em PC **e celular**.
- **Medir antes de afirmar.** O usuário cobra isso, com razão (ver seção 6).

## 2. Estado atual — FUNCIONANDO

### Sala Principal (Scripts 01–03)
- 3 GLBs importados (Arquitetura, Vegetação, Objetos), ~92 malhas, texturas assadas em ~34 atlas 1024.
- `Workspace > Invokyr > SalaPrincipal > {Visual, Colisao, PontosDeLuz, Spawns, Efeitos, Tabuleiro, ...}`
- Estados Dormente → Ativando → Ativa: tremor, poeira, lustre pisca e firma, 8 lamparinas em sequência, piscadas aleatórias.
- 4 portais com 8 folhas que giram na dobradiça real. `AbrirPortas:Fire("todas")` / `Fire("todas", false)`.
- Iluminação noturna: Technology Future, ClockTime 2.2, luar frio, feixes volumétricos falsos (Beams + névoa + poeira).
- **Lição importante**: metal alto (Metallic > 0) fica PRETO no escuro do Roblox. Zerar sempre na exportação.

### Lanterna (Scripts 04–05)
- Viewmodel com mão em `ReplicatedStorage > Invokyr > LanternaMao` (PrimaryPart = `Raiz`, peças `VM_Corpo` e `VM_Lente`).
- 3 SpotLights numa peça separada no workspace + luz rebatida por raycast. F liga/desliga. Replica para os outros jogadores a 10 Hz.
- Câmera travada em 1ª pessoa (`StarterPlayer.CameraMode = 1`).

### Tabuleiro (Scripts 06–07)
- Caixa 3×3 studs, 4 tampas, 69 casas (`Tabuleiro > Referencia > Casa_N`), peça encapuzada, dado de marfim.
- Fluxo por ProximityPrompt em `Tabuleiro > Gatilho`. Estados: Fechado → Abrindo → Pronto → Rolando → Explorando → (LiberarDado) → Pronto.
- Dica em fumaça: letras sopradas pelo vento, fiapos ondulando por `math.noise`.

### Movimento (Script 08)
- Andar 8, Shift corre 17 (fôlego 4 s), Ctrl/C agacha 4. FOV 70→77 correndo. Botões no celular.
- **Quem manda em `Humanoid.WalkSpeed` é este script**, todo RenderStepped. Nada mais deve mexer em WalkSpeed, ou vira briga.

### Totens (Scripts 09 e 11 — feitos nesta sessão)
`invokyr_09_totens.lua` instala servidor + cliente. Ciclo completo e testado:

espalhar → pegar (E) → maldição → largar (Q) → entregar no altar (E) → na 3ª entrega `LiberarDado:Fire()` e portas fecham.

**Decisões do usuário, já implementadas:**
- 1 totem por jogador por vez.
- Pode largar: fica exatamente onde caiu.
- Maldições **atrapalham**, não atacam.

**As 5 maldições** (o poder é contra quem carrega, não uma arma):
| Totem | Efeito |
|---|---|
| Fogo | Cospe um jato PARA FRENTE a cada 14–22 s. A chama fica 7 s no chão e queima quem pisar (7/s, piso em `VIDA_MINIMA = 1`, ninguém morre). Bloqueia o próprio caminho. |
| Gelo | Placa de gelo sem atrito segue o jogador; ele escorrega. Não mexe em WalkSpeed, é física. |
| Teleporte | A cada 7–13 s joga o jogador até 22 studs para um ponto aleatório. |
| Raio | A cada 5–10 s um raio cai a 9 studs: clarão + empurrão. |
| **Diamante** | **SEM PODER DEFINIDO — decisão pendente do usuário.** Aparece com 18% de chance. |

**Detalhes técnicos do Script 09:**
- O totem é **sempre ancorado e sem solda**. Quando carregado, o servidor move o modelo inteiro com um `PivotTo` por Heartbeat. (Soldas faziam o modelo se desmontar; foram removidas de vez.)
- Pose na tela, ajustável no topo do script: `LADO_CARREGADO = 2.3`, `ALTURA_CARREGADO = -2.1`, `DISTANCIA_CARREGADO = 4.0`, `GIRO_CARREGADO = Vector3.new(-6, 205, -8)`. Os 205° em Y são o que faz a CARA ficar virada para o jogador.
- Enquanto carrega, a lanterna fica invisível (`LocalTransparencyModifier`) mas **continua acesa**, e F continua funcionando. Não toca no Script 03.
- Cada totem tem um PointLight interno na cor do tipo (o corpo é quase preto e sumia no escuro).
- Esconderijos = qualquer Part com a tag **`Invokyr_Esconderijo`**, em qualquer lugar do Workspace. Hoje há 8 de teste dentro da sala principal; quando a mansão existir, basta marcar peças lá e apagar esses.

## 3. BUG ABERTO — peças dos totens fora do lugar

**Sintoma:** no modelo importado, algumas peças (argolas das orelhas, tubos) ficam deslocadas do corpo. Visível com luz de dia.

**Já descartado, com medição no arquivo `.rbxl` do usuário — NÃO REPETIR:**
1. ~~Ordem da solda~~ — soldas foram removidas totalmente; o problema continuou.
2. ~~Reposicionamento do script~~ — as posições que o script aplica batem com as do importador em **0.000** nas 47 peças.
3. ~~Rotação perdida~~ — todas as peças têm rotação identidade (ID 2), antes e depois.
4. ~~Escala~~ — `MeshPart.Size` bate com o bounding box do GLB.
5. ~~Peças soltas no Workspace~~ — zero.
6. ~~O GLB~~ — verificado byte a byte: 1 nó raiz, 9 filhos, cada um com translação própria, geometria centrada na própria origem.

**Conclusão:** o erro está na conversão GLB → MeshPart do Roblox. O `build.py` funde objetos **por material** em lotes de até 18k triângulos, então uma MeshPart contém várias peças espalhadas pelo totem inteiro. O importador parece não lidar bem com isso, mesmo mostrando a prévia correta.

**Caminho sugerido:** fundir cada totem num **único mesh** com textura assada em atlas (como foi feito com a sala no Script 01). Um totem = uma MeshPart = nada para posicionar errado. Custo: perde o Neon por peça (olhos acesos viram emissivo no atlas).

## 4. Texturas PBR — 4 MaterialVariants JÁ FUNCIONANDO no place

Convertidas de 4K JPG/EXR para **1024 PNG** (mapas de dado lidos como lineares, sem conversão sRGB; normal maps conferidos, média RGB ≈ 127/127/245). O usuário subiu 12 imagens no Asset Manager e o `invokyr_12_materiais.lua` criou os MaterialVariants. **Pareamento conferido na tela, está certo:**

| MaterialVariant | BaseMaterial | Studs/ladrilho | cor | normal | aspereza |
|---|---|---|---|---|---|
| `Invokyr_PainelEscuro` | Wood | 12 | 134844149630161 | 127301214384581 | 115758760516404 |
| `Invokyr_Lambril` | WoodPlanks | 10 | 80325303217451 | 105378489911630 | 101590325061624 |
| `Invokyr_Pedra` | Cobblestone | 8 | 102696433497678 | 124503670825828 | 82150281333510 |
| `Invokyr_Rocha` | Marble | 14 | 80598110418949 | 77919163559922 | 93987195445863 |

**Uso numa peça:**
```lua
peca.Material = Enum.Material.Wood
peca.MaterialVariant = "Invokyr_PainelEscuro"
```

**Ajuste de cor pendente** (o usuário ainda não escolheu): `Part.Color` multiplica o color map. O `Invokyr_Lambril` está avermelhado demais (sugerido `Color3.fromRGB(190,175,160)`) e o `Invokyr_PainelEscuro` quase preto (sugerido `Color3.fromRGB(205,200,195)`).

**Lote 2 — também já subido e criado pelo `invokyr_13_materiais2.lua`.** Os 8 convivem no MaterialService.

| MaterialVariant | BaseMaterial | Studs/ladrilho | cor | normal | aspereza |
|---|---|---|---|---|---|
| `Invokyr_PisoMadeira` | WoodPlanks | 8 | 101828036025545 | 134432862210828 | 81503987415706 |
| `Invokyr_Veludo` | Fabric | 8 | 86185006995276 | 76215259972071 | 133528224008493 |
| `Invokyr_Metal` | Metal | 8 | 139269131930064 | 109032421957339 | 118420803517171 |
| `Invokyr_Casca` | Wood | 6 | 140347282909242 | 138346663635254 | 122937567079665 |

Para que serve cada um: `PisoMadeira` é parquet escuro de tábua estreita (a falta mais grave, resolvida); `Veludo` é vermelho liso 174/45/71, para passadeira, cortina e forro; `Metal` são chapas gastas com emenda, para ferragem e grade; `Casca` só serve para viga rústica ou exterior.

O `StudsPerTile` de cada um saiu de ler a textura: o piso tem ~20 fileiras de tábua por ladrilho, então 8 studs deixa cada tábua com ~11 cm; o metal tem 3 a 4 chapas, 8 studs dá chapa de ~60 cm.

**Ainda falta:** papel de parede antigo (`wallpaper`), de preferência esverdeado. É a única da lista original que não veio.

**Os 8 estão conferidos na tela, lado a lado, e todos renderizam.** O `invokyr_13_materiais2.lua` levanta esse mural em z=92 (`TESTES = false` tira).

### Armadilha do cache do Studio (custou meia hora)

Se um `MaterialVariant` sair **branco**, com a imagem já subida e o ID certo, a causa quase certa é cache. Quando um `MaterialVariant` é criado nos segundos seguintes ao envio da imagem, o Studio guarda a falha de busca daquele ID — e **recriar o objeto não limpa**, porque o cache é por asset, não por instância. **Fechar e reabrir o Studio resolve.**

O que distingue essa causa das outras: uma `Decal` com o mesmo ID renderiza normalmente enquanto o `MaterialVariant` continua branco. Se a Decal também estiver branca, aí sim a imagem ainda está em processamento e é só esperar. Os dois scripts de material levantam uma folha com as imagens cruas embaixo do mural justamente para esse teste.

### Cores a acertar (pendente, é gosto)

Julgado só na luz de dia, então não vale decidir ainda. `Part.Color` multiplica o color map:

| Material | Problema aparente |
|---|---|
| `Invokyr_Lambril` | avermelhado demais, puxa mogno |
| `Invokyr_Veludo` | rosa saturado demais para mansão sombria |
| `Invokyr_PisoMadeira` | alaranjado na luz forte |
| `Invokyr_PainelEscuro` | quase preto |

**Acertar isso dentro da sala pronta, com a iluminação noturna ligada** (`invokyr_luz_de_dia.lua` com `DIA = false`), não no mural em pleno dia. Material escuro no sol parece uma coisa; à luz de lanterna, outra.

**Armadilha confirmada:** metálico acima de zero renderiza **preto** no escuro do Roblox. Zerar sempre, tanto no `MaterialVariant` quanto na exportação de GLB.

## 5. PRÓXIMO PASSO: a mansão

Combinado com o usuário:
- Começar pelo **Átrio**, depois Galeria, Arquivo, Passagem de Serviço — todas com **portais de encaixe padronizados** iguais aos da sala principal (vão de porta: 4,87 × 9,00 studs; portais a 14,4853 studs do centro, nas 4 direções).
- **Nada de versão provisória descartável.** O usuário recusou explicitamente: cada sala sai já com acabamento final, em peças reutilizáveis. O embaralhamento procedural fica para depois das salas existirem.
- **Estratégia visual** (decidida nesta sessão): arquitetura (parede, piso, teto) em **Parts do Roblox com MaterialVariant** tileado; Blender só para peças de forma própria — portas entalhadas, molduras, arcos, corrimãos, lustres, estátuas, móveis.
- O usuário mandou 4 referências (Darkwood/Dark Deception): madeira escura com painéis, corredores com passadeira vermelha, lambril, candelabros de parede, bibliotecas de teto alto.

### Os móveis SÃO os esconderijos (decidido pelo usuário)

No jogo original que inspirou o Invokyr, os totens são achados **dentro de armários, dentro de barris, em cima de mesas**. Então móvel não é enfeite: é onde o totem nasce.

Isso já se encaixa no que existe. O Script 09 sorteia os pontos de nascimento entre as peças com a Tag **`Invokyr_Esconderijo`** (hoje são 8 pontos de teste soltos no Workspace). Ao montar cada sala, basta marcar os móveis com essa Tag e os 8 pontos de teste podem sair. O `CollectionService` já é quem faz a busca, nada no script precisa mudar.

Vale montar as salas pensando nisso: cada sala precisa de alguns móveis que sirvam de esconderijo plausível, espalhados, não todos num canto. Faltam ainda **barril** e **mesa** no acervo — valem os próximos downloads do Poly Haven.
- **O Roblox não limita**: suporta SurfaceAppearance PBR completo (color/normal/roughness/metalness) e iluminação Future. A beleza depende de textura e capricho, não da plataforma.

## 6. Como o usuário trabalha

Ele testa na hora e manda print. Ele percebe quando a explicação não fecha e pergunta direto — **"você deduziu ou realmente encontrou o erro?"**. Nesta sessão eu errei quatro palpites seguidos no bug dos totens antes de ir medir o `.rbxl`. Quando ele mandou o arquivo do place, o diagnóstico saiu em minutos.

**Lição: peça o `.rbxl` cedo.** Dá para ler o formato binário com Python (zstd + estrutura INST/PROP/PRNT) e inspecionar hierarquia, propriedades, CFrames e tamanhos sem abrir o Studio.

## 7. Pendências menores

- Diamante sem poder definido.
- `ORDEM_MONSTROS = {"PlantaCarnivora"}` — só grava o nome num atributo, nada usa. Jacaré ainda não entrou.
- Nenhum `Sound` no jogo inteiro (portas, tremor, chamas, música da bailarina).
- Sem vida/morte/vitória. Chegar à casa 69 só mostra uma mensagem.
- Bailarina: modelo V3 existe, o desafio inteiro não.
- Monstros: nenhum importado no Roblox. `alligator_v2.blend` **já tem rig** (`Alligator_Armature`, 29 ossos, ações `Bite`, `Idle_Menace`, `Walk`) — o resumo anterior dizia que não tinha.
- Agachar não reduz a colisão do personagem, só a câmera desce.
- Um jogador só joga o dado; progressão compartilhada. Foi decisão implícita do código, não do usuário.

## 8. Modelos Blender (contagens reais, medidas)

| Arquivo | Malhas | Triângulos | Rig |
|---|---|---|---|
| `torre_tabuleiro_v04_sem_tabuleiro.blend` | 438 | 951 mil | não |
| `Invokyr_Totens.blend` (5 totens) | 48 | 533 mil (~25 mil cada depois do decimate) | não |
| `carnivorous_plant_official.blend` | 3.126 | 1,01 milhão | não (4 pivôs de mandíbula) |
| `alligator_v2.blend` | 454 | 247 mil | **sim** |

Decimate a 25 mil por totem ficou visualmente indistinguível do original; 12 mil já mostra olho poligonal; 6 mil entorta o nariz. Regerar em baixa resolução ficou **pior** que decimate no mesmo orçamento.

### Móveis do Poly Haven — GLB prontos para importar (`moveis_roblox/`)

Já exportados com escala de stud, base assentada no chão, centrados em X/Y, metálico zerado e texturas reduzidas a 1024. **Medidas conferidas lendo o GLB**, não a conta do Blender:

| GLB | Tris | Tamanho em studs (L × P × A) | Observação |
|---|---|---|---|
| `Armario_Gotico` | 12.170 | 6,14 × 3,99 × **8,43** | o mais a cara do jogo; passa pelo vão de 9 studs |
| `Armario_Oriental` | 15.668 | 4,51 × 1,95 × **10,26** | **não passa** pelo vão de 9: montar já dentro da sala |
| `Armario_Antigo` | 17.994 (de 61.096) | 7,22 × 2,39 × 7,98 | único que precisou de decimate |
| `Samambaia` | 6.232 | 7,04 × 6,16 × 1,53 | textura com alfa; folhagem no Roblox costuma ficar sofrível |
| `Televisao_Antiga` | 2.310 | 1,43 × 1,25 × 1,47 | TV de tubo; é pequena, vai em cima de móvel |

**Os 3 armários importaram certo, com textura.** A TV entrou com partes brancas e a samambaia o usuário nem importou — ele deixou os dois de lado de propósito, para não gastar tempo antes da mansão. O GLB da TV está correto (renderizado lado a lado com o `.blend` original, sai idêntico; o material aponta para a textura de cor e o metálico está zerado), então o problema é na leitura do importador, não no arquivo. Existe um `Televisao_Antiga_PNG.glb` com as texturas em PNG em vez de JPEG, que é a primeira coisa a tentar quando alguém voltar a isso. **Não é bloqueio para a mansão.**

**Não exportado, de propósito:** `flower_heliophila` (325 mil tris; cair para 8 mil destrói as pétalas, e flor viva não combina com o tema).

**Conversão metro → stud: multiplicar por 3,571** (1 stud = 0,28 m). O importador do Roblox lê 1 unidade do arquivo como 1 stud, então sem isso o móvel entra em miniatura.

**Armadilha achada nesta sessão:** os modelos do Poly Haven vêm com hierarquia de Empties que carrega cisalhamento. Mexer em `objeto.scale` e dar `transform_apply` **distorce o móvel** (o armário gótico saiu 10% mais alto e 10% mais estreito). O certo é aplicar a matriz do mundo inteira nos vértices: `obj.data.transform(Escala @ obj.matrix_world)` e depois zerar `matrix_world`. Além disso, `bound_box` fica em cache depois disso, então a medida confiável sai de ler o GLB, não do Blender.

## 9. O que anexar na nova conversa

| Arquivo | O que é |
|---|---|
| `Jogo-V2.rbxl` | **O mais importante.** O place inteiro. |
| `invokyr_09_totens.lua` | Sistema de totens (servidor + cliente) |
| `invokyr_11_totens_do_zero.lua` | Instalador dos totens importados |
| `invokyr_08_movimento.lua` | Correr / agachar / fôlego |
| `invokyr_02_montar_sala.lua` | Monta a sala (referência de medidas) |
| `invokyr_luz_de_dia.lua` | Ferramenta: acende a cena e enfileira os totens para conferência |
| `build.py` | Gerador dos 5 totens no Blender |
| `Invokyr_Totens.blend`, `alligator_v2.blend`, `carnivorous_plant_official.blend`, `torre_tabuleiro_v04_sem_tabuleiro.blend` | Modelos |
| `invokyr_12_materiais.lua` | Cria os MaterialVariants do lote 1 (IDs dentro do script) |
| `invokyr_13_materiais2.lua` | Cria os do lote 2 (piso, veludo, metal, casca) |
| `texturas_interior.zip` | Lote 1: 12 PNGs, **já subidos, IDs na seção 4** |
| `texturas_interior2.zip` | Lote 2: 12 PNGs, **já subidos, IDs na seção 4** |
| `moveis_roblox/*.glb` | 4 móveis prontos para o importador 3D |

**Ainda não enviados pelo usuário nesta linha:** `yeti_v2.blend`, `bailarina_v3/Bailarina_Invokyr.blend`, scripts 01, 03, 04, 05, 06, 07, e as capturas de referência da mansão.

## 10. Ambiente do assistente

- `pip install bpy` (5.2.3, mesma versão do usuário) — abre e edita os `.blend` direto.
- `luau-compile` do GitHub do Luau, para validar sintaxe antes de entregar.
- Leitor de `.rbxl`: formato binário com chunks `INST`/`PROP`/`PRNT`, comprimidos em **zstandard** (não LZ4, como em versões antigas). Dá para extrair hierarquia, `Source` dos scripts, atributos, CFrames e Sizes.
