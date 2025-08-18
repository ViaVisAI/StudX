import React from 'react';
import PropTypes from 'prop-types';
import OrderCard from '../OrderCard';
import Skeleton from '../../ui/Skeleton';
import './OrdersList.css';

function OrdersList({ orders = [], loading, onOrderClick, onStatusChange }) {
  // Группировка заказов по статусу для удобства
  const groupedOrders = groupOrdersByStatus(orders);
  
  if (loading && orders.length === 0) {
    return (
      <div className="orders-list loading">
        {[1, 2, 3].map(i => (
          <Skeleton key={i} height="120px" />
        ))}
      </div>
    );
  }

  if (!loading && orders.length === 0) {
    return (
      <div className="orders-list empty">
        <div className="empty-state">
          <span className="empty-icon">📋</span>
          <h3>Нет заказов</h3>
          <p>Создайте первый заказ, чтобы начать работу</p>
        </div>
      </div>
    );
  }

  return (
    <div className="orders-list">
      {Object.entries(groupedOrders).map(([status, statusOrders]) => (
        <div key={status} className="orders-group">
          <h3 className="group-title">
            {getStatusTitle(status)} ({statusOrders.length})
          </h3>
          <div className="orders-grid">
            {statusOrders.map(order => (
              <OrderCard
                key={order.id}
                order={order}
                onClick={() => onOrderClick(order)}
                onStatusChange={(newStatus) => onStatusChange(order.id, newStatus)}
              />
            ))}
          </div>
        </div>
      ))}
      
      {loading && orders.length > 0 && (
        <div className="loading-more">
          <Skeleton height="120px" />
        </div>
      )}
    </div>
  );
}

// Группировка заказов по статусу
function groupOrdersByStatus(orders) {
  return orders.reduce((groups, order) => {
    const status = order.status || 'draft';
    if (!groups[status]) groups[status] = [];
    groups[status].push(order);
    return groups;
  }, {});
}

// Получение заголовка для статуса
function getStatusTitle(status) {
  const titles = {
    draft: '📝 Черновики',
    pending: '⏳ В ожидании',
    in_progress: '🔄 В работе',
    completed: '✅ Завершенные',
    cancelled: '❌ Отмененные'
  };
  return titles[status] || status;
}

OrdersList.propTypes = {
  orders: PropTypes.arrayOf(PropTypes.object),
  loading: PropTypes.bool,
  onOrderClick: PropTypes.func,
  onStatusChange: PropTypes.func
};

export default OrdersList;