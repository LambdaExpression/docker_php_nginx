# Dockerfile - PHP 7.0 + Nginx 基础镜像
FROM php:7.0.33-fpm-alpine3.7

# 安装 Nginx 和必要的 PHP 扩展
RUN apk update && apk add --no-cache \
    # Nginx
    nginx \
    # 系统工具
    curl \
    wget \
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
    # PHP 扩展包
    php7-redis \
    php7-pdo_mysql \
    php7-mysqli \
    php7-mbstring \
    php7-xml \
    php7-json \
    php7-gd \
    php7-bcmath \
    php7-opcache \
    php7-intl \
    php7-zip \
    php7-bz2 \
    php7-pcntl \
    php7-soap \
    php7-sockets \
    php7-tokenizer \
    && rm -rf /var/cache/apk/*

# 从源码编译安装 mcrypt 扩展（PHP 7.0 需要）
RUN apk add --no-cache --virtual .build-deps \
    libmcrypt-dev \
    && pecl install mcrypt-1.0.1 \
    && docker-php-ext-enable mcrypt \
    && apk del .build-deps

# 配置 GD 库
RUN docker-php-ext-configure gd \
    --with-freetype-dir=/usr/include/ \
    --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install gd

# 配置时区
RUN cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Asia/Shanghai" > /etc/timezone \
    && echo "date.timezone = Asia/Shanghai" > /usr/local/etc/php/conf.d/timezone.ini

# 配置基本的 PHP 设置
RUN echo "memory_limit = 256M" > /usr/local/etc/php/conf.d/memory.ini \
    && echo "upload_max_filesize = 50M" >> /usr/local/etc/php/conf.d/uploads.ini \
    && echo "post_max_size = 50M" >> /usr/local/etc/php/conf.d/uploads.ini \
    && echo "max_execution_time = 300" > /usr/local/etc/php/conf.d/execution.ini \
    && echo "max_input_time = 300" >> /usr/local/etc/php/conf.d/execution.ini \
    && echo "error_log = /var/log/php_error.log" > /usr/local/etc/php/conf.d/errors.ini \
    && echo "log_errors = On" >> /usr/local/etc/php/conf.d/errors.ini \
    && echo "display_errors = Off" >> /usr/local/etc/php/conf.d/errors.ini

# 配置 Opcache
RUN echo "[opcache]" > /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.enable=1" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.enable_cli=1" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.memory_consumption=128" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.interned_strings_buffer=8" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.max_accelerated_files=10000" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.validate_timestamps=0" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.revalidate_freq=2" >> /usr/local/etc/php/conf.d/opcache.ini

# 创建必要的目录和权限
RUN mkdir -p /run/nginx \
    && chown -R www-data:www-data /run/nginx \
    && mkdir -p /app \
    && chown -R www-data:www-data /app \
    && mkdir -p /var/www/html \
    && chown -R www-data:www-data /var/www/html

# 创建测试页面
RUN echo "<?php" > /var/www/html/test.php \
    && echo "phpinfo();" >> /var/www/html/test.php \
    && echo "?>" >> /var/www/html/test.php

# 创建简单的健康检查脚本
RUN echo '#!/bin/sh' > /healthcheck.sh \
    && echo 'curl -f http://localhost/test.php > /dev/null 2>&1 || exit 1' >> /healthcheck.sh \
    && chmod +x /healthcheck.sh

# 设置工作目录
WORKDIR /app

# 暴露端口
EXPOSE 80 9000

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD /healthcheck.sh

# 列出已安装的扩展
RUN echo "=== 已安装的 PHP 扩展 ===" && php -m

# 默认命令（显示帮助信息）
CMD ["echo", "This is a base image with PHP 7.0.33, Nginx and required extensions. Use this as base for your Yii2 application."]