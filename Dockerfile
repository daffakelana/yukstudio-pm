# Base PHP image
FROM php:8.3-fpm

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    unzip \
    nodejs \
    npm \
    libpng-dev \
    libzip-dev \
    libonig-dev \
    libxml2-dev \
    libicu-dev \
    zip

RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd intl zip

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www

# Copy project files into container
COPY . .

# ENV sebelum composer
ENV APP_ENV=production
ENV APP_KEY=base64:X+wV86VcUvKwcKyBTHA3O7OFXlVmu+9e43DLiz2NRms=

# Install PHP dependencies (ini HARUS selesai dulu!)
RUN composer install --no-dev --optimize-autoloader

# Clear Laravel caches
RUN php artisan optimize:clear

# Publish Filament assets (fonts, etc)
RUN php artisan vendor:publish --tag=filament-public --force

# Generate Filament assets
RUN php artisan filament:assets

# Build Vite assets
RUN npm install
RUN npm run build

# Permissions
RUN chmod -R 775 storage bootstrap/cache

EXPOSE 8080

CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=8080"]
