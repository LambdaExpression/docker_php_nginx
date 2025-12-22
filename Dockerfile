# Dockerfile - PHP 7.0 + Nginx 基础镜像 (基于 Debian)
FROM php:7.0.33-fpm

# 1. 更新包列表
RUN apt-get update

# 2. 安装 Nginx
RUN apt-get install -y nginx

# 3. 安装 PHP 依赖库
RUN apt-get install -y libzip-dev
RUN apt-get install -y libxml2-dev
RUN apt-get install -y libpng-dev
RUN apt-get install -y libjpeg-dev
RUN apt-get install -y libfreetype6-dev
RUN apt-get install -y libmcrypt-dev
RUN apt-get install -y libicu-dev
RUN apt-get install -y libssl-dev
RUN apt-get install -y libbz2-dev
RUN apt-get install -y libcurl4-openssl-dev

# 4. 安装系统工具
RUN apt-get install -y curl
RUN apt-get install -y wget
RUN apt-get install -y git
RUN apt-get install -y vim
RUN apt-get install -y unzip
RUN apt-get install -y tzdata

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

# 7. 安装 Redis 扩展 (从源码编译)
RUN pecl install redis-3.1.6
RUN docker-php-ext-enable redis

# 8. 安装 mcrypt 扩展
RUN pecl install mcrypt-1.0.1
RUN docker-php-ext-enable mcrypt

# 9. 安装 Opcache (已经包含在 PHP 中，只需启用)
RUN docker-php-ext-enable opcache

# 10. 配置时区
RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
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

# 14. 清理缓存
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/*

# 15. 创建必要的目录和权限
RUN mkdir -p /run/nginx
RUN chown -R www-data:www-data /run/nginx
RUN mkdir -p /app
RUN chown -R www-data:www-data /app
RUN mkdir -p /var/www/html
RUN chown -R www-data:www-data /var/www/html

# 16. 创建测试页面
RUN echo "<?php" > /var/www/html/test.php
RUN echo "phpinfo();" >> /var/www/html/test.php
RUN echo "?>" >> /var/www/html/test.php

# 17. 创建简单的健康检查脚本
RUN echo '#!/bin/bash' > /healthcheck.sh
RUN echo 'curl -f http://localhost/test.php > /dev/null 2>&1 || exit 1' >> /healthcheck.sh
RUN chmod +x /healthcheck.sh

# 18. 设置工作目录
WORKDIR /app

# 19. 暴露端口
EXPOSE 80 9000

# 20. 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD /healthcheck.sh

# 21. 列出已安装的扩展
RUN echo "=== 已安装的 PHP 扩展 ==="
RUN php -m

# 22. 默认命令（显示帮助信息）
CMD ["echo", "This is a base image with PHP 7.0.33, Nginx and required extensions. Use this as base for your Yii2 application."]