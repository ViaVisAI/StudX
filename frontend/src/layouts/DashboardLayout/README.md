# DashboardLayout

## Назначение
Основной layout для админ-панели с боковым меню и областью контента

## Использование
```jsx
// В App.jsx
import DashboardLayout from './layouts/DashboardLayout';

<Route path="/admin" element={<DashboardLayout />}>
  <Route path="orders" element={<OrdersPage />} />
  <Route path="diagnostics" element={<DiagnosticsPage />} />
</Route>
```

## Props
- `user` (object, optional) - информация о текущем пользователе
  - `name` (string) - имя пользователя
  - `role` (string) - роль пользователя

## Структура
- **Sidebar** - навигационное меню слева
- **Header** - заголовок текущей страницы
- **Content** - область для дочерних роутов (Outlet)

## Особенности
- Автоматическое определение активного пункта меню
- Адаптивность для мобильных устройств
- Поддержка информации о пользователе для будущей авторизации

## Зависимости
- react-router-dom (NavLink, Outlet, useLocation)
- DashboardLayout.css для стилей

## Используется в
- App.jsx как обертка для админских страниц