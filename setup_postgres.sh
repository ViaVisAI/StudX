#!/bin/bash
# PostgreSQL Installation Script for StudX VPS

echo "=== Installing PostgreSQL for StudX ==="

# Update system
sudo apt update && sudo apt upgrade -y

# Install PostgreSQL
sudo apt install postgresql postgresql-contrib -y

# Start and enable PostgreSQL
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Generate secure password
DB_PASSWORD=$(openssl rand -base64 32)
echo "Generated secure password: $DB_PASSWORD"

# Create database and user
sudo -u postgres psql <<EOF
CREATE USER studx_user WITH ENCRYPTED PASSWORD '$DB_PASSWORD';
CREATE DATABASE studx_db OWNER studx_user;
GRANT ALL PRIVILEGES ON DATABASE studx_db TO studx_user;
\q
EOF

# Configure PostgreSQL for remote access
PG_VERSION=$(sudo -u postgres psql -t -c "SELECT version();" | grep -oP '\d+\.\d+' | head -1)
PG_CONF="/etc/postgresql/$PG_VERSION/main/postgresql.conf"
PG_HBA="/etc/postgresql/$PG_VERSION/main/pg_hba.conf"

# Allow connections from anywhere (we'll use firewall for security)
sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" $PG_CONF

# Add connection rule
echo "host    all             all             0.0.0.0/0               md5" | sudo tee -a $PG_HBA

# Restart PostgreSQL
sudo systemctl restart postgresql

# Configure firewall
sudo ufw allow 5432/tcp
sudo ufw allow OpenSSH
sudo ufw --force enable

echo "=== PostgreSQL Installation Complete ==="
echo ""
echo "Database: studx_db"
echo "User: studx_user"
echo "Password: $DB_PASSWORD"
echo "Connection string: postgres://studx_user:$DB_PASSWORD@167.71.48.249:5432/studx_db"
echo ""
echo "SAVE THIS PASSWORD! It will not be shown again."
