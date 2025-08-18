// Базовый HTTP клиент с retry механизмом
import axios from 'axios';

// Создание экземпляра axios с базовой конфигурацией
const apiClient = axios.create({
  baseURL: process.env.REACT_APP_API_URL || 'http://localhost:5000',
  timeout: 30000,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Retry конфигурация
const MAX_RETRIES = 3;
const RETRY_DELAY = 1000; // Начальная задержка в ms

// Функция задержки с экспоненциальным увеличением
const delay = (ms) => new Promise(resolve => setTimeout(resolve, ms));

// Request interceptor для добавления токена
apiClient.interceptors.request.use(
  (config) => {
    // Добавляем токен если есть
    const token = localStorage.getItem('auth_token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    
    // Логирование в dev режиме
    if (process.env.NODE_ENV === 'development') {
      console.log(`📤 ${config.method?.toUpperCase()} ${config.url}`, config.data);
    }
    
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Response interceptor с retry логикой
apiClient.interceptors.response.use(
  (response) => {
    // Логирование успешных ответов в dev
    if (process.env.NODE_ENV === 'development') {
      console.log(`📥 ${response.config.method?.toUpperCase()} ${response.config.url}`, response.data);
    }
    return response.data;
  },
  async (error) => {
    const config = error.config;
    
    // Проверяем можно ли повторить запрос
    if (!config || !config.retry) {
      config.retry = 0;
    }
    
    // Условия для retry
    const shouldRetry = 
      config.retry < MAX_RETRIES &&
      (error.code === 'ECONNABORTED' || // Timeout
       error.code === 'ERR_NETWORK' || // Network error
       (error.response?.status >= 500 && error.response?.status <= 599)); // Server errors
    
    if (shouldRetry) {
      config.retry++;
      
      // Экспоненциальная задержка: 1s, 2s, 4s
      const retryDelay = RETRY_DELAY * Math.pow(2, config.retry - 1);
      
      console.warn(`⚠️ Retry ${config.retry}/${MAX_RETRIES} after ${retryDelay}ms`);
      await delay(retryDelay);
      
      return apiClient(config);
    }
    
    // Обработка ошибок
    const errorMessage = error.response?.data?.message || error.message || 'Неизвестная ошибка';
    console.error(`❌ ${error.config?.method?.toUpperCase()} ${error.config?.url}: ${errorMessage}`);
    
    return Promise.reject({
      message: errorMessage,
      status: error.response?.status,
      data: error.response?.data
    });
  }
);

export default apiClient;