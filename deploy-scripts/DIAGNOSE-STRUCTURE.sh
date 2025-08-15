#!/bin/bash
# СКОПИРУЙ В КОНСОЛЬ ДЛЯ ДИАГНОСТИКИ

echo "🔍 ДИАГНОСТИКА СТРУКТУРЫ ПРОЕКТА"
echo "================================"

echo ""
echo "📁 Что есть в backend папке:"
ls -la /var/www/studx/current/backend/ | head -15

echo ""
echo "📁 Что есть в корне проекта:"
ls -la /var/www/studx/current/ | head -15

echo ""
echo "📁 Проверяю есть ли папка src:"
ls -la /var/www/studx/current/backend/src/ 2>/dev/null | head -10 || echo "❌ Папки src нет"

echo ""
echo "🔍 Ищу JS файлы во всем проекте:"
find /var/www/studx/current -name "*.js" -type f | head -20

echo ""
echo "📦 Проверяю package.json в корне:"
cat /var/www/studx/current/package.json 2>/dev/null | grep -E '"main"|"start"|"scripts"' -A 3 || echo "❌ package.json не в корне"

echo ""
echo "📦 Проверяю package.json в backend:"
cat /var/www/studx/current/backend/package.json 2>/dev/null | grep -E '"main"|"start"|"scripts"' -A 3 || echo "❌ package.json не в backend"

echo ""
echo "🔍 Ищу server/app/index файлы рекурсивно:"
find /var/www/studx/current -name "server.js" -o -name "app.js" -o -name "index.js" 2>/dev/null | head -10

echo ""
echo "📁 Структура backend папки (рекурсивно):"
tree /var/www/studx/current/backend -L 3 2>/dev/null || ls -R /var/www/studx/current/backend | head -50