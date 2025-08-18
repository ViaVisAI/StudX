// Валидация формы заказа
export function validateOrderForm(formData) {
  const errors = {};
  
  // Обязательные поля
  if (!formData.type) {
    errors.type = 'Выберите тип работы';
  }
  
  if (!formData.topic || formData.topic.trim().length < 3) {
    errors.topic = 'Тема должна быть не менее 3 символов';
  }
  
  if (!formData.subject || formData.subject.trim().length < 2) {
    errors.subject = 'Укажите предмет';
  }
  
  // Валидация числовых полей
  if (formData.pageCount) {
    const pages = parseInt(formData.pageCount);
    if (isNaN(pages) || pages < 1 || pages > 500) {
      errors.pageCount = 'Количество страниц от 1 до 500';
    }
  }
  
  // Валидация даты
  if (formData.deadline) {
    const deadline = new Date(formData.deadline);
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    
    if (deadline < today) {
      errors.deadline = 'Дедлайн не может быть в прошлом';
    }
  }
  
  return errors;
}

// Санитизация данных перед отправкой
export function sanitizeOrderData(formData) {
  return {
    ...formData,
    topic: formData.topic?.trim(),
    subject: formData.subject?.trim(),
    requirements: formData.requirements?.trim(),
    pageCount: parseInt(formData.pageCount) || 50
  };
}