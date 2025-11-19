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

# Set ENV sebelum composer install
ENV APP_ENV=production

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Install PHP dependencies
RUN composer install \
    --no-dev \
    --prefer-dist \
    --optimize-autoloader

# Clear Laravel caches
RUN php artisan optimize:clear

# Publish Filament assets (fonts, etc)
RUN php artisan vendor:publish --tag=filament-public

# Generate Filament assets
RUN php artisan filament:assets

# Install Node dependencies
RUN npm install

# Build frontend
RUN npm run build

# Set permissions
RUN chmod -R 775 storage bootstrap/cache

EXPOSE 8000

# Gunakan artisan serve atau php-fpm sesuai kebutuhan
CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=8000"]