# PHP base image (8.3)
FROM php:8.3-fpm

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

# Copy composer files
COPY composer.json composer.lock ./

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Install PHP dependencies BEFORE npm build
RUN composer install \
    --no-dev \
    --prefer-dist \
    --optimize-autoloader

# Copy package.json files
COPY package.json package-lock.json ./

# Install Vite / Node dependencies
RUN npm install

# Copy entire project AFTER composer works
COPY . .

# Build Vite
RUN npm run build

# Laravel optimize
RUN php artisan optimize:clear && php artisan optimize

# Railway uses reverse proxy, FPM run at 8000 for safety
EXPOSE 8000

CMD ["php-fpm"]
