#!/bin/bash

# StudX Monitoring Script - Проверка здоровья системы
# Запускается через cron каждые 5 минут

set -e

# Конфигурация
SERVER_URL="https://studx.ru"
ADMIN_EMAIL="admin@studx.ru"
TELEGRAM_BOT_TOKEN=""  # Опционально для уведомлений
TELEGRAM_CHAT_ID=""    # Опционально

# Пороги для алертов
CPU_THRESHOLD=80
MEM_THRESHOLD=85
DISK_THRESHOLD=90
RESPONSE_TIME_THRESHOLD=3  # секунды

# Цвета для логов
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Файл для хранения состояний
STATE_FILE="/var/log/studx-monitor.state"
ALERT_SENT_FILE="/var/log/studx-alert.sent"

# Функция отправки уведомлений
send_alert() {
    local message="$1"
    local severity="$2"  # INFO, WARNING, CRITICAL
    
    echo "[$(date)] [$severity] $message" >> /var/log/studx-monitor.log
    
    # Email уведомление (если настроен postfix)
    if [ ! -z "$ADMIN_EMAIL" ]; then
        echo "$message" | mail -s "StudX Alert [$severity]" $ADMIN_EMAIL 2>/dev/null || true
    fi
    
    # Telegram уведомление
    if [ ! -z "$TELEGRAM_BOT_TOKEN" ] && [ ! -z "$TELEGRAM_CHAT_ID" ]; then
        curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
            -d chat_id="$TELEGRAM_CHAT_ID" \
            -d text="🚨 StudX [$severity]: $message" \
            >/dev/null 2>&1 || true
    fi
}

# 1. Проверка доступности сайта
echo -e "${YELLOW}→ Проверяю доступность сайта...${NC}"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 $SERVER_URL || echo "000")
RESPONSE_TIME=$(curl -s -o /dev/null -w "%{time_total}" --connect-timeout 5 $SERVER_URL || echo "999")

if [ "$HTTP_CODE" != "200" ] && [ "$HTTP_CODE" != "301" ] && [ "$HTTP_CODE" != "302" ]; then
    echo -e "${RED}✗ Сайт недоступен! HTTP код: $HTTP_CODE${NC}"
    
    # Проверяем, не отправляли ли уже алерт
    if [ ! -f "$ALERT_SENT_FILE" ] || [ $(find "$ALERT_SENT_FILE" -mmin +15 2>/dev/null | wc -l) -gt 0 ]; then
        send_alert "Сайт недоступен! HTTP код: $HTTP_CODE" "CRITICAL"
        touch "$ALERT_SENT_FILE"
        
        # Попытка автоматического восстановления
        echo -e "${YELLOW}→ Пытаюсь перезапустить сервисы...${NC}"
        sudo systemctl restart nginx
        sudo pm2 restart studx-backend
        sleep 5
        
        # Повторная проверка
        HTTP_CODE_RETRY=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 $SERVER_URL || echo "000")
        if [ "$HTTP_CODE_RETRY" == "200" ]; then
            send_alert "Сайт восстановлен после автоперезапуска" "INFO"
            rm -f "$ALERT_SENT_FILE"
        fi
    fi
else
    echo -e "${GREEN}✓ Сайт доступен (${RESPONSE_TIME}s)${NC}"
    rm -f "$ALERT_SENT_FILE" 2>/dev/null || true
    
    # Проверка времени отклика
    if (( $(echo "$RESPONSE_TIME > $RESPONSE_TIME_THRESHOLD" | bc -l) )); then
        echo -e "${YELLOW}⚠ Медленный отклик: ${RESPONSE_TIME}s${NC}"
        send_alert "Медленный отклик сайта: ${RESPONSE_TIME}s" "WARNING"
    fi
fi

# 2. Проверка процессов
echo -e "${YELLOW}→ Проверяю процессы...${NC}"

# PM2 процессы
PM2_STATUS=$(sudo -u studx pm2 list --no-color 2>/dev/null | grep "studx-backend" | awk '{print $18}' || echo "stopped")
if [ "$PM2_STATUS" != "online" ]; then
    echo -e "${RED}✗ Backend не работает!${NC}"
    send_alert "Backend процесс не работает!" "CRITICAL"
    
    # Автоперезапуск
    sudo -u studx pm2 restart studx-backend
    sleep 3
    send_alert "Backend перезапущен автоматически" "INFO"
else
    echo -e "${GREEN}✓ Backend работает${NC}"
fi

# PostgreSQL
if ! systemctl is-active --quiet postgresql; then
    echo -e "${RED}✗ PostgreSQL не работает!${NC}"
    send_alert "PostgreSQL не работает!" "CRITICAL"
    sudo systemctl restart postgresql
else
    echo -e "${GREEN}✓ PostgreSQL работает${NC}"
fi

# Redis
if ! systemctl is-active --quiet redis-server; then
    echo -e "${YELLOW}⚠ Redis не работает${NC}"
    send_alert "Redis не работает" "WARNING"
    sudo systemctl restart redis-server
else
    echo -e "${GREEN}✓ Redis работает${NC}"
fi

# Nginx
if ! systemctl is-active --quiet nginx; then
    echo -e "${RED}✗ Nginx не работает!${NC}"
    send_alert "Nginx не работает!" "CRITICAL"
    sudo systemctl restart nginx
else
    echo -e "${GREEN}✓ Nginx работает${NC}"
fi

# 3. Проверка ресурсов
echo -e "${YELLOW}→ Проверяю ресурсы...${NC}"

# CPU
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print int($2)}')
if [ "$CPU_USAGE" -gt "$CPU_THRESHOLD" ]; then
    echo -e "${YELLOW}⚠ Высокая загрузка CPU: ${CPU_USAGE}%${NC}"
    send_alert "Высокая загрузка CPU: ${CPU_USAGE}%" "WARNING"
else
    echo -e "${GREEN}✓ CPU: ${CPU_USAGE}%${NC}"
fi

# Память
MEM_USAGE=$(free | grep Mem | awk '{print int($3/$2 * 100)}')
if [ "$MEM_USAGE" -gt "$MEM_THRESHOLD" ]; then
    echo -e "${YELLOW}⚠ Высокое использование памяти: ${MEM_USAGE}%${NC}"
    send_alert "Высокое использование памяти: ${MEM_USAGE}%" "WARNING"
    
    # Попытка очистки кеша
    sync && echo 3 > /proc/sys/vm/drop_caches
else
    echo -e "${GREEN}✓ Память: ${MEM_USAGE}%${NC}"
fi

# Диск
DISK_USAGE=$(df -h / | awk 'NR==2 {print int($5)}')
if [ "$DISK_USAGE" -gt "$DISK_THRESHOLD" ]; then
    echo -e "${RED}✗ Критическое заполнение диска: ${DISK_USAGE}%${NC}"
    send_alert "Критическое заполнение диска: ${DISK_USAGE}%" "CRITICAL"
    
    # Автоочистка
    echo -e "${YELLOW}→ Очищаю старые логи и временные файлы...${NC}"
    find /var/log -type f -name "*.log" -mtime +30 -delete 2>/dev/null || true
    find /tmp -type f -mtime +7 -delete 2>/dev/null || true
    find /var/www/studx/releases -maxdepth 1 -type d -mtime +30 -exec rm -rf {} \; 2>/dev/null || true
    journalctl --vacuum-time=7d 2>/dev/null || true
else
    echo -e "${GREEN}✓ Диск: ${DISK_USAGE}%${NC}"
fi

# 4. Проверка SSL сертификата
echo -e "${YELLOW}→ Проверяю SSL сертификат...${NC}"
SSL_EXPIRY=$(echo | openssl s_client -servername studx.ru -connect studx.ru:443 2>/dev/null | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)
if [ ! -z "$SSL_EXPIRY" ]; then
    SSL_EXPIRY_EPOCH=$(date -d "$SSL_EXPIRY" +%s)
    CURRENT_EPOCH=$(date +%s)
    DAYS_LEFT=$(( ($SSL_EXPIRY_EPOCH - $CURRENT_EPOCH) / 86400 ))
    
    if [ "$DAYS_LEFT" -lt 7 ]; then
        echo -e "${RED}✗ SSL сертификат истекает через $DAYS_LEFT дней!${NC}"
        send_alert "SSL сертификат истекает через $DAYS_LEFT дней!" "CRITICAL"
        
        # Попытка автообновления
        certbot renew --quiet
    elif [ "$DAYS_LEFT" -lt 30 ]; then
        echo -e "${YELLOW}⚠ SSL сертификат истекает через $DAYS_LEFT дней${NC}"
        send_alert "SSL сертификат истекает через $DAYS_LEFT дней" "WARNING"
    else
        echo -e "${GREEN}✓ SSL сертификат действителен еще $DAYS_LEFT дней${NC}"
    fi
fi

# 5. Проверка бэкапов
echo -e "${YELLOW}→ Проверяю бэкапы...${NC}"
LAST_BACKUP=$(find /var/backups/studx -type f -name "*.gz" -mtime -1 2>/dev/null | wc -l)
if [ "$LAST_BACKUP" -eq 0 ]; then
    echo -e "${YELLOW}⚠ Нет свежих бэкапов за последние 24 часа${NC}"
    send_alert "Нет свежих бэкапов за последние 24 часа" "WARNING"
else
    echo -e "${GREEN}✓ Найдено $LAST_BACKUP свежих бэкапов${NC}"
fi

# 6. Проверка очереди задач (Redis)
echo -e "${YELLOW}→ Проверяю очередь задач...${NC}"
QUEUE_SIZE=$(redis-cli -a "$REDIS_PASSWORD" llen studx:queue 2>/dev/null || echo "0")
if [ "$QUEUE_SIZE" -gt 100 ]; then
    echo -e "${YELLOW}⚠ Большая очередь задач: $QUEUE_SIZE${NC}"
    send_alert "Большая очередь задач: $QUEUE_SIZE" "WARNING"
else
    echo -e "${GREEN}✓ Очередь задач: $QUEUE_SIZE${NC}"
fi

# Сохранение состояния
echo "{
  \"timestamp\": \"$(date -Iseconds)\",
  \"http_code\": \"$HTTP_CODE\",
  \"response_time\": \"$RESPONSE_TIME\",
  \"cpu_usage\": \"$CPU_USAGE\",
  \"mem_usage\": \"$MEM_USAGE\",
  \"disk_usage\": \"$DISK_USAGE\",
  \"ssl_days_left\": \"$DAYS_LEFT\",
  \"queue_size\": \"$QUEUE_SIZE\"
}" > "$STATE_FILE"

echo -e "${GREEN}[$(date)] Мониторинг завершен${NC}"
