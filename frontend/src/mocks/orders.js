// Моковые данные для разработки без бэкенда
import { generateOrderNumber } from '../utils/formatters';

// Начальные данные
let mockOrders = [
  {
    id: '1',
    orderNumber: 'ORD-20250117-001',
    type: 'diploma',
    subject: 'Экономика',
    topic: 'Анализ финансовых рынков в условиях цифровизации',
    status: 'in_progress',
    price: 15000,
    pageCount: 65,
    createdAt: '2025-01-15T10:00:00Z',
    updatedAt: '2025-01-16T14:30:00Z'
  },
  {
    id: '2',
    orderNumber: 'ORD-20250116-002',
    type: 'coursework',
    subject: 'Информатика',
    topic: 'Разработка веб-приложения для учета товаров',
    status: 'pending',
    price: 8000,
    pageCount: 35,
    createdAt: '2025-01-16T09:00:00Z',
    updatedAt: '2025-01-16T09:00:00Z'
  },
  {
    id: '3',
    orderNumber: 'ORD-20250115-003',
    type: 'essay',
    subject: 'Философия',
    topic: 'Экзистенциализм в современном мире',
    status: 'completed',
    price: 3500,
    pageCount: 15,
    createdAt: '2025-01-14T15:00:00Z',
    updatedAt: '2025-01-15T18:00:00Z'
  }
];

// Имитация API методов
const mockApi = {
  // Получить все заказы
  getAll: (params = {}) => {
    let result = [...mockOrders];
    
    // Фильтрация по статусу
    if (params.status) {
      result = result.filter(o => o.status === params.status);
    }
    
    // Сортировка
    result.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
    
    return result;
  },

  // Получить по ID
  getById: (id) => {
    const order = mockOrders.find(o => o.id === id);
    if (!order) throw new Error('Order not found');
    return order;
  },

  // Создать новый
  create: (data) => {
    const newOrder = {
      id: String(Date.now()),
      orderNumber: generateOrderNumber(),
      status: 'draft',
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
      ...data
    };
    mockOrders.unshift(newOrder);
    return newOrder;
  },

  // Обновить существующий
  update: (id, updates) => {
    const index = mockOrders.findIndex(o => o.id === id);
    if (index === -1) throw new Error('Order not found');
    
    mockOrders[index] = {
      ...mockOrders[index],
      ...updates,
      updatedAt: new Date().toISOString()
    };
    return mockOrders[index];
  },

  // Удалить (soft delete)
  delete: (id) => {
    const index = mockOrders.findIndex(o => o.id === id);
    if (index === -1) throw new Error('Order not found');
    
    mockOrders[index].status = 'cancelled';
    mockOrders[index].updatedAt = new Date().toISOString();
    return { success: true };
  }
};

export default mockApi;