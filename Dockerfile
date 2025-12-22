# Dockerfile - 基于 Alpine 的 PHP 7.0 + Nginx
FROM php:7.0-fpm-alpine

# 使用国内镜像源加速（针对中国用户）
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories

# 1. 更新并安装基础包
RUN apk update

# 2. 安装 Nginx
RUN apk add --no-cache nginx

# 3. 安装 PHP 扩展依赖
RUN apk add --no-cache libzip-dev
RUN apk add --no-cache libxml2-dev
RUN apk add --no-cache libpng-dev
RUN apk add --no-cache libjpeg-turbo-dev
RUN apk add --no-cache freetype-dev
RUN apk add --no-cache libmcrypt-dev
RUN apk add --no-cache icu-dev
RUN apk add --no-cache openssl-dev
RUN apk add --no-cache bzip2-dev

# 4. 安装系统工具
RUN apk add --no-cache curl
RUN apk add --no-cache wget
RUN apk add --no-cache git
RUN apk add --no-cache vim
RUN apk add --no-cache unzip
RUN apk add --no-cache tzdata

# 5. 安装 PHP 扩展
RUN docker-php-ext-install zip
RUN docker-php-ext-install xml
RUN docker-php-ext-install json
RUN docker-php-ext-install mbstring
RUN docker-php-ext-install pdo
RUN docker-php-ext-install pdo_mysql
RUN docker-php-ext-install pdo_pgsql
RUN docker-php-ext-install mysqli
RUN docker-php-ext-install bcmath
RUN docker-php-ext-install bz2
RUN docker-php-ext-install intl
RUN docker-php-ext-install pcntl
RUN docker-php-ext-install soap
RUN docker-php-ext-install sockets
RUN docker-php-ext-install tokenizer

# 6. 安装 GD 扩展
RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/
RUN docker-php-ext-install gd

# 7. 安装 Redis 扩展
RUN apk add --no-cache autoconf g++ make
RUN pecl install redis-3.1.6
RUN docker-php-ext-enable redis
RUN apk del autoconf g++ make

# 8. 安装 mcrypt 扩展
RUN apk add --no-cache autoconf g++ make
RUN pecl install mcrypt-1.0.1
RUN docker-php-ext-enable mcrypt
RUN apk del autoconf g++ make

# 9. 启用 Opcache
RUN docker-php-ext-enable opcache

# 10. 配置时区
RUN cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
RUN echo "Asia/Shanghai" > /etc/timezone
RUN echo "date.timezone = Asia/Shanghai" > /usr/local/etc/php/conf.d/timezone.ini

# 11. 配置基本的 PHP 设置
RUN echo "memory_limit = 256M" > /usr/local/etc/php/conf.d/memory.ini
RUN echo "upload_max_filesize = 50M" >> /usr/local/etc/php/conf.d/uploads.ini
RUN echo "post_max_size = 50M" >> /usr/local/etc/php/conf.d/uploads.ini
RUN echo "max_execution_time = 300" > /usr/local/etc/php/conf.d/execution.ini
RUN echo "max_input_time = 300" >> /usr/local/etc/php/conf.d/execution.ini

# 12. 配置错误日志
RUN echo "error_log = /var/log/php_error.log" > /usr/local/etc/php/conf.d/errors.ini
RUN echo "log_errors = On" >> /usr/local/etc/php/conf.d/errors.ini
RUN echo "display_errors = Off" >> /usr/local/etc/php/conf.d/errors.ini
RUN echo "display_startup_errors = Off" >> /usr/local/etc/php/conf.d/errors.ini

# 13. 配置 Opcache
RUN echo "[opcache]" > /usr/local/etc/php/conf.d/opcache.ini
RUN echo "opcache.enable=1" >> /usr/local/etc/php/conf.d/opcache.ini
RUN echo "opcache.enable_cli=1" >> /usr/local/etc/php/conf.d/opcache.ini
RUN echo "opcache.memory_consumption=128" >> /usr/local/etc/php/conf.d/opcache.ini
RUN echo "opcache.interned_strings_buffer=8" >> /usr/local/etc/php/conf.d/opcache.ini
RUN echo "opcache.max_accelerated_files=10000" >> /usr/local/etc/php/conf.d/opcache.ini
RUN echo "opcache.validate_timestamps=0" >> /usr/local/etc/php/conf.d/opcache.ini
RUN echo "opcache.revalidate_freq=2" >> /usr/local/etc/php/conf.d/opcache.ini

# 14. 创建必要的目录和权限
RUN mkdir -p /run/nginx
RUN chown -R www-data:www-data /run/nginx
RUN mkdir -p /app
RUN chown -R www-data:www-data /app
RUN mkdir -p /var/www/html
RUN chown -R www-data:www-data /var/www/html

# 15. 创建测试页面
RUN echo "<?php" > /var/www/html/test.php
RUN echo "phpinfo();" >> /var/www/html/test.php
RUN echo "?>" >> /var/www/html/test.php

# 16. 创建简单的健康检查脚本
RUN echo '#!/bin/sh' > /healthcheck.sh
RUN echo 'curl -f http://localhost/test.php > /dev/null 2>&1 || exit 1' >> /healthcheck.sh
RUN chmod +x /healthcheck.sh

# 17. 设置工作目录
WORKDIR /app

# 18. 暴露端口
EXPOSE 80 9000

# 19. 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD /healthcheck.sh

# 20. 列出已安装的扩展
RUN echo "=== 已安装的 PHP 扩展 ==="
RUN php -m

# 21. 默认命令（显示帮助信息）
CMD ["echo", "This is a base image with PHP 7.0, Nginx and required extensions. Use this as base for your Yii2 application."]