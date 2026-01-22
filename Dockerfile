# Dockerfile - PHP 7.0 + Nginx 基础镜像（无 mcrypt）
FROM php:5.6.30-fpm-alpine

# 1. 更新包管理器
RUN apk update

# 2. 安装 Nginx
RUN apk add --no-cache nginx

# 3. 安装所有 PHP 扩展依赖
RUN apk add --no-cache libzip-dev libxml2-dev libpng-dev libjpeg-turbo-dev
RUN apk add --no-cache freetype-dev icu-dev openssl-dev
RUN apk add --no-cache bzip2-dev

# 4. 安装系统工具
RUN apk add --no-cache curl wget git vim unzip tzdata

# 5. 安装 PHP 核心扩展
RUN docker-php-ext-install zip xml json mbstring
RUN docker-php-ext-install pdo pdo_mysql mysqli
RUN docker-php-ext-install bcmath bz2 intl pcntl
RUN docker-php-ext-install soap sockets tokenizer

# 6. 安装并配置 GD 扩展
RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/
RUN docker-php-ext-install gd

# 7. 安装 Redis 扩展
RUN apk add --no-cache autoconf g++ make
RUN pecl install redis-3.1.6
RUN docker-php-ext-enable redis
RUN apk del autoconf g++ make

# 8. 启用 Opcache
RUN docker-php-ext-enable opcache

# 9. 配置时区
RUN cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
RUN echo "Asia/Shanghai" > /etc/timezone

# 10. 配置 PHP 设置
RUN echo "date.timezone = Asia/Shanghai" > /usr/local/etc/php/conf.d/timezone.ini
RUN echo "memory_limit = 256M" > /usr/local/etc/php/conf.d/memory.ini
RUN echo "upload_max_filesize = 50M" > /usr/local/etc/php/conf.d/uploads.ini
RUN echo "post_max_size = 50M" >> /usr/local/etc/php/conf.d/uploads.ini
RUN echo "max_execution_time = 300" > /usr/local/etc/php/conf.d/execution.ini

# 11. 配置 Opcache
RUN echo "[opcache]" > /usr/local/etc/php/conf.d/opcache.ini
RUN echo "opcache.enable=1" >> /usr/local/etc/php/conf.d/opcache.ini
RUN echo "opcache.enable_cli=1" >> /usr/local/etc/php/conf.d/opcache.ini
RUN echo "opcache.memory_consumption=128" >> /usr/local/etc/php/conf.d/opcache.ini

# 12. 创建目录和权限
RUN mkdir -p /run/nginx /app /var/www/html
RUN chown -R www-data:www-data /run/nginx /app /var/www/html

# 13. 测试页面
RUN echo "<?php phpinfo(); ?>" > /var/www/html/test.php

# 14. 工作目录
WORKDIR /app

# 15. 暴露端口
EXPOSE 80 9000

# 16. 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost/test.php > /dev/null 2>&1 || exit 1

# 17. 默认命令
CMD ["echo", "Yii2 PHP 7.0 + Nginx base image ready"]