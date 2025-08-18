import React, { useEffect, useCallback } from 'react';
import PropTypes from 'prop-types';
import './Modal.css';

function Modal({ 
  title, 
  children, 
  onClose, 
  isOpen = true,
  size = 'medium',
  closeOnOverlay = true,
  closeOnEscape = true 
}) {
  // Закрытие по Escape
  const handleEscape = useCallback((e) => {
    if (closeOnEscape && e.key === 'Escape') {
      onClose();
    }
  }, [closeOnEscape, onClose]);

  // Закрытие по клику на оверлей
  const handleOverlayClick = (e) => {
    if (closeOnOverlay && e.target.classList.contains('modal-overlay')) {
      onClose();
    }
  };

  useEffect(() => {
    if (isOpen) {
      // Блокируем скролл страницы
      document.body.style.overflow = 'hidden';
      // Слушаем Escape
      document.addEventListener('keydown', handleEscape);
      
      return () => {
        document.body.style.overflow = '';
        document.removeEventListener('keydown', handleEscape);
      };
    }
  }, [isOpen, handleEscape]);

  if (!isOpen) return null;

  return (
    <div className="modal-overlay" onClick={handleOverlayClick}>
      <div className={`modal modal-${size}`}>
        <div className="modal-header">
          <h2 className="modal-title">{title}</h2>
          <button 
            className="modal-close" 
            onClick={onClose}
            aria-label="Закрыть"
          >
            ✕
          </button>
        </div>
        <div className="modal-body">
          {children}
        </div>
      </div>
    </div>
  );
}

Modal.propTypes = {
  title: PropTypes.string.isRequired,
  children: PropTypes.node.isRequired,
  onClose: PropTypes.func.isRequired,
  isOpen: PropTypes.bool,
  size: PropTypes.oneOf(['small', 'medium', 'large']),
  closeOnOverlay: PropTypes.bool,
  closeOnEscape: PropTypes.bool
};

export default Modal;