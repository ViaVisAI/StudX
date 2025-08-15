#!/bin/bash
# SSH Security hardening for StudX VPS

set -e

# Цвета
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== Защита SSH доступа ===${NC}"

# Бэкап текущего конфига
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.$(date +%Y%m%d)

# Создание нового защищенного конфига
cat > /etc/ssh/sshd_config << 'EOF'
# StudX SSH Security Configuration

# Порт (можешь изменить для скрытности)
Port 22

# Протокол только версии 2
Protocol 2

# Отключаем root логин
PermitRootLogin no

# Только ключи, без паролей
PasswordAuthentication no
PubkeyAuthentication yes
ChallengeResponseAuthentication no

# Защита от брутфорса
MaxAuthTries 3
MaxSessions 10
LoginGraceTime 20

# Отключаем пустые пароли
PermitEmptyPasswords no

# Отключаем X11 forwarding (не нужен на сервере)
X11Forwarding no

# Отключаем ненужные методы аутентификации
GSSAPIAuthentication no
UsePAM yes

# Keepalive для стабильного соединения
ClientAliveInterval 300
ClientAliveCountMax 2

# Логирование попыток входа
SyslogFacility AUTH
LogLevel VERBOSE

# Разрешаем только конкретного пользователя (замени на своего!)
AllowUsers studx

# Баннер безопасности
Banner /etc/ssh/banner.txt
EOF

# Создание баннера безопасности
cat > /etc/ssh/banner.txt << 'EOF'
******************************************************************
*                      AUTHORIZED ACCESS ONLY                    *
* Unauthorized access to this system is strictly prohibited.     *
* All access attempts are logged and monitored.                  *
******************************************************************
EOF

# Создание пользователя если не существует
if ! id -u studx > /dev/null 2>&1; then
    echo -e "${GREEN}Создаю пользователя studx...${NC}"
    useradd -m -s /bin/bash studx
    usermod -aG sudo studx
    
    # Создание SSH директории
    mkdir -p /home/studx/.ssh
    touch /home/studx/.ssh/authorized_keys
    chmod 700 /home/studx/.ssh
    chmod 600 /home/studx/.ssh/authorized_keys
    chown -R studx:studx /home/studx/.ssh
    
    echo -e "${YELLOW}ВАЖНО: Добавь свой SSH ключ в /home/studx/.ssh/authorized_keys${NC}"
fi

# Настройка Fail2ban для защиты от брутфорса
if ! command -v fail2ban-client &> /dev/null; then
    echo -e "${GREEN}Устанавливаю Fail2ban...${NC}"
    apt-get update
    apt-get install -y fail2ban
fi

# Конфиг Fail2ban для SSH
cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3
destemail = admin@studx.ru
action = %(action_mwl)s

[sshd]
enabled = true
port = 22
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
EOF

# Перезапуск сервисов
systemctl restart sshd
systemctl enable fail2ban
systemctl restart fail2ban

echo -e "${GREEN}✅ SSH защищен!${NC}"
echo -e "${YELLOW}Теперь подключайся только через:${NC}"
echo -e "${YELLOW}ssh studx@157.230.21.54${NC}"
echo -e "${YELLOW}С использованием SSH ключа (без пароля)${NC}"
