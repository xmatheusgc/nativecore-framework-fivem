# Testes Automatizados

O NativeCore é construído com foco em confiabilidade. O módulo `[nc-tests]` fornece uma suite completa de testes unitários e de integração.

## Como Executar

### 1. Execução Manual (Recomendado para Dev)
No console do servidor (F8 ou Terminal), digite:

```bash
# Rodar todos os testes
nc_test

# Rodar apenas testes de banco de dados
nc_test db

# Rodar apenas testes de player
nc_test player
```

### 2. Auto-Run no Start
Você pode configurar o `nc-tests` para rodar automaticamente sempre que o servidor for ligado ou o recurso for reiniciado. 
Isso é configurado em `resources/[nc-tests]/nc-tests/config.lua`.

## Como Criar Novos Testes

Os testes ficam localizados em `nc-tests/server/tests/`. Um teste básico segue este padrão:

```lua
NativeCore.Test.Register('Meu Novo Teste', function(assert)
    local valor = 10
    assert.Equal(valor, 10, "O valor deve ser 10")
end)
```

### Asserts Disponíveis:
- `assert.Equal(actual, expected, msg)`
- `assert.NotEqual(actual, expected, msg)`
- `assert.True(val, msg)`
- `assert.False(val, msg)`
- `assert.Nil(val, msg)`
- `assert.NotNil(val, msg)`

## Por que testar?
O NativeCore incentiva o uso de **TDD (Test Driven Development)**. Ao criar um novo módulo, crie um arquivo de teste correspondente para garantir que atualizações futuras no Core não quebrem a sua lógica de negócio.
