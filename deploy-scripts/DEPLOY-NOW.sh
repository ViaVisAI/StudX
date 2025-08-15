#!/bin/bash

# StudX - Финальный деплой скрипт
# Запускай после создания VPS в DigitalOcean

set -e

echo "================================================"
echo "🚀 StudX DEPLOYMENT SCRIPT v1.0"
echo "================================================"
echo ""

# Запрашиваем IP адрес
read -p "📍 Введи IP адрес нового VPS: " SERVER_IP
echo ""

# SSH ключ
SSH_KEY="$HOME/.ssh/id_rsa"
if [ ! -f "$SSH_KEY" ]; then
    SSH_KEY="$HOME/.ssh/id_ed25519"
fi

echo "🔑 Использую SSH ключ: $SSH_KEY"
echo ""

# Копируем скрипты на сервер
echo "📦 Копирую файлы настройки на сервер..."
scp -o StrictHostKeyChecking=no -r ./server-setup root@$SERVER_IP:/root/
echo "✅ Файлы скопированы"
echo ""

# Подключаемся и запускаем установку
echo "🔧 Подключаюсь к серверу и запускаю установку..."
echo "⏱️  Это займет 5-10 минут..."
echo ""

ssh -o StrictHostKeyChecking=no root@$SERVER_IP << 'ENDSSH'
cd /root/server-setup
chmod +x *.sh

# Установка базовых компонентов
echo "📦 Устанавливаю Node.js, PostgreSQL, Redis, Nginx..."
apt-get update
apt-get install -y curl git nginx postgresql postgresql-contrib redis-server

# Node.js 20 LTS
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

# PM2
npm install -g pm2

# Создание пользователя
useradd -m -s /bin/bash studx || true
usermod -aG sudo studx || true

# PostgreSQL
sudo -u postgres psql << EOF
CREATE USER studx WITH PASSWORD 'StudX2025Secure';
CREATE DATABASE studx_db OWNER studx;
GRANT ALL PRIVILEGES ON DATABASE studx_db TO studx;
EOF

# Redis
sed -i 's/^# requirepass .*/requirepass StudX2025Redis/' /etc/redis/redis.conf
systemctl restart redis

# Nginx конфиг
cp nginx.conf /etc/nginx/sites-available/studx
ln -sf /etc/nginx/sites-available/studx /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
systemctl restart nginx

# Директория для проекта
mkdir -p /var/www/studx
chown -R studx:studx /var/www/studx

echo "✅ Базовая установка завершена!"
ENDSSH

echo ""
echo "🌐 Клонирую репозиторий..."
ssh -o StrictHostKeyChecking=no root@$SERVER_IP << ENDSSH
cd /var/www/studx
git clone https://github.com/ViaVisAI/StudX.git current || echo "Репозиторий уже существует"
cd current

# Переменные окружения
cat > backend/.env << 'EOF'
NODE_ENV=production
PORT=3000

# Database
DATABASE_URL=postgresql://studx:StudX2025Secure@localhost:5432/studx_db
DB_HOST=localhost
DB_PORT=5432
DB_NAME=studx_db
DB_USER=studx
DB_PASSWORD=StudX2025Secure

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=StudX2025Redis

# Security
JWT_SECRET=$(openssl rand -base64 32)
SESSION_SECRET=$(openssl rand -base64 32)

# API (добавь свои ключи)
OPENAI_API_KEY=
ANTHROPIC_API_KEY=
EOF

echo "📦 Устанавливаю зависимости..."
cd backend && npm install --production
cd ../frontend && npm install && npm run build

echo "🗄️ Инициализирую базу данных..."
cd ../backend
PGPASSWORD=StudX2025Secure psql -h localhost -U studx -d studx_db < init-db.sql || true

echo "🚀 Запускаю через PM2..."
pm2 start /root/server-setup/ecosystem.config.js
pm2 save
pm2 startup systemd -u root --hp /root

echo "✅ Приложение запущено!"
ENDSSH

echo ""
echo "🔒 Получаю SSL сертификат..."
ssh -o StrictHostKeyChecking=no root@$SERVER_IP << ENDSSH
apt-get install -y certbot python3-certbot-nginx
certbot --nginx -d studx.ru -d www.studx.ru --non-interactive --agree-tos --email viavis.aix@gmail.com || true
ENDSSH

echo ""
echo "================================================"
echo "✅ ДЕПЛОЙ ЗАВЕРШЕН!"
echo "================================================"
echo ""
echo "📍 Сервер: $SERVER_IP"
echo "🌐 Сайт: https://studx.ru"
echo "📊 Проверка: https://studx.ru/api/health"
echo ""
echo "🔑 Доступы к БД:"
echo "   User: studx"
echo "   Pass: StudX2025Secure"
echo "   База: studx_db"
echo ""
echo "🔴 Redis:"
echo "   Pass: StudX2025Redis"
echo ""
echo "📝 Команды управления:"
echo "   pm2 status      - статус приложения"
echo "   pm2 logs        - логи"
echo "   pm2 restart all - перезапуск"
echo ""
echo "================================================"
