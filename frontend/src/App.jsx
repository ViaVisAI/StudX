import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import DashboardLayout from './layouts/DashboardLayout';
import OrdersPage from './pages/OrdersPage';
import HomePage from './pages/HomePage';
import './App.css';

function App() {
  return (
    <Router>
      <div className="App">
        <Routes>
          {/* Публичные страницы */}
          <Route path="/" element={<HomePage />} />
          
          {/* Админ-панель с вложенными роутами */}
          <Route path="/admin" element={<DashboardLayout />}>
            <Route index element={<Navigate to="/admin/orders" replace />} />
            <Route path="orders" element={<OrdersPage />} />
            <Route path="diagnostics" element={
              <div style={{ padding: '2rem' }}>
                <h2>Диагностика системы</h2>
                <p>Раздел в разработке...</p>
              </div>
            } />
            <Route path="settings" element={
              <div style={{ padding: '2rem' }}>
                <h2>Настройки</h2>
                <p>Раздел в разработке...</p>
              </div>
            } />
          </Route>
          
          {/* Обработка несуществующих маршрутов */}
          <Route path="*" element={
            <div style={{ padding: '2rem', textAlign: 'center' }}>
              <h1>404</h1>
              <p>Страница не найдена</p>
              <a href="/">Вернуться на главную</a>
            </div>
          } />
        </Routes>
      </div>
    </Router>
  );
}

export default App;