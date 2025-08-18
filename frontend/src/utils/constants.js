// Константы приложения

// Статусы заказов
export const ORDER_STATUSES = {
  DRAFT: 'draft',
  PENDING: 'pending',
  IN_PROGRESS: 'in_progress',
  COMPLETED: 'completed',
  CANCELLED: 'cancelled'
};

// Типы работ
export const WORK_TYPES = {
  DIPLOMA: 'diploma',
  COURSEWORK: 'coursework',
  ESSAY: 'essay',
  REPORT: 'report',
  PRESENTATION: 'presentation',
  ARTICLE: 'article',
  OTHER: 'other'
};

// Лимиты
export const LIMITS = {
  MIN_PAGE_COUNT: 1,
  MAX_PAGE_COUNT: 500,
  MIN_PRICE: 0,
  MAX_PRICE: 1000000,
  MAX_FILE_SIZE: 50 * 1024 * 1024, // 50MB
  MAX_TOPIC_LENGTH: 500,
  MAX_REQUIREMENTS_LENGTH: 2000
};

// API endpoints
export const API_ENDPOINTS = {
  ORDERS: '/api/orders',
  AUTH: '/api/auth',
  UPLOAD: '/api/upload',
  GENERATE: '/api/generate'
};

// Локальное хранилище ключи
export const STORAGE_KEYS = {
  AUTH_TOKEN: 'auth_token',
  USER_DATA: 'user_data',
  ORDERS_CACHE: 'orders_cache',
  DRAFT_ORDER: 'draft_order'
};

// Временные задержки (мс)
export const DELAYS = {
  DEBOUNCE: 300,
  RETRY: 1000,
  TIMEOUT: 30000,
  CACHE_TTL: 5 * 60 * 1000 // 5 минут
};

export default {
  ORDER_STATUSES,
  WORK_TYPES,
  LIMITS,
  API_ENDPOINTS,
  STORAGE_KEYS,
  DELAYS
};