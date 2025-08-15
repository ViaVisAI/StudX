#!/bin/bash
# StudX Backend Launch Script
# Копируй весь скрипт в веб-консоль DigitalOcean

echo "🚀 Запускаю StudX Backend..."

# Переход в папку
cd /var/www/studx/current/backend

# Проверка структуры
echo "📁 Структура backend:"
ls -la *.js | head -5

# Определение главного файла
if [ -f "server.js" ]; then
    MAIN_FILE="server.js"
elif [ -f "app.js" ]; then
    MAIN_FILE="app.js"
elif [ -f "index.js" ]; then
    MAIN_FILE="index.js"
else
    echo "❌ ОШИБКА: Главный файл не найден!"
    echo "Файлы в директории:"
    ls *.js
    exit 1
fi

echo "✅ Найден главный файл: $MAIN_FILE"

# Остановка если уже запущен
pm2 stop studx-backend 2>/dev/null || true

# Запуск через PM2
echo "🔄 Запускаю через PM2..."
pm2 start $MAIN_FILE --name studx-backend

# Проверка статуса
sleep 2
pm2 status

# Сохранение конфигурации
pm2 save
pm2 startup systemd -u root --hp /root | tail -n 1 | bash

# Проверка API
echo "🔍 Проверяю API..."
sleep