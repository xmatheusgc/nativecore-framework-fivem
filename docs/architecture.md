# Arquitetura do NativeCore

O NativeCore foi projetado para ser modular e organizado, separando as responsabilidades de sistema, configurações e gameplay.

## Estrutura de Pastas

```txt
txData/FiveMBasicServerCFXDefault_F64CFE.base/
├── docs/               # Documentação técnica
├── resources/
│   ├── [nativecore]/   # Recursos núcleo do framework
│   ├── [nc-tests]/     # Suite de testes automatizados
│   ├── [ox]/           # Dependências (oxmysql, etc)
│   ├── [managers]/     # Gerenciadores de mapa e spawn
│   └── [system]/       # Recursos base do FXServer
├── server.cfg.example  # Template de configuração
├── permissions.cfg     # Gestão de ACE/Principal
└── misc.cfg            # Configurações de segurança e rede
```

## Sistema de Configuração Modular

Em vez de um único arquivo `server.cfg` gigante, dividimos a lógica:

### 1. server.cfg
É o orquestrador. Ele define o nome do servidor, slots, build e faz o `exec` dos outros módulos de configuração.

### 2. permissions.cfg
Focado exclusivamente em segurança e hierarquia.
- Define quem é `group.admin`, `group.mod`, etc.
- Gerencia herança de cargos (ex: Admin herda de Mod).
- Define quais comandos cada cargo ou recurso pode executar.

### 3. misc.cfg
Contém convars de "baixo nível" que otimizam a performance e segurança:
- Filtros de eventos de rede.
- Configurações de Pure Level.
- Otimizações de reassembly de rede.

## Ordem de Inicialização Recomendada

O framework deve sempre carregar as dependências de banco de dados antes do core:
1. `oxmysql`
2. `[nativecore]`
3. `[your-resources]` (Seus scripts)
