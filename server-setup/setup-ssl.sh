#!/bin/bash
# SSL Certificate setup with Let's Encrypt for StudX

set -e

# Цвета
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

DOMAIN="studx.ru"
EMAIL="admin@studx.ru"  # ИЗМЕНИТЬ на твой email!

echo -e "${GREEN}=== Настройка SSL для $DOMAIN ===${NC}"

# Проверка что Nginx установлен
if ! command -v nginx &> /dev/null; then
    echo -e "${RED}Nginx не установлен! Сначала запусти setup.sh${NC}"
    exit 1
fi

# Установка Certbot
if ! command -v certbot &> /dev/null; then
    echo "Устанавливаю Certbot..."
    apt-get update
    apt-get install -y certbot python3-certbot-nginx
fi

# Получение сертификата
echo -e "${GREEN}Получаю SSL сертификат...${NC}"
certbot certonly \
    --nginx \
    --non-interactive \
    --agree-tos \
    --email $EMAIL \
    -d $DOMAIN \
    -d www.$DOMAIN

# Обновление Nginx конфига для SSL
cat > /etc/nginx/sites-available/studx-ssl.conf << 'EOF'
# HTTP редирект на HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name studx.ru www.studx.ru;
    return 301 https://$server_name$request_uri;
}

# HTTPS конфиг
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name studx.ru www.studx.ru;

    # SSL сертификаты
    ssl_certificate /etc/letsencrypt/live/studx.ru/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/studx.ru/privkey.pem;

    # SSL параметры для A+ рейтинга
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    ssl_stapling on;
    ssl_stapling_verify on;

    # Безопасность
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Strict-Transport-Security "max-age=31536000" always;

    # Логи
    access_log /var/log/nginx/studx-ssl.access.log;
    error_log /var/log/nginx/studx-ssl.error.log;

    # Корневая директория
    root /var/www/studx/current/frontend/build;
    index index.html;

    # Обработка статики
    location / {
        try_files $uri $uri/ /index.html;
    }

    # API проксирование
    location /api {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Таймауты для длинных операций
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Загрузка файлов
    location /upload {
        proxy_pass http://localhost:3000;
        client_max_body_size 100M;
        proxy_request_buffering off;
    }

    # Статика с кешированием
    location ~* \.(jpg|jpeg|gif|png|css|js|ico|xml)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
    }

    # Защита от доступа к служебным файлам
    location ~ /\. {
        deny all;
    }
}
EOF

# Активация SSL конфига
ln -sf /etc/nginx/sites-available/studx-ssl.conf /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Проверка конфига
nginx -t

# Перезапуск Nginx
systemctl reload nginx

# Настройка автообновления сертификата
echo "0 0,12 * * * root certbot renew --quiet --post-hook 'systemctl reload nginx'" > /etc/cron.d/certbot-renew

echo -e "${GREEN}✅ SSL настроен успешно!${NC}"
echo -e "${GREEN}Сайт доступен по: https://$DOMAIN${NC}"
echo -e "${YELLOW}Сертификат будет автоматически обновляться каждые 12 часов${NC}"
