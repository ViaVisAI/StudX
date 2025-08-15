# 🚀 StudX - Инструкция по развертыванию на VPS

## Информация о сервере
- **IP адрес:** 157.230.21.54  
- **Домен:** studx.ru
- **Характеристики:** 2 vCPU, 4GB RAM, 80GB SSD
- **ОС:** Ubuntu 22.04 LTS

## 📋 Что нужно сделать ПРЯМО СЕЙЧАС

### Шаг 1: Настройка DNS (5 минут)
В панели Timeweb удали старые записи и добавь:
- **A запись:** @ → 157.230.21.54
- **A запись:** www → 157.230.21.54
- Остальные записи (MX, TXT) оставь как есть

Подожди 15-30 минут пока DNS обновится.

### Шаг 2: Первое подключение к серверу (2 минуты)

```bash
# На твоем компьютере выполни:
ssh root@157.230.21.54
```

При первом подключении введи пароль который пришел на email от DigitalOcean.

### Шаг 3: Копирование файлов на сервер (2 минуты)

```bash
# На твоем компьютере (НЕ на сервере!) выполни:
cd /Users/mak/Documents/StudX/StudX
scp -r server-setup root@157.230.21.54:/root/
```

### Шаг 4: Запуск главного установщика (10 минут)

```bash
# Теперь на сервере выполни:
cd /root/server-setup
chmod +x *.sh
./main-setup.sh
```

Скрипт автоматически:
- Установит весь необходимый софт
- Создаст пользователя studx  
- Настроит firewall и защиту
- Установит Node.js, PostgreSQL, Redis, Nginx
- Создаст структуру папок
- Настроит SSL сертификат

**ВАЖНО:** Скрипт выведет пароли для БД и Redis - СОХРАНИ ИХ!

### Шаг 5: Настройка переменных окружения (3 минуты)

```bash
# На сервере:
sudo -u studx nano /var/www/studx/shared/.env
```

Заполни обязательные поля:
- Пароль для БД (который показал скрипт)
- Пароль для Redis (который показал скрипт)  
- API ключи для генерации (твои ключи)
- JWT секрет (любая случайная строка)

Сохрани: Ctrl+O, Enter, Ctrl+X

### Шаг 6: Первый деплой (5 минут)

```bash
# Клонируем репозиторий
sudo -u studx bash
cd /var/www/studx
git clone https://github.com/ViaVisAI/StudX.git releases/$(date +%Y%m%d%H%M%S)
ln -sfn releases/$(date +%Y%m%d%H%M%S) current

# Устанавливаем зависимости
cd current
npm install --prefix backend
npm install --prefix frontend
npm run build --prefix frontend

# Инициализируем БД
cd backend
npx sequelize db:migrate

# Запускаем через PM2
pm2 start /var/www/studx/server-setup/ecosystem.config.js
pm2 save
pm2 startup
```

### Шаг 7: Проверка работы (1 минута)

Открой в браузере:
1. http://157.230.21.54 - должен редиректить на https
2. https://studx.ru - должен открыться сайт
3. https://studx.ru/api/health - должен показать статус "healthy"

## 🔥 Быстрые команды для управления

### Просмотр логов:
```bash
pm2 logs studx-backend
```

### Перезапуск приложения:
```bash
pm2 restart studx-backend
```

### Деплой обновлений:
```bash
cd /var/www/studx
./deploy.sh
```

### Проверка статуса:
```bash
pm2 status
systemctl status nginx
systemctl status postgresql
```

## 🆘 Решение проблем

### Если сайт не открывается:
1. Проверь DNS: `nslookup studx.ru`
2. Проверь nginx: `sudo systemctl status nginx`
3. Проверь PM2: `pm2 status`

### Если ошибка 502 Bad Gateway:
1. Проверь backend: `pm2 logs studx-backend`
2. Проверь порт: `sudo netstat -tlpn | grep 3000`
3. Перезапусти: `pm2 restart studx-backend`

### Если не работает БД:
1. Проверь PostgreSQL: `sudo systemctl status postgresql`
2. Проверь подключение: `psql -U studx_user -d studx_db`
3. Проверь пароль в .env файле

## 📝 Важные файлы и папки

```
/var/www/studx/
├── current/          # Текущая версия (симлинк)
├── releases/         # Все версии для отката
├── shared/           # Общие файлы
│   ├── .env         # Переменные окружения
│   ├── uploads/     # Загруженные файлы
│   └── logs/        # Логи приложения
└── deploy.sh        # Скрипт деплоя

/etc/nginx/sites-available/studx  # Конфиг nginx
/var/log/nginx/                   # Логи nginx
```

## 🔐 Пароли и доступы

Все пароли сохранены в файле на сервере:
```bash
cat /root/server-setup/credentials.txt
```

## ✅ Готово!

Теперь твой сайт работает на https://studx.ru

Для автоматического деплоя при пуше в GitHub:
1. Добавь SSH ключ сервера в GitHub Deploy Keys
2. Настрой webhook или GitHub Actions
3. При каждом пуше будет автоматический деплой

---
*Создано для StudX проекта*
