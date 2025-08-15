# 🚀 StudX - Запуск на Production

## ✅ Что уже готово:
- **VPS создан:** 157.230.21.54 (2 vCPU, 4GB RAM, Ubuntu 22.04)
- **Домен:** studx.ru (нужно настроить DNS)
- **Все скрипты установки готовы** в папке server-setup/
- **GitHub Actions настроен** для автодеплоя

## 📋 Что нужно сделать ПРЯМО СЕЙЧАС:

### Шаг 1: Настройка DNS (5 минут)
В панели Timeweb удали старые записи и добавь новые:
```
Тип: A    Хост: @     Значение: 157.230.21.54
Тип: A    Хост: www   Значение: 157.230.21.54
```
Остальные записи (MX, TXT) оставь как есть для почты.

### Шаг 2: Добавление SSH ключа на сервер (2 минуты)
```bash
# На твоем компьютере:
# Если нет SSH ключа, создай:
ssh-keygen -t ed25519 -C "your_email@example.com"

# Скопируй публичный ключ:
cat ~/.ssh/id_ed25519.pub

# Зайди на сервер через консоль DigitalOcean (в панели управления)
# И добавь ключ:
echo "ТВОЙ_ПУБЛИЧНЫЙ_КЛЮЧ" >> ~/.ssh/authorized_keys
```

### Шаг 3: Запуск установки (10 минут)
```bash
# Подключись к серверу:
ssh root@157.230.21.54

# Скачай и запусти установщик:
wget https://raw.githubusercontent.com/ViaVisAI/StudX/main/server-setup/first-run.sh
chmod +x first-run.sh
./first-run.sh

# Скрипт все сделает автоматически!
```

### Шаг 4: Сохрани пароли!
После установки появится файл `/root/studx-info.txt` с паролями.
**ОБЯЗАТЕЛЬНО СОХРАНИ ЕГО В БЕЗОПАСНОЕ МЕСТО!**

### Шаг 5: Добавь API ключи
```bash
# Открой файл конфигурации:
nano /var/www/studx/shared/config/.env.production

# Добавь свои ключи:
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...

# Сохрани: Ctrl+O, Enter, Ctrl+X

# Перезапусти приложение:
pm2 reload all
```

### Шаг 6: Настрой GitHub для автодеплоя
В репозитории GitHub:
1. Settings → Secrets and variables → Actions
2. Добавь секреты:
   - `SERVER_HOST`: 157.230.21.54
   - `SERVER_USER`: root
   - `SERVER_SSH_KEY`: содержимое твоего приватного ключа (~/.ssh/id_ed25519)
   - `SERVER_HOST_KEY`: получи командой `ssh-keyscan 157.230.21.54`

## 🎯 Проверка что все работает:

### 1. Проверь сайт:
- Открой https://studx.ru - должен работать с SSL
- Проверь /api/health - должен вернуть статус

### 2. Проверь процессы:
```bash
pm2 status  # Должны быть 2 процесса studx
pm2 logs    # Логи приложения
```

### 3. Проверь базу данных:
```bash
sudo -u postgres psql -c "\l"  # Список БД
```

### 4. Проверь автодеплой:
Сделай коммит в main ветку - должен автоматически задеплоиться.

## 🔧 Полезные команды:

### Управление приложением:
```bash
pm2 restart all       # Перезапустить
pm2 logs             # Посмотреть логи
pm2 monit            # Мониторинг в реальном времени
```

### Бэкапы БД:
```bash
# Ручной бэкап:
pg_dump studx_production | gzip > backup_$(date +%Y%m%d).sql.gz

# Восстановление:
gunzip < backup_20240101.sql.gz | psql studx_production
```

### Откат на предыдущую версию:
```bash
cd /var/www/studx/releases
ls -la  # Список версий
ln -sfn /var/www/studx/releases/СТАРАЯ_ВЕРСИЯ /var/www/studx/current
pm2 reload all
```

## ⚠️ Если что-то пошло не так:

### DNS не работает:
- Подожди до 2 часов - DNS обновляется не мгновенно
- Проверь: `nslookup studx.ru`

### Сайт не открывается:
```bash
# Проверь nginx:
nginx -t
systemctl status nginx

# Проверь приложение:
pm2 status
curl http://localhost:3000/api/health
```

### База данных не работает:
```bash
systemctl status postgresql
sudo -u postgres psql
```

## 📊 Мониторинг:

### Проверка ресурсов:
```bash
htop     # CPU и память
df -h    # Место на диске
ncdu /   # Что занимает место
```

### Логи:
```bash
# Приложение:
pm2 logs

# Nginx:
tail -f /var/log/nginx/error.log

# PostgreSQL:
tail -f /var/log/postgresql/*.log
```

## 🎉 Готово!

После выполнения всех шагов у тебя будет:
- ✅ Рабочий сайт на https://studx.ru
- ✅ SSL сертификат с автообновлением
- ✅ Автоматические бэкапы каждую ночь
- ✅ Автодеплой при пуше в GitHub
- ✅ Мониторинг и логирование
- ✅ Защита от взлома и DDoS

## 💡 Что дальше:

1. **Протестируй основные функции** - создание заказа, генерация
2. **Настрой email** если нужна отправка писем
3. **Добавь домен в Google Search Console** для SEO
4. **Настрой аналитику** (Google Analytics, Яндекс.Метрика)

---

**Техническая поддержка:** Если возникли проблемы, покажи логи и опиши что не работает.
