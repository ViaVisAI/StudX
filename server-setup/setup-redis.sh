#!/bin/bash

# StudX Redis Setup Script - Настройка Redis для очередей задач
# Автор: StudX DevOps
# Версия: 1.0

set -e  # Остановка при ошибке

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== StudX Redis Setup ===${NC}"
echo "Настройка Redis для очередей задач генерации..."

# Проверка что запущен под root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Ошибка: Запустите скрипт с sudo${NC}"
   exit 1
fi

# Установка Redis
echo -e "${YELLOW}Шаг 1: Установка Redis${NC}"
apt-get update
apt-get install -y redis-server redis-tools

# Генерация пароля
REDIS_PASSWORD=$(openssl rand -base64 32)
echo "REDIS_PASSWORD=$REDIS_PASSWORD" >> /var/www/studx/shared/.env

# Бэкап оригинального конфига
echo -e "${YELLOW}Шаг 2: Конфигурация Redis${NC}"
cp /etc/redis/redis.conf /etc/redis/redis.conf.backup

# Создание оптимизированного конфига
cat > /etc/redis/redis.conf << 'EOF'
# StudX Redis Configuration

# Сеть
bind 127.0.0.1 ::1
protected-mode yes
port 6379
tcp-backlog 511
timeout 0
tcp-keepalive 300

# Общие настройки
daemonize yes
supervised systemd
pidfile /var/run/redis/redis-server.pid
loglevel notice
logfile /var/log/redis/redis-server.log

# База данных
databases 16

# Сохранение на диск (persistence)
save 900 1      # Сохранять если 1 изменение за 15 минут
save 300 10     # Сохранять если 10 изменений за 5 минут  
save 60 10000   # Сохранять если 10000 изменений за минуту

stop-writes-on-bgsave-error yes
rdbcompression yes
rdbchecksum yes
dbfilename dump.rdb
dir /var/lib/redis

# Репликация
replica-read-only yes

# Безопасность
requirepass REDIS_PASSWORD_PLACEHOLDER
maxclients 1000

# Лимиты памяти
maxmemory 512mb
maxmemory-policy allkeys-lru

# AOF (Append Only File) для надежности
appendonly yes
appendfilename "appendonly.aof"
appendfsync everysec
no-appendfsync-on-rewrite no
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb

# Slow log
slowlog-log-slower-than 10000
slowlog-max-len 128

# Latency monitor
latency-monitor-threshold 0

# Event notification
notify-keyspace-events ""

# Advanced config
hash-max-ziplist-entries 512
hash-max-ziplist-value 64
list-max-ziplist-size -2
list-compress-depth 0
set-max-intset-entries 512
zset-max-ziplist-entries 128
zset-max-ziplist-value 64
hll-sparse-max-bytes 3000
stream-node-max-bytes 4096
stream-node-max-entries 100
activerehashing yes
client-output-buffer-limit normal 0 0 0
client-output-buffer-limit replica 256mb 64mb 60
client-output-buffer-limit pubsub 32mb 8mb 60
hz 10
dynamic-hz yes
aof-rewrite-incremental-fsync yes
rdb-save-incremental-fsync yes

# Модули для очередей задач
loadmodule /usr/lib/redis/modules/rejson.so
EOF

# Вставка пароля в конфиг
sed -i "s/REDIS_PASSWORD_PLACEHOLDER/$REDIS_PASSWORD/g" /etc/redis/redis.conf

# Настройка systemd
echo -e "${YELLOW}Шаг 3: Настройка автозапуска${NC}"
cat > /etc/systemd/system/redis.service << 'EOF'
[Unit]
Description=Redis In-Memory Data Store
After=network.target

[Service]
Type=notify
ExecStart=/usr/bin/redis-server /etc/redis/redis.conf
ExecStop=/usr/bin/redis-cli shutdown
TimeoutStopSec=0
Restart=always
User=redis
Group=redis
RuntimeDirectory=redis
RuntimeDirectoryMode=0755

# Лимиты
LimitNOFILE=65535
LimitNPROC=4096

# Защита
PrivateTmp=yes
NoNewPrivileges=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=-/var/lib/redis
ReadWritePaths=-/var/log/redis
ReadWritePaths=-/var/run/redis

[Install]
WantedBy=multi-user.target
EOF

# Создание пользователя Redis если не существует
if ! id -u redis > /dev/null 2>&1; then
    adduser --system --group --no-create-home redis
fi

# Настройка прав
chown redis:redis /var/lib/redis
chown redis:redis /var/log/redis
chmod 640 /etc/redis/redis.conf
chown root:redis /etc/redis/redis.conf

# Настройка ядра для Redis
echo -e "${YELLOW}Шаг 4: Оптимизация системы${NC}"
cat >> /etc/sysctl.conf << 'EOF'

# Redis Optimizations
vm.overcommit_memory = 1
net.core.somaxconn = 1024
net.ipv4.tcp_max_syn_backlog = 1024
EOF

sysctl -p

# Отключение transparent huge pages
echo never > /sys/kernel/mm/transparent_hugepage/enabled
echo 'echo never > /sys/kernel/mm/transparent_hugepage/enabled' >> /etc/rc.local

# Запуск Redis
echo -e "${YELLOW}Шаг 5: Запуск Redis${NC}"
systemctl daemon-reload
systemctl enable redis
systemctl restart redis

# Проверка работы
sleep 2
if redis-cli -a "$REDIS_PASSWORD" ping | grep -q PONG; then
    echo -e "${GREEN}✓ Redis работает корректно${NC}"
else
    echo -e "${RED}✗ Ошибка запуска Redis${NC}"
    exit 1
fi

# Создание скрипта для проверки Redis
cat > /usr/local/bin/check-redis << EOF
#!/bin/bash
redis-cli -a "$REDIS_PASSWORD" ping
redis-cli -a "$REDIS_PASSWORD" info server | grep redis_version
redis-cli -a "$REDIS_PASSWORD" info memory | grep used_memory_human
redis-cli -a "$REDIS_PASSWORD" info stats | grep instantaneous_ops_per_sec
EOF

chmod +x /usr/local/bin/check-redis

# Создание скрипта бэкапа Redis
cat > /usr/local/bin/backup-redis << EOF
#!/bin/bash
BACKUP_DIR="/var/www/studx/backups/redis"
mkdir -p \$BACKUP_DIR
redis-cli -a "$REDIS_PASSWORD" BGSAVE
sleep 5
cp /var/lib/redis/dump.rdb "\$BACKUP_DIR/redis-\$(date +%Y%m%d_%H%M%S).rdb"
find \$BACKUP_DIR -name "*.rdb" -mtime +7 -delete
echo "Redis backup completed: \$(date)"
EOF

chmod +x /usr/local/bin/backup-redis

# Добавление в cron
echo "0 4 * * * /usr/local/bin/backup-redis >> /var/log/redis-backup.log 2>&1" | crontab -l | { cat; echo "0 4 * * * /usr/local/bin/backup-redis >> /var/log/redis-backup.log 2>&1"; } | crontab -

# Установка Redis Commander (веб-интерфейс) - опционально
echo -e "${YELLOW}Шаг 6: Установка Redis Commander (веб-интерфейс)${NC}"
npm install -g redis-commander

# Создание сервиса для Redis Commander
cat > /etc/systemd/system/redis-commander.service << EOF
[Unit]
Description=Redis Commander
After=network.target redis.service

[Service]
Type=simple
User=studx
Group=studx
WorkingDirectory=/var/www/studx
ExecStart=/usr/bin/redis-commander --redis-password $REDIS_PASSWORD --port 8081
Restart=always
Environment="NODE_ENV=production"

[Install]
WantedBy=multi-user.target
EOF

# Информация для пользователя
echo -e "${GREEN}==================================${NC}"
echo -e "${GREEN}Redis успешно настроен!${NC}"
echo -e "${GREEN}==================================${NC}"
echo ""
echo "Информация о Redis:"
echo "-------------------"
echo "Порт: 6379 (localhost only)"
echo "Пароль: $REDIS_PASSWORD"
echo "Память: 512MB максимум"
echo "Persistence: включен (AOF + RDB)"
echo ""
echo "Полезные команды:"
echo "-----------------"
echo "check-redis          - Проверка статуса"
echo "backup-redis         - Ручной бэкап"
echo "redis-cli -a [pass]  - Консоль Redis"
echo ""
echo "Redis Commander (веб-интерфейс):"
echo "--------------------------------"
echo "URL: http://157.230.21.54:8081"
echo "Для запуска: systemctl start redis-commander"
echo ""
echo -e "${YELLOW}Пароль сохранен в /var/www/studx/shared/.env${NC}"
echo -e "${GREEN}Бэкапы настроены каждую ночь в 4:00${NC}"
