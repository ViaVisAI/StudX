import React, { useState } from 'react';
import PropTypes from 'prop-types';
import Button from '../../ui/Button';
import { validateOrderForm } from './validation';
import './OrderForm.css';

function OrderForm({ onSubmit, initialData = {}, mode = 'create' }) {
  const [formData, setFormData] = useState({
    type: initialData.type || 'diploma',
    subject: initialData.subject || '',
    topic: initialData.topic || '',
    pageCount: initialData.pageCount || 50,
    deadline: initialData.deadline || '',
    requirements: initialData.requirements || '',
    ...initialData
  });
  
  const [errors, setErrors] = useState({});
  const [submitting, setSubmitting] = useState(false);

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
    // Очищаем ошибку при изменении поля
    if (errors[name]) {
      setErrors(prev => ({ ...prev, [name]: null }));
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    // Валидация
    const validationErrors = validateOrderForm(formData);
    if (Object.keys(validationErrors).length > 0) {
      setErrors(validationErrors);
      return;
    }
    
    setSubmitting(true);
    try {
      await onSubmit(formData);
      // Очищаем форму после успеха
      if (mode === 'create') {
        setFormData({
          type: 'diploma',
          subject: '',
          topic: '',
          pageCount: 50,
          deadline: '',
          requirements: ''
        });
      }
    } catch (error) {
      console.error('Form submission error:', error);
    } finally {
      setSubmitting(false);
    }
  };

  // Автосохранение в localStorage
  React.useEffect(() => {
    if (mode === 'create') {
      const saved = localStorage.getItem('orderFormDraft');
      if (saved) {
        setFormData(JSON.parse(saved));
      }
    }
  }, []);

  React.useEffect(() => {
    if (mode === 'create' && formData.topic) {
      localStorage.setItem('orderFormDraft', JSON.stringify(formData));
    }
  }, [formData, mode]);

  return (
    <form className="order-form" onSubmit={handleSubmit}>
      <div className="form-group">
        <label htmlFor="type">Тип работы *</label>
        <select
          id="type"
          name="type"
          value={formData.type}
          onChange={handleChange}
          className={errors.type ? 'error' : ''}
        >
          <option value="diploma">Дипломная работа</option>
          <option value="coursework">Курсовая работа</option>
          <option value="essay">Эссе</option>
          <option value="report">Реферат</option>
          <option value="practice">Отчет по практике</option>
        </select>
        {errors.type && <span className="error-message">{errors.type}</span>}
      </div>

      {/* Остальные поля формы аналогично */}
      
      <div className="form-actions">
        <Button
          type="submit"
          variant="primary"
          loading={submitting}
          disabled={submitting}
        >
          {mode === 'create' ? 'Создать заказ' : 'Сохранить'}
        </Button>
        
        {mode === 'create' && formData.topic && (
          <Button
            type="button"
            variant="secondary"
            onClick={() => {
              setFormData({
                type: 'diploma',
                subject: '',
                topic: '',
                pageCount: 50,
                deadline: '',
                requirements: ''
              });
              localStorage.removeItem('orderFormDraft');
            }}
          >
            Очистить
          </Button>
        )}
      </div>
    </form>
  );
}

OrderForm.propTypes = {
  onSubmit: PropTypes.func.isRequired,
  initialData: PropTypes.object,
  mode: PropTypes.oneOf(['create', 'edit'])
};

export default OrderForm;