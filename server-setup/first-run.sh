#!/bin/bash

# StudX Server Setup - Первый запуск
# Запустить на сервере: bash <(curl -s https://raw.githubusercontent.com/yourusername/studx/main/server-setup/first-run.sh)

set -e  # Остановка при ошибке

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Функция логирования
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Проверка что запущено от root
if [[ $EUID -ne 0 ]]; then
   error "Этот скрипт должен быть запущен от root"
fi

# Переменные
DOMAIN="studx.ru"
USER="studx"
APP_DIR="/var/www/studx"
REPO_URL="https://github.com/ViaVisAI/StudX.git"
NODE_VERSION="20"
SERVER_IP=$(curl -s ifconfig.me)

log "========================================="
log "StudX Server Setup - Production Deployment"
log "========================================="
log "Domain: $DOMAIN"
log "Server IP: $SERVER_IP"
log "App Directory: $APP_DIR"
log "========================================="

# Проверка SSH ключа
log "Проверка SSH доступа..."
if [ ! -f ~/.ssh/authorized_keys ] || [ ! -s ~/.ssh/authorized_keys ]; then
    warning "SSH ключ не найден! Добавьте ваш публичный ключ в ~/.ssh/authorized_keys"
    read -p "Продолжить все равно? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Обновление системы
log "Обновление системы..."
apt update && apt upgrade -y

# Установка базовых пакетов
log "Установка базовых пакетов..."
apt install -y \
    curl \
    wget \
    git \
    build-essential \
    software-properties-common \
    ufw \
    fail2ban \
    nginx \
    certbot \
    python3-certbot-nginx \
    postgresql \
    postgresql-contrib \
    redis-server \
    htop \
    ncdu \
    ripgrep \
    jq

# Создание пользователя для приложения
log "Создание пользователя $USER..."
if ! id "$USER" &>/dev/null; then
    useradd -m -s /bin/bash $USER
    usermod -aG sudo $USER
    log "Пользователь $USER создан"
else
    log "Пользователь $USER уже существует"
fi

# Установка Node.js
log "Установка Node.js v$NODE_VERSION..."
curl -fsSL https://deb.nodesource.com/setup_$NODE_VERSION.x | bash -
apt install -y nodejs

# Установка PM2 глобально
log "Установка PM2..."
npm install -g pm2

# Настройка firewall
log "Настройка firewall..."
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp    # SSH
ufw allow 80/tcp    # HTTP
ufw allow 443/tcp   # HTTPS
echo "y" | ufw enable

# Настройка fail2ban
log "Настройка fail2ban..."
systemctl enable fail2ban
systemctl start fail2ban

# Создание структуры приложения
log "Создание структуры приложения..."
mkdir -p $APP_DIR/{releases,shared/{logs,uploads,config}}
chown -R $USER:$USER $APP_DIR

# Генерация паролей
DB_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
REDIS_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
JWT_SECRET=$(openssl rand -base64 64)
SESSION_SECRET=$(openssl rand -base64 32)

# Настройка PostgreSQL
log "Настройка PostgreSQL..."
sudo -u postgres psql <<EOF
CREATE USER studx WITH PASSWORD '$DB_PASSWORD';
CREATE DATABASE studx_production OWNER studx;
GRANT ALL PRIVILEGES ON DATABASE studx_production TO studx;
EOF

# Оптимизация PostgreSQL для 4GB RAM
cat > /etc/postgresql/*/main/conf.d/optimization.conf <<EOF
# Оптимизация для 4GB RAM VPS
shared_buffers = 1GB
effective_cache_size = 3GB
maintenance_work_mem = 256MB
checkpoint_completion_target = 0.9
wal_buffers = 16MB
default_statistics_target = 100
random_page_cost = 1.1
effective_io_concurrency = 200
work_mem = 5MB
min_wal_size = 1GB
max_wal_size = 4GB
max_worker_processes = 2
max_parallel_workers_per_gather = 1
max_parallel_workers = 2
max_parallel_maintenance_workers = 1
EOF

systemctl restart postgresql

# Настройка Redis
log "Настройка Redis..."
sed -i "s/^# requirepass .*/requirepass $REDIS_PASSWORD/" /etc/redis/redis.conf
sed -i "s/^# maxmemory .*/maxmemory 512mb/" /etc/redis/redis.conf
sed -i "s/^# maxmemory-policy .*/maxmemory-policy allkeys-lru/" /etc/redis/redis.conf
systemctl restart redis-server

# Клонирование репозитория
log "Клонирование репозитория..."
cd $APP_DIR/releases
RELEASE_DIR=$(date +%Y%m%d%H%M%S)
git clone $REPO_URL $RELEASE_DIR
cd $RELEASE_DIR

# Создание .env файла
log "Создание конфигурации..."
cat > $APP_DIR/shared/config/.env.production <<EOF
# Server Configuration
NODE_ENV=production
PORT=3000
HOST=0.0.0.0

# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=studx_production
DB_USER=studx
DB_PASSWORD=$DB_PASSWORD

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=$REDIS_PASSWORD

# Security
JWT_SECRET=$JWT_SECRET
SESSION_SECRET=$SESSION_SECRET
CORS_ORIGIN=https://$DOMAIN

# File Upload
MAX_FILE_SIZE=104857600
UPLOAD_DIR=$APP_DIR/shared/uploads

# Logs
LOG_DIR=$APP_DIR/shared/logs
LOG_LEVEL=info

# API Keys (заполнить позже)
OPENAI_API_KEY=
ANTHROPIC_API_KEY=

# Domain
DOMAIN=$DOMAIN
BASE_URL=https://$DOMAIN
EOF

# Копирование конфига в релиз
ln -s $APP_DIR/shared/config/.env.production $APP_DIR/releases/$RELEASE_DIR/backend/.env

# Установка зависимостей
log "Установка зависимостей backend..."
cd $APP_DIR/releases/$RELEASE_DIR/backend
npm ci --production

log "Сборка frontend..."
cd $APP_DIR/releases/$RELEASE_DIR/frontend
npm ci
npm run build

# Симлинк на текущий релиз
log "Активация релиза..."
ln -sfn $APP_DIR/releases/$RELEASE_DIR $APP_DIR/current

# Инициализация БД
log "Инициализация базы данных..."
cd $APP_DIR/current/backend
PGPASSWORD=$DB_PASSWORD psql -h localhost -U studx -d studx_production < ../server-setup/database/init.sql

# Настройка Nginx
log "Настройка Nginx..."
cp $APP_DIR/current/server-setup/nginx/studx.conf /etc/nginx/sites-available/studx
ln -sf /etc/nginx/sites-available/studx /etc/nginx/sites-enabled/studx
rm -f /etc/nginx/sites-enabled/default

# Проверка конфига Nginx
nginx -t && systemctl reload nginx

# Настройка PM2
log "Настройка PM2..."
cd $APP_DIR/current/backend
pm2 start ecosystem.config.js --env production
pm2 save
pm2 startup systemd -u $USER --hp /home/$USER

# Создание swap файла (для запаса)
log "Создание swap файла..."
if [ ! -f /swapfile ]; then
    fallocate -l 2G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi

# Настройка автоматических бэкапов
log "Настройка автоматических бэкапов..."
cat > /etc/cron.d/studx-backup <<EOF
# Ежедневный бэкап БД в 3:00
0 3 * * * postgres pg_dump studx_production | gzip > $APP_DIR/shared/backups/db_\$(date +\%Y\%m\%d).sql.gz
# Удаление старых бэкапов (старше 30 дней)
0 4 * * * find $APP_DIR/shared/backups -name "*.sql.gz" -mtime +30 -delete
EOF

mkdir -p $APP_DIR/shared/backups
chown postgres:postgres $APP_DIR/shared/backups

# Получение SSL сертификата
log "Получение SSL сертификата..."
certbot --nginx -d $DOMAIN -d www.$DOMAIN --non-interactive --agree-tos -m admin@$DOMAIN

# Финальная проверка
log "Проверка установки..."
sleep 5

# Health check
HEALTH_CHECK=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/api/health)
if [ "$HEALTH_CHECK" = "200" ]; then
    log "✅ Backend работает!"
else
    error "❌ Backend не отвечает!"
fi

# Сохранение информации
cat > /root/studx-info.txt <<EOF
========================================
StudX Server Installation Complete!
========================================
Domain: https://$DOMAIN
Server IP: $SERVER_IP
========================================
Database Credentials:
  Host: localhost
  Database: studx_production
  User: studx
  Password: $DB_PASSWORD
========================================
Redis:
  Host: localhost
  Port: 6379
  Password: $REDIS_PASSWORD
========================================
Application:
  Directory: $APP_DIR
  User: $USER
  PM2 Status: pm2 status
  Logs: pm2 logs
========================================
SSL Certificate:
  Auto-renewal enabled via cron
========================================
Backups:
  Database: Daily at 3:00 AM
  Location: $APP_DIR/shared/backups
========================================
IMPORTANT: Save this information securely!
========================================
EOF

log "========================================="
log "✅ УСТАНОВКА ЗАВЕРШЕНА УСПЕШНО!"
log "========================================="
log "Сайт доступен по адресу: https://$DOMAIN"
log "Информация сохранена в: /root/studx-info.txt"
log ""
log "Не забудьте добавить API ключи в файл:"
log "$APP_DIR/shared/config/.env.production"
log "========================================="
