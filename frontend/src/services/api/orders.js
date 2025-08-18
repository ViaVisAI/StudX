// API клиент для работы с заказами
import apiClient from './client';
import mockOrders from '../../mocks/orders';

// Флаг для использования моков пока нет бэкенда
const USE_MOCKS = true;

// Получение списка заказов
export async function getOrders(params = {}) {
  if (USE_MOCKS) {
    // Имитация задержки сети
    await new Promise(resolve => setTimeout(resolve, 300));
    return mockOrders.getAll(params);
  }
  
  return apiClient.get('/api/orders', { params });
}

// Получение одного заказа
export async function getOrder(orderId) {
  if (USE_MOCKS) {
    await new Promise(resolve => setTimeout(resolve, 200));
    return mockOrders.getById(orderId);
  }
  
  return apiClient.get(`/api/orders/${orderId}`);
}

// Создание заказа
export async function createOrder(orderData) {
  if (USE_MOCKS) {
    await new Promise(resolve => setTimeout(resolve, 500));
    return mockOrders.create(orderData);
  }
  
  return apiClient.post('/api/orders', orderData);
}

// Обновление заказа
export async function updateOrder(orderId, updates) {
  if (USE_MOCKS) {
    await new Promise(resolve => setTimeout(resolve, 300));
    return mockOrders.update(orderId, updates);
  }
  
  return apiClient.patch(`/api/orders/${orderId}`, updates);
}

// Удаление заказа (soft delete)
export async function deleteOrder(orderId) {
  if (USE_MOCKS) {
    await new Promise(resolve => setTimeout(resolve, 200));
    return mockOrders.delete(orderId);
  }
  
  return apiClient.delete(`/api/orders/${orderId}`);
}

// Смена статуса заказа
export async function changeOrderStatus(orderId, status) {
  if (USE_MOCKS) {
    await new Promise(resolve => setTimeout(resolve, 300));
    return mockOrders.update(orderId, { status, statusChangedAt: new Date().toISOString() });
  }
  
  return apiClient.post(`/api/orders/${orderId}/status`, { status });
}

// Экспорт всех методов
export default {
  getOrders,
  getOrder,
  createOrder,
  updateOrder,
  deleteOrder,
  changeOrderStatus
};