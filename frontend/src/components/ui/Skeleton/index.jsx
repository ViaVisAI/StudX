import React from 'react';
import PropTypes from 'prop-types';
import './Skeleton.css';

function Skeleton({ 
  width = '100%', 
  height = '20px', 
  variant = 'text',
  animation = 'pulse',
  count = 1 
}) {
  const skeletons = Array.from({ length: count }, (_, i) => (
    <div
      key={i}
      className={`skeleton skeleton-${variant} skeleton-${animation}`}
      style={{ 
        width, 
        height: variant === 'text' ? height : undefined,
        aspectRatio: variant === 'circle' ? '1/1' : undefined
      }}
    />
  ));

  return count > 1 ? (
    <div className="skeleton-group">{skeletons}</div>
  ) : (
    skeletons[0]
  );
}

Skeleton.propTypes = {
  width: PropTypes.string,
  height: PropTypes.string,
  variant: PropTypes.oneOf(['text', 'rect', 'circle']),
  animation: PropTypes.oneOf(['pulse', 'wave', 'none']),
  count: PropTypes.number
};

export default Skeleton;