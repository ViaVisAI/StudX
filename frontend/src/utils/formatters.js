// Утилиты для форматирования данных
// Форматирование даты в читаемый вид
export function formatDate(date) {
  if (!date) return 'Нет даты';
  
  const d = new Date(date);
  if (isNaN(d)) return 'Неверная дата';
  
  const options = { 
    day: 'numeric',
    month: 'long',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  };
  
  return d.toLocaleDateString('ru-RU', options);
}

// Форматирование цены
export function formatPrice(price) {
  if (price === null || price === undefined) return '—';
  
  return new Intl.NumberFormat('ru-RU', {
    style: 'currency',
    currency: 'RUB',
    minimumFractionDigits: 0,
    maximumFractionDigits: 0
  }).format(price);
}

// Форматирование статуса на русский
export function formatStatus(status) {
  const statuses = {
    draft: 'Черновик',
    pending: 'В ожидании',
    in_progress: 'В работе',
    completed: 'Завершен',
    cancelled: 'Отменен',
    error: 'Ошибка'
  };
  return statuses[status] || status;
}

// Форматирование типа работы
export function formatWorkType(type) {
  const types = {
    diploma: 'Дипломная работа',
    coursework: 'Курсовая работа',
    essay: 'Эссе',
    report: 'Реферат',
    presentation: 'Презентация',
    article: 'Статья',
    other: 'Другое'
  };
  return types[type] || type;
}

// Сокращение длинного текста
export function truncateText(text, maxLength = 100) {
  if (!text) return '';
  if (text.length <= maxLength) return text;
  return text.substring(0, maxLength) + '...';
}

// Генерация номера заказа
export function generateOrderNumber() {
  const date = new Date();
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  const random = Math.floor(Math.random() * 1000).toString().padStart(3, '0');
  
  return `ORD-${year}${month}${day}-${random}`;
}