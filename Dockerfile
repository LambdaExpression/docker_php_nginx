# Dockerfile
FROM php:7.0.4-fpm

# 安装 Nginx 和必要的工具
RUN apk update && apk add --no-cache \
    # Nginx
    nginx \
    curl \
    wget \
    vim \
    tzdata \
    && rm -rf /var/cache/apk/*

# 设置时区
RUN cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Asia/Shanghai" > /etc/timezone

# 创建测试页面
RUN mkdir -p /var/www/html
RUN echo "<!DOCTYPE html><html><head><title>Welcome</title></head><body><h1>Node.js $(node -v) with Nginx</h1><p>Yarn $(yarn --version)</p></body></html>" > /var/www/html/index.html

# 设置工作目录
WORKDIR /app

# 暴露端口
EXPOSE 80

# 启动 nginx
CMD ["nginx"]