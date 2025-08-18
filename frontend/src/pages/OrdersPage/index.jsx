import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import useOrders from './useOrders';
import OrdersList from '../../components/orders/OrdersList';
import OrderForm from '../../components/orders/OrderForm';
import Modal from '../../components/ui/Modal';
import Button from '../../components/ui/Button';
import './OrdersPage.css';

function OrdersPage() {
  const { orders, loading, error, createOrder, updateOrder, refreshOrders } = useOrders();
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [selectedOrder, setSelectedOrder] = useState(null);
  
  useEffect(() => {
    refreshOrders();
  }, []);

  const handleCreateOrder = async (orderData) => {
    try {
      await createOrder(orderData);
      setShowCreateModal(false);
      refreshOrders();
    } catch (err) {
      console.error('Failed to create order:', err);
    }
  };

  const handleOrderClick = (order) => {
    setSelectedOrder(order);
  };

  const handleStatusChange = async (orderId, newStatus) => {
    try {
      await updateOrder(orderId, { status: newStatus });
      refreshOrders();
    } catch (err) {
      console.error('Failed to update order:', err);
    }
  };

  if (error) {
    return (
      <div className="error-container">
        <h2>Ошибка загрузки</h2>
        <p>{error.message}</p>
        <Button onClick={refreshOrders}>Повторить</Button>
      </div>
    );
  }

  return (
    <div className="orders-page">
      <div className="page-header">
        <h1>Заказы</h1>
        <div className="header-actions">
          <Button variant="primary" onClick={() => setShowCreateModal(true)}>
            ➕ Новый заказ
          </Button>
          <Button variant="secondary" onClick={refreshOrders}>
            🔄 Обновить
          </Button>
        </div>
      </div>

      <OrdersList 
        orders={orders}
        loading={loading}
        onOrderClick={handleOrderClick}
        onStatusChange={handleStatusChange}
      />

      {showCreateModal && (
        <Modal 
          title="Создание заказа" 
          onClose={() => setShowCreateModal(false)}
        >
          <OrderForm onSubmit={handleCreateOrder} />
        </Modal>
      )}

      {selectedOrder && (
        <Modal 
          title={`Заказ #${selectedOrder.orderNumber}`}
          onClose={() => setSelectedOrder(null)}
        >
          <pre>{JSON.stringify(selectedOrder, null, 2)}</pre>
        </Modal>
      )}
    </div>
  );
}

export default OrdersPage;