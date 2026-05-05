# Referência da API (V1)

O NativeCore expõe suas funções através de **Exports** e de um objeto global após o import.

## Player Management

### Server-Side
```lua
-- Obter objeto do jogador pelo source
local player = NativeCore.Player.Get(source)

-- Atributos do objeto player
print(player.identifier)
print(player.group)

-- Métodos do objeto player
player.SetGroup('admin')
player.Save()
```

### Client-Side
```lua
-- Obter dados do próprio jogador local
local playerData = NativeCore.Player.GetPlayerData()
print(playerData.identifier)
```

---

## RPC & Callbacks

O sistema de Callbacks permite que o Client peça informações ao Server e aguarde a resposta (ou vice-versa) sem travar a thread.

### Client pedindo ao Server
```lua
-- Client
NativeCore.Callback.Trigger('nc:getPlayerData', function(data)
    print("Dados recebidos:", data)
end, param1, param2)

-- Server (Registro)
NativeCore.Callback.Register('nc:getPlayerData', function(source, cb, p1, p2)
    local data = { name = "Teste" }
    cb(data)
end)
```

---

## Event Bus

Wrappers otimizados para eventos de rede e locais.

### Eventos de Rede
```lua
-- Server disparando para Client específico
NativeCore.Events.TriggerClient('nc:notify', source, "Mensagem")

-- Client ouvindo
NativeCore.Events.OnNet('nc:notify', function(msg)
    print("Notificação:", msg)
end)
```

---

## Utils & Shared

Funções utilitárias comuns disponíveis em ambos os lados:

```lua
-- Debug de tabelas
NativeCore.Utils.Dump(minha_tabela)

-- Geração de ID único
local uuid = NativeCore.Utils.GenerateUUID()
```
