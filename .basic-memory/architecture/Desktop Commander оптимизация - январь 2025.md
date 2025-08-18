---
title: Desktop Commander оптимизация - январь 2025
type: solution
permalink: architecture/desktop-commander-2025
tags:
- '["optimization"'
- '"mcp"'
- '"desktop-commander"'
- '"token-economy"]'
---

# Desktop Commander MCP - Оптимизация для экономии токенов

## Проблема
Desktop Commander без оптимизации исчерпывал лимиты Claude Desktop за 1-2 операции из-за вывода тысяч строк.

## Решение (применено 18.01.2025)

### Критичные параметры в конфиге Claude Desktop:
```json
"desktop-commander": {
  "env": {
    "fileReadLineLimit": "200",  // было 1000
    "fileWriteLineLimit": "25",   // было 50
    "defaultShell": "/bin/zsh"
  }
}
```

### Runtime настройки (применять в начале каждого чата):
```
set_config_value("fileReadLineLimit", 200)
set_config_value("fileWriteLineLimit", 25)
set_config_value("allowedDirectories", ["/Users/mak/Documents/StudX", "/Users/mak/Documents/ALMA MATER", "/Users/mak/Downloads", "/Users/mak/tools"])
```

## Результаты
- **Чат живет в 3-5 раз дольше** (10-15 сообщений вместо 2-3)
- **Защита от потери работы** при обрыве (максимум 25 строк вместо 50+)
- **100% функциональность** сохранена

## Техническая специфика
- fileReadLineLimit: 200 = золотая середина между скоростью и экономией
- fileWriteLineLimit: 25 = оптимальный чанкинг для защиты от потерь
- НЕ работают через env: blockedCommands, allowedDirectories (только runtime)
- Массивы в env вызывают ошибку парсинга JSON

## Бэкапы конфигурации
Сохранены в `/Users/mak/Documents/StudX/backups/`:
- claude_config_backup_2025-01-18.json (оригинал)
- claude_config_FIXED_2025-01-18.json (рабочий)
- README с инструкциями

## Важно помнить
- После перезапуска Claude Desktop конфиг применяется из файла
- В текущей сессии можно менять через set_config_value
- Основной эффект от fileReadLineLimit (экономия в 5 раз)