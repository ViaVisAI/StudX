# 📐 Архитектура Frontend StudX

## 🎯 Философия

**Модульность превыше всего** - каждый компонент решает одну задачу и делает это идеально.

### Железные правила:
- **50-100 строк максимум** на компонент - жесткое ограничение
- **Один файл = одна ответственность** - никаких монстров
- **Легко добавить/удалить/переместить** - слабая связанность
- **Самодокументируемый код** + README для каждого модуля
- **Композиция вместо наследования** - собираем из кубиков

## 📁 Структура папок

```
frontend/src/
├── layouts/                    # Контейнеры-обертки страниц
│   └── DashboardLayout/        # Админская обертка с меню
│
├── pages/                      # Страницы-контейнеры (роуты)
│   ├── OrdersPage/            # Страница списка заказов
│   └── DiagnosticsPage/       # Страница диагностики (будущее)
│
├── components/                 # Переиспользуемые компоненты
│   ├── orders/                # Компоненты заказов
│   │   ├── OrdersList/       # Список заказов
│   │   ├── OrderCard/        # Карточка заказа
│   │   └── OrderForm/        # Форма создания
│   │
│   └── ui/                    # Базовые UI элементы
│       ├── StatusBadge/       # Бейдж статуса
│       ├── Button/            # Универсальная кнопка
│       ├── Modal/             # Модальное окно
│       └── Skeleton/          # Загрузочный скелетон
│
├── services/                   # API и бизнес-логика
│   ├── api/                  # Работа с API
│   │   ├── orders.js         # Endpoints заказов
│   │   └── client.js         # Axios с retry
│   │
│   └── storage/              # Локальное хранилище
│       └── localStorage.js   # Кеширование
│
├── utils/                      # Утилиты
│   ├── formatters.js          # Форматирование данных
│   ├── validators.js          # Валидация форм
│   └── constants.js           # Константы приложения
│
├── hooks/                      # Кастомные React хуки
│   ├── useLocalStorage.js     # Работа с localStorage
│   ├── useDebounce.js         # Дебаунс для оптимизации
│   └── useErrorHandler.js     # Централизованная обработка ошибок
│
└── mocks/                      # Моковые данные для разработки
    └── orders.js              # Данные заказов
```

## 🔌 Принципы взаимодействия

### Поток данных:
```
Page (контейнер) 
  → использует hooks для данных
  → передает props в components
  → компоненты рендерят UI
  → события идут обратно через callbacks
```

### Зависимости:
- **Pages** зависят от layouts, components, hooks, services
- **Components** зависят только от ui components и utils
- **UI Components** - независимые, только props
- **Services** - независимые, только axios
- **Utils** - чистые функции без зависимостей

## 🚀 Добавление нового функционала

### Новый компонент:
1. Создать папку в правильной категории (components/ui/pages)
2. Добавить index.jsx (50-100 строк)
3. Добавить styles.css если нужны стили
4. Добавить README.md с документацией
5. Экспортировать из index.jsx

### Новая страница:
1. Создать папку в pages/
2. Добавить index.jsx с логикой страницы
3. Добавить хук useXxx.js для данных
4. Зарегистрировать роут в App.jsx
5. Добавить пункт меню в DashboardLayout

### Новый API endpoint:
1. Добавить метод в services/api/xxx.js
2. Использовать базовый client для retry
3. Добавить моковые данные в mocks/
4. Документировать в README

## ⚡ Оптимизации

### Встроенные с самого начала:
- **Error Boundaries** - приложение не падает от ошибок
- **Lazy loading** - страницы грузятся по требованию
- **Optimistic updates** - UI обновляется мгновенно
- **Skeleton loading** - понятная загрузка вместо спиннеров
- **LocalStorage cache** - работает офлайн
- **Debounced inputs** - не спамим API

## 🔧 Технические решения

### Почему так:
- **CRA вместо Vite** - стабильность и совместимость важнее скорости сборки
- **CSS модули вместо styled-components** - простота и производительность
- **Axios вместо fetch** - встроенные retry и interceptors
- **Prop-types вместо TypeScript** - быстрая разработка без overhead

### Что НЕ используем:
- **Redux/MobX** - для MVP достаточно локального стейта
- **CSS-in-JS** - оверхед для простых стилей
- **Микрофронтенды** - излишняя сложность
- **Server-side rendering** - не нужно для админки

## 📝 Стандарты кода

### Именование:
- Компоненты - PascalCase (OrderCard)
- Функции/переменные - camelCase (handleSubmit)
- Константы - UPPER_SNAKE_CASE (MAX_FILE_SIZE)
- CSS классы - kebab-case (order-card-title)

### Структура компонента:
```jsx
// 1. Импорты
import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import './styles.css';

// 2. Компонент (50-100 строк!)
function ComponentName({ prop1, prop2, onAction }) {
  // 3. Хуки
  const [state, setState] = useState(null);
  
  // 4. Эффекты
  useEffect(() => {}, []);
  
  // 5. Обработчики
  const handleClick = () => {};
  
  // 6. Рендер
  return <div>...</div>;
}

// 7. PropTypes
ComponentName.propTypes = {
  prop1: PropTypes.string.required,
  prop2: PropTypes.number,
  onAction: PropTypes.func
};

// 8. Экспорт
export default ComponentName;
```

## 🎯 Цель архитектуры

**Легко работать вдвоем без документации** - код настолько чистый и организованный, что новый разработчик поймет всё за 15 минут.

---
*Архитектура спроектирована для долгосрочной поддержки и масштабирования*