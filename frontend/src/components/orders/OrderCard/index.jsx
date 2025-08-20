import React from 'react';
import PropTypes from 'prop-types';
import StatusBadge from '../../ui/StatusBadge';
import Button from '../../ui/Button';
import { formatDate, formatPrice } from '../../../utils/formatters';
import './OrderCard.css';

function OrderCard({ order, onClick, onStatusChange }) {
  const handleStatusChange = (e, newStatus) => {
    e.stopPropagation(); // Не триггерить onClick карточки
    
    // Подтверждение для критичных статусов
    if (newStatus === 'cancelled') {
      if (!window.confirm('Отменить заказ? Это действие необратимо.')) {
        return;
      }
    }
    
    onStatusChange(newStatus);
  };

  // Доступные переходы статусов
  const getAvailableActions = (currentStatus) => {
    const transitions = {
      draft: ['pending', 'cancelled'],
      pending: ['in_progress', 'cancelled'],
      in_progress: ['completed', 'cancelled'],
      completed: [],
      cancelled: []
    };
    return transitions[currentStatus] || [];
  };

  const actions = getAvailableActions(order.status);

  return (
    <div 
      className={`order-card status-${order.status}`} 
      onClick={onClick}
      onKeyPress={(e) => {
        if (e.key === 'Enter' || e.key === ' ') {
          e.preventDefault();
          onClick(e);
        }
      }}
      tabIndex={0}
      role="button"
      aria-label={`Карточка заказа ${order.orderNumber || order.id}`}
    >
      <div className="order-header">
        <span className="order-number">#{order.orderNumber || order.id}</span>
        <StatusBadge status={order.status} />
      </div>
      
      <div className="order-body">
        <h4 className="order-title">{order.type || 'Без типа'}</h4>
        <p className="order-topic">{order.topic || 'Тема не указана'}</p>
        
        <div className="order-meta">
          <span className="order-date">
            📅 {formatDate(order.createdAt)}
          </span>
          {order.price && (
            <span className="order-price">
              💰 {formatPrice(order.price)}
            </span>
          )}
        </div>
      </div>
      
      {actions.length > 0 && (
        <div 
          className="order-actions" 
          onClick={e => e.stopPropagation()}
          onKeyPress={e => e.stopPropagation()}
        >
          {actions.map(action => (
            <Button
              key={action}
              size="small"
              variant={action === 'cancelled' ? 'danger' : 'secondary'}
              onClick={(e) => handleStatusChange(e, action)}
            >
              {getActionLabel(action)}
            </Button>
          ))}
        </div>
      )}
    </div>
  );
}

// Получение текста для кнопки действия
function getActionLabel(action) {
  const labels = {
    pending: 'В ожидание',
    in_progress: 'В работу',
    completed: 'Завершить',
    cancelled: 'Отменить'
  };
  return labels[action] || action;
}

OrderCard.propTypes = {
  order: PropTypes.shape({
    id: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired,
    orderNumber: PropTypes.string,
    type: PropTypes.string,
    topic: PropTypes.string,
    status: PropTypes.string,
    price: PropTypes.number,
    createdAt: PropTypes.string
  }).isRequired,
  onClick: PropTypes.func,
  onStatusChange: PropTypes.func
};

export default OrderCard;