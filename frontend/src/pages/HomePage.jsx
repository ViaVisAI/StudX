import React from 'react';

function HomePage() {
  return (
    <div className="home-page">
      <h1>StudX - Генератор академических работ</h1>
      <p>Сервис готов к разработке</p>
      <button onClick={() => console.log('Order clicked')}>
        Создать заказ
      </button>
    </div>
  );
}

export default HomePage;