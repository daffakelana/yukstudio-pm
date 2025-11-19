FROM php:8.3-fpm

# Install dependencies
RUN apt-get update && apt-get install -y \
    git curl zip unzip \
    libpng-dev libjpeg-dev libfreetype6-dev \
    libonig-dev libzip-dev libicu-dev libxml2-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd intl zip

# Install Node.js 20
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs

# Workdir
WORKDIR /var/www

# Copy all project files
COPY . .

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Install PHP dependencies
RUN composer install \
    --no-dev \
    --prefer-dist \
    --optimize-autoloader

# Publish Filament assets & views (PENTING!)
RUN php artisan filament:assets
RUN php artisan vendor:publish --tag=filament-config 
RUN php artisan vendor:publish --tag=filament-views 

# Install Node dependencies
RUN npm install

# Build frontend
RUN npm run build

# Laravel optimize (hapus optimize view yang bermasalah)
RUN php artisan optimize:clear
RUN php artisan config:cache
RUN php artisan route:cache

# Set permissions
RUN chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache

EXPOSE 8000

CMD ["php-fpm"]