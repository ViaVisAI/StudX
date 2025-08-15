#!/bin/bash
# СКОПИРУЙ ЭТИ КОМАНДЫ В КОНСОЛЬ

# 1. Смотрим какие JS файлы есть
echo "📁 JS файлы в backend:"
ls *.js 2>/dev/null | head -10

# 2. Смотрим что в package.json (там указан главный файл)
echo ""
echo "📦 Проверяю package.json:"
cat package.json | grep -E '"main"|"start"|"scripts"' -A 2

# 3. Ищем типичные имена главных файлов
echo ""
echo "🔍 Поиск главного файла:"
for file in app.js index.js main.js src/index.js src/app.js src/server.js bin/www; do
  if [ -f "$file" ]; then
    echo "✅ НАЙДЕН: $file"
    MAIN_FILE="$file"
    break
  fi
done

# 4. Если нашли - запускаем
if [ ! -z "$MAIN_FILE" ]; then
  echo ""
  echo "🚀 Запускаю $MAIN_FILE через PM2:"
  pm2 start $MAIN_FILE --name studx-backend
  pm2 save
  pm2 startup systemd -u root --hp /root | tail -n 1 | bash
  
  sleep 3
  pm2 status
  echo ""
  echo "✅ ЗАПУЩЕНО! Проверяю..."
  curl -s localhost:3000/api/health || echo "API endpoint не настроен, но сервер должен работать"
else
  echo "❌ Главный файл не найден автоматически!"
  echo "Посмотри на список файлов выше и запусти вручную:"
  echo "pm2 start ИМЯ_ФАЙЛА.js --name studx-backend"
fi