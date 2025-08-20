// Jest конфигурация для StudX Backend
// Минимальная настройка для работы CI/CD

module.exports = {
  // Где искать тесты
  testMatch: [
    '**/tests/**/*.test.js',
    '**/__tests__/**/*.js'
  ],
  
  // Окружение для тестов
  testEnvironment: 'node',
  
  // Папки для покрытия кода (на будущее)
  collectCoverageFrom: [
    'src/**/*.js',
    '!src/index.js', // Точка входа не тестируется
    '!**/node_modules/**'
  ],
  
  // Таймауты
  testTimeout: 10000,
  
  // Очистка моков после каждого теста
  clearMocks: true,
  
  // Детальный вывод при падении
  verbose: true
};
