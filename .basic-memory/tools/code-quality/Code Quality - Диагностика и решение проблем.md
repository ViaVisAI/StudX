---
title: Code Quality - Диагностика и решение проблем
type: troubleshooting
permalink: tools/code-quality/code-quality
tags:
- '["code-quality"'
- '"sonarqube"'
- '"debugging"'
- '"tools"'
- '"proxy"'
- '"backend"]'
---

# Code Quality System - Диагностика и решение проблем

## 📍 Путь проекта
`/Users/mak/tools/code-quality`

## 🏗️ Архитектура системы

```
Frontend (3001) → Proxy Server (3002) → Backend API (8891) → SonarQube API
```

### Компоненты:
1. **Frontend** - React приложение на порту 3001
2. **Proxy Server** - proxy-server.js на порту 3002
3. **Backend API** - src/index.js на порту 8891
4. **SonarQube** - внешний API (https://code.studx.ru/sonarqube)

## ❌ Частая проблема: знаки вопроса вместо данных

### Симптомы:
- В UI показываются знаки ?????? вместо метрик
- В логах ошибки ECONNREFUSED на порт 8891
- Backend API не отвечает на запросы

### Корень проблемы:
**Backend API (src/index.js) не запущен!** Proxy пытается проксировать на пустой порт 8891.

### Решение:

#### 1. Быстрая диагностика:
```bash
# Проверить процессы
ps aux | grep -E "node|npm" | grep code-quality

# Должно быть 3 процесса:
# - node index.js (API на 8891)
# - node proxy-server.js (Proxy на 3002)
# - react-scripts start (Frontend на 3001)

# Проверить порт 8891
lsof -i :8891
# Если пусто = API не запущен
```

#### 2. Использовать health-check скрипт:
```bash
cd /Users/mak/tools/code-quality
./scripts/health-check.sh
```

#### 3. Полный перезапуск системы:
```bash
# Убить все процессы
pkill -f "code-quality\|react-scripts"
sleep 2

# Запустить заново
cd /Users/mak/tools/code-quality
./scripts/start.sh
```

## 🔧 Структура скриптов

### scripts/start.sh
Правильный порядок запуска:
1. Освобождение портов (3001, 3002, 8891)
2. Запуск Backend API на 8891 (`cd backend/src && PORT=8891 node index.js`)
3. Запуск Proxy Server на 3002 (`cd backend && npm start`)
4. Запуск Frontend на 3001 (`cd frontend && npm start`)

### scripts/health-check.sh
Проверяет:
- ✅ Все порты активны
- ✅ Все процессы запущены
- ✅ Связь Proxy → API
- ✅ Связь API → SonarQube
- ✅ Последние ошибки в логах

## 📝 Конфигурация

### backend/.env
```env
PORT=3002  # для proxy-server.js
SONARQUBE_URL=https://code.studx.ru/sonarqube
SONARQUBE_TOKEN=squ_1b77a66d64510f11fdb24f70b9b76d0395eb75b3
SONARQUBE_PROJECT_KEY=studx
```

### backend/src/config.js
Важно! Должен читать .env из правильного пути:
```javascript
const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../.env') });
```

## 🐛 Другие известные проблемы

### Проблема: Конфликт портов
**Симптом:** EADDRINUSE: address already in use :::8891

**Решение:**
```bash
# Найти процесс
lsof -i :8891

# Убить процесс
kill -9 <PID>

# Или использовать start.sh (автоматически освобождает порты)
```

### Проблема: SonarQube не отвечает
**Симптом:** Failed to fetch metrics from SonarQube

**Решение:**
1. Проверить доступность: `curl -I https://code.studx.ru/sonarqube`
2. Проверить токен в .env
3. Проверить логи: `tail -f backend/backend.log`

### Проблема: Неправильная конфигурация
**Симптом:** API использует localhost:9000 вместо внешнего SonarQube

**Решение:**
Проверить что config.js читает .env из правильного пути (см. выше)

## 📊 Мониторинг

### Логи
- Backend лог: `/Users/mak/tools/code-quality/backend/backend.log`
- Консоль браузера для Frontend ошибок

### Проверка API
```bash
# Health check прокси
curl http://localhost:3002/health

# Health check API
curl http://localhost:8891/api/health

# Метрики
curl http://localhost:8891/api/sonarqube/measures/component?component=studx&metricKeys=bugs
```

## 🚀 Git коммиты после исправлений

После любых исправлений:
```bash
cd /Users/mak/tools/code-quality
git add -A
git commit -m "fix: описание исправления"
git push origin main
```

## 📌 Важные файлы

- `/scripts/start.sh` - запуск системы
- `/scripts/health-check.sh` - диагностика
- `/backend/proxy-server.js` - прокси сервер (3002)
- `/backend/src/index.js` - основной API (8891)
- `/backend/src/config.js` - конфигурация
- `/backend/.env` - переменные окружения

---
*Последнее обновление: 24.08.2025*
*Автор: Claude (MCP StudX)*