#!/bin/bash

# StudX System Check - Проверка готовности системы
# Запускается после настройки для проверки что все работает

set -e

# Цвета для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Счетчики
ERRORS=0
WARNINGS=0

echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║        StudX System Readiness Check        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
echo ""

# Функция проверки
check() {
    local name="$1"
    local command="$2"
    local critical="$3"  # true/false
    
    echo -n "→ Проверяю $name... "
    
    if eval "$command" >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC}"
        return 0
    else
        if [ "$critical" = "true" ]; then
            echo -e "${RED}✗ КРИТИЧНО${NC}"
            ((ERRORS++))
        else
            echo -e "${YELLOW}⚠ Предупреждение${NC}"
            ((WARNINGS++))
        fi
        return 1
    fi
}

echo -e "${YELLOW}1. Проверка системных компонентов${NC}"
echo "─────────────────────────────────"
check "Node.js установлен" "which node" true
check "Node.js версия >= 18" "node -v | grep -E 'v(1[89]|[2-9][0-9])'" true
check "NPM установлен" "which npm" true
check "PM2 установлен" "which pm2" true
check "Git установлен" "which git" true
check "Nginx установлен" "which nginx" true
check "PostgreSQL установлен" "which psql" true
check "Redis установлен" "which redis-cli" false
check "Certbot установлен" "which certbot" false

echo ""
echo -e "${YELLOW}2. Проверка сервисов${NC}"
echo "─────────────────────"
check "Nginx работает" "systemctl is-active nginx" true
check "PostgreSQL работает" "systemctl is-active postgresql" true
check "Redis работает" "systemctl is-active redis-server" false

echo ""
echo -e "${YELLOW}3. Проверка папок и прав${NC}"
echo "──────────────────────"
check "Папка /var/www/studx существует" "[ -d /var/www/studx ]" true
check "Пользователь studx существует" "id studx" true
check "Права на папку studx" "[ -w /var/www/studx ]" true
check "Папка логов существует" "[ -d /var/log/studx ]" false
check "Папка бэкапов существует" "[ -d /var/backups/studx ]" false

echo ""
echo -e "${YELLOW}4. Проверка БД${NC}"
echo "──────────────"
check "База studx_db существует" "sudo -u postgres psql -lqt | grep -q studx_db" true
check "Пользователь БД studx_user" "sudo -u postgres psql -c \"\\du\" | grep -q studx_user" true
check "Подключение к БД" "PGPASSWORD=\$(grep DB_PASSWORD /var/www/studx/shared/.env | cut -d'=' -f2) psql -U studx_user -d studx_db -c 'SELECT 1'" false

echo ""
echo -e "${YELLOW}5. Проверка конфигурации${NC}"
echo "───────────────────────"
check "Nginx конфиг studx.ru" "[ -f /etc/nginx/sites-enabled/studx.ru ]" true
check "PM2 ecosystem.config.js" "[ -f /var/www/studx/ecosystem.config.js ]" true
check ".env файл" "[ -f /var/www/studx/shared/.env ]" true
check "SSL сертификат" "[ -d /etc/letsencrypt/live/studx.ru ]" false

echo ""
echo -e "${YELLOW}6. Проверка сети${NC}"
echo "────────────────"
check "Порт 80 открыт" "nc -zv localhost 80" true
check "Порт 443 открыт" "nc -zv localhost 443" false
check "Порт 3000 (backend)" "nc -zv localhost 3000" false
check "DNS резолвинг studx.ru" "nslookup studx.ru" false

echo ""
echo -e "${YELLOW}7. Проверка приложения${NC}"
echo "──────────────────────"

# Проверка backend
if [ -d "/var/www/studx/current/backend" ]; then
    check "Backend папка" "[ -d /var/www/studx/current/backend ]" true
    check "node_modules backend" "[ -d /var/www/studx/current/backend/node_modules ]" false
else
    echo -e "→ Backend папка... ${YELLOW}⚠ Еще не задеплоено${NC}"
fi

# Проверка frontend
if [ -d "/var/www/studx/current/frontend" ]; then
    check "Frontend папка" "[ -d /var/www/studx/current/frontend ]" true
    check "Frontend build" "[ -d /var/www/studx/current/frontend/build ]" false
else
    echo -e "→ Frontend папка... ${YELLOW}⚠ Еще не задеплоено${NC}"
fi

# PM2 процессы
if pm2 list 2>/dev/null | grep -q "studx-backend"; then
    check "PM2 процесс studx-backend" "pm2 list | grep -q 'online.*studx-backend'" false
else
    echo -e "→ PM2 процесс... ${YELLOW}⚠ Еще не запущен${NC}"
fi

echo ""
echo -e "${YELLOW}8. Проверка безопасности${NC}"
echo "───────────────────────"
check "UFW firewall включен" "ufw status | grep -q 'Status: active'" false
check "Fail2ban установлен" "which fail2ban-client" false
check "SSH ключевая аутентификация" "grep -q 'PasswordAuthentication no' /etc/ssh/sshd_config" false
check "Root login отключен" "grep -q 'PermitRootLogin no' /etc/ssh/sshd_config" false

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              РЕЗУЛЬТАТЫ ПРОВЕРКИ           ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✅ СИСТЕМА ПОЛНОСТЬЮ ГОТОВА К РАБОТЕ!${NC}"
    echo ""
    echo -e "${GREEN}Следующие шаги:${NC}"
    echo "1. Запустить первый деплой: cd /var/www/studx && ./deploy.sh"
    echo "2. Проверить сайт: https://studx.ru"
    echo "3. Настроить мониторинг: crontab -e"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠️  СИСТЕМА ГОТОВА, НО ЕСТЬ ПРЕДУПРЕЖДЕНИЯ${NC}"
    echo ""
    echo -e "Критических ошибок: ${GREEN}0${NC}"
    echo -e "Предупреждений: ${YELLOW}$WARNINGS${NC}"
    echo ""
    echo -e "${YELLOW}Рекомендации:${NC}"
    echo "• Проверьте предупреждения выше"
    echo "• Большинство можно игнорировать для старта"
    echo "• SSL и Redis желательно настроить позже"
    exit 0
else
    echo -e "${RED}❌ СИСТЕМА НЕ ГОТОВА К РАБОТЕ${NC}"
    echo ""
    echo -e "Критических ошибок: ${RED}$ERRORS${NC}"
    echo -e "Предупреждений: ${YELLOW}$WARNINGS${NC}"
    echo ""
    echo -e "${RED}Необходимо исправить:${NC}"
    echo "• Все пункты помеченные красным ✗"
    echo "• Запустите setup.sh для установки компонентов"
    echo "• Проверьте логи: journalctl -xe"
    exit 1
fi
