import { useState, useCallback } from 'react';
import { getOrders, createOrder, updateOrder } from '../../services/api/orders';
import { loadFromStorage, saveToStorage } from '../../services/storage/localStorage';

// Кастомный хук для работы с заказами
function useOrders() {
  const [orders, setOrders] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  // Загрузка заказов с кешированием
  const refreshOrders = useCallback(async () => {
    setLoading(true);
    setError(null);
    
    try {
      // Сначала показываем кешированные данные
      const cached = loadFromStorage('orders');
      if (cached) {
        setOrders(cached);
      }
      
      // Затем загружаем свежие
      const fresh = await getOrders();
      setOrders(fresh);
      saveToStorage('orders', fresh);
    } catch (err) {
      setError(err);
      console.error('Failed to load orders:', err);
    } finally {
      setLoading(false);
    }
  }, []);

  // Создание заказа с оптимистичным обновлением
  const handleCreateOrder = useCallback(async (orderData) => {
    const tempId = `temp-${Date.now()}`;
    const tempOrder = { ...orderData, id: tempId, status: 'creating' };
    
    // Оптимистично добавляем
    setOrders(prev => [tempOrder, ...prev]);
    
    try {
      const created = await createOrder(orderData);
      // Заменяем временный на реальный
      setOrders(prev => prev.map(o => o.id === tempId ? created : o));
      saveToStorage('orders', orders);
      return created;
    } catch (err) {
      // Откатываем при ошибке
      setOrders(prev => prev.filter(o => o.id !== tempId));
      throw err;
    }
  }, [orders]);

  // Обновление заказа
  const handleUpdateOrder = useCallback(async (orderId, updates) => {
    const oldOrders = orders;
    
    // Оптимистично обновляем
    setOrders(prev => prev.map(o => 
      o.id === orderId ? { ...o, ...updates } : o
    ));
    
    try {
      const updated = await updateOrder(orderId, updates);
      setOrders(prev => prev.map(o => o.id === orderId ? updated : o));
      saveToStorage('orders', orders);
      return updated;
    } catch (err) {
      // Откатываем при ошибке
      setOrders(oldOrders);
      throw err;
    }
  }, [orders]);

  return {
    orders,
    loading,
    error,
    refreshOrders,
    createOrder: handleCreateOrder,
    updateOrder: handleUpdateOrder
  };
}

export default useOrders;