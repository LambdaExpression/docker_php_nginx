#!/bin/sh
set -e

echo "=== 容器启动初始化 ==="
echo "当前用户: $(whoami)"
echo "工作目录: $(pwd)"

# 等待数据库（如果使用外部数据库）
if [ "${WAIT_FOR_DB}" = "true" ]; then
    echo "等待数据库服务..."
    while ! nc -z ${DB_HOST:-mysql} ${DB_PORT:-3306}; do
        sleep 1
    done
    echo "数据库服务已就绪"
fi

# 等待 Redis（如果使用）
if [ "${WAIT_FOR_REDIS}" = "true" ]; then
    echo "等待Redis服务..."
    while ! nc -z ${REDIS_HOST:-redis} ${REDIS_PORT:-6379}; do
        sleep 1
    done
    echo "Redis服务已就绪"
fi

# 设置目录权限
echo "设置目录权限..."
mkdir -p /app/backend/runtime /app/backend/web/assets
chown -R www-data:www-data /app
chmod -R 755 /app
chmod -R 777 /app/backend/runtime /app/backend/web/assets

# 生成环境配置文件（如果需要）
if [ ! -f "/app/.env" ]; then
    echo "生成环境配置文件..."
    cat > /app/.env << EOF
YII_ENV=${YII_ENV:-prod}
YII_DEBUG=${YII_DEBUG:-0}
DB_HOST=${DB_HOST:-mysql}
DB_PORT=${DB_PORT:-3306}
DB_NAME=${DB_NAME:-yii2}
DB_USERNAME=${DB_USERNAME:-root}
DB_PASSWORD=${DB_PASSWORD:-password}
REDIS_HOST=${REDIS_HOST:-redis}
REDIS_PORT=${REDIS_PORT:-6379}
REDIS_PASSWORD=${REDIS_PASSWORD:-}
EOF
fi

# 安装 Composer 依赖（如果存在 composer.json）
if [ -f "/app/composer.json" ] && [ ! -d "/app/vendor" ]; then
    echo "安装 Composer 依赖..."
    cd /app
    composer install --no-dev --optimize-autoloader --no-interaction
fi

# 执行数据库迁移（如果使用）
if [ "${RUN_MIGRATIONS}" = "true" ]; then
    echo "执行数据库迁移..."
    cd /app
    php yii migrate/up --interactive=0
fi

# 清除缓存
echo "清除缓存..."
rm -rf /app/backend/runtime/cache/*

# 启动 PHP-FPM
echo "启动 PHP-FPM..."
php-fpm -D

# 启动 Nginx
echo "启动 Nginx..."
nginx -g "daemon off;" &

# 等待所有服务
wait -n