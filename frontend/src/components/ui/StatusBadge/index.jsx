import React from 'react';
import PropTypes from 'prop-types';
import './StatusBadge.css';

function StatusBadge({ status, size = 'medium' }) {
  const statusConfig = {
    draft: { label: 'Черновик', color: 'gray', icon: '📝' },
    pending: { label: 'Ожидание', color: 'yellow', icon: '⏳' },
    in_progress: { label: 'В работе', color: 'blue', icon: '🔄' },
    completed: { label: 'Завершен', color: 'green', icon: '✅' },
    cancelled: { label: 'Отменен', color: 'red', icon: '❌' },
    error: { label: 'Ошибка', color: 'red', icon: '⚠️' }
  };

  const config = statusConfig[status] || {
    label: status,
    color: 'gray',
    icon: '❓'
  };

  return (
    <span 
      className={`status-badge status-${config.color} size-${size}`}
      title={config.label}
    >
      <span className="status-icon">{config.icon}</span>
      <span className="status-label">{config.label}</span>
    </span>
  );
}

StatusBadge.propTypes = {
  status: PropTypes.string.isRequired,
  size: PropTypes.oneOf(['small', 'medium', 'large'])
};

export default StatusBadge;