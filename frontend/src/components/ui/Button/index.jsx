import React from 'react';
import PropTypes from 'prop-types';
import './Button.css';

function Button({ 
  children, 
  onClick, 
  variant = 'primary', 
  size = 'medium',
  type = 'button',
  disabled = false,
  loading = false,
  fullWidth = false,
  className = ''
}) {
  const handleClick = (e) => {
    if (!disabled && !loading && onClick) {
      onClick(e);
    }
  };

  const buttonClass = [
    'btn',
    `btn-${variant}`,
    `btn-${size}`,
    fullWidth && 'btn-full',
    loading && 'btn-loading',
    disabled && 'btn-disabled',
    className
  ].filter(Boolean).join(' ');

  return (
    <button
      type={type}
      className={buttonClass}
      onClick={handleClick}
      disabled={disabled || loading}
    >
      {loading && <span className="btn-spinner">⟳</span>}
      <span className="btn-content">{children}</span>
    </button>
  );
}

Button.propTypes = {
  children: PropTypes.node.isRequired,
  onClick: PropTypes.func,
  variant: PropTypes.oneOf(['primary', 'secondary', 'danger', 'success']),
  size: PropTypes.oneOf(['small', 'medium', 'large']),
  type: PropTypes.oneOf(['button', 'submit', 'reset']),
  disabled: PropTypes.bool,
  loading: PropTypes.bool,
  fullWidth: PropTypes.bool,
  className: PropTypes.string
};

export default Button;