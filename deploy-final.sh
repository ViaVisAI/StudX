#!/bin/bash

# StudX Production Deployment Script
# Одна команда для полного деплоя

set -e  # Остановка при ошибке

echo "🚀 StudX Production Deployment Starting..."

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Переменные
APP_DIR="/var/www/studx/current"
BACKEND_DIR="$APP_DIR/backend"

echo -e "${YELLOW}📍 Шаг 1: Переход в директорию проекта${NC}"
cd $APP_DIR

echo -e "${YELLOW}📥 Шаг 2: Получение последнего кода из GitHub${NC}"
git pull origin main

echo -e "${YELLOW}📦 Шаг 3: Установка зависимостей backend${NC}"
cd $BACKEND_DIR
npm install --production

echo -e "${YELLOW}🔧 Шаг 4: Проверка .env файла${NC}"
if [ ! -f .env ]; then
    echo -e "${RED}❌ Файл .env не найден! Создаю базовый...${NC}"
    cat > .env << 'EOF'
NODE_ENV=production
PORT=3000
APP_VERSION=1.0.0

# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=studx
DB_USER=studx
DB_PASSWORD=$(cat /root/db-password.txt 2>/dev/null || echo "change_me")

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379

# JWT
JWT_SECRET=$(openssl rand -base64 32)

# API Keys (добавьте свои)
# OPENAI_API_KEY=
# ANTHROPIC_API_KEY=
EOF
    echo -e "${GREEN}✅ Базовый .env создан${NC}"
fi

echo -e "${YELLOW}🚀 Шаг 5: Запуск backend через PM2${NC}"
pm2 stop studx-backend 2>/dev/null || true
pm2 delete studx-backend 2>/dev/null || true
pm2 start src/index.js --name studx-backend --max-memory-restart 1G
pm2 save

echo -e "${YELLOW}⚙️ Шаг 6: Настройка автозапуска PM2${NC}"
pm2 startup systemd -u root --hp /root | tail -n 1 | bash

echo -e "${YELLOW}🔍 Шаг 7: Проверка работоспособности${NC}"
sleep 3
if curl -f http://localhost:3000/api/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Backend работает!${NC}"
else
    echo -e "${RED}❌ Backend не отвечает!${NC}"
    echo "Проверьте логи: pm2 logs studx-backend"
    exit 1
fi

echo -e "${YELLOW}🌐 Шаг 8: Перезапуск Nginx${NC}"
nginx -t && systemctl reload nginx

echo -e "${YELLOW}🔒 Шаг 9: Финальная проверка HTTPS${NC}"
if curl -f https://studx.ru/api/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ HTTPS работает!${NC}"
else
    echo -e "${YELLOW}⚠️ HTTPS пока не отвечает, возможно нужно подождать${NC}"
fi

echo -e "${GREEN}🎉 Деплой завершен успешно!${NC}"
echo ""
echo "📊 Статус системы:"
pm2 status
echo ""
echo "📝 Полезные команды:"
echo "  pm2 logs studx-backend    - просмотр логов"
echo "  pm2 restart studx-backend - перезапуск"
echo "  pm2 monit                 - мониторинг в реальном времени"
echo ""
echo -e "${GREEN}✨ StudX готов к работе на https://studx.ru${NC}"