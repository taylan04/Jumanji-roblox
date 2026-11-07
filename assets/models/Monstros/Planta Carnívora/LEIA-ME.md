# Planta carnívora — versão oficial de apresentação

Abra `carnivorous_plant_official.blend` no Blender 5.2.3 LTS. A cena mantém as partes organizadas nas coleções CP_ e uma câmera com rotação de 360 graus em 240 quadros.

## Mudanças dirigidas pela referência
- Boca reconstruída: arco superior largo, contorno assimétrico, mandíbulas espessas e cavidade profunda.
- 124 dentes individuais em fileiras sobrepostas, com comprimentos e curvaturas variados.
- Gengivas e dobras carnosas, língua volumosa com ponta curva, sulco central e fios finos de saliva.
- Escamas vegetais em relevo na borda das mandíbulas e nova coroa de folhas.
- Seis cipós principais curvados, com fibras entrelaçadas, bifurcações e folhas secundárias.
- Raízes finas ramificadas conectando corpo, membros e chão.
- Tons de casca mais escuros, folhas verde-oliva e tecidos úmidos.

O torso, o bulbo posterior e os membros da V2 foram reaproveitados. As versões anteriores permanecem intactas. O script trabalha sobre uma cópia de V2 incluída em `source` e substitui somente as regiões revisadas.

## Arquivos
- `carnivorous_plant_official.blend`: modelo editável, materiais internos e referência empacotada.
- `renders/01` a `08`: oito vistas do mesmo modelo, com a mesma pose.
- `renders/09_mouth_detail.png`: câmera de detalhe da boca.
- `eight_views.jpg`: conjunto das oito vistas.
- `comparison_v2_official.jpg`: comparação com a versão 2.
- `geometry.json`: contagens de malhas, vértices, polígonos e dentes.
- `validation.json`: resultados da reabertura e verificação.
- `scripts`: revisão reproduzível, funções geométricas reutilizadas e renderização.

## Inspecionar no Blender
Numpad 0 alterna a câmera. Botão do meio orbita o modelo. Espaço reproduz a rotação. UpperJaw, LowerJaw e Tongue possuem pivôs identificados para trabalho posterior de animação.

## Execução
```powershell
& 'C:\Program Files\Blender Foundation\Blender 5.2\blender.exe' --background --python '.\scripts\refine_official.py' -- --preview
& 'C:\Program Files\Blender Foundation\Blender 5.2\blender.exe' --background --python '.\scripts\render_validate.py'
python '.\scripts\contact_sheet.py'
```

A entrega é o modelo visual para aprovação no Blender. A semelhança com a imagem deve ser avaliada pelas renderizações; o nome oficial não certifica equivalência exata à referência. Rig completo, retopologia e integração ao Roblox continuam sendo etapas de produção separadas. Não houve alterações no jogo nem commits.
