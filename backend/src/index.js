// Минимальный Express сервер для StudX
// Создаю базовое приложение чтобы хотя бы что-то показывалось на сайте

const express = require('express');
const cors = require('cors');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Статические файлы frontend (если собран)
app.use(express.static(path.join(__dirname, '../../frontend/build')));

// Health check для CI/CD
app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'ok',
    service: 'StudX Backend',
    timestamp: new Date().toISOString(),
    version: '0.0.1'
  });
});

// API endpoint для проверки работы
app.get('/api/status', (req, res) => {
  res.json({
    message: 'StudX работает!',
    environment: process.env.NODE_ENV || 'development',
    uptime: process.uptime()
  });
});

// Заглушка для будущих API endpoints
app.get('/api/orders', (req, res) => {
  res.json({
    orders: [],
    message: 'API готов к работе'
  });
});

// Fallback на index.html для React Router (SPA)
app.get('*', (req, res) => {
  const indexPath = path.join(__dirname, '../../frontend/build/index.html');
  
  // Если есть собранный frontend - отдаем его
  if (require('fs').existsSync(indexPath)) {
    res.sendFile(indexPath);
  } else {
    // Иначе показываем минимальную страницу
    res.send(`
      <!DOCTYPE html>
      <html>
      <head>
        <title>StudX - Генерация академических работ</title>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style>
          body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            margin: 0;
            padding: 40px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
          }
          .container {
            text-align: center;
            max-width: 600px;
          }
          h1 {
            font-size: 48px;
            margin-bottom: 20px;
          }
          .status {
            background: rgba(255,255,255,0.2);
            padding: 20px;
            border-radius: 10px;
            margin: 20px 0;
          }
          .api-link {
            color: white;
            text-decoration: none;
            padding: 10px 20px;
            background: rgba(255,255,255,0.3);
            border-radius: 5px;
            display: inline-block;
            margin: 10px;
          }
          .api-link:hover {
            background: rgba(255,255,255,0.4);
          }
        </style>
      </head>
      <body>
        <div class="container">
          <h1>🎓 StudX</h1>
          <p>Платформа для генерации академических работ</p>
          
          <div class="status">
            <h2>✅ Сервер работает!</h2>
            <p>Backend запущен и готов к работе</p>
            <p>Frontend в разработке</p>
          </div>
          
          <div>
            <a href="/api/health" class="api-link">Health Check</a>
            <a href="/api/status" class="api-link">API Status</a>
            <a href="/api/orders" class="api-link">Orders API</a>
          </div>
          
          <p style="margin-top: 40px; opacity: 0.8;">
            Версия: 0.0.1 | Окружение: ${process.env.NODE_ENV || 'development'}
          </p>
        </div>
      </body>
      </html>
    `);
  }
});

// Обработка ошибок
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(500).json({
    error: 'Внутренняя ошибка сервера',
    message: process.env.NODE_ENV === 'development' ? err.message : undefined
  });
});

// Запуск сервера
app.listen(PORT, () => {
  console.log(`
  ==========================================
  🚀 StudX Backend запущен!
  ==========================================
  
  🔗 Локально: http://localhost:${PORT}
  📡 API Health: http://localhost:${PORT}/api/health
  🌐 Окружение: ${process.env.NODE_ENV || 'development'}
  
  ==========================================
  `);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM signal received: closing HTTP server');
  app.close(() => {
    console.log('HTTP server closed');
    process.exit(0);
  });
});

module.exports = app;
