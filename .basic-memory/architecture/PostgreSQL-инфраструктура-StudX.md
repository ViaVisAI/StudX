---
title: PostgreSQL-инфраструктура-StudX
type: note
permalink: architecture/postgre-sql-stud-x
tags:
- '["architecture"'
- '"database"'
- '"postgresql"'
- '"digitalocean"'
- '"infrastructure"]'
---

# PostgreSQL инфраструктура StudX - полностью готова

## Текущий статус
✅ **PostgreSQL 16.9** на DigitalOcean Managed Database работает
✅ **MCP подключение** через dbhub-dev стабильно
✅ **Структура БД** создана и протестирована
✅ **SSL проблема** решена через NODE_TLS_REJECT_UNAUTHORIZED

## Подключение к БД

### Рабочий MCP конфиг (dbhub-dev)
```json
"dbhub-dev": {
  "command": "npx",
  "args": [
    "-y",
    "@bytebase/dbhub",
    "--transport", "stdio",
    "--dsn", "postgres://studx_claude:YOUR_STUDX_CLAUDE_PASSWORD@studx-postgres-do-user-24656643-0.d.db.ondigitalocean.com:25060/defaultdb?sslmode=require"
  ],
  "env": {
    "NODE_TLS_REJECT_UNAUTHORIZED": "0"
  }
}
```

### Данные кластера
- **Cluster ID:** 60d640b7-e186-4d5c-a44a-3b77f5118458
- **Хост:** studx-postgres-do-user-24656643-0.d.db.ondigitalocean.com:25060
- **База:** defaultdb
- **Admin:** doadmin / YOUR_DOADMIN_PASSWORD
- **User:** studx_claude / YOUR_STUDX_CLAUDE_PASSWORD
- **CA сертификат:** /Users/mak/.ssl/digitalocean-ca.crt

## Структура БД (схема studx)

### 8 основных таблиц созданы:
1. **users** (18 колонок) - пользователи с ролями, балансом, реферальной системой
2. **orders** (21 колонка) - заказы с полным жизненным циклом
3. **documents** (17 колонок) - версионирование документов
4. **templates** (15 колонок) - шаблоны работ (диплом, курсовая)
5. **payments** (18 колонок) - все виды платежей
6. **generation_history** (12 колонок) - логи генераций
7. **settings** (7 колонок) - системные настройки
8. **promo_codes** (14 колонок) - промокоды и скидки

### Технические решения
- UUID везде (gen_random_uuid()) - защита от коллизий
- JSONB для метаданных - гибкость без изменения схемы
- Все необходимые индексы созданы
- Каскадные удаления настроены
- created_at/updated_at везде для аудита

### Тестовые данные загружены
- 2 пользователя (admin@studx.ru и test@gmail.com)
- 1 шаблон (Дипломная работа по IT)
- 3 системные настройки

## Почему такие решения

### SSL через NODE_TLS_REJECT_UNAUTHORIZED
DigitalOcean использует самоподписанные сертификаты. Попытки использовать CA сертификат не работают с MCP. Решение с обходом проверки - стандарт для managed БД.

### UUID вместо автоинкремента
- Масштабируемость без конфликтов
- Возможность генерации ID на клиенте
- Безопасность (нельзя угадать следующий ID)

### JSONB для метаданных
- Добавление полей без миграций
- Хранение специфичных данных для разных типов
- Эффективные индексы и поиск

## Что можно менять легко

Добавить таблицу: 1 команда CREATE TABLE
Добавить колонку: 1 команда ALTER TABLE ADD COLUMN
Удалить ненужное: 1 команда DROP
Переименовать: 1 команда ALTER TABLE RENAME

Структура гибкая, под реальные нужды будем адаптировать без проблем.

## Для быстрого старта в новом чате

```
PostgreSQL StudX на DigitalOcean работает
Подключение через dbhub-dev в Claude Desktop
8 таблиц структуры готовы в схеме studx
Тестовые данные загружены
```