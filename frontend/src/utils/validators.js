// Валидаторы для форм и данных

// Валидация email
export function isValidEmail(email) {
  if (!email) return false;
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
}

// Валидация телефона (российский формат)
export function isValidPhone(phone) {
  if (!phone) return false;
  const cleanPhone = phone.replace(/\D/g, '');
  return cleanPhone.length === 11 && (cleanPhone.startsWith('7') || cleanPhone.startsWith('8'));
}

// Валидация URL
export function isValidUrl(url) {
  try {
    new URL(url);
    return true;
  } catch {
    return false;
  }
}

// Валидация файла
export function validateFile(file, options = {}) {
  const {
    maxSize = 50 * 1024 * 1024, // 50MB по умолчанию
    allowedTypes = ['application/pdf', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'],
    allowedExtensions = ['.pdf', '.doc', '.docx']
  } = options;
  
  const errors = [];
  
  // Проверка размера
  if (file.size > maxSize) {
    errors.push(`Файл слишком большой. Максимум: ${Math.round(maxSize / 1024 / 1024)}MB`);
  }
  
  // Проверка типа
  if (allowedTypes.length && !allowedTypes.includes(file.type)) {
    errors.push('Неподдерживаемый тип файла');
  }
  
  // Проверка расширения
  const extension = '.' + file.name.split('.').pop().toLowerCase();
  if (allowedExtensions.length && !allowedExtensions.includes(extension)) {
    errors.push(`Разрешены только: ${allowedExtensions.join(', ')}`);
  }
  
  return {
    valid: errors.length === 0,
    errors
  };
}

// Валидация формы заказа
export function validateOrderForm(data) {
  const errors = {};
  
  // Обязательные поля
  if (!data.topic || data.topic.trim().length < 3) {
    errors.topic = 'Тема должна содержать минимум 3 символа';
  }
  
  if (!data.subject || data.subject.trim().length < 2) {
    errors.subject = 'Предмет обязателен';
  }
  
  // Числовые поля
  if (data.pageCount < 1 || data.pageCount > 500) {
    errors.pageCount = 'Количество страниц от 1 до 500';
  }
  
  if (data.price < 0) {
    errors.price = 'Цена не может быть отрицательной';
  }
  
  // Дедлайн
  if (data.deadline) {
    const deadline = new Date(data.deadline);
    const now = new Date();
    if (deadline < now) {
      errors.deadline = 'Дедлайн не может быть в прошлом';
    }
  }
  
  return {
    valid: Object.keys(errors).length === 0,
    errors
  };
}

// Санитизация строки (удаление опасных символов)
export function sanitizeString(str) {
  if (!str) return '';
  return str
    .replace(/[<>]/g, '') // Удаляем теги
    .replace(/javascript:/gi, '') // Удаляем javascript:
    .replace(/on\w+=/gi, '') // Удаляем onclick= и подобные
    .trim();
}

// Проверка на пустоту
export function isEmpty(value) {
  return value === null || 
         value === undefined || 
         value === '' || 
         (Array.isArray(value) && value.length === 0) ||
         (typeof value === 'object' && Object.keys(value).length === 0);
}

export default {
  isValidEmail,
  isValidPhone,
  isValidUrl,
  validateFile,
  validateOrderForm,
  sanitizeString,
  isEmpty
};