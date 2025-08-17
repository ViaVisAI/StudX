---
title: React-архитектура-StudX
type: architecture
permalink: architecture/react-stud-x
tags:
- '["react"'
- '"architecture"'
- '"решение"'
- '"frontend"]'
---

# Архитектурное решение: React вместо HTML

## Контекст
Изначально планировали простой HTML для скорости. Но обнаружили что React 18.3 и вся инфраструктура УЖЕ настроены через Create React App.

## Решение
Остаемся на React - переделка на HTML = выброс готовой инфраструктуры.

## Что уже создано
```
/frontend/src/
  ├── index.js          # Точка входа
  ├── App.jsx           # Роутинг на React Router 6
  ├── /services/
  │   └── api.js        # Axios с retry механизмом (3 попытки)
  └── /pages/
      └── HomePage.jsx  # Главная страница
```

## Технические решения
1. **Retry механизм в API** - автоматически повторяет запросы при сбоях
2. **React Router 6** для навигации (уже установлен)
3. **Proxy на backend:5000** настроен в package.json
4. **Структура папок** для масштабирования

## НЕ делаем
- TypeScript (избыточно для малой команды)
- Redux (Context API достаточно)
- SSR/Next.js (SEO не критично для генератора)
- Микрофронтенды (оверинжиниринг)

## Запуск
```bash
cd /Users/mak/Documents/StudX/StudX/frontend
npm start
# Откроется localhost:3000
```

## Статус
✅ React приложение готово к запуску
✅ Базовая структура создана
⏳ Ждем добавления функционала