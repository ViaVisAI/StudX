# 🚨 CODE-QUALITY: SYNTAX WATCHER - БЫСТРОЕ РЕШЕНИЕ ПРОБЛЕМ

**Компонент:** Syntax Watcher  
**Путь:** `/Users/mak/tools/syntax-watcher`  
**Последний фикс:** 24.08.2025 | Время восстановления: 14 минут

## СИМПТОМЫ
- ❌ Кнопки "Запустить/Остановить" не работают в UI
- ❌ "Failed to start script" при попытке запуска
- ❌ Статус показывает active, но реально не работает
- ❌ API на localhost:8890 возвращает "Route not found"

## КОРНЕВЫЕ ПРИЧИНЫ
1. **Конфликт портов** - зомби-процессы на портах 8890 и 3002
2. **Мертвые PID файлы** - /tmp/syntax-status-server.pid с убитыми процессами
3. **Backend не работает** - порт 3002 занят другим процессом
4. **Неправильная версия** - запускается старый сервер вместо v2

## ⚡ БЫСТРОЕ РЕШЕНИЕ (5 минут)

```bash
# 1. УБИТЬ ВСЕ ПРОЦЕССЫ (30 сек)
lsof -ti:8890 | xargs kill -9
lsof -ti:3002 | xargs kill -9
pkill -f "syntax-watcher"
pkill -f "syntax-status-server"

# 2. ОЧИСТИТЬ МУСОР (10 сек)
rm -f /tmp/syntax-status-server.pid
rm -f /tmp/syntax_watcher_status.json
rm -f /tmp/syntax-server.log

# 3. ЗАПУСТИТЬ BACKEND (1 мин)
cd /Users/mak/tools/code-quality/backend
nohup npm start > backend.log 2>&1 &
sleep 3
curl http://localhost:3002/health  # Проверка

# 4. ЗАПУСТИТЬ SYNTAX WATCHER (1 мин)
cd /Users/mak/tools/syntax-watcher
bash start-syntax-watcher.sh

# 5. ПРОВЕРИТЬ РАБОТУ (30 сек)
curl -s http://localhost:8890/status | grep "РЕАЛЬНО РАБОТАЕТ"
```

## 🔍 ДИАГНОСТИКА

### Проверка портов:
```bash
lsof -i:8890  # Должен быть Python (syntax-status-server-v2)
lsof -i:3002  # Должен быть Node (backend)
```

### Проверка процессов:
```bash
ps aux | grep -E "(syntax|fswatch)" | grep -v grep
# Должны быть: fswatch, watch-syntax.sh, python3 syntax-status-server-v2.py
```

### Проверка API:
```bash
# Backend health
curl http://localhost:3002/health

# Syntax Watcher status
curl http://localhost:8890/status | python3 -m json.tool
```

## 📁 КРИТИЧЕСКИЕ ФАЙЛЫ

### Конфигурация:
- `/Users/mak/tools/code-quality/backend/src/services/scriptRegistry.js` - настройки всех скриптов
- `/Users/mak/tools/syntax-watcher/start-syntax-watcher.sh` - главный скрипт запуска
- `/Users/mak/tools/syntax-watcher/start-status-server.sh` - запуск v2 сервера

### PID и статус:
- `/tmp/syntax-status-server.pid` - PID файл сервера
- `/tmp/syntax_watcher_status.json` - статус файл
- `/tmp/syntax-watcher.log` - основной лог

### Проверка версии:
```bash
# ДОЛЖЕН вызывать start-status-server.sh, НЕ syntax-status-server.py напрямую
grep "start-status-server.sh" /Users/mak/tools/syntax-watcher/start-syntax-watcher.sh
```

## 🧪 ТЕСТИРОВАНИЕ ПОСЛЕ ФИКСА

### Создать файл с ошибкой:
```bash
echo 'const test = {a: 1' > /Users/mak/tools/test-error.js
sleep 2
curl -s http://localhost:8890/status | grep "errors"
rm /Users/mak/tools/test-error.js
```

### Проверить через UI:
1. Открыть http://localhost:3001/background-scripts
2. Блок "Syntax Watcher" должен показывать ✅ active
3. Кнопки "Остановить" и "Перезапустить" должны работать

## 📊 ПОДДЕРЖИВАЕМЫЕ ЯЗЫКИ (8)

1. **JavaScript** (.js) - через Node.js parser
2. **React/JSX** (.jsx) - через Babel parser
3. **TypeScript** (.ts) - через Babel parser
4. **React+TS** (.tsx) - через Babel parser
5. **Python** (.py) - через py_compile + pylint
6. **HTML+JS** (.html) - извлечение и проверка JS фрагментов
7. **JSON** (.json) - через python json.tool
8. **SQL** (.sql) - через sqlite3 + check_sql_syntax.py

## 📍 МОНИТОРИТ ДИРЕКТОРИИ

```bash
# Проверка активного мониторинга
ps aux | grep fswatch
# Должно показать: fswatch ... /Users/mak/Documents/StudX/StudX /Users/mak/tools
```

- `/Users/mak/Documents/StudX/StudX` - основной проект
- `/Users/mak/tools` - инструменты и утилиты

## 🚨 ЕСЛИ НЕ ПОМОГЛО

### 1. Проверить логи backend:
```bash
tail -100 /Users/mak/tools/code-quality/backend/backend.log | grep -E "error|ERROR"
```

### 2. Проверить логи watcher:
```bash
tail -100 /tmp/syntax-watcher.log | grep -E "❌|ERROR"
```

### 3. Убедиться в версии v2:
```bash
# Должен существовать файл
ls -la /Users/mak/tools/syntax-watcher/syntax-status-server-v2.py

# start-status-server.sh должен запускать v2
cat /Users/mak/tools/syntax-watcher/start-status-server.sh | grep v2
```

### 4. Полная переустановка:
```bash
cd /Users/mak/tools/syntax-watcher
npm install  # Установить зависимости для Babel parser
```

## 🏷️ ТЕГИ
syntax-watcher, failed-to-start, кнопки-не-работают, порт-8890, порт-3002, code-quality, background-scripts

---
*Последнее обновление: 24.08.2025 23:45*