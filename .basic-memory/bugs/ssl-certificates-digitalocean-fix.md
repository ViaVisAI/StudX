---
title: ssl-certificates-digitalocean-fix
type: solution
permalink: bugs/ssl-certificates-digitalocean-fix
tags:
- '["ssl"'
- '"postgresql"'
- '"digitalocean"'
- '"mcp"'
- '"solution"]'
---

# Решение: SSL сертификаты DigitalOcean Managed PostgreSQL

## Проблема
DigitalOcean Managed PostgreSQL использует самоподписанные SSL сертификаты, что вызывает ошибку:
```
self-signed certificate in certificate chain
```

## Универсальное решение для любых MCP

### Рабочий вариант через NODE_TLS_REJECT_UNAUTHORIZED
```json
"mcp-name": {
  "command": "npx",
  "args": [
    "-y",
    "@package/name",
    "--transport", "stdio",
    "--dsn", "postgres://user:pass@host:port/db?sslmode=require"
  ],
  "env": {
    "NODE_TLS_REJECT_UNAUTHORIZED": "0"
  }
}
```

### Альтернативные решения

**1. Через CA сертификат (если нужна полная верификация):**
```json
"env": {
  "NODE_EXTRA_CA_CERTS": "/path/to/digitalocean-ca.crt"
}
```

**2. Отключение SSL (только для dev):**
```
?sslmode=disable
```

**3. SSL без верификации:**
```
?sslmode=require с NODE_TLS_REJECT_UNAUTHORIZED=0
```

## Проверенные MCP которые работают

- **@bytebase/dbhub** ✅ Работает с NODE_TLS_REJECT_UNAUTHORIZED
- **@modelcontextprotocol/server-postgres** ✅ Работает с NODE_TLS_REJECT_UNAUTHORIZED  
- **@neondatabase/mcp-server-postgres** ✅ Работает с NODE_TLS_REJECT_UNAUTHORIZED

## Диагностика проблем

### Проверка подключения без MCP:
```bash
psql "postgresql://user:pass@host:port/db?sslmode=require"
```

### Логи Claude Desktop (macOS):
```bash
tail -f ~/Library/Logs/Claude/mcp*.log
```

### Проверка JSON синтаксиса конфига:
```bash
python3 -m json.tool ~/Library/Application\ Support/Claude/claude_desktop_config.json
```

## Почему NODE_TLS_REJECT_UNAUTHORIZED безопасно для managed БД

1. Подключение и так идет через зашифрованный канал (TLS)
2. Managed база находится в защищенной инфраструктуре DigitalOcean
3. Мы просто отключаем проверку сертификата, не отключая шифрование
4. Это стандартная практика для managed баз с самоподписанными сертификатами

## Важно помнить

- После изменения конфига нужен полный перезапуск Claude (Cmd+Q)
- Проверить что в Trusted Sources добавлен ваш IP или 0.0.0.0/0
- CA сертификат можно скачать через DigitalOcean API или веб-интерфейс

---
*Проверенное решение на StudX проекте*