# ============================
# Stage 1: Build Vite Assets
# ============================
FROM node:18 AS frontend

WORKDIR /app
COPY package*.json ./
RUN npm install

COPY . .
RUN npm run build


# ============================
# Stage 2: PHP-FPM + Composer
# ============================
FROM php:8.3-fpm AS backend

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git curl unzip nginx supervisor \
    libpng-dev libzip-dev libonig-dev libxml2-dev libicu-dev zip \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd intl zip

# Copy composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set workdir
WORKDIR /var/www

# Copy app code
COPY . .

# Copy built frontend assets
COPY --from=frontend /app/public/build ./public/build

# Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader

# Storage & cache permission
RUN chmod -R 777 storage bootstrap/cache

# ============================
# Nginx Setup
# ============================
COPY ./nginx.conf /etc/nginx/nginx.conf

# Supervisor (run PHP-FPM + Nginx together)
COPY ./supervisor.conf /etc/supervisor/conf.d/supervisor.conf

EXPOSE 8080

CMD ["/usr/bin/supervisord"]
