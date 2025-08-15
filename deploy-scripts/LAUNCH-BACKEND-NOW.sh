#!/bin/bash
# СКОПИРУЙ ВЕСЬ ЭТОТ СКРИПТ В ВЕБ-КОНСОЛЬ DIGITALOCEAN
# https://cloud.digitalocean.com/droplets/513406106/terminal

echo "🚀 ЗАПУСК STUDX BACKEND..."

# 1. Переход в папку
cd /var/www/studx/current/backend

# 2. Поиск главного файла
if [ -f "server.js" ]; then
    MAIN="server.js"
elif [ -f "app.js" ]; then
    MAIN="app.js"
elif [ -f "index.js" ]; then
    MAIN="index.js"
else
    echo "❌ Главный файл не найден! Файлы:"
    ls *.js
    exit 1
fi

echo "✅ Найден: $MAIN"

# 3. Запуск через PM2
pm2 start $MAIN --name studx-backend

# 4. Сохранение конфигурации
pm2 save
pm2 startup systemd -u root --hp /root | tail -n 1 | bash

# 5. Проверка
sleep 3
pm2 status
echo ""
echo "🔍 Проверка API..."
curl -s localhost:3000/api/health || echo "API endpoint не найден"
echo ""
echo "✅ ГОТОВО! Проверь https://studx.ru"