# Dockerfile - PHP 7.0 + Nginx 基础镜像（极简版）
FROM php:7.0-fpm-alpine

# 1. 安装所有包并清理（一次性完成）
RUN apk update && \
    # 安装运行时需要的包
    apk add --no-cache \
    nginx \
    curl \
    tzdata \
    # 运行时库依赖
    libzip \
    libxml2 \
    libpng \
    libjpeg-turbo \
    freetype \
    icu-libs \
    libbz2 \
    libssl1.0 && \
    # 安装构建依赖
    apk add --no-cache --virtual .build-deps \
    libzip-dev \
    libxml2-dev \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    icu-dev \
    openssl-dev \
    bzip2-dev \
    autoconf \
    g++ \
    make && \
    # 安装 PHP 扩展
    docker-php-ext-install \
    zip \
    xml \
    json \
    mbstring \
    pdo \
    pdo_mysql \
    mysqli \
    bcmath \
    bz2 \
    intl \
    pcntl \
    soap \
    sockets \
    tokenizer && \
    # 安装 GD 扩展
    docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ && \
    docker-php-ext-install gd && \
    # 安装 Redis 扩展
    pecl install redis-3.1.6 && \
    docker-php-ext-enable redis && \
    # 启用 Opcache
    docker-php-ext-enable opcache && \
    # 删除构建依赖
    apk del .build-deps && \
    # 清理缓存
    rm -rf /var/cache/apk/* /tmp/* /var/tmp/*

# 2. 配置时区和 PHP 设置
RUN cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo "Asia/Shanghai" > /etc/timezone && \
    echo "date.timezone = Asia/Shanghai" > /usr/local/etc/php/conf.d/timezone.ini && \
    echo "memory_limit = 256M" > /usr/local/etc/php/conf.d/memory.ini && \
    echo "upload_max_filesize = 50M" > /usr/local/etc/php/conf.d/uploads.ini && \
    echo "post_max_size = 50M" >> /usr/local/etc/php/conf.d/uploads.ini && \
    echo "max_execution_time = 300" > /usr/local/etc/php/conf.d/execution.ini && \
    echo "[opcache]" > /usr/local/etc/php/conf.d/opcache.ini && \
    echo "opcache.enable=1" >> /usr/local/etc/php/conf.d/opcache.ini && \
    echo "opcache.enable_cli=1" >> /usr/local/etc/php/conf.d/opcache.ini && \
    echo "opcache.memory_consumption=128" >> /usr/local/etc/php/conf.d/opcache.ini

# 3. 创建目录和测试页面
RUN mkdir -p /run/nginx /app /var/www/html && \
    chown -R www-data:www-data /run/nginx /app /var/www/html && \
    echo "<?php phpinfo(); ?>" > /var/www/html/test.php

# 4. 工作目录
WORKDIR /app

# 5. 暴露端口
EXPOSE 80 9000

# 6. 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost/test.php > /dev/null 2>&1 || exit 1

# 7. 默认命令
CMD ["echo", "Optimized Yii2 PHP 7.0 + Nginx base image. Size optimized with build dependencies removed."]