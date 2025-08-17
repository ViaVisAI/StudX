#!/bin/bash
# Установка PostgreSQL на VPS Digital Ocean для StudX

echo "==========================================="
echo "  Установка PostgreSQL для StudX"
echo "==========================================="

# Обновление системы
echo "[1/6] Обновление системы..."
apt update && apt upgrade -y

# Установка PostgreSQL
echo "[2/6] Установка PostgreSQL..."
apt install -y postgresql postgresql-contrib

# Генерация надежного пароля для БД
DB_PASSWORD="StudX_Db2025_$(openssl rand -hex 8)"
echo "[3/6] Сгенерирован пароль: $DB_PASSWORD"

# Настройка PostgreSQL
echo "[4/6] Настройка PostgreSQL..."
sudo -u postgres psql <<EOF
-- Создание пользователя для StudX
CREATE USER studx_user WITH ENCRYPTED PASSWORD '$DB_PASSWORD';

-- Создание базы данных
CREATE DATABASE studx_db OWNER studx_user;

-- Полные права для пользователя
GRANT ALL PRIVILEGES ON DATABASE studx_db TO studx_user;

-- Создание расширений для полнотекстового поиска (для генерации текстов)
\c studx_db
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS unaccent;
EOF

# Настройка доступа к БД
echo "[5/6] Настройка удаленного доступа..."

# Настройка postgresql.conf для прослушивания всех интерфейсов
PG_VERSION=$(sudo -u postgres psql -t -c "SELECT version();" | grep -oP '\d+(?=\.)')
CONF_PATH="/etc/postgresql/$PG_VERSION/main/postgresql.conf"
HBA_PATH="/etc/postgresql/$PG_VERSION/main/pg_hba.conf"

# Разрешаем подключения с любого IP (только для приватной сети VPC)
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" $CONF_PATH

# Добавляем правило для приватной сети Digital Ocean VPC
echo "# StudX connection from VPC" >> $HBA_PATH
echo "host    studx_db    studx_user    10.114.0.0/20    md5" >> $HBA_PATH
echo "# Localhost connection" >> $HBA_PATH
echo "host    studx_db    studx_user    127.0.0.1/32     md5" >> $HBA_PATH

# Перезапуск PostgreSQL
echo "[6/6] Перезапуск PostgreSQL..."
systemctl restart postgresql

# Проверка статуса
systemctl status postgresql --no-pager

echo ""
echo "==========================================="
echo "  УСТАНОВКА ЗАВЕРШЕНА!"
echo "==========================================="
echo ""
echo "СОХРАНИ ЭТИ ДАННЫЕ:"
echo "-------------------"
echo "База данных: studx_db"
echo "Пользователь: studx_user"
echo "Пароль: $DB_PASSWORD"
echo "Хост: 167.71.48.249 (внешний) или 10.114.0.2 (внутренний VPC)"
echo "Порт: 5432"
echo ""
echo "Строка подключения для DBHub:"
echo "postgres://studx_user:$DB_PASSWORD@167.71.48.249:5432/studx_db?sslmode=disable"
echo ""
echo "==========================================="