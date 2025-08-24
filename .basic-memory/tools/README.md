# 📚 CODE-QUALITY TROUBLESHOOTING INDEX

**Путь системы:** `/Users/mak/tools/code-quality`  
**Основные компоненты:** Backend, Frontend, Scripts, Infrastructure

---

## 🔧 КОМПОНЕНТЫ И РЕШЕНИЯ

### 1. [Syntax Watcher](./syntax-watcher-fix.md)
**Статус:** ✅ Решение готово  
**Симптомы:** Кнопки не работают, Failed to start script  
**Время решения:** 5 минут  
**Последний фикс:** 24.08.2025

### 2. Context7 Version Checker
**Статус:** 🟡 В разработке  
**Симптомы:** Неправильные версии, блокировка коммитов  
**Файл:** (будет добавлен при необходимости)

### 3. SonarQube Integration
**Статус:** 🟡 В разработке  
**Симптомы:** Proxy ошибки, порт 8891  
**Файл:** (будет добавлен при необходимости)

---

## ⚡ БЫСТРЫЕ КОМАНДЫ

### Диагностика системы:
```bash
# Проверить все порты
lsof -i:3001  # Frontend
lsof -i:3002  # Backend
lsof -i:8890  # Syntax Watcher
lsof -i:8891  # SonarQube

# Проверить процессы
ps aux | grep -E "(npm|node|python)" | grep -E "(3001|3002|8890)"
```

### Полный перезапуск системы:
```bash
# 1. Убить все процессы
pkill -f "npm start"
pkill -f "syntax-watcher"
lsof -ti:3001,3002,8890,8891 | xargs kill -9

# 2. Очистить временные файлы
rm -f /tmp/syntax*.* /tmp/*.pid

# 3. Запустить Frontend (порт 3001)
cd /Users/mak/tools/code-quality/frontend
nohup npm start > frontend.log 2>&1 &

# 4. Запустить Backend (порт 3002)
cd /Users/mak/tools/code-quality/backend
nohup npm start > backend.log 2>&1 &

# 5. Запустить Syntax Watcher
cd /Users/mak/tools/syntax-watcher
bash start-syntax-watcher.sh
```

---

## 📁 СТРУКТУРА ПАМЯТИ

```
.basic-memory/tools/
├── README.md (этот файл)
├── syntax-watcher-fix.md
├── context7-fix.md (будущее)
├── sonarqube-fix.md (будущее)
└── backend-fix.md (будущее)
```

---

## 🏷️ ТЕГИ ДЛЯ ПОИСКА

`code-quality`, `troubleshooting`, `syntax-watcher`, `context7`, `sonarqube`, `backend`, `frontend`, `порты`, `процессы`, `failed-to-start`

---
*Последнее обновление: 24.08.2025*