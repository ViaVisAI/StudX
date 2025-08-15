#!/bin/bash
# Генерация SSH ключа для GitHub Actions автодеплоя

echo "🔑 Создание SSH ключа для автоматического деплоя"
echo "================================================"

# Генерируем ключ
ssh-keygen -t ed25519 -C "studx-deploy@github-actions" -f ~/.ssh/studx_deploy_key -N ""

echo ""
echo "✅ SSH ключ создан!"
echo ""
echo "📋 ШАГ 1: Добавь ПРИВАТНЫЙ ключ в GitHub Secrets"
echo "================================================"
echo "1. Открой https://github.com/ViaVisAI/StudX/settings/secrets/actions"
echo "2. Нажми 'New repository secret'"
echo "3. Name: SSH_DEPLOY_KEY"
echo "4. Value: (скопируй содержимое ниже)"
echo ""
echo "--- НАЧАЛО ПРИВАТНОГО КЛЮЧА ---"
cat ~/.ssh/studx_deploy_key
echo "--- КОНЕЦ ПРИВАТНОГО КЛЮЧА ---"
echo ""
echo ""
echo "📋 ШАГ 2: Добавь ПУБЛИЧНЫЙ ключ на сервер"
echo "=========================================="
echo "Выполни на сервере под пользователем studx:"
echo ""
echo "mkdir -p ~/.ssh"
echo "echo '$(cat ~/.ssh/studx_deploy_key.pub)' >> ~/.ssh/authorized_keys"
echo "chmod 600 ~/.ssh/authorized_keys"
echo ""
echo "Или скопируй публичный ключ:"
echo ""
cat ~/.ssh/studx_deploy_key.pub
echo ""
echo ""
echo "✅ После выполнения этих шагов GitHub Actions сможет деплоить автоматически!"
