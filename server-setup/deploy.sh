#!/bin/bash
# Deploy script for StudX with rollback support
# Использование: ./deploy.sh [rollback]

set -e  # Остановка при ошибке

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Конфигурация
PROJECT_DIR="/var/www/studx"
REPO_URL="https://github.com/YOUR_USERNAME/studx.git"  # ИЗМЕНИТЬ НА СВОЙ!
BRANCH="main"
MAX_RELEASES=5  # Сколько релизов хранить для отката

# Функция логирования
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}
# Проверка режима работы
if [ "$1" == "rollback" ]; then
    log "Откат на предыдущую версию..."
    cd $PROJECT_DIR
    
    # Находим предпоследний релиз
    PREV_RELEASE=$(ls -t releases | head -2 | tail -1)
    
    if [ -z "$PREV_RELEASE" ]; then
        error "Нет предыдущих релизов для отката"
    fi
    
    log "Откат на версию: $PREV_RELEASE"
    ln -sfn "$PROJECT_DIR/releases/$PREV_RELEASE" "$PROJECT_DIR/current"
    
    # Перезапуск PM2
    cd $PROJECT_DIR/current
    pm2 reload ecosystem.config.js --update-env
    
    log "✅ Откат завершен успешно!"
    exit 0
fi
# Основной деплой
log "🚀 Начинаю деплой StudX..."

# Создание структуры директорий
log "Создаю структуру директорий..."
mkdir -p $PROJECT_DIR/{releases,shared/{logs,uploads,backups}}

# Генерация метки времени для релиза
RELEASE=$(date +%Y%m%d%H%M%S)
RELEASE_DIR="$PROJECT_DIR/releases/$RELEASE"

# Клонирование репозитория
log "Клонирую репозиторий..."
git clone -b $BRANCH $REPO_URL $RELEASE_DIR || error "Не удалось клонировать репозиторий"

# Копирование shared файлов
log "Подключаю shared директории..."
ln -nfs $PROJECT_DIR/shared/uploads $RELEASE_DIR/backend/uploads
ln -nfs $PROJECT_DIR/shared/logs $RELEASE_DIR/backend/logs
# Копирование .env файла
log "Копирую конфигурацию..."
if [ -f "$PROJECT_DIR/shared/.env" ]; then
    cp $PROJECT_DIR/shared/.env $RELEASE_DIR/backend/.env
else
    warn "Файл .env не найден! Создайте $PROJECT_DIR/shared/.env"
fi

# Установка зависимостей
log "Устанавливаю зависимости..."
cd $RELEASE_DIR/backend
npm ci --production || error "Не удалось установить backend зависимости"

cd $RELEASE_DIR/frontend
npm ci || error "Не удалось установить frontend зависимости"

# Сборка фронтенда
log "Собираю фронтенд..."
npm run build || error "Не удалось собрать фронтенд"
# Миграции БД (если есть)
if [ -d "$RELEASE_DIR/backend/migrations" ]; then
    log "Запускаю миграции БД..."
    cd $RELEASE_DIR/backend
    npm run migrate || warn "Миграции не прошли - проверьте вручную"
fi

# Переключение на новый релиз
log "Активирую новый релиз..."
ln -sfn $RELEASE_DIR $PROJECT_DIR/current

# Копирование PM2 конфига
cp $RELEASE_DIR/server-setup/ecosystem.config.js $PROJECT_DIR/current/

# Перезапуск PM2
log "Перезапускаю приложение..."
cd $PROJECT_DIR/current
pm2 startOrReload ecosystem.config.js --update-env
# Health check после деплоя
log "Проверяю что приложение запустилось..."
sleep 5  # Даем время на старт

HEALTH_CHECK=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/health || echo "000")

if [ "$HEALTH_CHECK" = "200" ]; then
    log "✅ Приложение работает корректно!"
else
    error "❌ Приложение не отвечает! Откатываюсь..."
    ./deploy.sh rollback
fi

# Очистка старых релизов
log "Очищаю старые релизы..."
cd $PROJECT_DIR/releases
ls -t | tail -n +$((MAX_RELEASES + 1)) | xargs -r rm -rf

# Финальное сообщение
log "🎉 Деплой завершен успешно!"
log "Версия: $RELEASE"
log "URL: https://studx.ru"

# Запись в лог деплоев
echo "$(date '+%Y-%m-%d %H:%M:%S') - Deploy: $RELEASE - Success" >> $PROJECT_DIR/shared/deploy.log

exit 0