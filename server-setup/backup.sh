#!/bin/bash

# StudX Backup Script - Автоматическое резервное копирование
# Запускается через cron каждую ночь в 3:00

set -e

# Конфигурация
BACKUP_DIR="/var/backups/studx"
DB_NAME="studx_db"
APP_DIR="/var/www/studx/current"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=30

# Цвета для логов
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Создание директории для бэкапов
mkdir -p $BACKUP_DIR/{database,files,configs}

echo -e "${GREEN}[$(date)] Начинаю резервное копирование StudX${NC}"

# 1. Бэкап базы данных PostgreSQL
echo -e "${YELLOW}→ Создаю бэкап базы данных...${NC}"
sudo -u postgres pg_dump $DB_NAME | gzip > "$BACKUP_DIR/database/db_${DATE}.sql.gz"
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ База данных сохранена${NC}"
else
    echo -e "${RED}✗ Ошибка при сохранении БД${NC}"
    exit 1
fi

# 2. Бэкап загруженных файлов пользователей
echo -e "${YELLOW}→ Архивирую файлы пользователей...${NC}"
if [ -d "$APP_DIR/uploads" ]; then
    tar -czf "$BACKUP_DIR/files/uploads_${DATE}.tar.gz" -C "$APP_DIR" uploads/
    echo -e "${GREEN}✓ Файлы заархивированы${NC}"
else
    echo -e "${YELLOW}⚠ Папка uploads не найдена${NC}"
fi

# 3. Бэкап конфигурационных файлов
echo -e "${YELLOW}→ Сохраняю конфигурации...${NC}"
tar -czf "$BACKUP_DIR/configs/configs_${DATE}.tar.gz" \
    /etc/nginx/sites-enabled/studx.ru \
    /var/www/studx/shared/.env \
    /var/www/studx/ecosystem.config.js \
    2>/dev/null || true
echo -e "${GREEN}✓ Конфигурации сохранены${NC}"

# 4. Удаление старых бэкапов
echo -e "${YELLOW}→ Удаляю бэкапы старше $RETENTION_DAYS дней...${NC}"
find $BACKUP_DIR -type f -mtime +$RETENTION_DAYS -delete
echo -e "${GREEN}✓ Старые бэкапы удалены${NC}"

# 5. Отправка на внешнее хранилище (если настроено)
if [ ! -z "$BACKUP_S3_BUCKET" ]; then
    echo -e "${YELLOW}→ Отправляю на S3...${NC}"
    aws s3 sync $BACKUP_DIR s3://$BACKUP_S3_BUCKET/studx-backups/ --delete
    echo -e "${GREEN}✓ Синхронизировано с S3${NC}"
fi

# 6. Проверка размера бэкапов
BACKUP_SIZE=$(du -sh $BACKUP_DIR | cut -f1)
echo -e "${GREEN}[$(date)] Бэкап завершен! Общий размер: $BACKUP_SIZE${NC}"

# 7. Логирование
echo "[$(date)] Backup completed. Size: $BACKUP_SIZE" >> /var/log/studx-backup.log

# 8. Уведомление (если настроено)
if [ ! -z "$ADMIN_EMAIL" ]; then
    echo "StudX backup completed at $(date). Size: $BACKUP_SIZE" | \
    mail -s "StudX Backup Report" $ADMIN_EMAIL
fi
