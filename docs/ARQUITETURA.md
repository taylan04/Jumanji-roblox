# Arquitetura inicial

- **server:** servidor autoritativo, gerador de mapa, validação de interações, turnos e dado.
- **client:** interface do jogador e módulos preparados para câmera e efeitos.
- **shared:** configuração e tipos compartilhados.
- **ServerScriptService/GameScripts:** recebe src/server via Script Sync.
- **StarterPlayerScripts/GameClient:** recebe src/client via Script Sync.
- **ReplicatedStorage/Shared:** recebe src/shared via Script Sync.
- **ReplicatedStorage/Remotes/GameEvent:** criado pelo Bootstrap do servidor.
- **Workspace/GeneratedPrototype:** sala gerada automaticamente durante o Play.

O dado é sorteado no servidor; o cliente recebe somente o resultado. Os turnos são compartilhados na instância do servidor. Ainda não há partidas isoladas, grupos, monstros ou persistência.
