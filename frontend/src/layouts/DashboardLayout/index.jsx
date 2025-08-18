import React from 'react';
import PropTypes from 'prop-types';
import { Outlet, NavLink, useLocation } from 'react-router-dom';
import './DashboardLayout.css';

function DashboardLayout({ user = null }) {
  const location = useLocation();
  
  // Навигационные пункты админки
  const menuItems = [
    { path: '/admin/orders', label: 'Заказы', icon: '📋' },
    { path: '/admin/diagnostics', label: 'Диагностика', icon: '🔍' },
    { path: '/admin/settings', label: 'Настройки', icon: '⚙️' }
  ];

  return (
    <div className="dashboard-layout">
      <aside className="dashboard-sidebar">
        <div className="sidebar-header">
          <h2>StudX Admin</h2>
          <span className="version">v0.0.1</span>
        </div>
        
        <nav className="sidebar-nav">
          {menuItems.map(item => (
            <NavLink
              key={item.path}
              to={item.path}
              className={({ isActive }) => 
                `nav-item ${isActive ? 'active' : ''}`
              }
            >
              <span className="nav-icon">{item.icon}</span>
              <span className="nav-label">{item.label}</span>
            </NavLink>
          ))}
        </nav>
        
        <div className="sidebar-footer">
          {user && (
            <div className="user-info">
              <span className="user-name">{user.name || 'Админ'}</span>
            </div>
          )}
        </div>
      </aside>
      
      <main className="dashboard-main">
        <header className="dashboard-header">
          <h1>{getCurrentPageTitle(location.pathname)}</h1>
          <div className="header-actions">
            <button className="btn-refresh" onClick={() => window.location.reload()}>
              🔄 Обновить
            </button>
          </div>
        </header>
        
        <div className="dashboard-content">
          <Outlet />
        </div>
      </main>
    </div>
  );
}

// Утилита для получения заголовка страницы
function getCurrentPageTitle(pathname) {
  const titles = {
    '/admin/orders': 'Управление заказами',
    '/admin/diagnostics': 'Диагностика системы',
    '/admin/settings': 'Настройки'
  };
  return titles[pathname] || 'Админ-панель';
}

DashboardLayout.propTypes = {
  user: PropTypes.shape({
    name: PropTypes.string,
    role: PropTypes.string
  })
};

export default DashboardLayout;