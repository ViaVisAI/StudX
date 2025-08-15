#!/bin/bash
# PostgreSQL setup for StudX

set -e

# Цвета для вывода
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== Настройка PostgreSQL для StudX ===${NC}"

# Генерация случайного пароля
DB_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)

# Создание пользователя и БД
sudo -u postgres psql << EOF
-- Создание пользователя
CREATE USER studx_user WITH PASSWORD '$DB_PASSWORD';

-- Создание базы данных
CREATE DATABASE studx OWNER studx_user;

-- Права для пользователя
GRANT ALL PRIVILEGES ON DATABASE studx TO studx_user;

-- Оптимизация для веб-приложения
ALTER DATABASE studx SET random_page_cost = 1.1;
ALTER DATABASE studx SET effective_cache_size = '3GB';
ALTER DATABASE studx SET shared_buffers = '1GB';
ALTER DATABASE studx SET maintenance_work_mem = '256MB';
EOF

echo -e "${GREEN}✅ PostgreSQL настроен!${NC}"
echo -e "${YELLOW}Сохрани эти данные в /var/www/studx/shared/.env:${NC}"
echo "DB_PASSWORD=$DB_PASSWORD"

# Настройка бэкапов через cron
(crontab -l 2>/dev/null; echo "0 3 * * * pg_dump studx | gzip > /var/www/studx/shared/backups/db_\$(date +\%Y\%m\%d).sql.gz") | crontab -

# Очистка старых бэкапов (старше 30 дней)
(crontab -l 2>/dev/null; echo "0 4 * * * find /var/www/studx/shared/backups -name 'db_*.sql.gz' -mtime +30 -delete") | crontab -

echo -e "${GREEN}✅ Автобэкапы настроены (ежедневно в 3:00)${NC}"
