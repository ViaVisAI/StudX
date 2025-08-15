#!/bin/bash
set -e

# StudX Server Setup Script v1.0
# Automatic server configuration for studx.ru

echo "==================================="
echo "StudX Server Setup - Starting..."
echo "==================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root${NC}" 
   exit 1
fi

echo -e "${GREEN}✓ Running as root${NC}"

# Variables
DOMAIN="studx.ru"
APP_USER="studx"
APP_DIR="/var/www/studx"
NODE_VERSION="20"

# Step 1: System Update
echo -e "\n${YELLOW}Step 1: Updating system...${NC}"
apt update && apt upgrade -y
echo -e "${GREEN}✓ System updated${NC}"

# Step 2: Create swap file (additional memory buffer)
echo -e "\n${YELLOW}Step 2: Creating 2GB swap file...${NC}"
if [ ! -f /swapfile ]; then
    fallocate -l 2G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' | tee -a /etc/fstab
    echo -e "${GREEN}✓ Swap file created${NC}"
else
    echo -e "${GREEN}✓ Swap file already exists${NC}"
fi

# Step 3: Install essential packages
echo -e "\n${YELLOW}Step 3: Installing essential packages...${NC}"
apt install -y curl wget git build-essential software-properties-common ufw fail2ban

# Step 4: Configure firewall
echo -e "\n${YELLOW}Step 4: Configuring firewall...${NC}"
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
echo "y" | ufw enable
echo -e "${GREEN}✓ Firewall configured${NC}"

# Step 5: Setup fail2ban for SSH protection
echo -e "\n${YELLOW}Step 5: Configuring fail2ban...${NC}"
systemctl enable fail2ban
systemctl start fail2ban
echo -e "${GREEN}✓ Fail2ban configured${NC}"

# Step 6: Create application user
echo -e "\n${YELLOW}Step 6: Creating application user...${NC}"
if ! id "$APP_USER" &>/dev/null; then
    useradd -m -s /bin/bash $APP_USER
    usermod -aG sudo $APP_USER
    echo -e "${GREEN}✓ User $APP_USER created${NC}"
else
    echo -e "${GREEN}✓ User $APP_USER already exists${NC}"
fi

# Step 7: Install Node.js
echo -e "\n${YELLOW}Step 7: Installing Node.js v${NODE_VERSION}...${NC}"
curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash -
apt install -y nodejs
npm install -g npm@latest
echo -e "${GREEN}✓ Node.js $(node -v) installed${NC}"

# Step 8: Install PM2
echo -e "\n${YELLOW}Step 8: Installing PM2...${NC}"
npm install -g pm2
pm2 startup systemd -u $APP_USER --hp /home/$APP_USER
echo -e "${GREEN}✓ PM2 installed${NC}"

# Step 9: Install PostgreSQL
echo -e "\n${YELLOW}Step 9: Installing PostgreSQL...${NC}"
apt install -y postgresql postgresql-contrib
systemctl enable postgresql
systemctl start postgresql

# Generate secure password
DB_PASSWORD=$(openssl rand -base64 32)

# Create database and user
sudo -u postgres psql <<EOF
CREATE USER studx_user WITH PASSWORD '$DB_PASSWORD';
CREATE DATABASE studx_db OWNER studx_user;
GRANT ALL PRIVILEGES ON DATABASE studx_db TO studx_user;
EOF

# Save credentials
echo "Database credentials saved to /root/db_credentials.txt"
cat > /root/db_credentials.txt <<EOF
Database: studx_db
User: studx_user
Password: $DB_PASSWORD
EOF
chmod 600 /root/db_credentials.txt

echo -e "${GREEN}✓ PostgreSQL configured${NC}"

# Step 10: Install Redis
echo -e "\n${YELLOW}Step 10: Installing Redis...${NC}"
apt install -y redis-server
sed -i 's/supervised no/supervised systemd/g' /etc/redis/redis.conf
sed -i 's/# maxmemory <bytes>/maxmemory 512mb/g' /etc/redis/redis.conf
sed -i 's/# maxmemory-policy noeviction/maxmemory-policy allkeys-lru/g' /etc/redis/redis.conf
systemctl restart redis-server
systemctl enable redis-server
echo -e "${GREEN}✓ Redis configured${NC}"

# Step 11: Install Nginx
echo -e "\n${YELLOW}Step 11: Installing Nginx...${NC}"
apt install -y nginx
systemctl enable nginx
echo -e "${GREEN}✓ Nginx installed${NC}"

# Step 12: Create application directory structure
echo -e "\n${YELLOW}Step 12: Creating application directories...${NC}"
mkdir -p $APP_DIR/{current,releases,shared/{config,logs,uploads}}
chown -R $APP_USER:$APP_USER $APP_DIR
echo -e "${GREEN}✓ Application directories created${NC}"

# Step 13: Install Certbot for SSL
echo -e "\n${YELLOW}Step 13: Installing Certbot...${NC}"
snap install --classic certbot
ln -sf /snap/bin/certbot /usr/bin/certbot
echo -e "${GREEN}✓ Certbot installed${NC}"

# Step 14: Setup automatic backups
echo -e "\n${YELLOW}Step 14: Setting up automatic backups...${NC}"
mkdir -p /var/backups/studx
cat > /etc/cron.d/studx-backup <<EOF
0 3 * * * root /usr/bin/pg_dump -U studx_user studx_db | gzip > /var/backups/studx/db_\$(date +\%Y\%m\%d).sql.gz
0 4 * * * root find /var/backups/studx -name "*.sql.gz" -mtime +7 -delete
EOF
echo -e "${GREEN}✓ Automatic backups configured${NC}"

# Step 15: System optimizations
echo -e "\n${YELLOW}Step 15: Applying system optimizations...${NC}"
cat >> /etc/sysctl.conf <<EOF

# StudX optimizations
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 30
vm.swappiness = 10
EOF
sysctl -p
echo -e "${GREEN}✓ System optimizations applied${NC}"

# Final message
echo -e "\n${GREEN}==================================="
echo "StudX Server Setup Complete!"
echo "===================================${NC}"
echo ""
echo "Next steps:"
echo "1. Configure Nginx for your domain (nginx config ready in this folder)"
echo "2. Upload your application code to $APP_DIR/current"
echo "3. Configure environment variables in $APP_DIR/shared/config/.env"
echo "4. Run: pm2 start ecosystem.config.js"
echo "5. Setup SSL: certbot --nginx -d $DOMAIN -d www.$DOMAIN"
echo ""
echo "Database credentials saved in: /root/db_credentials.txt"
echo ""
echo -e "${GREEN}Server is ready for StudX deployment!${NC}"
