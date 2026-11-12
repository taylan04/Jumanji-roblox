# INVOKYR — Resumo completo do projeto (para continuar em outra conversa)

> Cole este documento no início da nova conversa, junto com os arquivos listados na seção "O que anexar".

## 1. O jogo

**Invokyr** é um jogo de terror cooperativo no Roblox (até 4 jogadores, PC + celular), inspirado no jogo original Invokyr. Ciclo de jogo:

1. Os jogadores aparecem numa **Sala Principal** escura (torre gótica octogonal) com uma mesa redonda no centro.
2. Perto da mesa, apertam **E**: o tabuleiro de madeira abre as 4 tampas como pétalas, a sala treme, cai poeira e as luzes (lustre + 8 lamparinas) acendem uma a uma.
3. Apertam **E** de novo: o dado rola, a peça anda as casas e uma **dica rimada** (relacionada ao monstro da rodada) se forma em letras de fumaça flutuando sobre a mesa.
4. As 4 portas se abrem e os jogadores exploram o mapa atrás de **totens** (mínimo 3), fugindo de monstros.
5. Ao devolver os totens, as portas fecham, jogam o dado de novo e entra um monstro novo (os anteriores continuam). O tabuleiro tem 69 casas; chegar ao poço central = fim.

### Regras de trabalho do usuário (IMPORTANTES)
- Ele quer **máxima automação**: scripts prontos que ele só executa (barra de comandos do Roblox Studio ou Blender). Ele manda prints e o Output de volta.
- **Nunca apagar trabalho existente**: tudo que sai de uso vai para `ServerStorage > Invokyr_Backup`.
- **Scripts idempotentes**: pode rodar de novo quantas vezes quiser; substituem só o que eles mesmos criaram.
- Scripts de barra de comandos devem **bloquear execução em Play** (guard `RunService:IsRunning()`), porque em Play nada persiste — isso já causou confusão uma vez.
- Qualidade visual alta ("cinematográfica"), mas rodando em PC **e celular**.
- Avisar quanto tempo uma tarefa longa vai demorar; testar em amostra pequena antes de rodar tudo; dar retornos parciais.
- Idioma: **português**. Comentários dos scripts em português sem acentos (Luau aceita, mas manteve-se assim).

## 2. O que anexar na nova conversa

Arquivos que o usuário deve ter guardados (todos foram entregues ao longo do projeto):

| Arquivo | O que é |
|---|---|
| `invokyr_01_exportar_sala_roblox.py` | Pipeline Blender→Roblox da sala (bake + GLB + dados) |
| `invokyr_02_montar_sala.lua` | Monta a sala no Roblox (colisões, spawns, pontos de luz) |
| `invokyr_03_iluminacao_lanterna_evento.lua` (v11) | Iluminação noturna, lanterna, evento do dado, portas |
| `invokyr_04_lanterna_mao_blender.py` | Gera a lanterna com mão (viewmodel) no Blender |
| `invokyr_05_preparar_lanterna_mao.lua` | Prepara o viewmodel no Roblox |
| `invokyr_06_tabuleiro_blender.py` | Gera o tabuleiro/peça/dado no Blender |
| `invokyr_07_instalar_tabuleiro.lua` (v8) | Instala tabuleiro + fluxo E/dado/dicas |
| `invokyr_08_movimento.lua` | Andar 8, Shift corre 17 (fôlego 4 s), Ctrl agacha 4 |
| `torre_tabuleiro_v04_sem_tabuleiro.blend` | Fonte da Sala Principal |
| `Invokyr_Totens.blend` | 5 totens (Fogo, Gelo, Teleporte, Raio, Diamante Raro) |
| `carnivorous_plant_official.blend` | Monstro Planta Carnívora |
| `alligator_v2.blend` | Monstro jacaré |
| `fonte_burn_atlas.png` | Atlas da fonte Burn (já subido no Roblox: `rbxassetid://90766365321747`) |
| `burn.zip` (Burn.otf) | Fonte original, caso precise regerar o atlas |

Os GLBs (SP04_*, VM_LanternaMao, TAB_Tabuleiro) já estão importados no place do usuário; só precisam ser regerados se algo mudar.

## 3. Ambiente de trabalho (recriar na nova conversa)

- **Blender como módulo**: `pip install bpy` num venv Python 3.11 (foi usado uv em `/tmp/bv`; Blender 5.0.1). O usuário usa Blender 5.2.3, mas tudo roda aqui mesmo — ele **não abre o Blender**.
- **Validação Luau**: binário `luau-compile` (baixado do GitHub do Luau) para checar sintaxe de todo .lua antes de entregar.
- Máquina lenta (1 vCPU): bakes grandes ~20 min; o Script 01 tem **retomada** (reaproveita atlas já assados em disco por assinatura).
- Técnica dos instaladores .lua: um template com `[==[...]==]` embutindo os scripts de servidor/cliente; o instalador cria `Script`/`LocalScript` com `.Source`.

## 4. Estado atual — tudo FUNCIONANDO e testado pelo usuário

### Sala Principal (Scripts 01–03)
- 3 GLBs (Arquitetura 48 MB, Vegetação 15 MB, Objetos 14 MB), 84 malhas, texturas assadas em ~34 atlas 1024 (cor+AO, normal 512, mr 256), **metal zerado na exportação** (metal fica preto no Roblox escuro — lição importante).
- Estrutura: `Workspace > Invokyr > SalaPrincipal > {Visual, Colisao, PontosDeLuz, Spawns, Efeitos, Tabuleiro}`. Colisões invisíveis separadas do visual; 4 spawns; âncora `PontosDeLuz > AncoraLuzes` com attachments nomeados (lamparinas com atributo `Ordem`, janelas com `Direcao`, portais com `Fora`).
- Tags: `Invokyr_Chama` (chamas separadas POR lamparina: `...Lamparina_N...`), `Invokyr_Oculo`, `Invokyr_PortaVisual`, `Invokyr_PortaColisao`.
- Iluminação noturna: Technology Future, ClockTime 2.2, Ambient (9,9,12), luar frio (150,178,232) só em 2 janelas + óculo, **feixes volumétricos falsos** (3 camadas de Beam + névoa com textura + poeira iluminada), Atmosphere/ColorCorrection(-0.35 sat, contraste 0.1)/Bloom próprios `Invokyr_*`.
- Lanterna 1ª pessoa: modelo Blender com mão/manga (`ReplicatedStorage > Invokyr > LanternaMao`), 3 SpotLights (quente 20°, feixe 46°, borda 95°) + **luz rebatida** (PointLight no ponto do raycast, imita bounce), mira no centro da tela via raycast, balanço ao andar, F liga/desliga, lanterna dos outros jogadores replicada por atributos a 10 Hz.
- Evento do dado (`AtivarSala:Fire()`): tremor 4,5 s + poeira → lustre pisca e firma → lamparinas em sequência (cada uma com SUA chama) → vela → clima quente sutil (Ambient 15,13,12) → piscadas aleatórias de terror.
- Portas: giram nas dobradiças reais (atributos), tranco + abertura lenta, fundo escuro atrás some; `AbrirPortas:Fire("todas")`. Folha visual ligada à colisão **por proximidade** (importador repete nomes!).
- Teclas de teste (Studio): G dado, R reset, T portas.

### Tabuleiro (Scripts 06–07, v8)
- Caixa 3×3 studs com 4 tampas triangulares (dobradiças/sinal de abertura calculados), caminho CONTÍNUO de marfim com curvas arredondadas, 69 casas (attachments `Casa_N` em `Tabuleiro > Referencia`), fundo verde-oliva gravado, poço elevado, peça = estatueta encapuzada, dado de marfim.
- Fluxo por ProximityPrompt (`Tabuleiro > Gatilho`): Fechado →(E)→ abre+acende → Pronto →(E)→ dado rola (animação servidor: voo, giro, quique; rotação final correta pela face) → peça pula casa a casa → dica → portas abrem → Explorando. `LiberarDado:Fire()` (futuro: entrega de totens) volta a Pronto e avança a rodada.
- Rodadas: `ORDEM_MONSTROS = {"PlantaCarnivora"}` + tabela `DICAS` com 4 rimas; monstros acumulam.
- **Dica em fumaça**: letras formadas por vento (chegam esticadas da esquerda, 4 fiapos ondulando por letra, balanço contínuo por `math.noise`, transparência 0.38, rajadas de ParticleEmitter, poço brilha verde). Fonte: **atlas de imagem da fonte Burn** (`ATLAS_ID = "rbxassetid://90766365321747"`, mapa de recortes embutido no cliente; acentos desenhados à mão no estilo da fonte; se ATLAS_ID="" cai para Garamond cor pergaminho).
- Importante: todo `FindFirstChild` de peças importadas deve ser recursivo ou as peças devem ser achatadas no modelo (o importador aninha em subpastas) — isso já quebrou o E uma vez.

### Movimento (Script 08)
- Andar 8, correr 17 (Shift, fôlego 4 s, recupera 4 s, barra discreta), agachar 4 (Ctrl/C, câmera desce 1,6), FOV 70→77 correndo, botões de celular, shift lock desativado.

## 5. Modelos novos (recém-analisados, AINDA NÃO processados)

Análise feita dos .blend enviados:

| Arquivo | Conteúdo | Triângulos | Observações |
|---|---|---|---|
| `Invokyr_Totens.blend` | 5 totens em coleções (`01_Fogo`, `02_Gelo`, `03_Teleporte`, `04_Raio`, `05_Diamante_Raro`) | ~103–117k cada (533k total) | ~2,2×2,1×4,3 m cada; texturas de imagem 256 já embutidas (67 packed); malhas já agrupadas por material (lotes ≤18k tris); partes emissivas em material `*_Luminous` |
| `carnivorous_plant_official.blend` | Planta Carnívora (cena `CarnivorousPlant_Presentation`) | 1.011.330 em 3.126 objetos | Coleções CP_* (mandíbulas, dentes, língua, tentáculos, raízes...); tem animação turntable de câmera; ~7,9×5,4 m |
| `alligator_v2.blend` | Jacaré (cena `Alligator_Presentation`) | 246.752 em 454 objetos | Coleções AG_*; ~4,3×10,3 m |

**Trabalho pendente nesses modelos:** reduzir triângulos (decimate), juntar por coleção, fazer bake se preciso (os totens talvez já sirvam com as texturas de imagem que têm), exportar GLB com escala certa (os modelos estão em metros; a sala usa 1 unidade = 1 stud, conferir conversão — jogador do Roblox tem ~5 studs de altura, então um totem de 4,3 "m" importado 1:1 fica ~4,3 studs, tamanho razoável; o jacaré 10 studs de comprimento é um monstro grande, ok). Monstros vão precisar de **separação em partes articuláveis** (mandíbula, cauda) para animar por script, ou rig simples.

## 6. PRÓXIMO PASSO: o mapa da Planta Carnívora

O que foi combinado com o usuário:

1. **Mapa que muda a cada partida.** As salas trocam de posição/conexões a cada rodada de exploração (layout procedural a partir de salas pré-construídas, encaixadas por portais padronizados). Ninguém pode decorar o caminho.
2. **Ala planejada** (do contexto original do projeto): Átrio → Galeria → Arquivo → Passagem de Serviço → retorno à Sala Principal. Isso pode virar o conjunto base de salas embaralháveis.
3. **Salas exploráveis**: objetos, esconderijos, caminhos alternativos.
4. **Sala da bailarina** (destaque): estátua GIGANTE de bailarina que gira tocando música. Enquanto gira, pode andar; quando ela PARA, todos têm que congelar — quem se mexer sofre consequência (estilo "batatinha frita 1,2,3" / Squid Game). Precisa ser construída (modelo + lógica servidor detectando movimento dos jogadores).
5. **Totens**: os 5 totens espalhados em pontos sorteados; carregar de volta (mínimo 3) à Sala Principal; entrega chama `LiberarDado:Fire()`.
6. **Monstros**: Planta Carnívora na rodada 1 (dicas já escritas); jacaré como segundo monstro (adicionar em `ORDEM_MONSTROS` + escrever dicas rimadas). IA de perseguição/patrulha ainda não existe.
7. Som ainda não foi feito em nada (portas, tremor, chamas, música da bailarina) — pendência geral.

### Pendências menores conhecidas
- Pele da mão da lanterna um pouco clara/acinzentada de perto (acabamento).
- 34 atlas de cor 1024 na sala podem pesar no celular (otimização futura).
- Animações do dado/peça rodam no servidor (suaves no Studio; se travarem online, mover para o cliente).
- Agachar não reduz a colisão do personagem (só a câmera desce).

## 7. Como retomar

Sugestão de primeira mensagem na nova conversa: anexar este resumo + os arquivos da seção 2 e dizer em que etapa quer começar (ex.: "montar o ambiente e começar o mapa procedural" ou "otimizar e importar os totens e monstros"). O assistente deve recriar o ambiente (bpy + luau-compile), reinspecionar os .blend anexados e seguir as regras da seção 1.
