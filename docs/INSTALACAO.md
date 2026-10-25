# Instalação rápida

1. No GitHub Desktop: **Fetch origin > Pull origin**. Abra o repositório no VS Code.
2. No Roblox Studio, abra seu Baseplate e salve um backup **.rbxl**.
3. Abra a **Barra de Comandos** e cole o conteúdo de `tools/studio-setup-command.luau`. Execute fora do modo Play.
4. No **Explorador** do Studio, clique com botão direito nas pastas abaixo e use **Sincronizar para… (Sync to...)**:

| Studio | Pasta local |
|---|---|
| ServerScriptService/GameScripts | src/server |
| ReplicatedStorage/Shared | src/shared |
| StarterPlayer/StarterPlayerScripts/GameClient | src/client |

5. Revise possíveis conflitos da sincronização antes de sobrescrever qualquer arquivo. Os arquivos `.server.luau` viram Script, `.local.luau` viram LocalScript e os demais `.luau` viram ModuleScript.
6. Pressione **F5**. Deve aparecer uma sala com tabuleiro. Aproxime-se e pressione **E** para lançar o dado.
7. Teste a alternância de turnos com **Teste > Servidor e Clientes**, usando dois jogadores.
8. Se algo falhar, abra **Saída (Output)** e confira a mensagem de erro.

**Limitações:** sem lobby, monstros ou economia nesta versão. Mapas gerados em tempo de execução não ficam salvos após Parar.

Documentação oficial: https://create.roblox.com/docs/pt-br/scripting/sync
