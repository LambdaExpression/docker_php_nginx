# Dockerfile
FROM php:7.0.33-fpm-alpine3.7

# 安装 Nginx、PHP 扩展和必要的工具
RUN apk update && apk add --no-cache \
    # Nginx
    nginx \
    # 开发工具
    build-base \
    autoconf \
    git \
    curl \
    wget \
    vim \
    tzdata \
    # PHP 依赖库
    libzip-dev \
    libxml2-dev \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    libmcrypt-dev \
    icu-dev \
    openssl-dev \
    bzip2-dev \
    # 数据库客户端（可选）
    mysql-client \
    postgresql-client \
    && rm -rf /var/cache/apk/*

# 安装系统依赖
RUN apk update && apk add --no-cache \
    freetype-dev \
    libjpeg-turbo-dev \
    libpng-dev \
    libxml2-dev \
    libzip-dev \
    postgresql-dev \
    bzip2-dev \
    gettext-dev \
    icu-dev \
    libxslt-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd \
    && docker-php-ext-install zip xml json mbstring pdo pdo_mysql pdo_pgsql mysqli opcache bcmath bz2 intl pcntl soap sockets

# 安装 Redis 扩展（需要从源码编译）
RUN apk add --no-cache --virtual .build-deps \
    linux-headers \
    && mkdir -p /usr/src/php/ext/redis \
    && curl -fsSL https://pecl.php.net/get/redis-3.1.6.tgz | tar xvz -C /usr/src/php/ext/redis --strip 1 \
    && docker-php-ext-install redis \
    && apk del .build-deps

# 安装其他 PECL 扩展
RUN pecl install mcrypt-1.0.1 \
    && docker-php-ext-enable mcrypt

# 设置时区
RUN cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Asia/Shanghai" > /etc/timezone

# 配置 PHP
COPY config/php.ini /usr/local/etc/php/conf.d/custom.ini
COPY config/opcache.ini /usr/local/etc/php/conf.d/opcache.ini

# 配置 Nginx
RUN mkdir -p /run/nginx \
    && chown -R www-data:www-data /run/nginx \
    && chown -R www-data:www-data /var/lib/nginx

COPY config/nginx.conf /etc/nginx/nginx.conf
COPY config/default.conf /etc/nginx/conf.d/default.conf

# 创建项目目录
RUN mkdir -p /app \
    && chown -R www-data:www-data /app \
    && mkdir -p /var/www/html \
    && chown -R www-data:www-data /var/www/html

# 创建测试页面
RUN echo "<?php phpinfo(); ?>" > /var/www/html/info.php \
    && echo "<!DOCTYPE html><html><head><title>Welcome</title></head><body><h1>PHP $(php -v | head -n 1 | awk '{print \$2}') with Nginx</h1><p>Extensions: $(php -m | wc -l)</p></body></html>" > /var/www/html/index.html

# 设置工作目录
WORKDIR /app

# 复制启动脚本
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# 暴露端口
EXPOSE 80 9000

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost/ || exit 1

# 启动服务
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["supervisord", "-c", "/etc/supervisor/supervisord.conf"]