# NativeCore Framework

![FiveM](https://img.shields.io/badge/Platform-FiveM-orange.svg)
![Lua](https://img.shields.io/badge/Language-Lua-blue.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

**NativeCore** é uma framework moderna, modular e de alta performance para servidores FiveM. Diferente de frameworks tradicionais, o NativeCore foi projetado para ser extremamente leve e adaptável a qualquer modo de jogo (Roleplay, PvP, Survival, Race, etc).

## 🚀 Filosofia

- **Modularidade Real**: Cada sistema é um módulo independente. Remova ou substitua módulos sem quebrar o core.
- **Performance First**: Foco em baixo uso de CPU (ms) tanto no client quanto no server.
- **Independência**: Sem dependências obrigatórias de bibliotecas externas, mas com total compatibilidade via adapters.
- **Simplicidade**: API limpa e previsível para desenvolvedores.
- **Evolução Segura**: Sistema de migrations integrado para gerenciamento automático de banco de dados.

## 🛠️ Arquitetura de Configuração

A base utiliza uma estrutura modular de arquivos de configuração para manter a organização e segurança:

- `server.cfg`: Arquivo principal que orquestra o servidor.
- `permissions.cfg`: Gerenciamento centralizado de ACEs, Principals e hierarquia de cargos (Admin, Mod, Support).
- `misc.cfg`: Configurações de segurança, otimização de rede e variáveis globais do FXServer.

## 📦 Instalação via txAdmin Recipe

O NativeCore é 100% compatível com o **txAdmin Recipe Deployer**. Para instalar:

1. No txAdmin, vá em **Deployer**.
2. Selecione **Remote URL**.
3. Use o link do arquivo `nativecore.yaml` deste repositório.
4. O instalador configurará automaticamente o banco de dados, os recursos e as permissões.

## 💻 Para Desenvolvedores

### Sistema de Migrations
O framework oferece um serviço de migrations opcional. Ao registrar uma migration, o Core garante que as tabelas e alterações de banco de dados sejam aplicadas automaticamente na ordem correta.

```lua
NativeCore.DB.RegisterMigration('meu_modulo', {
    [1] = [[ CREATE TABLE IF NOT EXISTS ... ]],
    [2] = [[ ALTER TABLE ... ADD COLUMN ... ]]
})
```

### Suite de Testes
O NativeCore possui uma suite de testes integrada no módulo `[nc-tests]`.
- **Automático**: Os testes podem ser configurados para rodar automaticamente no início do servidor (`onResourceStart`).
- **Manual**: Utilize o comando `nc_test [filtro]` no console para executar testes específicos ou toda a suite.


---

*Desenvolvido com foco em liberdade e performance.*
