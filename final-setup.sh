#!/bin/bash

# StudX Final Setup & Monitor
# Завершение настройки и проверка работы

set -e

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║        StudX Final Setup               ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# 1. Настройка автозапуска PM2
echo -e "${YELLOW}⚙️  Настройка автозапуска PM2...${NC}"
pm2 startup systemd -u root --hp /root --no-treekill | grep "sudo" | bash 2>/dev/null || {
    echo -e "${GREEN}✅ PM2 автозапуск уже настроен${NC}"
}
pm2 save

# 2. Проверка PM2
echo -e "\n${YELLOW}📊 Статус PM2:${NC}"
pm2 status

# 3. Проверка локального API
echo -e "\n${YELLOW}🔍 Проверка локального API...${NC}"
if curl -s http://localhost:3000/api/health | python3 -m json.tool; then
    echo -e "${GREEN}✅ API работает локально${NC}"
else
    echo -e "${RED}❌ API не отвечает${NC}"
    echo "Смотрим логи..."
    pm2 logs studx-backend --lines 10 --nostream
fi

# 4. Перезапуск Nginx
echo -e "\n${YELLOW}🌐 Проверка и перезапуск Nginx...${NC}"
nginx -t && systemctl reload nginx && echo -e "${GREEN}✅ Nginx перезапущен${NC}"

# 5. Проверка SSL
echo -e "\n${YELLOW}🔒 Проверка SSL сертификата...${NC}"
echo | openssl s_client -connect studx.ru:443 2>/dev/null | openssl x509 -noout -dates && echo -e "${GREEN}✅ SSL работает${NC}"

# 6. Финальная проверка HTTPS API
echo -e "\n${YELLOW}🌍 Проверка HTTPS API...${NC}"
sleep 2
if curl -s https://studx.ru/api/health | python3 -m json.tool; then
    echo -e "${GREEN}✅ HTTPS API работает${NC}"
else
    echo -e "${YELLOW}⚠️  HTTPS API пока не отвечает, пробуем еще раз...${NC}"
    sleep 5
    curl -v https://studx.ru/api/health
fi

# 7. Проверка главной страницы
echo -e "\n${YELLOW}🏠 Проверка главной страницы...${NC}"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://studx.ru)
if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "304" ]; then
    echo -e "${GREEN}✅ Главная страница доступна (HTTP $HTTP_CODE)${NC}"
else
    echo -e "${YELLOW}⚠️  Главная страница вернула код: $HTTP_CODE${NC}"
fi

# 8. Системная информация
echo -e "\n${BLUE}═══════════════════════════════════════${NC}"
echo -e "${BLUE}       СИСТЕМНАЯ ИНФОРМАЦИЯ${NC}"
echo -e "${BLUE}═══════════════════════════════════════${NC}"

echo -e "\n${YELLOW}💾 Использование диска:${NC}"
df -h | grep -E "^/dev|Filesystem"

echo -e "\n${YELLOW}💻 Использование памяти:${NC}"
free -h

echo -e "\n${YELLOW}🔥 Активные процессы:${NC}"
ps aux | grep -E "node|nginx|postgres|redis" | grep -v grep | awk '{print $11}' | sort | uniq -c

echo -e "\n${YELLOW}🔌 Открытые порты:${NC}"
ss -tulpn | grep LISTEN | grep -E ":(22|80|443|3000|5432|6379)"

# 9. Итоговый статус
echo -e "\n${BLUE}═══════════════════════════════════════${NC}"
echo -e "${BLUE}           ИТОГОВЫЙ СТАТУС${NC}"
echo -e "${BLUE}═══════════════════════════════════════${NC}"

CHECKS_PASSED=0
CHECKS_TOTAL=5

# Проверка PM2
pm2 status | grep -q "online" && ((CHECKS_PASSED++)) && echo -e "✅ PM2 процесс работает" || echo -e "❌ PM2 процесс не работает"

# Проверка локального API
curl -s http://localhost:3000/api/health > /dev/null 2>&1 && ((CHECKS_PASSED++)) && echo -e "✅ Локальный API отвечает" || echo -e "❌ Локальный API не отвечает"

# Проверка Nginx
systemctl is-active nginx > /dev/null && ((CHECKS_PASSED++)) && echo -e "✅ Nginx активен" || echo -e "❌ Nginx не активен"

# Проверка PostgreSQL
systemctl is-active postgresql > /dev/null && ((CHECKS_PASSED++)) && echo -e "✅ PostgreSQL активен" || echo -e "❌ PostgreSQL не активен"

# Проверка HTTPS
curl -s https://studx.ru > /dev/null 2>&1 && ((CHECKS_PASSED++)) && echo -e "✅ HTTPS доступен" || echo -e "❌ HTTPS недоступен"

echo ""
if [ $CHECKS_PASSED -eq $CHECKS_TOTAL ]; then
    echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   🎉 StudX ПОЛНОСТЬЮ РАБОТАЕТ! 🎉     ║${NC}"
    echo -e "${GREEN}║                                        ║${NC}"
    echo -e "${GREEN}║   https://studx.ru - ДОСТУПЕН         ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
else
    echo -e "${YELLOW}⚠️  Пройдено проверок: $CHECKS_PASSED из $CHECKS_TOTAL${NC}"
    echo -e "${YELLOW}Требуется дополнительная настройка${NC}"
fi

echo -e "\n${BLUE}📝 Полезные команды:${NC}"
echo "  pm2 logs studx-backend      - логи backend"
echo "  pm2 restart studx-backend   - перезапуск"
echo "  pm2 monit                   - мониторинг"
echo "  tail -f /var/log/nginx/error.log - логи Nginx"
echo ""