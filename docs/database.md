# Gerenciamento de Banco de Dados

O NativeCore utiliza o `oxmysql` como driver padrão e oferece um sistema de **Migrations** para garantir que o seu banco de dados esteja sempre sincronizado com o código.

## Migrations Automáticas

As migrations eliminam a necessidade de enviar arquivos `.sql` manuais para seus usuários. Quando o seu recurso inicia, o Core verifica se a tabela ou alteração já existe.

### Como Registrar uma Migration

No seu script de servidor (server-side):

```lua
NativeCore.DB.RegisterMigration('nome_do_recurso', {
    [1] = [[
        CREATE TABLE IF NOT EXISTS `nc_players` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `identifier` VARCHAR(60) NOT NULL,
            `group` VARCHAR(50) DEFAULT 'user',
            `money` LONGTEXT DEFAULT '{}',
            UNIQUE KEY (`identifier`)
        );
    ]],
    [2] = [[
        ALTER TABLE `nc_players` ADD COLUMN `last_login` TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
    ]]
})
```

### Regras das Migrations:
- **Indexação**: Os índices (`[1]`, `[2]`) devem ser sequenciais. O Core salva a última versão executada na tabela `nc_migrations`.
- **Idempotência**: Sempre use `IF NOT EXISTS` quando possível, embora o sistema de versões já evite a re-execução.
- **Opcional**: Você não é obrigado a usar este sistema, mas ele é altamente recomendado para módulos que pretendem ser distribuídos.

## Consultas ao Banco (API)

O framework expõe wrappers simplificados para o `oxmysql`:

### Async/Await (Recomendado)
```lua
-- Buscar um jogador
local result = NativeCore.DB.FetchOne('SELECT * FROM nc_players WHERE identifier = ?', { identifier })

-- Inserir dados
local insertId = NativeCore.DB.Insert('INSERT INTO nc_players (identifier) VALUES (?)', { identifier })
```

### Transações
Para operações complexas que dependem umas das outras:
```lua
local success = NativeCore.DB.Transaction({
    { query = 'UPDATE accounts SET money = money - ? WHERE id = ?', values = { 100, 1 } },
    { query = 'INSERT INTO logs (action) VALUES (?)', values = { 'buy_item' } }
})
```
