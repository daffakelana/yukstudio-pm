# PHP base image
FROM php:8.2-fpm

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git curl zip unzip \
    libpng-dev libjpeg-dev libfreetype6-dev \
    libonig-dev libzip-dev libicu-dev libxml2-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd intl zip

# Install Node.js 20
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs

# Create working directory
WORKDIR /var/www

# Copy only composer files first for cache optimization
COPY composer.json composer.lock ./

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Install PHP dependencies BEFORE npm run build
RUN composer install \
    --no-dev \
    --prefer-dist \
    --optimize-autoloader

# Copy package.json first (better cache)
COPY package.json package-lock.json ./

# Install Node/Vite dependencies
RUN npm install

# Copy the whole application
COPY . .

# Build frontend AFTER vendor exists
RUN npm run build

# Laravel optimize
RUN php artisan optimize:clear && php artisan optimize

# Expose port used by Railway
EXPOSE 8000

# Start PHP-FPM
CMD ["php-fpm"]
